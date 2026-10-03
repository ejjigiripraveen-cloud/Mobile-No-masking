public without sharing class ProjectDocumentUploadController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getProjectPicklistValues() {
        List<String> values = new List<String>();
        try {
            Schema.DescribeFieldResult fieldRes = Schema.getGlobalDescribe()
                .get('Lead')
                .getDescribe()
                .fields
                .getMap()
                .get('Referral_Project__c')
                .getDescribe();
            
            for (Schema.PicklistEntry entry : fieldRes.getPicklistValues()) {
                if (entry.isActive()) {
                    values.add(entry.getLabel());
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching global picklist: ' + e.getMessage());
        }
        return values;
    }
    
    /**
     * Queries Opportunity by Project Name and Plot No.
     */
    @AuraEnabled
    public static Opportunity searchOpportunity(String projectName, String plotNo) {
        try {
            List<Opportunity> opps = [
                SELECT Id, Name, StageName, CloseDate, Amount,
                       Project_Name__c, Flat_No__c 
                FROM   Opportunity
                WHERE  Project_Name__c = :projectName
                AND    Flat_No__c       = :plotNo
                LIMIT  1
            ];
            return opps.isEmpty() ? null : opps[0];

            
        } catch (Exception e) {
            throw new AuraHandledException('Error searching Opportunity: ' + e.getMessage());
        }
    }

    /**
     * Search Opportunities by mobile number.
     * Checks PhoneNo__c, Secondary_Mobile__c, and Mobile__c fields.
     * Returns all matching Opportunities with Account name, Project Name, Plot No.
     */
    @AuraEnabled(cacheable=false)
    public static List<DetailsWrapper> searchOpportunityByMobile(String mobileNumber) {
        if (String.isBlank(mobileNumber)) {
            return new List<DetailsWrapper>();
        }
        try {
            String mobile = mobileNumber.trim();
            List<Opportunity> opportunities = [
                SELECT
                    Id,
                    Name,
                    StageName,
                    CloseDate,
                    Amount,
                    Project_Name__c,
                    Flat_No__c,
                    PhoneNo__c,
                    Secondary_Mobile__c,
                    Mobile__c,
                    Account.Name
                FROM Opportunity
                WHERE (PhoneNo__c          = :mobile
                   OR Secondary_Mobile__c = :mobile
                   OR Mobile__c           = :mobile)
                and StageName != 'Cancelled' ORDER BY CreatedDate DESC
                LIMIT 200
            ];

            List<DetailsWrapper> wrappers = new List<DetailsWrapper>();
            for (Opportunity opp : opportunities) {
                CRM__c crm = [ SELECT Id,Sub_Registrar_Office__c,Reg_Document_Number__c,Year_Of_Registration__c FROM CRM__c WHERE Opportunity__c = :opp.Id LIMIT 1];
                wrappers.add(new DetailsWrapper(new List<CRM__c>{crm}, new List<Opportunity>{opp}));
            }
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException('Error searching Opportunity by mobile: ' + e.getMessage());
        }
    }
    
    /**
     * Uploads a base64 file as a ContentVersion linked to the given record.
     * The file is saved with the title "Sales Deed" or "Encumbrance Certificate".
     */
    @AuraEnabled
public static void uploadFile(String recordId, String fileName,
String base64Data, String contentType) {
    try {
        String ext = getExtension(contentType);
        ContentVersion cv = new ContentVersion();
        cv.Title                  = fileName;
        cv.PathOnClient           = fileName + '.' + ext;
        cv.VersionData            = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;

        // Re-query to get the ContentDocumentId
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        // ✅ Fix: Update the auto-created ContentDocumentLink to AllUsers
        ContentDocumentLink oppLink = [
            SELECT Id, Visibility
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :cv.ContentDocumentId
            AND LinkedEntityId = :recordId
            LIMIT 1
        ];
        oppLink.Visibility = 'AllUsers';
        update oppLink;

        // Grant access to Gsquare Connect user
        User gsquareUser = [
            SELECT Id FROM User 
            WHERE Name = 'Gsquare Connect' 
            AND IsActive = true 
            LIMIT 1
        ];

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId    = gsquareUser.Id;
        cdl.ShareType         = 'V';
        cdl.Visibility        = 'AllUsers';
        insert cdl;

        CRM__c crm = [SELECT Id FROM CRM__c WHERE Opportunity__c = :recordId LIMIT 1];
        crm.encumbrance_certificate_uploaded__c = true;
        update crm;

    } catch (Exception e) {
        throw new AuraHandledException('Error uploading file: ' + e.getMessage());
    }
}
    
    /**
     * Returns all ContentVersions (latest) linked to the given record.
     */
    @AuraEnabled(cacheable=false)
    public static List<ContentVersion> getAttachedFiles(String recordId) {
        try {
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM   ContentDocumentLink
                WHERE  LinkedEntityId = :recordId
            ];
            if (links.isEmpty()) return new List<ContentVersion>();
            
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink l : links) docIds.add(l.ContentDocumentId);
            
            return [
                SELECT Id, Title, FileExtension, ContentSize,
                       ContentDocumentId, CreatedDate, VersionNumber
                FROM   ContentVersion
                WHERE  ContentDocumentId IN :docIds
                AND    IsLatest = true
                ORDER BY CreatedDate DESC
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching files: ' + e.getMessage());
        }
    }
    
    private static String getExtension(String contentType) {
        Map<String, String> m = new Map<String, String>{
            'application/pdf'  => 'pdf',
            'image/jpeg'       => 'jpg',
            'image/jpg'        => 'jpg',
            'image/png'        => 'png',
            'image/gif'        => 'gif',
            'application/msword' => 'doc',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'docx'
        };
        return String.isBlank(contentType) ? 'bin'
            : (m.containsKey(contentType) ? m.get(contentType) : 'bin');
    }

    // Proper inner wrapper class to return CRM__c and Opportunity records to JS
    public class DetailsWrapper {
        @AuraEnabled public List<CRM__c> crmList { get; set; }
        @AuraEnabled public List<Opportunity> oppList { get; set; }
        
        public DetailsWrapper() {
            this.crmList = new List<CRM__c>();
            this.oppList = new List<Opportunity>();
        }
        
        public DetailsWrapper(List<CRM__c> crms, List<Opportunity> opps) {
            this.crmList = crms == null ? new List<CRM__c>() : crms;
            this.oppList = opps == null ? new List<Opportunity>() : opps;
        }
    }
}