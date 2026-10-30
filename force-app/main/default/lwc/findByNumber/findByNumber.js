import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import findLeads from '@salesforce/apex/FindByNumberController.findLeads';

const DEFAULT_ERROR = 'The search could not be completed.';

/**
 * Find by number (v1.8.0). Masked users can no longer find a Lead by number in global search, because they
 * cannot read the phone fields. The user types the full number; Apex searches on the server and returns the
 * Leads the user can see, with MASKED numbers only. Every search is audited on the server.
 */
export default class FindByNumber extends NavigationMixin(LightningElement) {
    @api title = 'Find by number';

    phoneNumber = '';
    leads = [];
    maskedNumber;
    hasMore = false;
    errorMessage;
    isSearching = false;
    searched = false;

    get isSearchDisabled() {
        return this.isSearching || !this.phoneNumber || !this.phoneNumber.trim();
    }

    get hasLeads() {
        return this.leads.length > 0;
    }

    get showNotFound() {
        return this.searched && !this.errorMessage && !this.hasLeads;
    }

    get summary() {
        const count = this.leads.length;
        const found = count === 1 ? '1 lead' : `${count} leads`;
        return this.hasMore ? `Newest ${found} for ${this.maskedNumber}` : `${found} for ${this.maskedNumber}`;
    }

    get notFoundText() {
        return `No lead you can access has ${this.maskedNumber}.`;
    }

    handleNumberChange(event) {
        this.phoneNumber = event.target.value;
    }

    handleKeyUp(event) {
        if (event.key === 'Enter' && !this.isSearchDisabled) {
            this.handleSearch();
        }
    }

    async handleSearch() {
        this.isSearching = true;
        this.errorMessage = undefined;
        this.searched = false;
        try {
            const result = await findLeads({ phoneNumber: this.phoneNumber });
            this.errorMessage = result.errorMessage;
            this.maskedNumber = result.maskedNumber;
            this.leads = result.leads || [];
            this.hasMore = result.hasMore === true;
            this.searched = !result.errorMessage;
        } catch (error) {
            this.leads = [];
            this.hasMore = false;
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
        } finally {
            this.isSearching = false;
        }
    }

    handleClear() {
        this.phoneNumber = '';
        this.leads = [];
        this.maskedNumber = undefined;
        this.hasMore = false;
        this.errorMessage = undefined;
        this.searched = false;
    }

    handleOpen(event) {
        event.preventDefault();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.id,
                objectApiName: 'Lead',
                actionName: 'view'
            }
        });
    }
}
