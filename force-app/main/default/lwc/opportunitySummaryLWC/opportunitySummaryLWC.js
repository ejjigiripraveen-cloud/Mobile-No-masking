import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getOpportunity         from '@salesforce/apex/OpportunitySummaryController.getOpportunity';
import getNotesAndFiles       from '@salesforce/apex/OpportunitySummaryController.getNotesAndFiles';
import getRelatedOpportunities from '@salesforce/apex/OpportunitySummaryController.getRelatedOpportunities';
import updateContactDetails   from '@salesforce/apex/OpportunitySummaryController.updateContactDetails';
import sendCustomerEmail      from '@salesforce/apex/OpportunityCredentialAPI.sendCustomerEmail';

const DOCUMENT_TITLES = ['Encumbrance Certificate', 'Sale Deed'];

const CRED_STATE = {
    IDLE    : 'IDLE',
    LOADING : 'LOADING',
    SUCCESS : 'SUCCESS',
    ERROR   : 'ERROR'
};

export default class OpportunitySummaryLWC extends NavigationMixin(LightningElement) {
    @api recordId;

    opp;
    project;
    eoi;
    _wiredOppResult;

    @track notes       = [];
    @track documents   = [];
    @track relatedOpps = [];

    isEditing      = false;
    isSaving       = false;
    isLoading      = true;
    saveError      = '';
    editEmail      = '';
    editPhone      = '';
    editMobile    = '';
    editSecMobile = '';
    editMailValid  = false;

    _credState  = CRED_STATE.IDLE;
    credMessage = '';

    /* ── Wires ─────────────────────────────────────────────────────── */

    @wire(getOpportunity, { recordId: '$recordId' })
    wiredOpportunity(result) {
        this._wiredOppResult = result;
        const { data, error } = result;
        if (data) {
            this.opp       = data.opp;
            this.project   = data.project;
            this.eoi       = data.eoi;
            this.isLoading = false;
            console.log('oppStatus::'+JSON.stringify(this.opp?.Apartment__r?.Block__r?.Project__r?.Project_Approval_Status__c));
            console.log('ProjectDetails::'+JSON.stringify(this.project));
        } else if (error) {
            console.error('Opportunity wire error:', error);
            this.isLoading = false;
        }
    }

    @wire(getNotesAndFiles, { recordId: '$recordId', documentTitles: DOCUMENT_TITLES })
    wiredNotesAndFiles({ data, error }) {
        if (data) {
            this.notes = (data.notes || []).map(n => ({
                ...n,
                TextPreview               : n.TextPreview ? n.TextPreview.substring(0, 200) : '',
                LastModifiedDateFormatted : n.LastModifiedDate
                    ? new Date(n.LastModifiedDate).toLocaleDateString('en-IN', {
                          day: '2-digit', month: 'short', year: 'numeric'
                      })
                    : ''
            }));
            this.documents = (data.files || []).map(f => ({
                ...f,
                downloadUrl : `/sfc/servlet.shepherd/document/download/${f.ContentDocumentId}`,
                ContentSize : f.ContentSize ? this.formatBytes(f.ContentSize) : ''
            }));
        } else if (error) {
            console.error('Notes/Files wire error:', error);
        }
    }

    @wire(getRelatedOpportunities, { recordId: '$recordId' })
    wiredRelatedOpportunities({ data, error }) {
        if (data) {
            this.relatedOpps = data.map(o => ({
                ...o,
                ApartmentName : o.Apartment__r?.Name || '—',
                BookingDateFormatted : o.Booking_Date__c
                    ? new Date(o.Booking_Date__c).toLocaleDateString('en-IN', {
                          day: '2-digit', month: 'short', year: 'numeric'
                      })
                    : '—'
            }));
        } else if (error) {
            console.error('Related opportunities wire error:', error);
            this.relatedOpps = [];
        }
    }

    /* ── Computed: related opportunities ──────────────────────────── */

    get hasRelatedOpps() {
        return this.relatedOpps.length > 0;
    }

    /* ── Navigation ───────────────────────────────────────────────── */

    handleRelatedOppClick(event) {
        const oppId = event.currentTarget.dataset.id;
        if (!oppId) return;

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId : oppId,
                objectApiName : 'Opportunity',
                actionName : 'view'
            }
        });
    }

    /* ── Computed: general ──────────────────────────────────────────── */

    get apartmentName() {
        return this.opp?.Apartment__r?.Name || '';
    }

    get contactEmail() {
        return this.opp?.Contact__r?.Email || '';
    }

    get PlotCostValidation(){
        return this.opp?.Total_Cost_With_Tax__c? true : false;
    }
    get showInclusiveTax() {
        console.log('booleanInc:'+this.opp?.Apartment__r?.Block__r?.Project__r?.Project_Approval_Status__c);
    return this.opp?.Apartment__r?.Block__r?.Project__r?.Project_Approval_Status__c === 'Approved'?true : false;
    }
    get showExclusiveTax() {
            console.log('booleanExc:'+this.opp?.Apartment__r?.Block__r?.Project__r?.Project_Approval_Status__c);

    return this.opp?.Apartment__r?.Block__r?.Project__r?.Project_Approval_Status__c === 'YTA'?true : false;
    }

    get hasNotes() {
        return this.notes.length > 0;
    }

    get hasDocuments() {
        return this.documents.length > 0;
    }

    get mailValidatedLabel() {
        return this.opp?.Mail_Validated__c ? 'Yes' : 'No';
    }

    get mailValidatedIcon() {
        return this.opp?.Mail_Validated__c ? 'utility:check' : 'utility:close';
    }

    get mailValidatedClass() {
        return this.opp?.Mail_Validated__c
            ? 'validBadge validBadge--yes'
            : 'validBadge validBadge--no';
    }

    get paymentValidationUrl() {
        return `/apex/Payment_Validation?id=${this.recordId}`;
    }

    get credsSentAlready() {
        return this.opp?.Contact__r?.Customer_Creds_Sent__c;
    }

    get credIsLoading() { return this._credState === CRED_STATE.LOADING; }
    get credIsError()   { return this._credState === CRED_STATE.ERROR;   }
    get credIsSuccess() { return this._credState === CRED_STATE.SUCCESS; }
    get credIsIdle()    { return this._credState === CRED_STATE.IDLE;    }

    /* ── Computed: project bank details ─────────────────────────────── */

    get hasProjectBankDetails() {
        return !!this.project;
    }

    get hasEoiDetails() {
        return !!this.eoi;
    }

    /* ── Contact edit handlers ──────────────────────────────────────── */

    handleEdit() {
        this.editEmail     = this.contactEmail;
        this.editPhone     = this.opp?.PhoneNo__c || '';
        this.editMobile   = this.opp?.Mobile__c || ''
        this.editSecMobile = this.opp.Secondary_Mobile__c || ''
        this.editMailValid = this.opp?.Mail_Validated__c || false;
        this.saveError     = '';
        this.isEditing     = true;
    }

    handleCancel() {
        this.isEditing = false;
        this.saveError = '';
    }

    handleFieldChange(event) {
        const field = event.target.dataset.field;
        if (field === 'email')     this.editEmail     = event.target.value;
        if (field === 'phone')     this.editPhone     = event.target.value;
        if (field === 'mailvalid') this.editMailValid = event.target.checked;
        if (field === 'mobile') this.editMobile = event.target.value;
        if (field === 'secmobile') this.editSecMobile = event.target.value;
    }

    async handleSave() {
        this.isSaving  = true;
        this.saveError = '';
        try {
            await updateContactDetails({
                recordId      : this.recordId,
                contactId     : this.opp?.Contact__c || null,
                accountId     : this.opp?.AccountId || null,
                email         : this.editEmail,
                phone         : this.editPhone,
                mailValidated : this.editMailValid,
                mobile    : this.editMobile,
                secmobile : this.editSecMobile
            });
            await refreshApex(this._wiredOppResult);
            this.isEditing = false;
            this.dispatchEvent(new ShowToastEvent({
                title   : 'Success',
                message : 'Contact details updated.',
                variant : 'success'
            }));
        } catch (err) {
            this.saveError = err?.body?.message || 'Save failed. Please try again.';
        } finally {
            this.isSaving = false;
        }
    }

    /* ── Credential send (manual only) ─────────────────────────────── */

    async handleSendCredentials() {
        this._credState  = CRED_STATE.LOADING;
        this.credMessage = '';
        try {
            const result = await sendCustomerEmail({ opportunityId: this.recordId });

            this._credState  = CRED_STATE.SUCCESS;
            this.credMessage = 'Customer credentials sent successfully.';

            await refreshApex(this._wiredOppResult);

            this.dispatchEvent(new ShowToastEvent({
                title   : 'Success',
                message : this.credMessage,
                variant : 'success'
            }));

        } catch (err) {
            const msg        = err?.body?.message || 'Failed to send email.';
            this._credState  = CRED_STATE.ERROR;
            this.credMessage = msg;
            this.dispatchEvent(new ShowToastEvent({
                title   : 'Error',
                message : msg,
                variant : 'error'
            }));
        }
    }

    /* ── Utilities ──────────────────────────────────────────────────── */

    formatBytes(bytes) {
        if (!bytes) return '';
        if (bytes < 1024)    return `${bytes} B`;
        if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / 1048576).toFixed(1)} MB`;
    }
}