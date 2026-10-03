import { LightningElement, track ,api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getConvertedDetails from '@salesforce/apex/ConvertedLeadInformation.getConvertedDetails';
export default class ShowConvertedOppRecord extends NavigationMixin(LightningElement) {
    @track opportunity;
    @track account;
    @track contact;
    @track error;
    @api recordId;

    connectedCallback() {
         getConvertedDetails({ recordId: this.recordId })
             .then(result => {
                this.opportunity = result.oppDetails[0];
                 this.account = result.accDetails[0];
                 this.contact = result.conDetails[0];
                 console.log(this.opportunity.Id);
                 console.log(this.account.Id);
                 console.log(this.contact.Id);
             })
             .catch(error => {
                 this.error = error;
                 const evt = new ShowToastEvent({
                     title: 'Error',
                     message: this.error,
                     variant: 'error',
                     mode: 'dismissable'
                 });
                 this.dispatchEvent(evt);
             });
    }
    openOppRecordPage(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.opportunity.Id,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        });
    }
    openAccRecordPage(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.account.Id,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }
    openConRecordPage(){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contact.Id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        });
    }
}