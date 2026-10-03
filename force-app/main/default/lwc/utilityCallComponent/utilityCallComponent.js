import { LightningElement, track, wire } from 'lwc';
import triggerCall from '@salesforce/apex/OfflineCallAppAPI.triggerCall';
import getLeadPhone from '@salesforce/apex/OfflineCallAppAPI.getLeadPhone';
import getCurrentUsername from '@salesforce/apex/OfflineCallAppAPI.getCurrentUsername';
import updateCallDetailComment from '@salesforce/apex/OfflineCallAppAPI.updateCallDetailComment';
import getPicklistValues from '@salesforce/apex/OfflineCallAppAPI.getPicklistValues';
import createCallInitiatedTask from '@salesforce/apex/OfflineCallAppAPI.createCallInitiatedTask';
import isUserRecordOwner from '@salesforce/apex/OfflineCallAppAPI.isUserRecordOwner';
import getUser from '@salesforce/apex/CallDetailsAPI.getUser';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { publish, subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import CALL_DETAIL_CHANNEL from '@salesforce/messageChannel/CallDetailChannel__c';

export default class UtilityCallComponent extends LightningElement {
    @track leadId = '';
    @track cmts = '';
    @track dispositionOptions = [];
    @track subDispositionOptions = [];
    @track isOwner = false;   

    username = '';
    primaryPhoneNumber = '';
    secondaryPhoneNumber = '';
    ldId;
    callId;
    callname;
    clickedSecondary = false;
    clickedPrimary = false;
    nriStatus;
    description;
    latestCallDetailId = '';
    subscription = null;
    selectedDisposition;
    selectedSubDisposition;
    subject;

    @wire(MessageContext)
    messageContext;

    async connectedCallback() {
        this.extractLeadIdFromUrl();

        if (this.leadId) {
            try {
                this.isOwner = await isUserRecordOwner({ recordId: this.leadId });
                console.log('Is User Record Owner:', this.isOwner);
            } catch (error) {
                console.error('Error checking record ownership:', error);
                this.isOwner = false;
            }
        }

        this.loadUsernameAndPhones();
        this.subscribeToMessageChannel();
        this.fetchPicklist('Call_Detail__c', 'Disposition__c', 'dispositionOptions');
        this.fetchPicklist('Call_Detail__c', 'Sub_Dispoisition__c', 'subDispositionOptions');
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

   fetchPicklist(objectName, fieldName, targetProperty) {
    console.log(`Fetching picklist for: ${objectName}.${fieldName}, targetProperty: ${targetProperty}`);

    getPicklistValues({ objectName, fieldName })
        .then(result => {
            console.log(`Picklist result for ${fieldName}:`, JSON.stringify(result));

            this[targetProperty] = result.map(value => ({
                label: value,
                value: value
            }));
        })
        .catch(error => {
            console.error(`Error fetching picklist for ${fieldName}:`, JSON.stringify(error));
            this.showToast(
                'Error',
                `Failed to load ${fieldName} values. Details: ${error.body ? error.body.message : error.message}`,
                'error'
            );
        });
}


    async getUser(username) {
        try {
            const result = await getUser({ userName: username });
            return result?.Name || 'Unknown User';
        } catch (error) {
            console.error(`Error fetching user for ${username}:`, error);
            this.showToast('Error', `Failed to load user details`, 'error');
            return 'Unknown User';
        }
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                CALL_DETAIL_CHANNEL,
                (message) => this.handleCallDetailNotification(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        if (this.subscription) {
            unsubscribe(this.subscription);
            this.subscription = null;
        }
    }

    handleCallDetailNotification(message) {
        if (message && message.leadId === this.leadId) {
            this.latestCallDetailId = message.CallDetailId_c__c;
            this.showToast('Info', `Call ended. Call Detail ID: ${message.CallDetailId_c__c}`, 'info');
            this.loadUsernameAndPhones();
        }
    }

    handleLeadIdChange(event) {
        this.ldId = event.target.value;
    }

    handleDispositionChange(event) {
        this.selectedDisposition = event.target.value;
    }

    handleSubDispositionChange(event) {
        this.selectedSubDisposition = event.target.value;
    }

    handleCmtsChange(event) {
        this.cmts = event.target.value;
    }

    handleCallIdChange(event) {
        this.callId = event.target.value;
    }

    handleRefresh() {
        this.callId = '';
        this.showToast('Warning', 'Refresh till the recent call id is fetched.', 'Warning');
        this.loadUsernameAndPhones();
    }

    async loadUsernameAndPhones() {
        try {
            this.username = await getCurrentUsername();

            if (this.leadId) {
                const phoneMap = await getLeadPhone({ leadId: this.leadId });
                console.log('Phone Map from Apex:', phoneMap);
                this.ldId = phoneMap.LeadId;
                this.callname = phoneMap.callName ? phoneMap.callName : 'No Call Name';
                this.callId = phoneMap.callId ? phoneMap.callId : 'No Call ID';
                this.nriStatus = phoneMap.Nri;

                if (phoneMap) {
                    if ((phoneMap.PrimaryPhone && phoneMap.PrimaryPhone.length > 10) && this.nriStatus !== 'Yes') {
                        const last4 = phoneMap.PrimaryPhone.slice(-4);
                        this.primaryPhoneNumber = 'XXXXXX' + last4;
                    } else {
                        this.primaryPhoneNumber = phoneMap.PrimaryPhone;
                    }

                    if ((phoneMap.SecondaryPhone && phoneMap.SecondaryPhone.length > 10) && this.nriStatus !== 'Yes') {
                        const last4 = phoneMap.SecondaryPhone.slice(-4);
                        this.secondaryPhoneNumber = 'XXXXXX' + last4;
                    } else {
                        this.secondaryPhoneNumber = phoneMap.SecondaryPhone;
                    }
                }

                this.showToast('Info', 'Recent Call refreshed.', 'info');
            }
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }

    async handleTriggerCallPrimary() {
        this.clickedPrimary = true;
        const displayName = await this.getUser(this.username);
        this.description = `Call initiated by ${displayName} for Lead ID: ${this.ldId} on Primary Phone`;
        this.callNumber(this.primaryPhoneNumber, this.description);
    }

    async handleTriggerCallSecondary() {
        this.clickedSecondary = true;
        const displayName = await this.getUser(this.username);
        this.description = `Call initiated by ${displayName} for Lead ID: ${this.ldId} on Secondary Phone`;
        this.callNumber(this.secondaryPhoneNumber, this.description);
    }

    callNumber(phone, description) {
        if (!this.username || !phone || !this.leadId) {
            this.showToast('Error', 'Missing required data (username, phone, or lead ID).', 'error');
            return;
        }

        triggerCall({
            username: this.username,
            phoneNumber: phone,
            leadId: this.leadId
        })
            .then(() => {
                this.showToast('Success', 'Call triggered successfully.', 'success');
                this.subject = 'Call Initiated';
                console.log('Creating task with description:', description);
                console.log('Lead ID for task:', this.leadId);
                console.log('Subject for task:', this.subject);
                createCallInitiatedTask({ leadId: this.leadId, description: description, subject: this.subject })
                    .then(() => {
                        console.log('Task created for call initiation.');
                    })
                    .catch(error => {
                        console.error('Failed to create task:', error);
                        this.showToast('Error', 'Task creation failed.', 'error');
                    });
            })
            .catch(error => {
                console.error('Call trigger failed:', error);
                this.showToast('Error', 'Call failed. Check console for details.', 'error');
            });
    }

    handleSaveComments() {
        if (!this.cmts || !this.callId) {
            this.showToast('Error', 'Missing comment or Call Detail ID.', 'error');
            return;
        }

        updateCallDetailComment({
            callDetailId: this.callId,
            comment: this.cmts,
            disposition: this.selectedDisposition,
            subDisposition: this.selectedSubDisposition
        })
            .then(() => {
                this.showToast('Success', 'Comment saved successfully.', 'success');
                this.cmts = '';
            })
            .catch(error => {
                console.error('Error saving comment:', error);
                this.showToast('Error', 'Failed to save comment.', 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    notifyCallEnded(callDetailId) {
        const message = {
            leadId: this.leadId,
            callDetailId: callDetailId
        };
        publish(this.messageContext, CALL_DETAIL_CHANNEL, message);
    }

    extractLeadIdFromUrl() {
        try {
            const url = window.location.href;
            const match = url.match(/\/lead\/([a-zA-Z0-9]{15,18})/i);
            if (match) {
                this.leadId = match[1];
            }
        } catch (err) {
            console.error('Error extracting Lead ID:', err);
        }
    }
}