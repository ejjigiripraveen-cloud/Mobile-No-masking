import { LightningElement, api, track, wire } from 'lwc';
import getMessagingSessionId from '@salesforce/apex/LeadMsgConversationController.getMessagingSessionId';
import whatsappIcon from '@salesforce/resourceUrl/whatsappIcon';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import { sendTextMessage, getConversationLog } from 'lightning/conversationToolkitApi'
import { subscribe as lmsSubscribe, unsubscribe as lmsUnsubscribe, MessageContext } from 'lightning/messageService';
import CONVERSATION_MESSAGE_CHANNEL from '@salesforce/messageChannel/lightning__conversationEndUserMessage';
import getTransferContext from '@salesforce/apex/LeadMsgConversationController.getTransferContext';
import transferMessagingSession from '@salesforce/apex/LeadMsgConversationController.transferMessagingSession';
import notifyLeadStakeholders from '@salesforce/apex/LeadMsgConversationController.notifyLeadStakeholders';
import getSessionAttachments from '@salesforce/apex/LeadMsgConversationController.getSessionAttachments';
// === CONNECT REST API FALLBACK — NEW IMPORT — START ===
import getConversationViaConnectApi from '@salesforce/apex/LeadMsgConversationController.getConversationViaConnectApi';
// === CONNECT REST API FALLBACK — NEW IMPORT — END ===

export default class LeadMsgConversationLWC extends NavigationMixin(LightningElement) {

    @api recordId;
    @api leadId;
    currentUserProfileId;
    error;
    @track messages = [];
    @track hasMessages = false;
    whatsappLogo = whatsappIcon;
    _refreshing = false;
    _toolkitAvailable = true;
    _pollHandle = null;
    _lastAttachmentCount = 0;
    POLL_INTERVAL_MS = 6000;
    @track isTransferring = false;
    currentUserId;
    sessionOwnerId;
    sessionStatus;
    canTransfer = false;
    transferSessionId;
    lmsSubscription = null;
    @track selectedFileName = '';
    selectedFileBase64 = '';
    _lastMessagesSignature = '';
    @track isLoading = false;
    isInitialLoad = true;
    @track showImagePreview = false;
    @track previewImageUrl = '';
    @track isSendingFile = false;
    shouldScroll = false;
    _lastMessageCount = 0;
    _lastConfirmedAttachmentCount = 0;
    @wire(MessageContext)
    messageContext;
    @wire(CurrentPageReference)
    pageRef(pageRef) {
        if (pageRef && !this.leadId) {
            this.recordId = pageRef?.attributes?.recordId;
        }
    }

    connectedCallback() {
        if (this.leadId) {
            this.recordId = this.leadId;
        }
        this.loadConversation();
        this.loadTransferContext();
        this.subscribeToMessageChannel();
        this.startPolling();
    }

    disconnectedCallback() {
        this.unsubscribeFromMessageChannel();
        this.stopPolling();
    }
    subscribeToMessageChannel() {
        if (!this.lmsSubscription) {
            this.lmsSubscription = lmsSubscribe(
                this.messageContext,
                CONVERSATION_MESSAGE_CHANNEL,
                (message) => this.handleEndUserMessage(message)
            );
        }
    }

    unsubscribeFromMessageChannel() {
        if (this.lmsSubscription) {
            lmsUnsubscribe(this.lmsSubscription);
            this.lmsSubscription = null;
        }
    }

    // Guarded refresh so overlapping events don't fire multiple reloads at once
    async refreshConversation() {
        if (this._refreshing) return;
        this._refreshing = true;
        try {
            await this.loadConversation();
        } finally {
            this._refreshing = false;
        }
    }

    startPolling() {
        if (this._pollHandle) return;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._pollHandle = setInterval(() => this.pollForUpdates(), this.POLL_INTERVAL_MS);
    }

    stopPolling() {
        if (this._pollHandle) {
            clearInterval(this._pollHandle);
            this._pollHandle = null;
        }
    }

    // === NON-OWNER LIVE REFRESH — START ===
    // The session owner already gets near-instant updates via the LMS
    // subscription (handleEndUserMessage) for inbound customer messages,
    // and an immediate refresh right after they send something themselves.
    // SV_User__c / Sales_User__c / Lead Owner viewing WITHOUT owning the
    // toolkit session have no such push event, so — just like attachments
    // already did — we poll on the same cadence and pull a full refresh,
    // so they see the owner's new sent/received messages within ~6 seconds.
    async pollForUpdates() {
        if (this._refreshing) return;
        try {
            if (this._toolkitAvailable === false) {
                await this.refreshConversation();
                return;
            }
   
            const atts = await getSessionAttachments({ leadId: this.recordId });
            const attachmentCount = (atts || []).length;

            const confirmedSendTimestamps = await this.getConfirmedSendTimestamps();
            const confirmedCount = confirmedSendTimestamps.length;

            if (
                attachmentCount !== this._lastAttachmentCount ||
                confirmedCount !== this._lastConfirmedAttachmentCount
            ) {
                this._lastAttachmentCount = attachmentCount;
                this._lastConfirmedAttachmentCount = confirmedCount;

                await this.refreshConversation();
            }
        } catch (e) {
            console.error('pollForUpdates error =>', JSON.stringify(e));
        }
    }
    // === NON-OWNER LIVE REFRESH — END ===

    /* =========================================================
      TRANSFER: pull owner/SV/Sales/session state for buttons
   ========================================================= */
    async loadTransferContext() {
        try {
            const ctx = await getTransferContext({ leadId: this.recordId });
            console.log('ctx::' + JSON.stringify(ctx));
            this.applyTransferContext(ctx);
        } catch (error) {
            console.error('loadTransferContext error => ', JSON.stringify(error));
        }
    }

    applyTransferContext(ctx) {
        if (!ctx) return;
        this.currentUserId = ctx.currentUserId;
        this.sessionOwnerId = ctx.sessionOwnerId;
        this.sessionStatus = ctx.sessionStatus;
        this.transferSessionId = ctx.sessionId;
        this.canTransfer = ctx.canTransfer;
    }

    /* ---------- button getters ---------- */
    get hasActiveSession() {
        return !!this.transferSessionId && this.sessionStatus === 'Active';
    }
    get isOwner() {
        return !!this.currentUserId && this.currentUserId === this.sessionOwnerId;
    }
    get disableTransferToMe() {
        return this.isTransferring || !this.hasActiveSession || this.isOwner || !this.canTransfer;
    }
    get disableClickToChat() {
    return !this.hasActiveSession || !this.isOwner;
}

    /* ---------- transfer handlers ---------- */
    handleTransferToMe() { this.transferTo('ME'); }

    async transferTo(userType) {
        this.isTransferring = true;
        try {
            const ctx = await transferMessagingSession({ leadId: this.recordId, userType });
            console.log('ctx+++++::' + JSON.stringify(ctx))
            this.applyTransferContext(ctx);
            this.dispatchEvent(new ShowToastEvent({
                title: 'Transferred',
                message: 'Conversation ownership updated.',
                variant: 'success'
            }));
            await this.loadConversation();
        } catch (error) {
            const msg = (error && error.body && error.body.message)
                || (error && error.message) || 'Transfer failed.';
            this.dispatchEvent(new ShowToastEvent({
                title: 'Transfer failed',
                message: msg,
                variant: 'error'
            }));
        } finally {
            this.isTransferring = false;
        }
    }

    /* =========================================================
       ATTACHMENTS — UNCHANGED, working as-is
    ========================================================= */
   async loadAttachments(confirmedSendTimestamps = []) {
    try {
        console.log('Inside loadAttachments::');
        const atts = await getSessionAttachments({ leadId: this.recordId });
        console.log('att loadAttachments::' + JSON.stringify(atts));
        this._lastAttachmentCount = (atts || []).length;
        console.log('_lastAttachmentCount::'+this._lastAttachmentCount);
        // atts are already ordered oldest -> newest (SOQL ORDER BY CreatedDate ASC)
        const outboundAtts = (atts || []).filter(a => a.isOutbound === true);
        console.log('outboundAtts::' + JSON.stringify(outboundAtts));
        const outboundTimestamps = outboundAtts.map(a => Number(a.createdDate));
        console.log('outboundTimestamps::' + JSON.stringify(outboundTimestamps));
        // Two-pointer interval matching: a confirmation can only be claimed
        // by an upload if it falls BEFORE the next upload's timestamp too -
        // this stops an earlier cancelled/unsent upload from "stealing" a
        // confirmation that actually belongs to a later, real send.
        const matchedContentVersionIds = new Set();
        let confIdx = 0;
        const TOLERANCE_BEFORE_MS = 2000; // confirmation can land up to 2s "before" upload timestamp (clock skew)

        for (let u = 0; u < outboundAtts.length; u++) {
             console.log('inside for::');
            const uploadTs = outboundTimestamps[u];
            console.log('uploadTs::' + JSON.stringify(uploadTs));
            const nextUploadTs = (u + 1 < outboundTimestamps.length) ? outboundTimestamps[u + 1] : Infinity;
            console.log('nextUploadTs::' + JSON.stringify(nextUploadTs));
            // skip confirmations too old to belong to this upload
            while (confIdx < confirmedSendTimestamps.length &&
                   confirmedSendTimestamps[confIdx] < uploadTs - TOLERANCE_BEFORE_MS) {
                    console.log('inside While Loop::');
                confIdx++;
            }

            // this confirmation is only valid for THIS upload if it happens
            // before the NEXT upload starts - otherwise it belongs to that one
            if (confIdx < confirmedSendTimestamps.length &&
                confirmedSendTimestamps[confIdx] < nextUploadTs) {
                    console.log('inside if condition::' );
                matchedContentVersionIds.add(outboundAtts[u].contentVersionId);
                console.log('matchedContentVersionIds::' +matchedContentVersionIds);
                confIdx++; // consume it, move to next confirmation
            }
        }

        return (atts || [])
            .filter(a => {
                console.log('inside filter::' );
                const outbound = a.isOutbound === true;
                console.log('outbound::' +outbound);
                if (!outbound) return true; // inbound customer files always shown
                console.log('matchedContentVersionIds condition::' +matchedContentVersionIds.has(a.contentVersionId));
                return matchedContentVersionIds.has(a.contentVersionId);
            })
            .map(a => {
                console.log('Map inside condition::' );
                const outbound = a.isOutbound === true;
                console.log('outbound::' +outbound);
                const hasRealData = a.dataUri && a.dataUri.length > 100;
                console.log('hasRealData::' +hasRealData);
                return {
                    id: 'att-' + a.contentVersionId,
                    message: a.title || '',
                    actorType: outbound ? 'Agent' : 'EndUser',
                    senderName: '',
                    createdDate: a.createdDate,
                    isMedia: true,
                    isImage: a.isImage,
                    isAudio: a.isAudio,
                    isVideo: a.isVideo,
                    fileUrl: (a.isAudio && hasRealData) ? a.dataUri : a.downloadUrl,
                    fileName: a.title
                };
            });
    } catch (error) {
        console.error('loadAttachments error => ', JSON.stringify(error));
        return [];
    }
}

openImagePreview(event) {
    event.stopPropagation();
    this.previewImageUrl = event.target.dataset.url;
    this.showImagePreview = true;
}

closeImagePreview(event) {
    if (event) {
        event.stopPropagation();
    }
    this.showImagePreview = false;
    this.previewImageUrl = '';
}

    /* =========================================================
       Loads rows (toolkit for owner, Connect REST API for
       non-owner), merges attachments, renders.
    ========================================================= */
    async loadConversation() {
        if (this.isInitialLoad) {
            this.isLoading = true;
        }
    try {
        const logRows = await this.getLogRows(); // still toolkit-first for text display

        // Confirmation signal is ALWAYS pulled from Connect API, regardless
        // of which path renders text messages - because getSessionAttachments
        // is shared across all viewers, so its gating must be too.
        const confirmedSendTimestamps = await this.getConfirmedSendTimestamps();

        const mediaRows = await this.loadAttachments(confirmedSendTimestamps);
        let rows = [...logRows, ...mediaRows];

        const processed = rows
            .filter(r => !r.hasAttachmentSignal)
            .sort((a, b) => Number(a.createdDate) - Number(b.createdDate))
            .filter(r => {
                if (r.isMedia) return true;
                const m = (r.message || '').trim();
                if (m === '') return false;
                const role = (r.actorType || '').toLowerCase();
                const isBareLink = /^https?:\/\/\S+$/.test(m);
                if (isBareLink && role !== 'enduser') return false;
                return true;
            })
            .map(r => this.transform(r));

        const newSignature = processed.map(m => m.id + ':' + m.message).join('|');
        if (newSignature !== this._lastMessagesSignature) {
            this._lastMessagesSignature = newSignature;

            this.messages = processed;
            this.hasMessages = processed.length > 0;

            if (this.shouldScroll || this.isInitialLoad) {
                this.scrollToBottom();
            }

            this._lastMessageCount = processed.length;
            this.shouldScroll = false;
        }
    } catch (error) {
        console.error('loadConversation error => ', JSON.stringify(error));
    }finally {
        this.isLoading = false;
        this.isInitialLoad = false;
    }
}

// NEW: dedicated confirmation fetch, always via Connect API, for both viewer types
async getConfirmedSendTimestamps() {
    try {
        const rows = await getConversationViaConnectApi({ leadId: this.recordId });
        return (rows || [])
            .filter(r => r.hasAttachmentSignal === true && (r.actorType || '').toLowerCase() === 'agent')
            .map(r => Number(r.createdDate))
            .filter(ts => !isNaN(ts))
            .sort((a, b) => a - b);
    } catch (e) {
        console.error('getConfirmedSendTimestamps error =>', JSON.stringify(e));
        return [];
    }
}

    /* =========================================================
       Owner path: getConversationLog (toolkit) — unchanged.
       Non-owner path: Connect REST API fallback — NEW.
    ========================================================= */
    async getLogRows() {
        try {
            const sessionId = await getMessagingSessionId({ leadId: this.recordId });
            console.log('sessionId =>', sessionId);
            if (!sessionId) {
                this._toolkitAvailable = false;
                // === CONNECT REST API FALLBACK — START ===
                return await this.getConnectApiRows();
                // === CONNECT REST API FALLBACK — END ===
            }

            let log;
            try {
                log = await getConversationLog(sessionId);
                this._toolkitAvailable = true;
                console.log('getConversationLog RAW =>', JSON.stringify(log));
            } catch (toolkitErr) {
                this._toolkitAvailable = false;
                console.error('TOOLKIT ERROR NAME =>', toolkitErr && toolkitErr.name);
                console.error('TOOLKIT ERROR MESSAGE =>', toolkitErr && toolkitErr.message);
                console.warn('Toolkit not available for this user; using Connect REST API fallback:',
                    toolkitErr && toolkitErr.message);
                // === CONNECT REST API FALLBACK — START ===
                return await this.getConnectApiRows();
                // === CONNECT REST API FALLBACK — END ===
            }

            const entries = log?.messages || [];
            console.log('entries=>', entries);

            const mapped = (entries || []).map(e => {
                const result = this.normaliseLogEntry(e);
                return result;
            });

            const filtered = mapped.filter(r => r !== null);
            console.log('filtered =>', JSON.stringify(filtered));

            return filtered;

        } catch (error) {
            console.error('getLogRows error => ', JSON.stringify(error));
            return [];
        }
    }

    // === CONNECT REST API FALLBACK — HELPER — START ===
    // Apex already returns rows in the exact shape transform() expects
    // (id, message, actorType, senderName, createdDate), same as the
    // toolkit path — so no extra normalisation needed here.
    async getConnectApiRows() {
        try {
            const rows = await getConversationViaConnectApi({ leadId: this.recordId });
            console.log('Connect REST API rows =>', JSON.stringify(rows));
            return (rows || []).map(r => ({
                id: r.id,
                message: r.message,
                actorType: r.actorType,
                senderName: r.senderName,
                createdDate: r.createdDate
            }));
        } catch (e) {
            console.error('getConnectApiRows error =>', JSON.stringify(e));
            return [];
        }
    }
    // === CONNECT REST API FALLBACK — HELPER — END ===

    /* =========================================================
       Maps one getConversationLog entry to our row shape — UNCHANGED
    ========================================================= */
    normaliseLogEntry(e) {
    if (!e) return null;

    const text =
        e.messageText
        || e.content?.text
        || e.value?.content?.text
        || e.body?.text
        || (typeof e.content === 'string' ? e.content : '')
        || '';

    const role = e.type || '';
    const ts = e.serverReceivedTimestamp || e.timestamp || e.clientTimestamp || e.createdDate || '';
    const id = e.id || e.identifier || e.messageId || `${ts}-${role}-${text}`;
    const senderName = e.name || e.sender?.name || '';

    if (!text && (role || '').toLowerCase() !== 'system') return null;

    return {
        id: String(id),
        message: String(text || ''),
        actorType: String(role || ''),
        senderName: String(senderName || ''),
        createdDate: String(ts || '')
    };
}
    /* =========================================================
       Row -> view model — UNCHANGED
    ========================================================= */
    transform(item) {
        const role = item.actorType ? item.actorType.toLowerCase() : '';

        const cssClass = role === 'enduser' ? 'customerMessage' : 'agentMessage';

        let senderLabel;
        if (role === 'enduser') {
            senderLabel = item.senderName || '';
        } else if (role === 'chatbot' || role === 'bot') {
            senderLabel = item.senderName || 'Bot';
        } else {
            senderLabel = 'Gsquare';
        }

        let formattedDate = item.createdDate;
        try {
            const ts = Number(item.createdDate);
            if (!isNaN(ts) && ts > 0) {
                formattedDate = new Date(ts).toLocaleString('en-IN', {
                    day: '2-digit', month: 'short', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', hour12: true
                });
            }
        } catch (e) { /* keep raw */ }

        if (item.isMedia) {
            return {
                ...item,
                cssClass,
                senderLabel,
                formattedDate,
                messageLines: []
            };
        }
        const bodyText = (item.message && item.message.trim() !== '') ? item.message : '';
        const rawLines = bodyText.replace(/\r\n/g, '\n').split('\n');
        const messageLines = rawLines.map((text, i) => ({
            key: `${item.id}-${i}`,
            value: text
        }));

        return { ...item, cssClass, senderLabel, formattedDate, messageLines };
    }

    scrollToBottom() {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            const c = this.template.querySelector('.chatContainer');
            if (c) c.scrollTop = c.scrollHeight;
        }, 100);
    }

    async handleAttachClick() {
        console.log('handleAttachClick called::');
        const sessionId = await getMessagingSessionId({ leadId: this.recordId });
        console.log('sessionId::' + sessionId);
        if (sessionId) {
            console.log('inside sessionId::' );
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: sessionId,
                    objectApiName: 'MessagingSession',
                    actionName: 'view'
                }
            }).then(url => {
                window.open(
                    url,
                    'MessagingPopup',
                    'width=800,height=600,left=200,top=100,resizable=yes,scrollbars=yes'
                );
            });
        } else {
            console.error('Cannot navigate: sessionId is missing.');
        }
    }
    
    handleInputChange(event) {
        this.replyMessage = event.target.value;
    }

    handleEndUserMessage(message) {
        console.log('conversationEndUserMessage =>', JSON.stringify(message));
        this.shouldScroll = true;
        this.refreshConversation();
        this.notifyStakeholders(message);

        [2500, 5000, 8000, 12000].forEach((delay) => {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => this.refreshConversation(), delay);
        });
    }

    notifyStakeholders(message) {
        let preview = '';
        try {
            preview = message?.content?.text
                || message?.messageText
                || message?.text
                || '';
        } catch (e) { /* ignore */ }

        notifyLeadStakeholders({ leadId: this.recordId, messagePreview: preview })
            .then(() => console.log('Stakeholder notifications sent'))
            .catch(err => console.error('notifyStakeholders error =>', JSON.stringify(err)));
    }
}