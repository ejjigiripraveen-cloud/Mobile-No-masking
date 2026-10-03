import { api, LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getOpportunity from '@salesforce/apex/Template_Controller.getOpportunity';
import updateContactApplicant from '@salesforce/apex/Template_Controller.updateContactApplicant';
import updateCoApplicantObj from '@salesforce/apex/Template_Controller.updateCoApplicantObj';
//import insertReceiptRecord from '@salesforce/apex/Template_Controller.insertReceiptRecord';
import getTokenAmount from '@salesforce/apex/Template_Controller.getTokenAmount';
import getSearchingBankName from '@salesforce/apex/Template_Controller.getSearchingBankName';
import insertTokenAndReceipt from '@salesforce/apex/TokenSelectionComponentController.insertTokenAndReceipt';
import userHasEncryptedData from '@salesforce/apex/Template_Controller.userHasEncryptedData';
import checkingNumTokenGenerated from '@salesforce/apex/TokenSelectionComponentController.checkingNumTokenGenerated';
import checkForToeknUpgradeDegrade from '@salesforce/apex/TokenSelectionComponentController.checkForTokenUpgradeDegrade';
//import UpdateQuotationWithReceiptDetails from '@salesforce/apex/TransferReAssignmentController.UpdateQuotationWithReceiptDetails';
//import onSubmit from '@salesforce/apex/TokenSelectionComponentController.onSubmit';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import BANK_NAME from '@salesforce/schema/Receipt__c.Bank_Name__c';

// Added by Anupam 29Dec2025
import RECEIPT_OBJECT from '@salesforce/schema/Receipt__c';
import PAYMENT_FIELD from '@salesforce/schema/Receipt__c.Payment__c';
import SOURCE_OF_FUNDS_FIELD from '@salesforce/schema/Receipt__c.Source_of_funds__c';

// import easeBuzzCallout from '@salesforce/apex/EasebuzzCallout.makeApiCalloutEasyPayment';
// import easeBuzzVerify from '@salesforce/apex/EasebuzzCallout.verifyPayment';
// import getMerchantId from '@salesforce/apex/EasebuzzCallout.getMerchantId';
// import checkPriorPayments from '@salesforce/apex/EasebuzzCallout.checkPriorPayments';
// import isEnabledEaseBuzz from '@salesforce/apex/EasebuzzCallout.isEnabledEaseBuzz';


import Occupation_Picklist__c from '@salesforce/schema/Contact.Occupation_Picklist__c';
import Payment_Category__c from '@salesforce/schema/Receipt__c.Payment_Category__c';
//import { ShowToastEvent } from 'lightning/platformShowToastEvent';				
import { subscribe, unsubscribe, onError,setDebugFlag,isEmpEnabled,} from 'lightning/empApi';   


export default class KycAndQuotationTabComponent extends NavigationMixin(LightningElement) 
{
    // Added by anupam 29Dec2025 - Start Here
    @track receiptToInsert = {};
    @track paymentOptions = [];
    @track sourceOfFundsOptions = [];
    
    // Get Object Info dynamically
    @wire(getObjectInfo, { objectApiName: RECEIPT_OBJECT })
    objectInfo;

    // Payment Picklist
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: PAYMENT_FIELD
    })
    paymentPicklistHandler({ data, error }) {
        if (data) {
            this.paymentOptions = this.formatPicklist(data.values);
        } else if (error) {
            console.error('Payment picklist error:', error);
        }
    }

    // Source of Funds Picklist
    @wire(getPicklistValues, {
        recordTypeId: '$objectInfo.data.defaultRecordTypeId',
        fieldApiName: SOURCE_OF_FUNDS_FIELD
    })
    sourceOfFundsPicklistHandler({ data, error }) {
        if (data) {
            this.sourceOfFundsOptions = this.formatPicklist(data.values);
        } else if (error) {
            console.error('Source of Funds picklist error:', error);
        }
    }

    // Common formatter
    formatPicklist(values) {
        return values.map(item => ({
            label: item.label,
            value: item.value
        }));
    }

    // Generic handler
    handleInputChange(event) {
        const fieldName = event.target.name;
        this.receiptToInsert[fieldName] = event.target.value;
    }
    // Added by anupam 29Dec2025 - End Here

    @api picklistValues = [];
    @api iconname = "standard:agent_home";
//////////////////////////////////////////////////////////////////////////////////////////////////
    @track channelName = '/event/easebuzz_Event__e';
    @track easeBuzzTransactionId = '';
    @track subMerchantId = '';
    @track enabledOnlinePayment = false;
    @track projIds = 'a0S5j000004cXi5EAE';
    @track PriorCheckDone = false;

    @track easeBuzzKey = '';
    @track easeBuzzSalt = '';
    isTransactionNo = true;
    
    @api set tokenProjId(value){ this._tokenProjId = value; console.log('j2dm : '+this._tokenProjId); this.projIdforEaseBuzz = this._tokenProjId != '' ? this._tokenProjId : this.project?.Id;}
    get tokenProjId(){return this._tokenProjId;}
    @track _tokenProjId ='';

   
    @track projIdforEaseBuzz = this._tokenProjId != '' ? this._tokenProjId : this.project?.Id;
    
    
//     @wire(isEnabledEaseBuzz,{projId:'$projIdforEaseBuzz'})
//   wiredCampaignList({error,data}){
//     if(data){  console.log('Inside Enabled Easebuzz check v1.00');
//       try{ 
//         if(data===true) this.enabledOnlinePayment = true;
//       }
//       catch(errorProblem){
//         //this.showToast('Attention!','Fatal Error : '+errorProblem,'error');
//         console.log('Error on get Enabled Easebuzz :'+JSON.stringify(errorProblem));
//       }
//     }
//     else if(error){
//      // this.showToast('Attention!','Fatal Error : '+error,'error');
//      console.log('Error on get Enabled Easebuzz error :'+JSON.stringify(error));

//     }
//   }

    @track paymentOptionsForRadio = [{label : 'Online' , value : 'Online'},
    {label : 'Offline' , value : 'Offline'}];
    paymentTypeValueForRadio = 'Offline';

    // changePaymentTypeForRadio(event)
    // {
    //     this.paymentTypeValueForRadio = event.target.value;
    //     if(this.paymentTypeValueForRadio === 'Online') this.showEaseBuzzButton = true;

    //     // if(this.paymentTypeValueForRadio === 'Online' && this.PriorCheckDone == false) 
    //     // {
    //     //     checkPriorPayments({oppId: this.opportunityId}).then((response)=>{
    //     //         if(response === 'NODATA')
    //     //         {

    //     //         }
    //     //         else
    //     //         {   this.PriorCheckDone = true;
    //     //             let webHookData = JSON.parse(response);

    //     //         if(webHookData!=null && webHookData.status === 'success') {

    //     //             this.isPaymentMade = true;
    //     //             this.isPaymentInitiated = false;
    //     //     this.receiptToInsert.Remarks__c = 'Online Payment';
    //     //     this.receiptToInsert.Receipt_Date__c = this.today;
    //     //     this.receiptToInsert.Bank_Name__c = 'Axis Bank';
    //     //     this.receiptToInsert.Transaction_No__c = webHookData.easepayid;
    //     //     this.receiptToInsert.Instrument_Date__c = this.today;
    //     //     //this.receiptToInsert.Name = 'Receipt Number '+(this.receiptNumber);
    //     //     this.receiptToInsert.Mode_of_Payment__c = 'EaseBuzz';
    //     //     this.receiptToInsert.Amount__c = webHookData.net_amount_debit;
    //     //     this.receiptToInsert.EasebuzzTransactionId__c = webHookData.txnid;

    //     //         }

    //     //         if(webHookData!=null && webHookData.status !== 'success')
    //     //         {
                    
    //     //             this.isPaymentInitiated = false;
    //     //             this.isPaymentFailed = true;
    //     //             this.showEaseBuzzButton = true;
    //     //         }
    //     //         }

    //     //     }).catch((error)=>{
    //     //         console.log('Easebuzz Prior Failed :'+JSON.stringify(error));
    //     //     });

    //         // if(this.selectedOnlinePayment === true)
    //         // {
    //         //     getMerchantId({ProjectId:this.projIdforEaseBuzz,BlockId:'',PaymentCategory:this.receiptToInsert.Payment_Category__c}).then(result => {
    //         //        if(result==='NODATA')
    //         //        {

    //         //        }
    //         //        else
    //         //        {   var merchMap = JSON.parse(result);
    //         //            this.subMerchantId = merchMap.subMerchant;
    //         //            this.easeBuzzSalt = merchMap.salt;
    //         //            this.easeBuzzKey = merchMap.key;
    //         //        }
    //         //     }).catch(error => {
                   
    //         //         console.log('Error on getMerchantId : '+error);

    //         //     });
    //         // }
    //     }
    // }

    get selectedOnlinePayment()
    {
        return this.paymentTypeValueForRadio === 'Offline' ? false : true ; 
    }


    @track isPaymentMade = false;
    @track isPaymentFailed = false;
    @track isPaymentInitiated = false;
    @track showEaseBuzzButton = false;
    get showRecButtons(){
        if(this.paymentTypeValueForRadio === 'Online' && this.isPaymentMade === false) return false;
        return true;
    }

    // verifyEaseBuzz()
    // {
    //     easeBuzzVerify({txnId : this.easeBuzzTransactionId}).then((response)=>{

    //         if(response === 'NODATA')
    //         {

    //         }
    //         else
    //         {  let webHookData = JSON.parse(response);

    //             if(webHookData!=null && webHookData.status === 'success') {

    //                 this.isPaymentMade = true;
    //                 this.isPaymentInitiated = false;
    //         this.receiptToInsert.Remarks__c = 'Online Payment';
    //         this.receiptToInsert.Receipt_Date__c = this.today;
    //         this.receiptToInsert.Bank_Name__c = 'Axis Bank';
    //         this.receiptToInsert.Transaction_No__c = webHookData.easepayid;
    //         this.receiptToInsert.Instrument_Date__c = this.today;
    //         //this.receiptToInsert.Name = 'Receipt Number '+(this.receiptNumber);
    //         this.receiptToInsert.Mode_of_Payment__c = 'EaseBuzz';
    //         this.receiptToInsert.Amount__c = webHookData.net_amount_debit;
    //         this.receiptToInsert.EasebuzzTransactionId__c = this.easeBuzzTransactionId;
    //         this.receiptToInsert.EaseBuzz_Log__c = this.ebLogId;


    //             }

    //             if(webHookData!=null && webHookData.status !== 'success')
    //             {
                    
    //                 this.isPaymentInitiated = false;
    //                 this.isPaymentFailed = true;
    //                 this.showEaseBuzzButton = true;
    //             }

                
    //         }

    //     }).catch((error) => {

    //     });
    // }

    // makeEaseBuzzCallout(event)
    // {   this.handleEaseBuzzSubscribe();
        
    //     easeBuzzCallout({OppId:this.opportunityId,MobNoParam:this.mobNoOpp,EmailParam:this.emailIdOpp,AmountParam:this.receiptToInsert.Amount__c,udf2Param:this.receiptToInsert.Payment_Category__c,SubMerchantId:this.subMerchantId,curKey:this.easeBuzzKey,curSalt:this.easeBuzzSalt}).then((response) => {
    //        let respObj = JSON.parse(response);
    //        console.log(JSON.stringify(respObj));
    //        console.log('Statuis is',respObj.status);
    //        if(respObj!=null && respObj.status === true && respObj.data!=null)
    //        {  
    //         this.isPaymentInitiated = true;
    //         this.showEaseBuzzButton = false;
    //         this.isPaymentFailed = false;
    //         this.isPaymentMade = false;
    //            let dataObj = respObj.data;
    //            console.log('Statuis isInsid',dataObj.merchant_txn);
    //            this.easeBuzzTransactionId = dataObj.merchant_txn;
    //        } 
    //        else
    //        if(respObj!=null && respObj.status != true && respObj.error!=null)
    //        {
    //         this.showMessage('Error','EaseBuzz Error '+JSON.stringify(respObj.error),'error');
    //         console.log('Error on Easebuzz Callout : '+JSON.stringify(response));
    //        }
    //        else
    //        {
    //         this.showMessage('Error','Error on Callout ','error');
    //         console.log('Error on Easebuzz Callout : '+JSON.stringify(response));
    //        }


    //     }).catch(error => {

    //         console.log('Error of Easebuzz callout : -> '+JSON.stringify(error));

    //     });
    // }

    handleEaseBuzzSubscribe() {
        console.log('inside Subscribe Call');
        // Callback invoked whenever a new event message is received
        const messageCallback =  (response) => {
            console.log('New message received: ', JSON.stringify(response));
            if(response.data.payload.Opportunity__c==this.opportunityId)
            {
                  //  this.isPaymentMade = 'Yes';
            }
            // Response contains the payload of the new message received
        };
        console.log('ChannelName is 2 :'+this.channelName);
        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, (response) => {
            console.log('New message received: ', JSON.stringify(response));
            if(response.data.payload.Opportunity__c==this.opportunityId)
            {
                  //  this.isPaymentMade = 'Yes';
            }
            // Response contains the payload of the new message received
        }).then((response) => {
            console.log('ChannelName is :'+this.channelName);
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
           
        }).catch((error) => {
            console.log('Subscription Failed : '+JSON.stringify(error))
        });

        console.log('After Subscribe Call');
    }

    handleOnlineReceiptInput(event)
    {
        var label = event.target.label;
        var eventValue = event.target.value;

        if(label === 'Email Id')
        {
            this.emailIdOpp = eventValue;
        }

        if(label === 'Mobile No')
        {
            this.mobNoOpp = eventValue;
        }
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////////
    @wire(getPicklistValues, {
        recordTypeId : '012000000000000AAA', 
        fieldApiName : BANK_NAME
        })
        wiredPicklistValues({ data, error}){
            if(data){
                console.log(' Picklist values are ', data.values);
                let pickData = data.values;
                
                for(let i = 0;i< pickData.length;i++)
                {
                    let pickObj = {};
                    pickObj.label = pickData[i].label;
                    pickObj.value = pickData[i].value;

                    this.picklistValues.push(pickObj);
                }

                this.error = undefined;
            }
            if(error){
                console.log(' Error while fetching Picklist values ${error}');
                this.error = error;
                this.picklistValues = undefined;
            }
        };

    @track occupationPickVal = [];
    occupationPickValPopulated = false;
    @wire(getPicklistValues, {
        recordTypeId : '012000000000000AAA', 
        fieldApiName : Occupation_Picklist__c
        })
        wiredPicklistValues1({ data, error}){
            if(data){
                console.log(' Picklist values are ', data.values);
                let pickData = data.values;
                console.log('pickData@@@@@@ ' + JSON.stringify(pickData));
                
                for(let i = 0;i< pickData.length;i++)
                {
                    let pickObj = {};
                    pickObj.label = pickData[i].label;
                    pickObj.value = pickData[i].value;

                    this.occupationPickVal.push(pickObj);
                }
                console.log('pickValll###### ' + JSON.stringify(this.occupationPickVal));
                this.occupationPickValPopulated = true;
                this.error = undefined;
            }
            if(error){
                console.log(' Error while fetching Picklist values ${error}');
                this.error = error;
                this.occupationPickVal = undefined;
            }
        };
        get defaultValue() {
            return this.occupationPickVal[0].value;
        }



        //@track picklistValuesForPaymentCaterogry;

        // @wire(getPicklistValues, {
        //     recordTypeId : '012000000000000AAA',
        //     fieldApiName : Payment_Category__c
        //     })
        //     wiredPickListValue({ data, error }){
        //         if(data){
        //             console.log(` Picklist values are `, data.values);
        //             this.picklistValuesForPaymentCaterogry = data.values;
        //             this.error = undefined;
        //         }
        //         if(error){
        //             console.log(` Error while fetching Picklist values  ${error}`);
        //             this.error = error;
        //             this.picklistValuesForPaymentCaterogry = undefined;
        //         }
        //     }

    @track selectedRecordForBank = false;

    @api tokenList = [];
    @api project;
    @api selectedApartment;
    @api opportunityId;
    @api isFromBooking;
    areDetailsVisible = true;
    activeValue = 'one';
    @track contact = {};
    coApplicant = [];
    sameAsApplicant1 = false;
    showApplicant2Details = false;
    errorMessage;
    errorInDML = false;
    @track receiptToInsert = {
        Name : null,
        Receipt_Date__c : null,
        Bank_Name__c : null,
        Transaction_No__c : null,
        Instrument_Date__c : null,
        Amount__c : null,
        Mode_of_Payment__c : null,
        Remarks__c : null,
        Payment_Category__c : null,
    };
    @api tokenAmount;
    @api tokenId;
    @api receiptToInsertList= [];
    receiptNumber = 1;
    today;
    @track pickListToShow;
    @api searchKey = null;
    @track noBankData;
    @track selectedBank;
    @api backToKycScreen;
    tokenUpgrade = [];
    tokenUpgradeAutoPopulateReceiptAmount = [];
    isEncrypted = false;
    @api isFromShifting = false;

    @api isFromOwnerShifting = false;

    @api shiftingCharges;
    @api quotationId;

    connectedCallback()
    {   ///////////////////////////////////////////////////////////////////////////
        this.projIdforEaseBuzz = this._tokenProjId != '' ? this._tokenProjId : this.project?.Id;
        //////////////////////////////////////////////////////////////////////////
        console.log('shiftingChargesshiftingCharges' + this.shiftingCharges);
        console.log("option="+ this.picklistValues);
        console.log("option="+JSON.stringify(this.picklistValues));
        console.log('KycAndQuotationTabComponent '+ JSON.stringify(this.project));   
        console.log('KycAndQuotationTabComponent '+ JSON.stringify(this.selectedApartment));    
        console.log('KycAndQuotationTabComponent '+ JSON.stringify(this.opportunityId));
        console.log('KycAndQuotationTabComponent '+ JSON.stringify(this.isFromBooking));
        console.log('KycAndQuotationTabComponent111 '+ this.isFromBooking);
        console.log('KycAndQuotationTabComponent@@@ '+ this.isFromShifting);
        console.log('quotationId' + this.quotationId);

        this.today = new Date().toISOString().slice(0, 10)
        console.log('KycAndQuotationTabComponent today' + this.today);
        checkForToeknUpgradeDegrade({oppId: this.opportunityId})
            .then(result => {
                console.log('Inside method called');
                this.tokenUpgradeAutoPopulateReceiptAmount = result;
                console.log('Token 103'+JSON.stringify(this.tokenUpgradeAutoPopulateReceiptAmount));
                /*if(this.tokenUpgradeAutoPopulateReceiptAmount != null)
                {
                    console.log('Token value112'+JSON.stringify(this.tokenUpgradeAutoPopulateReceiptAmount[0].Token_Upgrade_and_Degrade__c));
                    if(this.tokenUpgradeAutoPopulateReceiptAmount[0].Token_Upgrade_and_Degrade__c == 'Upgrade')
                    {
                        this.receiptToInsert.Amount__c = this.tokenAmount - this.tokenUpgradeAutoPopulateReceiptAmount[0].Discount_in_Amt__c;
                    }
                    else
                    {
                        this.receiptToInsert.Amount__c = this.tokenAmount
                    }
                }
                else
                {
                    console.log('tokenamount'+this.tokenAmount);
                    this.receiptToInsert.Amount__c = this.tokenAmount;
                }*/
                //console.log('Token value104'+JSON.stringify(this.tokenUpgradeAutoPopulateReceiptAmount[0].Token_Upgrade_and_Degrade__c));
            })
            .catch(error => {
                this.error = error;
            });
        this.receiptToInsert.Name = 'Receipt Number ' + this.receiptNumber;
        this.receiptToInsert.Receipt_Date__c = this.today;
        this.receiptToInsert.Instrument_Date__c = this.today;
        //this.receiptToInsert.Amount__c = this.tokenAmount;

        if(this.isFromShifting == true){
            this.isFromShifting = true;
            
            this.receiptToInsert.Payment_Category__c = 'Shifting Charges';
        }

        userHasEncryptedData({}).then(result => 
        {
            console.log(JSON.stringify(result));
            this.isEncrypted = result;
        })
        .catch(error => 
        {
            this.errorMessage = error;
            this.errorInDML = true;
        }); 

        if(this.opportunityId != null)
        {
            getOpportunity({filter : this.opportunityId}).then(result => 
            {
                console.log(JSON.stringify(result));
                console.log('coApplicantData ' + JSON.stringify(result.coApplicantList));

                this.coApplicant = result.coApplicantList;
                console.log('coApplicant ' + result.coApplicantList);
                console.log('coApplicant ' + result.coApplicantList.length);


                this.contact.Id = result.Id;  
                this.contact.Name = result.Name == null ? '': result.Name;
                this.contact.Co_FirstName = result.Co_FirstName == null ? '': result.Co_FirstName;
                this.contact.Co_LastName = result.Co_LastName == null ? '': result.Co_LastName;
                this.contact.Co_MiddleName = result.Co_MiddleName == null ? '': result.Co_MiddleName;
                this.contact.Co_App_Email_Id__c = result.Co_App_Email_Id == null ? '': result.Co_App_Email_Id;
                this.contact.Co_App_PAN_No__c = result.Co_App_PAN_No == null ? '': result.Co_App_PAN_No;
                this.contact.date_of_birth__c = result.date_of_birth == null ? null: result.date_of_birth;
                this.contact.Co_App_Mobile_No__c = result.Co_App_Mobile_No == null ? '': result.Co_App_Mobile_No;
                this.contact.Co_StreetAddress1 = result.Co_StreetAddress1 == null ? '': result.Co_StreetAddress1;
                this.contact.Co_StreetAddress2 = result.Co_StreetAddress2 == null ? '': result.Co_StreetAddress2;
                this.contact.Co_City = result.Co_City == null ? '': result.Co_City;
                this.contact.Co_Zip = result.Co_Zip == null ? '': result.Co_Zip;
                this.contact.Co_Country = result.Co_Country == null ? '': result.Co_Country;
                this.contact.Co_State = result.Co_State == null ? '': result.Co_State;
                this.contact.Co_App_Adhaar__c = result.Co_App_Adhaar == null ? '': result.Co_App_Adhaar;
                this.contact.Co_App_Passport_No__c = result.Co_App_Passport_No == null ? '': result.Co_App_Passport_No;
                this.contact.Attorney_Holder_mobile__c = result.Attorney_Holder_mobile == null?'':result.Attorney_Holder_mobile;
                this.contact.Secondary_Email_Id__c = result.Co_Secondary_Email_Id == null ? '':result.Co_Secondary_Email_Id;

                this.contact.Co_App_Occupation__c = result.Co_App_Occupation == null ? '': result.Co_App_Occupation;
                this.contact.Company_Name__c = result.Company_Name == null ? '':result.Company_Name;
                this.contact.Co_App_Designation__c = result.Co_App_Designation == null ? '':result.Co_App_Designation;
                this.contact.Designation__c = result.Designation == null ? '':result.Designation;
                this.contact.Occupation__c = result.Occupation == null ? '':result.Occupation;

                //Aplicant 2
                this.contact.Co2_FirstName = result.Co2_FirstName == null ? '': result.Co2_FirstName;
                this.contact.Co2_LastName = result.Co2_LastName == null ? '': result.Co2_LastName;
                this.contact.Co_App_2_Email__c = result.Co_App_2_Email == null ? '': result.Co_App_2_Email;
                this.contact.Co_App_2_PAN_Card__c = result.Co_App_2_PAN_Card == null ? '': result.Co_App_2_PAN_Card;
                this.contact.Co_App_2_Date_of_Birth__c = result.Co_App_2_Date_of_Birth == null ? null : result.Co_App_2_Date_of_Birth;
                this.contact.Co_App_2_Mobile__c = result.Co_App_2_Mobile == null ? '': result.Co_App_2_Mobile;
                this.contact.Co2_StreetAddress1 = result.Co2_StreetAddress1 == null ? '': result.Co2_StreetAddress1;
                this.contact.Co2_StreetAddress2 = result.Co2_StreetAddress2 == null ? '': result.Co2_StreetAddress2;
                this.contact.Co2_City = result.Co2_City == null ? '': result.Co2_City;
                this.contact.Co2_Zip = result.Co2_Zip == null ? '': result.Co2_Zip;
                this.contact.Co2_Country = result.Co2_Country == null ? '': result.Co2_Country;
                this.contact.Co2_State = result.Co2_State == null ? '': result.Co2_State;
                this.contact.Co_App2_Adhaar__c = result.Co_App2_Adhaar == null ? '': result.Co_App2_Adhaar;
                this.contact.Co_App_2_Passport_No__c = result.Co_App_2_Passport_No == null ? '': result.Co_App_2_Passport_No;

                this.contact.Co_App_2_Designation__c = result.Co_App_2_Designation == null ? '': result.Co_App_2_Designation;
                this.contact.Co_App_2_Occupation__c = result.Co_App_2_Occupation == null ? '': result.Co_App_2_Occupation;
                this.areDetailsVisible = true;

                //j2dM
                this.emailIdOpp = this.contact.Co_App_Email_Id__c;
                this.mobNoOpp = this.contact.Co_App_Mobile_No__c;
               
            })
            .catch(error => 
            {
                console.log('Catch Contact' + 'error msg' + JSON.stringify(error));
                //this.showMessage('Please Enter contact Detail On Opportunity' + error,'Error','error');
                this.showMessage('Error','Please Enter contact Detail On Opportunity','error');
                this.navigateToRecordPage(this.opportunityId);
                //this.errorMessage = error;
                this.errorInDML = true;
            }); 

            if(this.isFromBooking == true)
            {   
                this.isFromBooking = true;
                if(this.isFromShifting == true){
                    this.isFromShifting = true;
                    //this.receiptToInsert.Amount__c = this.shiftingCharges;
                    this.tokenAmount = this.shiftingCharges;
                }else{

                    getTokenAmount({oppId : this.opportunityId, aptObj : this.selectedApartment}).then(result => 
                    {
                        //this.receiptToInsert.Amount__c = parseFloat(result);
                        this.tokenAmount = parseFloat(result);
                    })
                    .catch(error => 
                    {
                        this.errorMessage = error;
                        this.errorInDML = true;
                    }); 
                }
            }
        }
    }

    handleContactNameClick(event)
    {
        if(this.contact != null)
        {
            window.open(window.location.origin + "/" + this.contact.Id);
        }
    }

    handleInputBlurApplicant1(event)
    {
        var label = event.target.label;
        if(label == 'First Name')
        {
            this.contact.Co_FirstName = event.target.value;
        }
        else if(label == 'Last Name')
        {
            this.contact.Co_LastName = event.target.value;
        }

        else if(label == 'Email')
        {
            this.contact.Co_App_Email_Id__c = event.target.value;
        }
        else if(label == 'Pan Number')
        {
            this.contact.Co_App_PAN_No__c = event.target.value;
        }
        else if(label == 'Date Of Birth')
        {
            this.contact.date_of_birth__c = event.target.value;
        }
        else if(label == 'Occupation')
        {
            this.contact.Occupation__c = event.target.value;
        }
        else if(label == 'Street Address')
        {
            this.contact.Co_StreetAddress1 = event.target.value;
        }
        else if(label == 'Street Address(cont\'d)')
        {
            this.contact.Co_StreetAddress2 = event.target.value;
        }
        else if(label == 'City')
        {
            this.contact.Co_City = event.target.value;
        }
        else if(label == 'Zip Code')
        {
            this.contact.Co_Zip = event.target.value;
        }
        else if(label == 'Country')
        {
            this.contact.Co_Country = event.target.value;
        }
        else if(label == 'State')
        {
            this.contact.Co_State = event.target.value;
        }
        else if(label == 'Phone')
        {
            this.contact.Co_App_Mobile_No__c = event.target.value;
        }
        else if(label == 'Aadhaar Number')
        {
            this.contact.Co_App_Adhaar__c = event.target.value;
        }
        else if(label == 'Passport Number')
        {
            this.contact.Co_App_Passport_No__c = event.target.value;
        }
        else if(label == 'Secondary Mobile Number')
        {
            this.contact.Attorney_Holder_mobile__c = event.target.value;
        }
        else if(label == 'Secondary Email Id')
        {
            this.contact.Secondary_Email_Id__c = event.target.value;
        }
        else if(label == 'Designation')
        {
            this.contact.Designation__c = event.target.value;
        }
        else if(label == 'Company Name')
        {
            this.contact.Company_Name__c = event.target.value;
        }
    }

    handleInputBlurApplicant2(event)
    {
        var label = event.target.label;
        if(label == 'First Name')
        {
            this.contact.Co2_FirstName = event.target.value;
        }
        else if(label == 'Last Name')
        {
            this.contact.Co2_LastName = event.target.value;
        }
        else if(label == 'Email')
        {
            this.contact.Co_App_2_Email__c = event.target.value;
        }
        else if(label == 'Pan Number')
        {
            this.contact.Co_App_2_PAN_Card__c = event.target.value;
        }
        else if(label == 'Date Of Birth')
        {
            this.contact.Co_App_2_Date_of_Birth__c = event.target.value;
        }
        else if(label == 'Occupation')
        {
            this.contact.Co_App_2_Occupation__c = event.target.value;
        }
        else if(label == 'Street Address')
        {
            this.contact.Co2_StreetAddress1 = event.target.value;
        }
        else if(label == 'Street Address(cont\'d)')
        {
            this.contact.Co2_StreetAddress2 = event.target.value;
        }
        else if(label == 'City')
        {
            this.contact.Co2_City = event.target.value;
        }
        else if(label == 'Zip Code')
        {
            this.contact.Co2_Zip = event.target.value;
        }
        else if(label == 'Country')
        {
            this.contact.Co2_Country = event.target.value;
        }
        else if(label == 'State')
        {
            this.contact.Co2_State = event.target.value;
        }
        else if(label == 'Phone')
        {
            this.contact.Co_App_2_Mobile__c = event.target.value;
        }
        else if(label == 'Aadhaar Number')
        {
            this.contact.Co_App2_Adhaar__c = event.target.value;
        }
        else if(label == 'Passport Number')
        {
            this.contact.Co_App_2_Passport_No__c = event.target.value;
        }

        else if(label == 'Designation')
        {
            this.contact.Co_App_2_Designation__c = event.target.value;
        }
    }

    handleApplicantCheckBox(event)
    {
        this.sameAsApplicant1 = event.target.checked;
        console.log(this.sameAsApplicant1);
    }
    
    handleContactUpdate()
    {
        let fieldErrorMsg="Please Enter the";

        var item = this.template.querySelectorAll('[data-id="check"]')
        var booleanArray = [];
    
        for(var i =0 ; i < item.length; i++ )
        {
            let fieldValue=item[i].value;
            let fieldLabel=item[i].label; 

            if(fieldValue == null || fieldValue == '' || fieldValue == ' ')
            {
                item[i].setCustomValidity(fieldErrorMsg+' '+fieldLabel);
            }
            else
            {
                item[i].setCustomValidity("");
            }

            booleanArray.push(item[i].reportValidity());
        }

        console.log(booleanArray);
        if(! booleanArray.includes(false))
        {
            this.activeValue = 'two'; 
        }
    }

    chengeActiveValueOne(event)
    {
        this.activeValue = 'one'; 
    }

    chengeActiveValueTwo(event)
    {
       this.activeValue = 'two'; 
    }

    contactUpdate()
    {
        var contactObjectToUpdate = {};
        var Applicant1Name;
        var Applicant1Address;
        var Applicant2Name;
        var Applicant2Address;

        Applicant1Name = this.contact.Co_FirstName + ' ' +this.contact.Co_LastName;
        Applicant1Address = this.contact.Co_StreetAddress1;
        
        if(this.contact.Co_StreetAddress2 != null && this.contact.Co_StreetAddress2 != ' ' && this.contact.Co_StreetAddress2 != '')
        {
            Applicant1Address = Applicant1Address + '\n' + this.contact.Co_StreetAddress2 + '\n' + this.contact.Co_City 
            + '\n' + this.contact.Co_State + '\n' + this.contact.Co_Country + '\n' + this.contact.Co_Zip;
        }
        else
        {
            Applicant1Address = Applicant1Address + '\n' + this.contact.Co_City 
            + '\n' + this.contact.Co_State + '\n' + this.contact.Co_Country + '\n' + this.contact.Co_Zip;
        }

        if(this.sameAsApplicant1 == false)
        {
            Applicant2Name = this.contact.Co2_FirstName + ' ' + this.contact.Co2_LastName;

            if(this.contact.Co2_StreetAddress2 != null && this.contact.Co2_StreetAddress2 != ' ' && this.contact.Co2_StreetAddress2 != '')
            {
                Applicant2Address = this.contact.Co2_StreetAddress1 + '\n' + this.contact.Co2_StreetAddress2 + '\n' + this.contact.Co2_City 
                    + '\n' + this.contact.Co2_State + '\n' + this.contact.Co2_Country + '\n' + this.contact.Co2_Zip;
            }
            else
            {
                Applicant2Address = this.contact.Co2_StreetAddress1 + '\n' + this.contact.Co2_City 
                    + '\n' + this.contact.Co2_State + '\n' + this.contact.Co2_Country + '\n' + this.contact.Co2_Zip;
            }
        }
        
        contactObjectToUpdate.Id = this.contact.Id;
        //contactObjectToUpdate.Name = Applicant1Name;
        contactObjectToUpdate.FirstName = this.contact.Co_FirstName;
        contactObjectToUpdate.LastName = this.contact.Co_LastName;
        contactObjectToUpdate.MiddleName = this.contact.Co_MiddleName;
        contactObjectToUpdate.MailingStreet = this.contact.Co_StreetAddress1;
        contactObjectToUpdate.MailingCity = this.contact.Co_City;
        contactObjectToUpdate.MailingState =  this.contact.Co_State;
        contactObjectToUpdate.MailingCountry =  this.contact.Co_Country;        
        contactObjectToUpdate.MailingPostalCode =  this.contact.Co_Zip;        
        contactObjectToUpdate.PAN_Card__c = this.contact.Co_App_PAN_No__c;
        contactObjectToUpdate.Birthdate = this.contact.date_of_birth__c;
        contactObjectToUpdate.Designation__c = this.contact.Co_App_Occupation__c;
        contactObjectToUpdate.MobilePhone = this.contact.Co_App_Mobile_No__c;
        contactObjectToUpdate.Email = this.contact.Co_App_Email_Id__c;
        contactObjectToUpdate.Passport_No__c = this.contact.Co_App_Passport_No__c;
        contactObjectToUpdate.Adhaar_No__c = this.contact.Co_App_Adhaar__c;
        contactObjectToUpdate.Attorney_Holder_mobile__c = this.contact.Attorney_Holder_mobile__c;
        contactObjectToUpdate.Secondary_Email_Id__c = this.contact.Secondary_Email_Id__c;

        contactObjectToUpdate.Co_App_Designation__c = this.contact.Co_App_Designation__c;
        contactObjectToUpdate.Company_Name__c = this.contact.Company_Name__c;
        contactObjectToUpdate.Co_App_Occupation__c = this.contact.Co_App_Occupation__c;
        contactObjectToUpdate.Designation__c = this.contact.Designation__c;
        contactObjectToUpdate.Occupation__c = this.contact.Occupation__c;

        contactObjectToUpdate.Co_Applicant_Name__c = Applicant2Name;
        contactObjectToUpdate.Co_App_PAN_No__c = this.contact.Co_App_2_PAN_Card__c;
        contactObjectToUpdate.date_of_birth__c = this.contact.Co_App_2_Date_of_Birth__c;
        contactObjectToUpdate.Co_App_Occupation__c = this.contact.Co_App_2_Occupation__c;
        contactObjectToUpdate.Co_App_Passport_No__c = this.contact.Co_App_2_Passport_No__c;
        contactObjectToUpdate.Co_App_Adhaar__c = this.contact.Co_App2_Adhaar__c;

        contactObjectToUpdate.Co_App_Designation__c = this.contact.Co_App_2_Designation__c;

        if(this.sameAsApplicant1 == false)
        {
            contactObjectToUpdate.Co_App_Address__c = Applicant2Address; 
            contactObjectToUpdate.Co_App_Mobile_No__c = this.contact.Co_App_2_Mobile__c;
            contactObjectToUpdate.Co_App_Email_Id__c = this.contact.Co_App_2_Email__c;
        }
        else
        {
            contactObjectToUpdate.Co_App_Address__c = Applicant2Address;
            contactObjectToUpdate.Co_App_Mobile_No__c = this.contact.Co_App_2_Mobile__c;
            contactObjectToUpdate.Co_App_Email_Id__c = this.contact.Co_App_2_Email__c;

        }

        updateContactApplicant({contactRecordToUpdate : contactObjectToUpdate}).then(result => 
        {
            if(result != 'success')
            {
                this.errorInDML = true;
                this.errorMessage = result;
            }
            else
            {
                this.updateCoApplicant(this.contact);
                this.activeValue = 'two';
            }
            console.log('RESULT '+result);
            if(this.isFromBooking == true && this.isFromOwnerShifting == false){
                
                const showquotationevent = new CustomEvent('showquotationevent', {
                    detail: { 
                        showOppLeadPage : true,
                        receiptList : this.receiptToInsertList 
                    }
                });

                this.dispatchEvent(showquotationevent);
            }

            // if(this.isFromOwnerShifting == true && this.isFromBooking == true){

            //     UpdateQuotationWithReceiptDetails({quotationId : this.quotationId, receiptWithQuot : this.receiptToInsertList}).
            //     then(result => 
            //         {
            //            console.log('result' + result);
            //            console.log('this.quotationId' + this.quotationId);
            //            console.log('this.this.receiptToInsertList' + JSON.stringify(this.receiptToInsertList));
            //         })
            //         .catch(error => 
            //         {
            //             this.errorMessage = error;
            //             this.errorInDML = true;
            //         }); 

            //     const redirecttoopppage = new CustomEvent('redirecttoopppage', {
            //         detail: {OppPage : this.opportunityId 
                        
            //         }
            //     });

            //     this.dispatchEvent(redirecttoopppage);
            // }
            
        })
        .catch(error => 
        {
            console.log(JSON.stringify(error));
            this.errorMessage = error;
        }); 

        console.log('Contact Record ' +JSON.stringify(contactObjectToUpdate));
    }

    handleReceiptInput(event)
    {
        var label = event.target.label;
        
         
        if(label == 'Receipt Number')
        { 
            this.receiptToInsert.Name = event.target.value;  
        }
        else if(label == 'Receipt Date')
        {
            this.receiptToInsert.Receipt_Date__c = event.target.value;
        }
        else if(label == 'Issuing Bank')
        {
            this.receiptToInsert.Bank_Name__c = event.target.value;
        }
        else if(label == 'Transaction No')
        {
            this.receiptToInsert.Transaction_No__c = event.target.value;
            if(this.receiptToInsert.Transaction_No__c){
                this.isTransactionNo = false;
            }
            else{
                this.isTransactionNo = true;
            }
            
        }
        else if(label == 'Instrument Date')
        {
            this.receiptToInsert.Instrument_Date__c = event.target.value;
        }
        else if(label == 'Amount')
        {
            this.receiptToInsert.Amount__c = event.target.value;
        }
        else if(label == 'Remarks')
        {
            this.receiptToInsert.Remarks__c = event.target.value;
        }
        else if(label == 'Payment Method')
        {
            this.receiptToInsert.Mode_of_Payment__c = event.target.value;    
        }

        else if(label == 'Payment Category')
        {
            this.receiptToInsert.Payment_Category__c = event.target.value;  
            
            if(this.selectedOnlinePayment === true)
            {
                getMerchantId({ProjectId:this.projIdforEaseBuzz,BlockId:'',PaymentCategory:this.receiptToInsert.Payment_Category__c}).then(result => {
                   if(result==='NODATA')
                   {

                   }
                   else
                   {
                    var merchMap = JSON.parse(result);
                    this.subMerchantId = merchMap.subMerchant;
                    this.easeBuzzSalt = merchMap.salt;
                    this.easeBuzzKey = merchMap.key;
                   }
                }).catch(error => {
                   
                    console.log('Error on getMerchantId : '+error);

                });
            }
        }
    }

    //Added Prem Notes and Attechments
   selectedFiles = [];
   uploadedFiles = []; 
    transactionToAttachmentsMap = {};
    handleFileChange(event) {
        this.selectedFiles = Array.from(event.target.files);
        console.log('Selected Files:', this.selectedFiles.map(file => file.name));
        console.log('Selected Files:', this.selectedFiles[0].size);
        const MAX_SIZE = 2.2 * 1024 * 1024; // 2 MB in bytes
        for (const file of this.selectedFiles) {
            if (file.size > MAX_SIZE) {
                this.selectedFiles = [];
                this.showMessage('Error', `File "${file.name}" exceeds 2 MB limit.`, 'error');
                return;
            } 
        }
    }
    removeFile(event) {
        const index = event.target.dataset.index;
        this.selectedFiles.splice(index, 1);
        this.selectedFiles = [...this.selectedFiles]; // Refresh reactive property
    }
    get hasUploadedFiles() {
        return this.uploadedFiles && this.uploadedFiles.length > 0;
    }
   async uploadFile() {
        const txnNo = this.receiptToInsert.Transaction_No__c;
        console.log('pcc==>1');
        console.log('pcc==>11'+this.selectedFiles.length);
        console.log('pcc==>12'+this.selectedFiles);
        if (!this.selectedFiles || this.selectedFiles.length === 0) {
            this.showMessage('Error', 'Please select files before uploading.', 'error');
            return;
        }
        console.log('pcc==>3');
        if (!this.transactionToAttachmentsMap[txnNo]) {
            this.transactionToAttachmentsMap[txnNo] = [];
        }
        // const pdfFiles = this.selectedFiles.filter(file => {
        //     const fileName = file.name;
        //     return file.type === 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');
        // });

        // // Check if any non-PDF files were removed
        // if (pdfFiles.length !== this.selectedFiles.length) {
        //     this.showMessage('Warning', 'Only PDF files are allowed.', 'warning');
        //     this.selectedFiles = pdfFiles;
        // }
        // if (this.selectedFiles.length === 0) {
        //     this.showMessage('Error', 'No valid PDF files to upload.', 'error');
        //     return;
        // }
        for (const file of this.selectedFiles) {
            const base64str = await this.readFileAsBase64(file);
            this.transactionToAttachmentsMap[txnNo].push(base64str);
            console.log('Selected File Name:', file.name);
            console.log('Selected File Type:', file.type);
        }
        this.uploadedFiles = [...this.uploadedFiles, ...this.selectedFiles.map(f => f.name)];
        this.showMessage('Success', 'Files uploaded successfully!', 'success');
        this.selectedFiles = [];
        console.log('Mapped Attachments to Transaction Number:');
        console.log(JSON.stringify(this.transactionToAttachmentsMap, null, 2));
    }
        
    readFileAsBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
               // const base64 = reader.result.split(',')[1];
                const base64 = reader.result;//.split(',')[1];
                console.log('  MIME Type : '+reader.result.split(',')[0]);
                resolve(base64);
            };
            reader.onerror = (error) => reject(error);
            reader.readAsDataURL(file);
        });
    }
    
    get paymentOption() {
        return [
            { label: 'NEFT | RTGS', value: 'Bank' },
            { label: 'GPay | Paytm | PhonePe | AmazonPay', value: 'Wallet' },
            { label: 'Card Swipe | POS', value: 'CardSwipe' },
            { label: 'Cheque', value: 'Cheque' },
            { label: 'Online Payment(Credit | Debit Card)', value: 'OnlinePayment' },
            { label: 'Demand Draft', value: 'Demand Draft' },
            { label: 'TDS Challan', value: 'TDS Challan' },
            { label: 'Razor Pay', value: 'Razor Pay' },
            { label: 'IMPS', value: 'IMPS' },
            { label: 'UPI', value: 'UPI' },
            { label: 'Online', value: 'Online' },
        ];
    }

    // Shubham Kumar
    @track receiptToInsert = {
        Receipt_Purpose__c: 'Payment Towards EOI' // Set your predefined category value here
    };

    @track paymentCategoryOption = [
            { label: 'Payment Towards EOI', value: 'Payment Towards EOI' }
    ];

    get occupationOption(){
        return [
            { label: 'Business', value: 'Business' },
            { label: 'Service', value: 'Service' },
        ];
    }
        
    onSubmitClick()
    {
        const currentDate = new Date();
        const instrumentDate = new Date(this.receiptToInsert.Instrument_Date__c);
        const trxnNo = this.receiptToInsert.Transaction_No__c;
        const checkAttachments = this.transactionToAttachmentsMap[trxnNo];
        var receiptAmount = 0;
        if(this.receiptToInsert.Remarks__c == null || this.receiptToInsert.Receipt_Date__c == null || this.receiptToInsert.Bank_Name__c == null || 
            this.receiptToInsert.Transaction_No__c == null || this.receiptToInsert.Instrument_Date__c == null || this.receiptToInsert.Name == null
            || this.receiptToInsert.Mode_of_Payment__c == null || !this.receiptToInsert.Amount__c)
        {
            this.showMessage('Error','Please fill all the fields','error');
            return;
        }
        else if(instrumentDate > currentDate)
        {
            this.showMessage('Error','The Instrument Date cannot be future dated','error');
            return;
        }
       else if (!checkAttachments || checkAttachments.length === 0) {
            this.showMessage('Error', 'Please upload attachment before submitting.', 'error');
            return;
        }
        else {
            console.log('Inside else');
            for(var j = 0 ; j < this.receiptToInsertList.length; j++ )
            {
                receiptAmount = parseInt(receiptAmount) + parseInt(this.receiptToInsertList[j].Amount__c);
                console.log(receiptAmount);           
            }

            receiptAmount = parseInt(receiptAmount) + parseInt(this.receiptToInsert.Amount__c);
            checkForToeknUpgradeDegrade({oppId: this.opportunityId})
            .then(result => {
                console.log('Inside method called');
                this.tokenUpgrade = result;
                console.log('this.tokenUpgrade - '+JSON.stringify(this.tokenUpgrade));
                if(this.tokenUpgrade == null || this.tokenUpgrade == '')
                {
                    console.log('Inside null token receipt first time');
                    // if(receiptAmount >= this.tokenAmount || this.isFromBooking == true)
                    // {
                        this.receiptToInsert.Opportunity__c = this.opportunityId;
                        //this.receiptToInsert.Project_Name__c = this.project.Name;
                        if(this.receiptToInsert.Payment_Category__c == null){
                            this.receiptToInsert.Payment_Category__c = 'Flat Cost';
                        }
                        this.receiptToInsert.isToken__c = true;
                        let clonedReceipt = JSON.parse(JSON.stringify(this.receiptToInsert));
                        this.receiptToInsertList.push(clonedReceipt);
                        console.log('Receipt JSON ' + JSON.stringify(this.receiptToInsertList));
                        console.log('Attachment Map iss:', JSON.stringify(this.transactionToAttachmentsMap));
                        const allAttachments = {};
                        this.receiptToInsertList.forEach(receipt => {
                            const txnNo = receipt.Transaction_No__c;
                            allAttachments[txnNo] = this.transactionToAttachmentsMap[txnNo] || [];
                        });

                        console.log('allAttachments Map iss:', JSON.stringify(allAttachments));
                        this.contactUpdate();
                        this.areDetailsVisible = false;

                        console.log('tokenId' + this.tokenId);
                        console.log('oppId' + this.opportunityId);
                        
                        // get updated token info and send it to parent to insert token and receip
                        insertTokenAndReceipt({ receiptListToInsert: [], tokenId: this.tokenId, oppId: this.opportunityId, tokenInsert: false,mapOfAttechments :{} })
                            .then(data => {
                            var tokenObj = data;
                            
                            console.log('data!!!' + JSON.stringify(tokenObj));
                            const sendDataForPDF = new CustomEvent('senddataforpdf', {
                                    detail: { tokenObj: tokenObj, receiptToInsert: this.receiptToInsertList, attachmentsMap: allAttachments }
                            });
                            
                            this.dispatchEvent(sendDataForPDF);
                        })
                        .catch(error => 
                        {
                            console.error('insertTokenAndReceipt error:', JSON.stringify(error));
    this.showMessage('Error', this.getErrorMessage(error), 'error');
    this.navigateToRecordPage(this.tokenId);
                        });
                    // }
                    // else
                    // {
                    //     this.showMessage('Error','Receipt amount should be equal or greater than token amount','error');
                    // }
                }
                else
                {
                    console.log('Inside else of second receipt');
                    if(this.tokenUpgrade[0].Token_Upgrade_and_Degrade__c == 'Upgrade')
                    {
                        console.log('Inside Upgrade');
                        if(receiptAmount < this.tokenAmount || this.isFromBooking == true)
                        {
                            this.receiptToInsert.Opportunity__c = this.opportunityId;
                            //this.receiptToInsert.Project_Name__c = this.project.Name;
                            //this.receiptToInsert.Payment_Category__c = 'Advance';
                            if(this.receiptToInsert.Payment_Category__c == null){
                                this.receiptToInsert.Payment_Category__c = 'Advance';
                            }
                            this.receiptToInsert.isToken__c = true;
                            let clonedReceipt = JSON.parse(JSON.stringify(this.receiptToInsert));
                            this.receiptToInsertList.push(clonedReceipt);
                                console.log('Receipt JSON ' + JSON.stringify(this.receiptToInsertList));
                                const allAttachments = {};
                                this.receiptToInsertList.forEach(receipt => {
                                    const txnNo = receipt.Transaction_No__c;
                                    allAttachments[txnNo] = this.transactionToAttachmentsMap[txnNo] || [];
                                });
                        
                            this.contactUpdate();
                            this.areDetailsVisible = false;

                            console.log('tokenId' + this.tokenId);
                            console.log('oppId' + this.opportunityId);
                            
                            // get updated token info and send it to parent to insert token and receip
                                insertTokenAndReceipt({ receiptListToInsert: [], tokenId: this.tokenId, oppId: this.opportunityId, tokenInsert: false,mapOfAttechments :{} })
                                    .then(data => {
                                var tokenObj = data;
                                
                                console.log('data!!!' + JSON.stringify(tokenObj));
                                const sendDataForPDF = new CustomEvent('senddataforpdf', {
                                            detail: { tokenObj: tokenObj, receiptToInsert: this.receiptToInsertList, attachmentsMap: allAttachments }
                                });
                                
                                this.dispatchEvent(sendDataForPDF);
                            })
                            .catch(error => 
                            {
                                this.showMessage(error,'error','error');
                                this.navigateToRecordPage(this.tokenId);
                            });
                        }
                        else
                        {
                            this.showMessage('Error','Please adjust the token amount with earlier token','error');
                        }
                    }
                    else if(this.tokenUpgrade[0].Token_Upgrade_and_Degrade__c == 'Degrade')
                    {
                        console.log('Inside degrade');
            if(receiptAmount >= this.tokenAmount || this.isFromBooking == true)
            {
                this.receiptToInsert.Opportunity__c = this.opportunityId;
                //this.receiptToInsert.Project_Name__c = this.project.Name;
                if(this.receiptToInsert.Payment_Category__c == null){
                    this.receiptToInsert.Payment_Category__c = 'Advance';
                }
                this.receiptToInsert.isToken__c = true;
                let clonedReceipt = JSON.parse(JSON.stringify(this.receiptToInsert));
                this.receiptToInsertList.push(clonedReceipt);
                                console.log('Receipt JSON ' + JSON.stringify(this.receiptToInsertList));
                                const allAttachments = {};
                                this.receiptToInsertList.forEach(receipt => {
                                    const txnNo = receipt.Transaction_No__c;
                                    allAttachments[txnNo] = this.transactionToAttachmentsMap[txnNo] || [];
                                });

                this.contactUpdate();
                this.areDetailsVisible = false;

                            console.log('tokenId' + this.tokenId);
                            console.log('oppId' + this.opportunityId);
                            
                // get updated token info and send it to parent to insert token and receip
                                insertTokenAndReceipt({ receiptListToInsert: [], tokenId: this.tokenId, oppId: this.opportunityId, tokenInsert: false, mapOfAttechments :{} })
                                    .then(data => {
                    var tokenObj = data;
                    
                                console.log('data!!!' + JSON.stringify(tokenObj));
                    const sendDataForPDF = new CustomEvent('senddataforpdf', {
                                            detail: { tokenObj: tokenObj, receiptToInsert: this.receiptToInsertList, attachmentsMap: allAttachments }
                    });
                    
                    this.dispatchEvent(sendDataForPDF);
                })
                .catch(error => 
                {
                    this.showMessage(error,'error','error');
                    this.navigateToRecordPage(this.tokenId);
                });
            }
            else
            {
                this.showMessage('Error','Receipt amount should be equal or greater than token amount','error');
            }
                    }
                }
            })
            .catch(error => {
                this.error = error;
            });
            
        }
    }

    handleShowQuotation(event)
    {   
        if(this.receiptToInsert.Remarks__c == null || this.receiptToInsert.Receipt_Date__c == null || this.receiptToInsert.Bank_Name__c == null || 
            this.receiptToInsert.Transaction_No__c == null || this.receiptToInsert.Instrument_Date__c == null || this.receiptToInsert.Name == null
            || this.receiptToInsert.Mode_of_Payment__c == null || this.receiptToInsert.Amount__c == null)
        {
            this.showMessage('Error','Please fill all the fields','error');
        }
        else
        {
            this.receiptToInsert.Opportunity__c = this.opportunityId;
            this.receiptToInsert.Project_Name__c = this.project.Name;
            if(this.receiptToInsert.Payment_Category__c == null){
                this.receiptToInsert.Payment_Category__c = 'Advance';
            }
            let clonedReceipt = JSON.parse(JSON.stringify(this.receiptToInsert));
            this.receiptToInsertList.push(clonedReceipt);

            console.log(JSON.stringify(this.receiptToInsertList));
            
            this.contactUpdate();
            this.areDetailsVisible = false;

            // const showquotationevent = new CustomEvent('showquotationevent', {
            //     detail: { 
            //         showOppLeadPage : true,
            //         receiptList : this.receiptToInsertList 
            //     }
            // });

            // this.dispatchEvent(showquotationevent);
            
            this.activeValue = 'two';
                

        }
    }
    
    showMessage(message,title,variant){

        const showtostmessgaefromkyc = new CustomEvent('showtostmessgaefromkyc', {
            detail: { message : message,title:title,type:variant}
        });
    
        this.dispatchEvent(showtostmessgaefromkyc);
    }

    navigateToRecordPage(id)
    {
        const navigatetorecordpagefromkyc = new CustomEvent('navigatetorecordpagefromkyc', {
            detail: { Id :id}
        });        
            
        this.dispatchEvent(navigatetorecordpagefromkyc);
    }

    onNextReceipt()
    {   
        const trxnNo_1 = this.receiptToInsert.Transaction_No__c;
        const checkAttachments_1 = this.transactionToAttachmentsMap[trxnNo_1];
        if(this.receiptToInsert.Remarks__c == null || this.receiptToInsert.Receipt_Date__c == null || this.receiptToInsert.Bank_Name__c == null || 
            this.receiptToInsert.Transaction_No__c == null || this.receiptToInsert.Instrument_Date__c == null || this.receiptToInsert.Name == null
            || this.receiptToInsert.Mode_of_Payment__c == null || this.receiptToInsert.Amount__c == null)
        {
            this.showMessage('Error','Please fill all the fields','error');
            return;
        }
       else if (!checkAttachments_1 || checkAttachments_1.length === 0) {
            this.showMessage('Error', 'Please upload attachment before next receipt', 'error');
        }
        else {
            this.receiptToInsert.Opportunity__c = this.opportunityId;
            if(this.receiptToInsert.Payment_Category__c == null){
                this.receiptToInsert.Payment_Category__c = 'Advance';
            }
            if(this.isFromBooking === false)
            {
                this.receiptToInsert.isToken__c = true;
            }
            else
            {
                this.receiptToInsert.Project_Name__c = this.project.Name;
            }   
                
            let clonedReceipt = JSON.parse(JSON.stringify(this.receiptToInsert));
            this.receiptToInsertList.push(clonedReceipt);
            console.log(JSON.stringify(this.receiptToInsertList));
            
            this.receiptNumber = this.receiptNumber + 1;
            this.receiptToInsert.Remarks__c = null;
            this.receiptToInsert.Receipt_Date__c = this.today;
            this.receiptToInsert.Bank_Name__c = null;
            this.receiptToInsert.Transaction_No__c = null;
            this.receiptToInsert.Instrument_Date__c = this.today;
            this.receiptToInsert.Name = 'Receipt Number '+(this.receiptNumber);
            this.receiptToInsert.Mode_of_Payment__c = null;
            this.receiptToInsert.Amount__c = null;
            this.selectedBank = {};
            this.searchKey = null;
            this.pickListToShow = [];
            this.selectedRecordForBank = false;

            this.paymentTypeValueForRadio = 'Offline';
            this.isPaymentInitiated = false;
            this.isPaymentMade = false;
            this.showEaseBuzzButton = false;

        }           
    }

    //This Function will get the value from Text Input of issuing bank.
    handleOnchange(event)
    {
        this.searchKey = event.detail.value;
        
        console.log('searchKey ' + this.searchKey);
    
        if(typeof this.searchKey !== 'undefined') 
        {
            getSearchingBankName({pickListBankName : this.picklistValues, searchKey : this.searchKey})
            .then(result => 
            {
                if(result != null && result.length > 0)
                {
                    this.noBankData = false;
                    this.pickListToShow = result;
                    console.log('pickListToShow ');
                }
                else
                {
                    this.noBankData = true;
                    this.pickListToShow = [];
                    console.log('pickListToHIDE ');
                }
            })
            .catch(error => 
            {
                this.error = error;
                this.pickListToShow = undefined;
            }); 
        }
    }

    handleOnClick() 
    {
        console.log('searchKey ' + this.searchKey);
        this.pickListToShow = [];

        getSearchingBankName({pickListBankName : this.picklistValues, searchKey : this.searchKey})
        .then(result => 
        {
            if(result != null && result.length > 0)
            {
                this.noBankData = false;
                this.pickListToShow = result;
                console.log('handleOnClick ' +JSON.stringify(this.pickListToShow));
            }
            else
            {
                this.noBankData = true;
                this.pickListToShow = [];
            }
        })
        .catch(error => 
        {
            this.error = error;
            this.pickListToShow = undefined;
        }); 
    }

    handleSelect(event)
    {
        const selectedValue = event.detail;
        console.log(selectedValue + ' Inside selectedvalue');
        /* eslint-disable no-console*/
        this.selectedBank = this.pickListToShow.find(record => record.value === selectedValue);
        console.log(JSON.stringify(this.selectedBank) + ' handleselect ');   
        this.selectedRecordForBank = true;
        this.receiptToInsert.Bank_Name__c = selectedValue;
    }

    handleRemove(event) {
        event.preventDefault();
        this.selectedRecordForBank = false;
        this.selectedBank = {};
        this.receiptToInsert.Bank_Name__c = null;
        this.pickListToShow = [];
        this.searchKey = null;
    }
    
    handleShowApplicant2Details(event)
    {
        this.showApplicant2Details = event.target.checked;
        console.log(this.showApplicant2Details);        
    }
    
    handleCancel()
    {
       const redirectToUnitPage = new CustomEvent('redirectToUnitPage', {
            detail: { isCancel : true }
        });

        console.log('Dispatch');
        this.dispatchEvent(redirectToUnitPage);       
    }

    onSkipReceipt(){
        //this.receiptToInsert = null;
        this.receiptToInsert.Name = null;
        this.receiptToInsert.Receipt_Date__c = null;
        this.receiptToInsert.Bank_Name__c = null;
        this.receiptToInsert.Transaction_No__c = null;
        this.receiptToInsert.Instrument_Date__c = null;
        this.receiptToInsert.Amount__c = null;
        this.receiptToInsert.Mode_of_Payment__c = null;
        this.receiptToInsert.Remarks__c = null;
        this.receiptToInsert.Payment_Category__c = null;

        this.contactUpdate();
        
        // const showquotationevent = new CustomEvent('showquotationevent', {
        //     detail: { 
        //         showOppLeadPage : true,
        //         receiptList : this.receiptToInsertList 
        //     }
        // });
        
        // this.dispatchEvent(showquotationevent);
    }
    updateCoApplicant(contactObj){

        let coApplicant1ToCreate = {};
        let coApplicant2ToCreate = {};
        console.log('CoApplicany length ' + this.coApplicant.length);
        let listOfCoApplicant = [];
        let isApplicant_1_Available = false;
        let isApplicant_2_Available = false;
        for(let i=0; i < this.coApplicant.length; i++){
            console.log('Applicant_Number__c ' + this.coApplicant[i].Applicant_Number__c);
            if(this.coApplicant[i].Applicant_Number__c == 'Applicant 1'){
                isApplicant_1_Available = true;
            }
            else if(this.coApplicant[i].Applicant_Number__c == 'Applicant 2'){
                isApplicant_2_Available = true;
            }
        }
        console.log('isApplicant_1_Available ' + isApplicant_1_Available);
        console.log('isApplicant_2_Available ' + isApplicant_2_Available);

        if(isApplicant_1_Available == false){
            coApplicant1ToCreate.First_Name__c = this.contact.Co_FirstName;
            coApplicant1ToCreate.Last_Name__c = this.contact.Co_LastName;
            coApplicant1ToCreate.Street_Address__c = this.contact.Co_StreetAddress1;
            coApplicant1ToCreate.City__c = this.contact.Co_City;
            coApplicant1ToCreate.State__c =  this.contact.Co_State;
            coApplicant1ToCreate.Country__c =  this.contact.Co_Country;        
            coApplicant1ToCreate.Zip_Code__c =  this.contact.Co_Zip;        
            coApplicant1ToCreate.PAN_Card__c = this.contact.Co_App_PAN_No__c;
            coApplicant1ToCreate.Date_Of_Birth__c = this.contact.date_of_birth__c;
            coApplicant1ToCreate.Mobile__c = this.contact.Co_App_Mobile_No__c;
            coApplicant1ToCreate.Email__c = this.contact.Co_App_Email_Id__c;
            coApplicant1ToCreate.Aadhaar__c = this.contact.Co_App_Adhaar__c;
            coApplicant1ToCreate.Opportunity__c = this.opportunityId;
            coApplicant1ToCreate.Contact__c = this.contact.Id;
            coApplicant2ToCreate.Occupation__c = this.contact.co_Occupation;
            coApplicant1ToCreate.Applicant_Number__c = 'Applicant 1';
            coApplicant1ToCreate.Name = 'Co Applicant 1 - ' + this.selectedApartment.Name;
            listOfCoApplicant.push(coApplicant1ToCreate);
        }
        if(isApplicant_2_Available == false && this.showApplicant2Details == true){
            coApplicant2ToCreate.First_Name__c = this.contact.Co2_FirstName;
            coApplicant2ToCreate.Last_Name__c = this.contact.Co2_LastName;
            coApplicant2ToCreate.Street_Address__c = this.contact.Co2_StreetAddress1;
            coApplicant2ToCreate.City__c = this.contact.Co2_City;
            coApplicant2ToCreate.State__c =  this.contact.Co2_State;
            coApplicant2ToCreate.Country__c =  this.contact.Co2_Country;        
            coApplicant2ToCreate.Zip_Code__c =  this.contact.Co2_Zip;        
            coApplicant2ToCreate.PAN_Card__c = this.contact.Co_App_2_PAN_Card__c;
            coApplicant2ToCreate.Date_Of_Birth__c = this.contact.Co_App_2_Date_of_Birth__c;
            coApplicant2ToCreate.Mobile__c = this.contact.Co_App_2_Mobile__c;
            coApplicant2ToCreate.Email__c = this.contact.Co_App_2_Email__c;
            coApplicant2ToCreate.Aadhaar__c = this.contact.Co_App2_Adhaar__c;
            coApplicant2ToCreate.Occupation__c = this.contact.Co_App_Occupation__c;
            coApplicant2ToCreate.Opportunity__c = this.opportunityId;
            coApplicant2ToCreate.Contact__c = this.contact.Id;
            coApplicant2ToCreate.Applicant_Number__c = 'Applicant 2';
            coApplicant2ToCreate.Name = 'Co Applicant 2 - ' + this.selectedApartment.Name;
            listOfCoApplicant.push(coApplicant2ToCreate);
        } 
        console.log('listOfCoApplicant@@ ' + JSON.stringify(listOfCoApplicant));
        if(listOfCoApplicant.length > 0){
            updateCoApplicantObj({listOfCoApp : listOfCoApplicant})
                .then(result => {
                    console.log('co Appilcant updated ')
                }).catch(error => {
                    console.log('Error in co applicant update');
                    
                })
        }
    }
}