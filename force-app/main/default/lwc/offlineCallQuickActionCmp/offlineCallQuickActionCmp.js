import { LightningElement, api } from 'lwc';
import triggerCall from '@salesforce/apex/OfflineCallAppAPI.triggerCall';
import getLeadPhone from '@salesforce/apex/OfflineCallAppAPI.getLeadPhone';
import getCurrentUsername from '@salesforce/apex/OfflineCallAppAPI.getCurrentUsername';
import isLeadRecentlyContacted from '@salesforce/apex/OfflineCallAppAPI.isLeadRecentlyContacted';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadCallQuickAction extends LightningElement {
    @api recordId;

    @api async invoke() {
        console.log('Invoked with recordId:', this.recordId);

        if (!this.recordId) {
            this.showToast('Error', 'Record ID is missing.', 'error');
            return;
        }

        try {
            // Optional: Uncomment to prevent call if not contacted recently
            // const isRecent = await isLeadRecentlyContacted({ leadId: this.recordId });
            // if (!isRecent) {
            //     this.showToast('Warning', 'Cannot trigger call. Lead was not contacted within the last 30 minutes.', 'warning');
            //     return;
            // }

            let username = await getCurrentUsername();
            let phoneNumber = await getLeadPhone({ leadId: this.recordId });
       
if (phoneNumber && phoneNumber.length > 10) {
    phoneNumber = phoneNumber.replace(/^\+?91/, '').slice(-10);
}


             alert ('phoneNo:'+phoneNumber);
              alert ('username:'+username);


            if (!username || !phoneNumber) {
                this.showToast('Error', 'Missing username or phone number.', 'error');
                return;
            }
            await triggerCall({
                username: username,
                phoneNumber: phoneNumber,
                leadId: this.recordId
            });

            this.showToast('Success', 'Call triggered successfully.', 'success');
        } catch (error) {
            console.error('Error triggering call:', error);
            this.showToast('Error', 'Failed to trigger call.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}