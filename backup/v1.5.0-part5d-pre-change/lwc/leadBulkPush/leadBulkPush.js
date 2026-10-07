import { LightningElement, wire, track, api }
    from 'lwc';

import getUserPicklistValues from '@salesforce/apex/LeadBulkPushController.getUserPicklistValues';

import getSelectedLeads
    from '@salesforce/apex/LeadBulkPushController.getSelectedLeads';

import pushBulkToDialer
    from '@salesforce/apex/LeadBulkPushController.pushBulkToDialer';

import updateBulkLeadStatus
    from '@salesforce/apex/LeadBulkPushController.updateBulkLeadStatus';

export default class LeadBulkPush
    extends LightningElement {

    @track leads = [];

    @api recordIds;

    leadIds = [];

    loading = false;

    message = '';

    messageType = '';

    @track selectedValue;
    @track selectedUserId;

    @track UserMap = {};

    @wire(getUserPicklistValues)
    wiredOptions({ error, data }) {
        if (data) {
            this.UserMap = data;
        } else if (error) {
            console.error('Error fetching picklist values', error);
        }
    }

    handleChange(event) {
        let UserId = event.detail.recordId;
        this.selectedUserId = UserId;
        if(this.UserMap[UserId]) {
            this.selectedValue = this.UserMap[UserId];
        } else {
            this.selectedValue = null;
        }
    }
   

    connectedCallback() {

        console.log(
            'Connected Callback:',
            JSON.stringify(this.recordIds)
        );

        this.leadIds = this.recordIds || [];

        if (this.leadIds.length > 0) {

            this.loadLeads();
        }
    }

    filter = {
        criteria: [
            {
            fieldPath: "Mcube_Phone__c",
            operator: "ne",
            value: null,
            },
        ],
        filterLogic: "1",
    };

    /*
    =====================================================
    GETTERS
    =====================================================
    */

    get leadCount() {

        return this.leads
            ? this.leads.length
            : 0;
    }

    get hasLeads() {

        return this.leadCount > 0;
    }



    /*
    =====================================================
    LOAD LEADS
    =====================================================
    */

    loadLeads() {

        this.loading = true;

        getSelectedLeads({
            leadIds: this.leadIds
        })

            .then(result => {

                console.log(
                    'Lead Result:',
                    JSON.stringify(result)
                );

                this.leads = result || [];
            })

            .catch(error => {

                console.error(error);

                this.showMessage(
                    'error',
                    this.reduceError(error)
                );
            })

            .finally(() => {

                this.loading = false;
            });
    }



    /*
    =====================================================
    SUBMIT
    =====================================================
    */

    handleSubmit() {

        if (this.loading) {
            return;
        }

        if (!this.leadIds.length) {

            this.showMessage(
                'error',
                'No Leads selected'
            );

            return;
        }

        this.loading = true;

        pushBulkToDialer({
            leadIds: this.leadIds,
            exeNumber: this.selectedValue,
            selectedUserId: this.selectedUserId
        })

            .then(result => {

                console.log(
                    'Push Result:',
                    result
                );

                return updateBulkLeadStatus({ leadIds: this.leadIds });
            })

            .then(() => {

                this.showMessage(
                    'success',
                    'Leads pushed successfully'
                );

                setTimeout(() => {

                    this.closeWindow();

                }, 1200);
            })

            .catch(error => {

                console.error(error);

                this.showMessage(
                    'error',
                    this.reduceError(error)
                );
            })

            .finally(() => {

                this.loading = false;
            });
    }

    get messageClass() {

        if (this.messageType === 'success') {

            return 'message successMessage';
        }

        if (this.messageType === 'error') {

            return 'message errorMessage';
        }

        return 'message';
    }

    get leadCountWord() {

        return this.leadCount === 1
            ? 'Lead'
            : 'Leads';
    } 

    /*
    =====================================================
    CLOSE WINDOW
    =====================================================
    */

    closeWindow() {

        /*
        Works better than window.close()
        in Lightning/VF contexts
        */

        window.history.back();
    }



    /*
    =====================================================
    ERROR HANDLING
    =====================================================
    */

    reduceError(error) {

        if (
            error &&
            error.body &&
            typeof error.body.message === 'string'
        ) {

            return error.body.message;
        }

        if (typeof error.message === 'string') {

            return error.message;
        }

        return 'Unknown error occurred';
    }



    /*
    =====================================================
    TOAST
    =====================================================
    */

    showMessage(type, message) {

        this.message = message;

        this.messageType = type;

        setTimeout(() => {

            this.message = '';
            this.messageType = '';

        }, 4000);
    }
}