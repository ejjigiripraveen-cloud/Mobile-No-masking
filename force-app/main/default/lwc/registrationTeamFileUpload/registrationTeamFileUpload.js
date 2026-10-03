import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import searchOpportunityByMobile from '@salesforce/apex/ProjectDocumentUploadController.searchOpportunityByMobile';
import uploadFile from '@salesforce/apex/ProjectDocumentUploadController.uploadFile';
import getAttachedFiles from '@salesforce/apex/ProjectDocumentUploadController.getAttachedFiles';

const MAX_FILE_SIZE = 30500000; // 17.5 MB

const OPPORTUNITY_COLUMNS = [
    // { label: 'Customer Name',     fieldName: 'AccountName',      type: 'text', sortable: true },
    { label: 'Opportunity Name',  fieldName: 'Name',             type: 'text', sortable: true },
    { label: 'Project Name',      fieldName: 'Project_Name__c',  type: 'text', sortable: true },
    { label: 'Plot No.',          fieldName: 'Flat_No__c',        type: 'text', sortable: true }
    // { label: 'Stage',             fieldName: 'StageName',        type: 'text', sortable: true }
];

export default class ProjectDocumentUpload extends NavigationMixin(LightningElement) {

    // ── Search state ───────────────────────────────────────────────────
    @track mobileNumber  = '';
    @track isSearching   = false;
    @track showNoRecord  = false;

    // ── Opportunity list (multiple results) ────────────────────────────
    @track opportunityList     = [];
    @track showOpportunityList = false;
    @track selectedRows        = [];

    // ── Selected single opportunity ────────────────────────────────────
    @track opportunityRecord = null;

    // ── Upload state ───────────────────────────────────────────────────
    @track salesDeedFile          = null;
    @track encumbranceFile        = null;
    @track isSalesDeedUploading   = false;
    @track isEncumbranceUploading = false;

    // ── Already-uploaded flags ─────────────────────────────────────────
    @track salesDeedExists      = false;
    @track encumbranceExists    = false;

    // ── Attached files ─────────────────────────────────────────────────
    @track attachedFiles  = [];
    @track isLoadingFiles = false;

    // ── Status message ─────────────────────────────────────────────────
    @track statusMessage = '';
    @track statusType    = '';

    get opportunityColumns() {
        return OPPORTUNITY_COLUMNS;
    }

    // ── Show upload box only if doc doesn't already exist ─────────────
    get showSalesDeedUpload() {
        return !this.salesDeedExists;
    }

    get showEncumbranceUpload() {
        return !this.encumbranceExists;
    }

    // ── Mobile Input ───────────────────────────────────────────────────
    handleMobileChange(event) {
        this.mobileNumber        = event.detail.value;
        this.showNoRecord        = false;
        this.showOpportunityList = false;
        this.opportunityRecord   = null;
        this.opportunityList     = [];
        this.selectedRows        = [];
        this._resetUpload();
    }

    // ── Search ─────────────────────────────────────────────────────────
    handleSearch() {
        const mobile = (this.mobileNumber || '').trim();
        if (!mobile) {
            this._toast('Warning', 'Please enter a mobile number to search.', 'warning');
            return;
        }

        this.isSearching         = true;
        this.showNoRecord        = false;
        this.showOpportunityList = false;
        this.opportunityRecord   = null;
        this.opportunityList     = [];
        this.selectedRows        = [];
        this._resetUpload();

        searchOpportunityByMobile({ mobileNumber: mobile })
            .then(results => {
    this.isSearching = false;

    if (!results || results.length === 0) {
        this.showNoRecord = true;
        return;
    }

    this.opportunityList = results.map(wrapper => {

    const oppList = wrapper.oppList || [];
    const crmList = wrapper.crmList || [];

    if (oppList.length === 0) {
        return null;
    }

    const opp = oppList[0];
    const crm = crmList.length > 0 ? crmList[0] : {};

    return {
        Id:                   opp.Id,
        Name:                 opp.Name,
        StageName:            opp.StageName,
        CloseDate:            opp.CloseDate,
        Amount:               opp.Amount,
        Project_Name__c:      opp.Project_Name__c,
        Flat_No__c:           opp.Flat_No__c,
        PhoneNo__c:           opp.PhoneNo__c,
        Secondary_Mobile__c:  opp.Secondary_Mobile__c,
        Mobile__c:            opp.Mobile__c,
        AccountName:          opp.Account ? opp.Account.Name : '—',

        crmId:                   crm.Id || null,
        Sub_Registrar_Office__c: crm.Sub_Registrar_Office__c || '',
        Reg_Document_Number__c:  crm.Reg_Document_Number__c || '',
        Year_Of_Registration__c: crm.Year_Of_Registration__c || ''
    };
}).filter(Boolean);

    if (this.opportunityList.length === 1) {
        this._selectOpportunity(this.opportunityList[0]);
    } else {
        this.showOpportunityList = true;
    }
})
            .catch(error => {
                this.isSearching = false;
                this._toast('Error', 'Search failed: ' + this._err(error), 'error');
            });
    }

    // ── Row Selection ──────────────────────────────────────────────────
    handleRowSelection(event) {
        const selectedRecords = event.detail.selectedRows;
        if (selectedRecords && selectedRecords.length > 0) {
            this._selectOpportunity(selectedRecords[0]);
        } else {
            this.opportunityRecord = null;
            this._resetUpload();
        }
    }

    _selectOpportunity(opp) {
        this.opportunityRecord   = opp;
        this.selectedRows        = [opp.Id];
        this.showOpportunityList = this.opportunityList.length > 1;
        this._resetUpload();
        this._loadAttachedFiles();
    }

    // ── File Selection ─────────────────────────────────────────────────
    handleSalesDeedUpload(event) {
        const file = event.target.files[0];
        if (!file) return;
        if (file.size > MAX_FILE_SIZE) {
            this._toast('Error', 'Sales Deed exceeds 4.5 MB limit.', 'error');
            return;
        }
        this.salesDeedFile = file;
        this.statusMessage = '';
    }

    handleEncumbranceUpload(event) {
        const file = event.target.files[0];
        if (!file) return;
        if (file.size > MAX_FILE_SIZE) {
            this._toast('Error', 'Encumbrance Certificate exceeds 4.5 MB limit.', 'error');
            return;
        }
        this.encumbranceFile = file;
        this.statusMessage   = '';
    }

    clearSalesDeed() {
        this.salesDeedFile = null;
        this.template.querySelector('[data-id="salesDeed"]').value = null;
    }

    clearEncumbrance() {
        this.encumbranceFile = null;
        this.template.querySelector('[data-id="encumbrance"]').value = null;
    }

    // ── Save ───────────────────────────────────────────────────────────
    async handleSave() {
        if (!this.salesDeedFile && !this.encumbranceFile) {
            this._toast('Warning', 'Please select at least one file to upload.', 'warning');
            return;
        }

        const recordId = this.opportunityRecord.Id;
        const uploads  = [];

        if (this.salesDeedFile)   uploads.push({ file: this.salesDeedFile,   docName: 'Sales Deed',              key: 'salesDeed' });
        if (this.encumbranceFile) uploads.push({ file: this.encumbranceFile, docName: 'Encumbrance Certificate', key: 'encumbrance' });

        let allSuccess = true;

        for (const upload of uploads) {
            try {
                if (upload.key === 'salesDeed')   this.isSalesDeedUploading   = true;
                if (upload.key === 'encumbrance')  this.isEncumbranceUploading = true;

                const base64 = await this._toBase64(upload.file);

                await uploadFile({
                    recordId:    recordId,
                    fileName:    upload.docName,
                    base64Data:  base64,
                    contentType: upload.file.type
                });

                if (upload.key === 'salesDeed')   { this.isSalesDeedUploading   = false; this.salesDeedFile   = null; }
                if (upload.key === 'encumbrance')  { this.isEncumbranceUploading = false; this.encumbranceFile = null; }

            } catch (error) {
                allSuccess = false;
                if (upload.key === 'salesDeed')   this.isSalesDeedUploading   = false;
                if (upload.key === 'encumbrance')  this.isEncumbranceUploading = false;
                this._toast('Error', `Failed to upload ${upload.docName}: ` + this._err(error), 'error');
            }
        }

        if (allSuccess) {
            this.statusMessage = 'Documents saved successfully.';
            this.statusType    = 'success';
            this._toast('Success', 'Documents uploaded successfully!', 'success');
            this._loadAttachedFiles();
        }
    }

    // ── Load Attached Files ────────────────────────────────────────────
    _loadAttachedFiles() {
        this.isLoadingFiles = true;
        this.attachedFiles  = [];

        getAttachedFiles({ recordId: this.opportunityRecord.Id })
            .then(files => {
                this.isLoadingFiles = false;
                this.attachedFiles  = files.map(f => ({
                    ...f,
                    iconName:      this._iconFor(f.FileExtension),
                    formattedSize: this._formatBytes(f.ContentSize),
                    formattedDate: new Date(f.CreatedDate).toLocaleDateString('en-IN', {
                        day: '2-digit', month: 'short', year: 'numeric'
                    }),
                    downloadUrl: `/sfc/servlet.shepherd/document/download/${f.ContentDocumentId}`
                }));

                // ── Check which documents already exist ────────────────
                this.salesDeedExists   = this.attachedFiles.some(
                    f => f.Title && f.Title.toLowerCase() === 'sales deed'
                );
                this.encumbranceExists = this.attachedFiles.some(
                    f => f.Title && f.Title.toLowerCase() === 'encumbrance certificate'
                );
            })
            .catch(error => {
                this.isLoadingFiles = false;
                console.error('getAttachedFiles error:', JSON.stringify(error));
            });
    }

    handleDownload(event) {
        window.open(event.target.dataset.url, '_blank');
    }

    // ── Getters ────────────────────────────────────────────────────────
    get isSearchDisabled() {
        return !this.mobileNumber || !this.mobileNumber.trim() || this.isSearching;
    }

    get isSaveDisabled() {
        return (!this.salesDeedFile && !this.encumbranceFile)
            || this.isSalesDeedUploading
            || this.isEncumbranceUploading;
    }

    get hasAttachedFiles() {
        return this.attachedFiles && this.attachedFiles.length > 0;
    }

    get oppRecordUrl() {
        return this.opportunityRecord
            ? `/lightning/r/Opportunity/${this.opportunityRecord.Id}/view`
            : '#';
    }

    get statusClass() {
        return this.statusType === 'success'
            ? 'slds-theme_success slds-text-color_inverse'
            : 'slds-theme_error slds-text-color_inverse';
    }

    get statusIcon() {
        return this.statusType === 'success' ? 'utility:success' : 'utility:error';
    }

    // ── Utilities ──────────────────────────────────────────────────────
    _toBase64(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload  = () => resolve(reader.result.split(',')[1]);
            reader.onerror = () => reject(new Error('FileReader error'));
            reader.readAsDataURL(file);
        });
    }

    _resetUpload() {
        this.salesDeedFile      = null;
        this.encumbranceFile    = null;
        this.attachedFiles      = [];
        this.statusMessage      = '';
        this.statusType         = '';
        this.salesDeedExists    = false;
        this.encumbranceExists  = false;
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _err(error) {
        if (error?.body?.message) return error.body.message;
        if (error?.message)       return error.message;
        return 'Unknown error';
    }

    _formatBytes(bytes) {
        if (!bytes)          return '—';
        if (bytes < 1024)    return `${bytes} B`;
        if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${(bytes / 1048576).toFixed(1)} MB`;
    }

    _iconFor(ext) {
        if (!ext) return 'doctype:unknown';
        switch (ext.toLowerCase()) {
            case 'pdf':  return 'doctype:pdf';
            case 'jpg':
            case 'jpeg':
            case 'png':
            case 'gif':  return 'doctype:image';
            case 'doc':
            case 'docx': return 'doctype:word';
            default:     return 'doctype:unknown';
        }
    }
}