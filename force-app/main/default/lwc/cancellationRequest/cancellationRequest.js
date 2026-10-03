import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getAudioFiles from '@salesforce/apex/CancellationController.getAudioFiles';
import sendCancellationEmail from '@salesforce/apex/CancellationController.sendCancellationEmail';
import updateCancellationStatus from '@salesforce/apex/CancellationController.updateCancellationStatus';
import getCRMRecord from '@salesforce/apex/BlockerUpdateAPI.getCRMRecord';
import updateFileRole from '@salesforce/apex/CancellationController.updateFileRole';
import deleteAudioFile from '@salesforce/apex/CancellationController.deleteAudioFile';

import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME from '@salesforce/schema/User.Profile.Name';

import NAME_FIELD from '@salesforce/schema/Opportunity.Name';
import PLOT_SIZE_FIELD from '@salesforce/schema/Opportunity.Built_Up_Area__c';
import PLOT_NO_FIELD from '@salesforce/schema/Opportunity.Flat_No__c';
import PRICE_FIELD from '@salesforce/schema/Opportunity.Price_Per_sft_cent__c';
import PROJECT_NAME_FIELD from '@salesforce/schema/Opportunity.Project_Name__c';
import PLOT_COST_FIELD from '@salesforce/schema/Opportunity.Total_Basic_After_Discount__c';
import TOTAL_COST_FIELD from '@salesforce/schema/Opportunity.Total_Cost_With_Tax__c';
import APPROVED_WITH_FIELD from '@salesforce/schema/Opportunity.Approved_With__c';
import NOC_SUBMITTED_DATE from '@salesforce/schema/Opportunity.NOC_Submitted_Date__c';
import TOTAL_RECEIPTS_FIELD from '@salesforce/schema/Opportunity.Total_Receipts__c';
import MOBILE from '@salesforce/schema/Opportunity.Mobile__c';
import SECONDARY_MOBILE from '@salesforce/schema/Opportunity.Secondary_Mobile__c';

const oppFields = [
    NAME_FIELD, PLOT_SIZE_FIELD, PLOT_NO_FIELD, PRICE_FIELD,
    PROJECT_NAME_FIELD, PLOT_COST_FIELD, TOTAL_COST_FIELD,
    APPROVED_WITH_FIELD, NOC_SUBMITTED_DATE, TOTAL_RECEIPTS_FIELD,
    SECONDARY_MOBILE, MOBILE
];

// ─────────────────────────────────────────────────────────────────
// DEPENDENCY MAP  (Reason → Remark → Sub Remark)
// ─────────────────────────────────────────────────────────────────
const REASON_MAP = {
    "Financial & Payment Related": {
        "Financial Constraint": ["Loss of income","Business loss","Existing loan burden","Family financial commitment"],
        "Payment Default": ["EMI not manageable","Cheque bounced","Payment delay beyond grace period"],
        "Loan Related Issue": ["Loan rejected","Eligible loan amount low","High interest rate concern","Delay in loan processing"]
    },
    "Product & Inventory Related": {
        "Product Availability Issue": ["Required plot not available","Preferred facing unavailable","Size expectation mismatch"],
        "Layout/Planning Concern": ["Change in layout","Site planning dissatisfaction","Open space concern","Road width concern"],
        "Product Preference Change": ["Interested in flat/apartment","Interested in villa","Planning resale purchase"],
        "Swap/Transfer Issue": ["Logged instead of swap","Name transfer not permitted"]
    },
    "Pricing & Offer Related": {
        "Pricing Concern": ["Budget exceeded","Better price in competitor project","Price escalation"],
        "Offer Dispute": ["Offer commitment mismatch","Scheme-related dissatisfaction","Discount expectation not met"],
        "CRM Pricing Miscommunication": ["Incorrect pricing communication","Offer not updated properly"]
    },
    "Legal & Approval Related": {
        "Approval Delay": ["Government approval pending","Registration delay","NOC delay"],
        "Legal Concern": ["Documentation concern","Legal verification negative","Parent document concern"],
        "Regulatory Impact": ["RAMSAR announcement","Zoning/environmental concern"]
    },
    "Location & Site Related": {
        "Location Concern": ["Distance from city","Poor connectivity","Area development concern"],
        "Site Condition Issue": ["Water logging concern","Groundwater issue","Site maintenance concern","Infrastructure concern"],
        "Vastu Concern": ["Vastu mismatch"],
        "Social Influence Impact": ["Negative social media feedback","Negative word-of-mouth"]
    },
    "Customer Personal Situation": {
        "Personal Reason": ["Family decision change","Priority change","Marriage/education expense"],
        "Medical Emergency": ["Self medical issue","Family medical issue"],
        "Sudden Demise": ["Immediate family demise"],
        "Relocation": ["Job transfer","Shifted to another city/country"],
        "Time Extension Request": ["Purchase postponed","Waiting for funds"]
    },
    "Competition Related": {
        "Competitor Purchase": ["Better amenities elsewhere","Better pricing elsewhere","Better location elsewhere"],
        "Alternative Investment Decision": ["Purchased resale property","Chose apartment instead"]
    },
    "Internal Process & Service Failure": {
        "Customer Experience Issue": ["Lack of follow-up","Delay in response","Sales experience dissatisfaction"],
        "CRM Process Failure": ["Incorrect information shared","Follow-up missed","Commitment mismatch"],
        "Registration Coordination Issue": ["Delay in scheduling","Poor coordination"],
        "Retention Failure": ["Customer not convinced","Escalation not handled properly"],
        "Sales Process Failure": ["Plot Not Allocated"]
    },
    "Management / Exceptional Cases": {
        "Management Decision": ["Strategic cancellation","Allocation correction","Internal approval issue"],
        "Exceptional Case": ["Duplicate booking","Test booking","Force majeure situation"],
        "Approval Delay": ["POA delay","RERA delay"]
    }
};

// SUB_REMARK_META[subRemark] = { categoryType, department }
const SUB_REMARK_META = {
    "Loss of income":                       { categoryType: "Avoidable",                 department: "Customer"      },
    "Business loss":                        { categoryType: "Avoidable",                 department: "Customer"      },
    "Existing loan burden":                 { categoryType: "Avoidable",                 department: "Customer"      },
    "Family financial commitment":          { categoryType: "Avoidable",                 department: "Customer"      },
    "EMI not manageable":                   { categoryType: "Avoidable",                 department: "Customer"      },
    "Cheque bounced":                       { categoryType: "Avoidable",                 department: "Customer"      },
    "Payment delay beyond grace period":    { categoryType: "Avoidable",                 department: "Customer"      },
    "Loan rejected":                        { categoryType: "Partially Avoidable",       department: "Customer"      },
    "Eligible loan amount low":             { categoryType: "Partially Avoidable",       department: "Customer"      },
    "High interest rate concern":           { categoryType: "Partially Avoidable",       department: "CBS"           },
    "Delay in loan processing":             { categoryType: "Partially Avoidable",       department: "CBS"           },
    "Required plot not available":          { categoryType: "Partially Avoidable",       department: "Sales"         },
    "Preferred facing unavailable":         { categoryType: "Partially Avoidable",       department: "Sales"         },
    "Size expectation mismatch":            { categoryType: "Partially Avoidable",       department: "Sales"         },
    "Change in layout":                     { categoryType: "Partially Avoidable",       department: "D&A"           },
    "Site planning dissatisfaction":        { categoryType: "Partially Avoidable",       department: "D&A"           },
    "Open space concern":                   { categoryType: "Partially Avoidable",       department: "Sales"         },
    "Road width concern":                   { categoryType: "Partially Avoidable",       department: "D&A"           },
    "Interested in flat/apartment":         { categoryType: "Competition Loss",          department: "Customer"      },
    "Interested in villa":                  { categoryType: "Competition Loss",          department: "Customer"      },
    "Planning resale purchase":             { categoryType: "Competition Loss",          department: "Customer"      },
    "Logged instead of swap":               { categoryType: "Avoidable",                 department: "Sales"         },
    "Name transfer not permitted":          { categoryType: "Avoidable",                 department: "Sales"         },
    "Budget exceeded":                      { categoryType: "Avoidable",                 department: "Customer"      },
    "Better price in competitor project":   { categoryType: "Avoidable",                 department: "Sales"         },
    "Price escalation":                     { categoryType: "Avoidable",                 department: "Sales"         },
    "Offer commitment mismatch":            { categoryType: "Avoidable",                 department: "Sales"         },
    "Scheme-related dissatisfaction":       { categoryType: "Avoidable",                 department: "Sales"         },
    "Discount expectation not met":         { categoryType: "Avoidable",                 department: "Sales"         },
    "Incorrect pricing communication":      { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Offer not updated properly":           { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Government approval pending":          { categoryType: "Partially Avoidable",       department: "D&A"           },
    "Registration delay":                   { categoryType: "Partially Avoidable",       department: "D&A"           },
    "NOC delay":                            { categoryType: "Partially Avoidable",       department: "Finance"       },
    "Documentation concern":               { categoryType: "Partially Avoidable",       department: "Legal"         },
    "Legal verification negative":          { categoryType: "Partially Avoidable",       department: "Legal"         },
    "Parent document concern":              { categoryType: "Partially Avoidable",       department: "Legal"         },
    "RAMSAR announcement":                  { categoryType: "Unavoidable",               department: "Legal"         },
    "Zoning/environmental concern":         { categoryType: "Unavoidable",               department: "Legal"         },
    "Distance from city":                   { categoryType: "Competition Loss",          department: "Sales"         },
    "Poor connectivity":                    { categoryType: "Competition Loss",          department: "Sales"         },
    "Area development concern":             { categoryType: "Competition Loss",          department: "Civil"         },
    "Water logging concern":                { categoryType: "Partially Avoidable",       department: "Civil"         },
    "Groundwater issue":                    { categoryType: "Partially Avoidable",       department: "Others"        },
    "Site maintenance concern":             { categoryType: "Partially Avoidable",       department: "Civil"         },
    "Infrastructure concern":               { categoryType: "Partially Avoidable",       department: "Civil"         },
    "Vastu mismatch":                       { categoryType: "Unavoidable",               department: "Customer"      },
    "Negative social media feedback":       { categoryType: "Competition Loss",          department: "Digital"       },
    "Negative word-of-mouth":               { categoryType: "Competition Loss",          department: "Others"        },
    "Family decision change":               { categoryType: "Unavoidable",               department: "Customer"      },
    "Priority change":                      { categoryType: "Unavoidable",               department: "Customer"      },
    "Marriage/education expense":           { categoryType: "Unavoidable",               department: "Customer"      },
    "Self medical issue":                   { categoryType: "Unavoidable",               department: "Customer"      },
    "Family medical issue":                 { categoryType: "Unavoidable",               department: "Customer"      },
    "Immediate family demise":              { categoryType: "Unavoidable",               department: "Customer"      },
    "Job transfer":                         { categoryType: "Unavoidable",               department: "Customer"      },
    "Shifted to another city/country":      { categoryType: "Unavoidable",               department: "Customer"      },
    "Purchase postponed":                   { categoryType: "Partially Avoidable",       department: "CRM"           },
    "Waiting for funds":                    { categoryType: "Partially Avoidable",       department: "CRM"           },
    "Better amenities elsewhere":           { categoryType: "Competition Loss",          department: "Customer"      },
    "Better pricing elsewhere":             { categoryType: "Competition Loss",          department: "Customer"      },
    "Better location elsewhere":            { categoryType: "Competition Loss",          department: "Customer"      },
    "Purchased resale property":            { categoryType: "Competition Loss",          department: "Customer"      },
    "Chose apartment instead":              { categoryType: "Competition Loss",          department: "Customer"      },
    "Lack of follow-up":                    { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Delay in response":                    { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Sales experience dissatisfaction":     { categoryType: "Internal Operational Issue",department: "Sales"         },
    "Incorrect information shared":         { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Follow-up missed":                     { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Commitment mismatch":                  { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Delay in scheduling":                  { categoryType: "Internal Operational Issue",department: "Registration"  },
    "Poor coordination":                    { categoryType: "Internal Operational Issue",department: "Registration"  },
    "Customer not convinced":               { categoryType: "Internal Operational Issue",department: "Retention"     },
    "Escalation not handled properly":      { categoryType: "Internal Operational Issue",department: "CRM"           },
    "Strategic cancellation":              { categoryType: "Exceptional",               department: "Management"    },
    "Allocation correction":               { categoryType: "Exceptional",               department: "Management"    },
    "Internal approval issue":             { categoryType: "Exceptional",               department: "Management"    },
    "Duplicate booking":                    { categoryType: "Exceptional",               department: "Sales"         },
    "Test booking":                         { categoryType: "Exceptional",               department: "Mis"           },
    "Force majeure situation":              { categoryType: "Exceptional",               department: "Civil"         },
    "POA delay":                            { categoryType: "Partially Avoidable",       department: "Management"    },
    "Plot Not Allocated":                   { categoryType: "Internal Operational Issue",department: "Sales"         },
    "RERA delay":                           { categoryType: "Partially Avoidable",       department: "D&A"           }
};

export default class CancellationRequest extends LightningElement {

    @api recordId;
    @track urlOppId;
    @track audioFiles = [];
    @track isLoading = false;
    isStatusAction = false;
    isUploading = false;

    crmId;
    opp = {};
    profileName;
    wiredResult;
    cancellationSubmittedDate = null;
    salesTLApprovedDate = null;
    salesHeadApprovedDate = null;
    finalApprovedDate = null;

    userId = USER_ID;
    acceptedFormats = ['.mp3','.wav','.m4a','.mp4','.mpeg','.avi','.mov','.aac','.ogg'];

    // Dependent dropdown state
    @track selectedReason = '';
    @track selectedRemark = '';
    @track selectedSubRemark = '';

    // ─── Computed ───────────────────────────────────────────────────

    get effectiveRecordId() {
        return this.urlOppId || this.recordId;
    }

    get isCancellationAlreadySubmitted() { return this.cancellationSubmittedDate != null; }
    get isTLApproved()                   { return this.salesTLApprovedDate != null; }
    get isSalesHeadApproved()            { return this.salesHeadApprovedDate != null; }
    get isFinalApproved()                { return this.finalApprovedDate != null; }
    get isFullyLocked()                  { return this.finalApprovedDate != null; }

    // Dropdown option lists
    get reasonOptions() {
        return Object.keys(REASON_MAP).map(r => ({ label: r, value: r }));
    }
    get remarkOptions() {
        if (!this.selectedReason || !REASON_MAP[this.selectedReason]) return [];
        return Object.keys(REASON_MAP[this.selectedReason]).map(r => ({ label: r, value: r }));
    }
    get subRemarkOptions() {
        if (!this.selectedReason || !this.selectedRemark) return [];
        return (REASON_MAP[this.selectedReason]?.[this.selectedRemark] || []).map(s => ({ label: s, value: s }));
    }

    // Disable chain
    get isRemarkDisabled()    { return this.isFullyLocked || !this.selectedReason; }
    get isSubRemarkDisabled() { return this.isFullyLocked || !this.selectedRemark; }

    // Auto-derived from Sub Remark
    get derivedCategoryType() {
        return this.selectedSubRemark ? (SUB_REMARK_META[this.selectedSubRemark]?.categoryType || '') : '';
    }
    get derivedDepartment() {
        return this.selectedSubRemark ? (SUB_REMARK_META[this.selectedSubRemark]?.department || '') : '';
    }

    // Profile getters
    get isCRM()            { return ['CRM Team','CRM Lead','System Administrator'].includes(this.profileName); }
    get isSalesTL()        { return ['Sales TL','Sales Head','Presales Head'].includes(this.profileName); }
    get isSalesTLButton()  { return this.profileName === 'Sales TL'; }
    get isSalesHead()      { return ['Sales Head','Presales Head'].includes(this.profileName); }
    get isSalesHeadButton(){ return this.profileName === 'Sales Head'; }
    get isPresalesHead()   { return this.profileName === 'Presales Head'; }

    // ─── Lifecycle ──────────────────────────────────────────────────

    @wire(CurrentPageReference)
    getStateParameters(pageRef) {
        if (pageRef?.state?.c__oppId) {
            this.urlOppId = pageRef.state.c__oppId;
        }
    }

    connectedCallback() {
        setTimeout(() => { this.loadCRMRecord(); }, 0);
    }

    // ─── Wire: Opportunity ──────────────────────────────────────────

    @wire(getRecord, { recordId: '$effectiveRecordId', fields: oppFields })
    wiredOpp({ data }) {
        if (data) {
            this.opp = {
                name:            getFieldValue(data, NAME_FIELD) || '',
                plotSize:        getFieldValue(data, PLOT_SIZE_FIELD) || '',
                plotNo:          getFieldValue(data, PLOT_NO_FIELD) || '',
                price:           getFieldValue(data, PRICE_FIELD) || '',
                projectName:     getFieldValue(data, PROJECT_NAME_FIELD) || '',
                plotCost:        getFieldValue(data, PLOT_COST_FIELD) || '',
                totalCost:       getFieldValue(data, TOTAL_COST_FIELD) || '',
                approvedWith:    getFieldValue(data, APPROVED_WITH_FIELD) || '',
                noCSubmittedDate:getFieldValue(data, NOC_SUBMITTED_DATE) || '',
                totalReceipts:   getFieldValue(data, TOTAL_RECEIPTS_FIELD) || '',
                secondaryMobile: getFieldValue(data, SECONDARY_MOBILE) || '',
                mobile:          getFieldValue(data, MOBILE) || ''
            };
        }
    }

    // ─── Wire: User profile ─────────────────────────────────────────

    @wire(getRecord, { recordId: USER_ID, fields: [PROFILE_NAME] })
    userInfo({ data }) {
        if (data) {
            this.profileName = data.fields.Profile.displayValue;
        }
    }

    // ─── Wire: Audio files ──────────────────────────────────────────

    @wire(getAudioFiles, { recordId: '$effectiveRecordId' })
    wiredFiles(result) {
        this.wiredResult = result;
        if (result.data) {
            this.audioFiles = result.data.map(file => ({
                id:          file.ContentDocumentId,
                title:       file.ContentDocument.Title,
                role:        file.ContentDocument.Description,
                extension:   file.ContentDocument.FileExtension,
                url:         `/sfc/servlet.shepherd/document/download/${file.ContentDocumentId}`,
                isVideo:     ['mp4','mpeg'].includes(file.ContentDocument.FileExtension),
                createdById: file.ContentDocument.CreatedById,
                canDelete:   file.ContentDocument.CreatedById === this.userId
            }));
        }
    }

    // ─── CRM Record Load ────────────────────────────────────────────

    loadCRMRecord() {
        if (!this.effectiveRecordId) return;
        this.isLoading = true;

        getCRMRecord({ oppId: this.effectiveRecordId })
            .then(result => {
                if (result?.crmRecord) {
                    this.crmId                  = result.crmRecord.Id;
                    this.cancellationSubmittedDate = result.crmRecord.Cancellation_Submitted_Date__c || null;
                    this.salesTLApprovedDate      = result.crmRecord.Sales_TL_Approved_Date__c || null;
                    this.salesHeadApprovedDate    = result.crmRecord.Sales_L2_Manager_Approved_Date__c || null;
                    this.finalApprovedDate        = result.crmRecord.Cancellation_Approved_Date__c || null;

                    // Pre-populate dependent dropdowns from saved values
                    const reason    = result.crmRecord.Cancellation_Reason__c || '';
                    const remark    = result.crmRecord.Cancellation_Remark__c || '';
                    const subRemark = result.crmRecord.Cancellation_Sub_Remark__c || '';

                    if (reason && REASON_MAP[reason]) {
                        this.selectedReason = reason;
                    }
                    if (remark && this.selectedReason && REASON_MAP[this.selectedReason]?.[remark]) {
                        this.selectedRemark = remark;
                    }
                    if (subRemark) {
                        this.selectedSubRemark = subRemark;
                    }
                }
            })
            .catch(error => { console.error('CRM Load Error:', error); })
            .finally(() => { this.isLoading = false; });
    }

    // ─── Dependent dropdown handlers ────────────────────────────────

    handleReasonChange(event) {
        this.selectedReason    = event.target.value;
        this.selectedRemark    = '';
        this.selectedSubRemark = '';
    }

    handleRemarkChange(event) {
        this.selectedRemark    = event.target.value;
        this.selectedSubRemark = '';
    }

    handleSubRemarkChange(event) {
        this.selectedSubRemark = event.target.value;
        // derivedCategoryType and derivedDepartment update automatically via getters
    }

    // ─── Form load (fallback pre-fill from lightning-record-edit-form) ─

    handleFormLoad(event) {
        const fields = event.detail?.recordUi?.record?.fields;
        if (!fields) return;

        const r  = fields.Cancellation_Reason__c?.value || '';
        const rm = fields.Cancellation_Remark__c?.value || '';
        const sr = fields.Cancellation_Sub_Remark__c?.value || '';

        if (r && REASON_MAP[r] && !this.selectedReason) {
            this.selectedReason = r;
        }
        if (rm && this.selectedReason && REASON_MAP[this.selectedReason]?.[rm] && !this.selectedRemark) {
            this.selectedRemark = rm;
        }
        if (sr && !this.selectedSubRemark) {
            this.selectedSubRemark = sr;
        }
    }

    // ─── Validation ─────────────────────────────────────────────────

    validateDependentFields() {
        if (!this.selectedReason) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Please select a Cancellation Reason.', variant: 'error' }));
            return false;
        }
        if (!this.selectedRemark) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Please select a Cancellation Remark.', variant: 'error' }));
            return false;
        }
        if (!this.selectedSubRemark) {
            this.dispatchEvent(new ShowToastEvent({ title: 'Validation Error', message: 'Please select a Cancellation Sub Remark.', variant: 'error' }));
            return false;
        }
        return true;
    }

    validateAudioRequired() {
        let requiredRole = null;
        if (this.isPresalesHead)     requiredRole = 'Presales Head';
        else if (this.isSalesTLButton) requiredRole = 'Sales TL';
        else if (this.isCRM)         requiredRole = 'CRM';

        if (!requiredRole) return true;

        const hasRoleAudio = this.audioFiles.some(f => f.role === requiredRole);
        if (!hasRoleAudio) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Audio Proof Required',
                message: `Please upload ${requiredRole} Audio Proof before proceeding.`,
                variant: 'error'
            }));
            return false;
        }
        return true;
    }

    // ─── Form submit ────────────────────────────────────────────────

    handleSuccess(event) {
        if (this.isStatusAction) return;

        if (!this.validateDependentFields()) return;
        if (!this.validateAudioRequired()) {
            if (event) event.preventDefault();
            return;
        }

        this.isLoading = true;
        this.sendEmail('Sales Owner Manager', 'Cancellation Approval Required',
            'Request for cancellation approval. Please review the cancellation request and take necessary action.')
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Cancellation request submitted successfully', variant: 'success' }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .finally(() => { this.isLoading = false; });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // ─── Audio handlers ─────────────────────────────────────────────

    handleDeleteAudio(event) {
        const docId = event.target.dataset.id;
        this.isLoading = true;
        deleteAudioFile({ contentDocumentId: docId })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: 'Audio deleted successfully', variant: 'success' }));
                return refreshApex(this.wiredResult);
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body.message, variant: 'error' }));
            })
            .finally(() => { this.isLoading = false; });
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        const role = event.target.dataset.role;
        const alreadyExists = this.audioFiles.some(f => f.role === role);

        if (alreadyExists) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Audio Already Uploaded',
                message: `${role} audio already exists. Delete it to upload again.`,
                variant: 'warning'
            }));
            return;
        }

        this.isUploading = true;
        updateFileRole({ documentIds: uploadedFiles.map(f => f.documentId), roleName: role })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Success', message: `${role} audio uploaded successfully`, variant: 'success' }));
                return this.refreshFiles();
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: error.body?.message || 'File upload error', variant: 'error' }));
                this.isUploading = false;
            });
    }

    refreshFiles() {
        this.isUploading = true;
        refreshApex(this.wiredResult)
            .then(() => { this.isUploading = false; })
            .catch(() => { this.isUploading = false; });
    }

    // ─── Approval handlers ───────────────────────────────────────────

    handleTLApprove()           { this.updateStatus('TL Approve',           'Sales Owner Managers Manager',    'Cancellation Approval Required', 'Team Leader has APPROVED the cancellation request.'); }
    handleTLReject()            { this.updateStatus('TL Reject',            'Opp Owner',                       'Cancellation Approval Required', 'Team Leader has REJECTED the cancellation request.'); }
    handleTLHold()              { this.updateStatus('TL Hold',              'Opp Owner',                       'Cancellation Approval Required', 'Team Leader has placed the cancellation request ON HOLD.'); }
    handleHeadApprove()         { this.updateStatus('Head Approve',         'Presales Owner Managers Manager', 'Cancellation Approval Required', 'Sales Head has APPROVED the cancellation request.'); }
    handleHeadReject()          { this.updateStatus('Head Reject',          'Opp Owner',                       'Cancellation Approval Required', 'Sales Head has REJECTED the cancellation request.'); }
    handleHeadHold()            { this.updateStatus('Head Hold',            'Opp Owner',                       'Cancellation Approval Required', 'Sales Head has placed the cancellation request ON HOLD.'); }
    handlePresalesHeadApprove() { this.updateStatus('Presales Head Approve','Presales Head',                   'Cancellation Approval Required', 'Presales Head has APPROVED the cancellation request.'); }
    handlePresalesHeadReject()  { this.updateStatus('Presales Head Reject', 'Opp Owner',                       'Cancellation Approval Required', 'Presales Head has REJECTED the cancellation request.'); }
    handlePresalesHeadHold()    { this.updateStatus('Presales Head Hold',   'Opp Owner',                       'Cancellation Approval Required', 'Presales Head has placed the cancellation request ON HOLD.'); }

    updateStatus(action, toEmail, subject, body) {
    if (this.isLoading) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Processing',
                message: 'Action already in progress',
                variant: 'warning'
            })
        );
        return;
    }

    if (this.isUploading) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Please Wait',
                message: 'File upload is still processing. Try again.',
                variant: 'warning'
            })
        );
        return;
    }

    if (!this.validateAudioRequired()) {
        return;
    }

    this.isLoading = true;
    this.isStatusAction = true;

    // REMOVE THIS
    // this.submitForm();

    updateCancellationStatus({
        oppId: this.effectiveRecordId,
        actionType: action
    })
        .then(() => {
            if (toEmail) {
                return this.sendEmail(toEmail, subject, body);
            }
        })
        .then(() => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Action completed successfully',
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch(error => {
            console.error(
                'Full Error Object:',
                JSON.stringify(error)
            );

            const message =
                error?.body?.message ||
                error?.body?.output?.errors?.[0]?.message ||
                error?.message ||
                'Unknown error occurred';

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error — ' + action,
                    message: message,
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        })
        .finally(() => {
            this.isLoading = false;
            this.isStatusAction = false;
        });
}

    submitForm() {
        const form = this.template.querySelector('lightning-record-edit-form');
        if (form) form.submit();
    }

    sendEmail(toEmail, subject, body) {
        console.log('Sending email to:', toEmail);
        return sendCancellationEmail({ toEmail, oppId: this.effectiveRecordId, subject, body });
    }
}