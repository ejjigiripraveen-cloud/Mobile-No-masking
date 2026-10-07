import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';
import hasRevealPermission from '@salesforce/customPermission/Reveal_Phone_Number';
import getMaskedNumbers from '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers';
import getReasons from '@salesforce/apex/PhoneRevealService.getReasons';
import revealNumber from '@salesforce/apex/PhoneRevealService.revealNumber';

const DESKTOP = 'Large';
const DEFAULT_ERROR = 'Unable to load phone numbers.';
const DEFAULT_REVEAL_ERROR = 'The number could not be revealed.';
const REASON_OTHER = 'Other';

/**
 * Shows a record's phone numbers masked (98XXXXXX21). The real number never reaches this component:
 * Apex returns masked values only. When click-to-dial is enabled (App Builder property, desktop only),
 * each number is rendered with lightning-click-to-dial carrying the masked value plus the record Id and
 * the field key, so the user's Open CTI softphone can resolve the real number on the server.
 *
 * Reveal (v1.6.0): users with the custom permission Reveal_Phone_Number (Team Leads, Heads, Admins) see a
 * Reveal button per number. They pick one of the approved reasons (comment required for "Other"); Apex checks
 * the permission, audits the reveal and returns the number, which is shown for the configured seconds (30)
 * and then removed from the component.
 */
export default class MaskedPhonePanel extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api title = 'Phone Numbers';
    @api enableClickToDial = false;

    rows = [];
    errorMessage;
    isLoading = true;

    wiredNumbersResult;
    lastModified;

    // Reveal state
    reasonOptions = [];
    revealTarget;
    selectedReason;
    revealComment = '';
    revealError;
    isRevealing = false;
    revealed = {};
    revealTimers = {};

    get lastModifiedField() {
        return this.objectApiName ? [`${this.objectApiName}.LastModifiedDate`] : undefined;
    }

    // Reload the masked numbers when the record is saved (e.g. the secondary number changes).
    @wire(getRecord, { recordId: '$recordId', optionalFields: '$lastModifiedField' })
    wiredRecord({ data }) {
        if (!data) {
            return;
        }
        const modified = data.lastModifiedDate;
        if (this.lastModified && modified !== this.lastModified && this.wiredNumbersResult) {
            refreshApex(this.wiredNumbersResult);
        }
        this.lastModified = modified;
    }

    @wire(getMaskedNumbers, { recordId: '$recordId' })
    wiredNumbers(result) {
        this.wiredNumbersResult = result;
        const { data, error } = result;
        if (data) {
            this.rows = data;
            this.errorMessage = undefined;
            this.isLoading = false;
        } else if (error) {
            this.rows = [];
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
            this.isLoading = false;
        }
    }

    @wire(getReasons)
    wiredReasons({ data }) {
        if (data) {
            this.reasonOptions = data.map((reason) => ({ label: reason, value: reason }));
        }
    }

    disconnectedCallback() {
        Object.values(this.revealTimers).forEach((timer) => clearTimeout(timer));
        this.revealTimers = {};
        this.revealed = {};
    }

    get isDesktop() {
        return FORM_FACTOR === DESKTOP;
    }

    get dialEnabled() {
        return this.enableClickToDial === true && this.isDesktop;
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get canReveal() {
        return hasRevealPermission === true;
    }

    get callHint() {
        if (!this.isDesktop) {
            return 'Calling from the mobile app is not available yet';
        }
        return 'Calling from this panel is not enabled';
    }

    get displayRows() {
        return this.rows.map((row) => {
            const showDial = this.dialEnabled && row.canDial === true;
            const revealedEntry = this.revealed[row.fieldKey];
            return {
                ...row,
                showDial,
                showMasked: row.hasNumber === true && !showDial,
                params: `fieldKey=${row.fieldKey}`,
                emptyText: `No ${(row.label || '').toLowerCase()} number`,
                revealedNumber: revealedEntry ? revealedEntry.number : undefined,
                revealedHint: revealedEntry ? `Hides after ${revealedEntry.seconds} seconds` : undefined,
                showRevealButton: this.canReveal && row.hasNumber === true && !revealedEntry,
                revealTitle: `Reveal ${(row.label || '').toLowerCase()} number`
            };
        });
    }

    // ---------------- Reveal dialog ----------------

    get showRevealDialog() {
        return Boolean(this.revealTarget);
    }

    get revealHeading() {
        return this.revealTarget ? `Reveal ${this.revealTarget.label.toLowerCase()} number` : '';
    }

    get isOtherReason() {
        return this.selectedReason === REASON_OTHER;
    }

    get revealDisabled() {
        return (
            this.isRevealing ||
            !this.selectedReason ||
            (this.isOtherReason && !(this.revealComment || '').trim())
        );
    }

    handleRevealClick(event) {
        const fieldKey = event.currentTarget.dataset.field;
        const row = this.rows.find((r) => r.fieldKey === fieldKey);
        if (!row) {
            return;
        }
        this.revealTarget = { fieldKey, label: row.label || 'phone' };
        this.selectedReason = undefined;
        this.revealComment = '';
        this.revealError = undefined;
    }

    handleReasonChange(event) {
        this.selectedReason = event.detail.value;
    }

    handleCommentChange(event) {
        this.revealComment = event.detail.value;
    }

    handleCancelReveal() {
        this.revealTarget = undefined;
        this.revealError = undefined;
    }

    async handleConfirmReveal() {
        if (this.revealDisabled) {
            return;
        }
        this.isRevealing = true;
        this.revealError = undefined;
        const fieldKey = this.revealTarget.fieldKey;
        try {
            const result = await revealNumber({
                recordId: this.recordId,
                fieldKey,
                reason: this.selectedReason,
                comment: this.revealComment
            });
            this.showRevealed(fieldKey, result.phoneNumber, result.seconds);
            this.revealTarget = undefined;
        } catch (error) {
            this.revealError = error?.body?.message || DEFAULT_REVEAL_ERROR;
        } finally {
            this.isRevealing = false;
        }
    }

    showRevealed(fieldKey, number, seconds) {
        this.revealed = { ...this.revealed, [fieldKey]: { number, seconds } };
        if (this.revealTimers[fieldKey]) {
            clearTimeout(this.revealTimers[fieldKey]);
        }
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.revealTimers[fieldKey] = setTimeout(() => this.hideRevealed(fieldKey), seconds * 1000);
    }

    hideRevealed(fieldKey) {
        const remaining = { ...this.revealed };
        delete remaining[fieldKey];
        this.revealed = remaining;
        delete this.revealTimers[fieldKey];
    }
}
