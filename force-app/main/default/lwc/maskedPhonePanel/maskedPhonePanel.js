import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getMaskedNumbers from '@salesforce/apex/MaskedPhonePanelController.getMaskedNumbers';

const DESKTOP = 'Large';
const DEFAULT_ERROR = 'Unable to load phone numbers.';

/**
 * Shows a record's phone numbers masked (98XXXXXX21). The real number never reaches this component:
 * Apex returns masked values only. When click-to-dial is enabled (App Builder property, desktop only),
 * each number is rendered with lightning-click-to-dial carrying the masked value plus the record Id and
 * the field key, so the user's Open CTI softphone can resolve the real number on the server.
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

    get isDesktop() {
        return FORM_FACTOR === DESKTOP;
    }

    get dialEnabled() {
        return this.enableClickToDial === true && this.isDesktop;
    }

    get hasRows() {
        return this.rows.length > 0;
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
            return {
                ...row,
                showDial,
                showMasked: row.hasNumber === true && !showDial,
                params: `fieldKey=${row.fieldKey}`,
                emptyText: `No ${(row.label || '').toLowerCase()} number`
            };
        });
    }
}
