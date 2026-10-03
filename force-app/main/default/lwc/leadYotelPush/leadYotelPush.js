import { LightningElement, api } from 'lwc';
import getSelectedLeads from '@salesforce/apex/LeadYotelBulkPushController.getSelectedLeads';
import pushBulkToYotel from '@salesforce/apex/LeadYotelBulkPushController.pushBulkToYotel';

export default class LeadYotelPush extends LightningElement {

    @api recordIds;

    leads = [];
    isLoading = false;
    resultMessage = '';
    hasPushed = false;

    connectedCallback() {
        console.log('leadYotelPush: connectedCallback, recordIds =', JSON.stringify(this.recordIds));
        this.loadLeads();
    }

    loadLeads() {
        this.isLoading = true;

        console.log('leadYotelPush: calling getSelectedLeads with', JSON.stringify(this.recordIds));

        getSelectedLeads({ leadIds: this.recordIds })
            .then((result) => {
                console.log('leadYotelPush: getSelectedLeads result =', JSON.stringify(result));
                this.leads = result;
            })
            .catch((error) => {
                console.error('leadYotelPush: getSelectedLeads error =', JSON.stringify(error));
                this.resultMessage = 'Error loading leads: ' + this.extractErrorMessage(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handlePush() {
        this.isLoading = true;
        this.resultMessage = '';

        console.log('leadYotelPush: calling pushBulkToYotel with', JSON.stringify(this.recordIds));

        pushBulkToYotel({ leadIds: this.recordIds })
            .then((result) => {
                console.log('leadYotelPush: pushBulkToYotel result =', result);
                this.resultMessage = result;
                this.hasPushed = true;
            })
            .catch((error) => {
                console.error('leadYotelPush: pushBulkToYotel error =', JSON.stringify(error));
                this.resultMessage = 'Error pushing leads: ' + this.extractErrorMessage(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    extractErrorMessage(error) {
        return (error && error.body && error.body.message) ? error.body.message : JSON.stringify(error);
    }

    get hasLeads() {
        return this.leads && this.leads.length > 0;
    }

    get pushDisabled() {
        return this.isLoading || !this.hasLeads || this.hasPushed;
    }
}