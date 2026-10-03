/**
 *  Description     :  OpportunitySummaryController
 *  Created By      :  Ejjigiri Praveen
 *  Created Date    :  03-06-26
 *  Revision Logs   :  V1.0 - Created - Ejjigiri Praveen
 *                     V1.1 - Added getNotesAndFiles, updateContactDetails
 *                     V1.2 - Fixed Email__c to update on Contact (not Opportunity)
 *                     V1.3 - Added Mail_Validated__c; removed auto-send on load
 *                     V1.4 - Added Customer_Creds_Sent__c to gate Send Credentials button
 *                     V1.5 - Fixed broken getProjectDetails (scope/typo bugs), wired Project__c
 *                            bank fields (Bank_Sub_ID__c, Default_Bank_Account_No__c,
 *                            Primary_Bank_Account_no__c, IFSC_Code__c, Bank_Account_Number__c)
 *                            into getOpportunity via OpportunityWithBankDetails wrapper
 **/
public without sharing class OpportunitySummaryController {
    
    @AuraEnabled(cacheable=true)
    public static OpportunityWithBankDetails getOpportunity(Id recordId) {
        try {
            if (recordId == null) return null;
            
            List<Opportunity> rows = [
                SELECT Id,
                       Bank_Virtual_Code__c,
                       Unit_Area__c,
                       Booking_Date__c,
                       Total_Receipts_del__c,
                       Total_Sale_Consideration_GST__c,Overall_Outstanding__c,
                       Amount_Due__c,Total_Basic_After_Discount__c, 
                       Apartment__c,
                       Apartment__r.Name,
                       Apartment__r.Block__r.Project__r.Project_Approval_Status__c,
                       PhoneNo__c,
                       Mobile__c, Secondary_Mobile__c,
                       Contact__c,Total_Cost_With_Tax__c,
                       Contact__r.Email,
                       Mail_Validated__c,
                       Customer_Creds_Sent__c,
                       Enquiry_Ref_No__c,
                       Booking_Reference_Number__c,
                       AccountId,
                       Contact__r.Customer_Creds_Sent__c,
                       Project__c
                FROM   Opportunity
                WHERE  Id = :recordId
                LIMIT  1
            ];
            
            if (rows.isEmpty()) return null;
            
            OpportunityWithBankDetails result = new OpportunityWithBankDetails();
            result.opp     = rows[0];
            result.project = getProjectDetails(rows[0].Project__c);
            result.eoi     = getEoiDetails(rows[0].Id);
            
            return result;
            
        } catch (Exception ex) {
            throw new AuraHandledException(
                'Unable to fetch Opportunity details. ' + ex.getMessage()
                );
        }
    }
    
    /**
     * Looks up the Project__c record (and its bank fields) by Project Name.
     * NOTE: Opportunity.Project__c stores the Project Name (text), not the Id,
     * so we match on Project__c.Name. Returns null if no match is found.
     */
    private static Project__c getProjectDetails(String projectName) {
        if (String.isBlank(projectName)) return null;
        
        List<Project__c> projects = [
            SELECT Id,
                   Bank_Sub_ID__c,
                   Default_Bank_Account_No__c,
                   Primary_Bank_Account_no__c,
                   IFSC_Code__c,
                   Bank_Account_Number__c
            FROM   Project__c
            WHERE  Name = :projectName
            LIMIT  1
        ];
        
        return projects.isEmpty() ? null : projects[0];
    }
    
    private static Token__c getEoiDetails(String oppId) {
        if (String.isBlank(oppId)) return null;
        
        List<Token__c> eoi = [
            SELECT Id,
                   Computed_Amount__c,Plot_Cost_Without_Discount__c
            FROM   Token__c
            WHERE  Opportunity__c = :oppId
            LIMIT  1
        ];
        
        return eoi.isEmpty() ? null : eoi[0];
    }
    
    @AuraEnabled(cacheable=true)
    public static NotesAndFilesWrapper getNotesAndFiles(
        Id           recordId,
    List<String> documentTitles
    ) {
        try {
            if (recordId == null) return new NotesAndFilesWrapper();
            
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId
                FROM   ContentDocumentLink
                WHERE  LinkedEntityId = :recordId
            ];
            if (links.isEmpty()) return new NotesAndFilesWrapper();
            
            Set<Id> docIds = new Set<Id>();
            for (ContentDocumentLink cdl : links) {
                docIds.add(cdl.ContentDocumentId);
            }
            
            List<ContentNote> notes = [
                SELECT Id, Title, TextPreview, LastModifiedDate
                FROM   ContentNote
                WHERE  Id IN :docIds
                ORDER  BY LastModifiedDate DESC
            ];
            
            Set<String> titleSet = new Set<String>();
            if (documentTitles != null) {
                for (String t : documentTitles) {
                    if (String.isNotBlank(t)) titleSet.add(t.trim());
                }
            }
            
            List<ContentVersion> files = new List<ContentVersion>();
            if (!titleSet.isEmpty()) {
                files = [
                    SELECT Id, Title, FileExtension, ContentSize,
                           ContentDocumentId, LastModifiedDate
                    FROM   ContentVersion
                    WHERE  ContentDocumentId IN :docIds
                    AND    Title             IN :titleSet
                    AND    IsLatest          = true
                    WITH   SECURITY_ENFORCED
                    ORDER  BY Title ASC
                ];
            }
            
            NotesAndFilesWrapper result = new NotesAndFilesWrapper();
            result.notes = notes;
            result.files = files;
            return result;
            
        } catch (Exception ex) {
            throw new AuraHandledException(
                'Unable to fetch notes and files. ' + ex.getMessage()
                );
        }
    }
    
    /**
     * Updates PhoneNo__c and Mail_Validated__c on Opportunity.
     * Updates Email/Mobile on the linked Contact when contactId is provided.
     * Updates Secondary_Mobile_No__c on the linked Account when accountId is provided.
     */
    @AuraEnabled
    public static void updateContactDetails(
        Id      recordId,
    Id      contactId,
    Id      accountId,
    String  email,
    String  phone,
    Boolean mailValidated,
    String  mobile,
    String  secmobile
    ) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record Id is required.');
            }
            
            Opportunity opp = new Opportunity(
                Id                = recordId,
            PhoneNo__c        = phone,
            Mail_Validated__c = (mailValidated != null ? mailValidated : false)
                );
            update opp;
            
            String leadId = [
    SELECT Enquiry_Ref_No__c
    FROM Opportunity
    WHERE Id = :recordId
].Enquiry_Ref_No__c;
            
            if (String.isNotBlank(leadId)) {
                List<Lead> leads = [
        SELECT Id
        FROM Lead
        WHERE Lead_ID__c = :leadId
        LIMIT 1
    ];
                
                if (!leads.isEmpty()) {
                    leads[0].Email = email;
                    update leads[0];
                }
            }
            
            if (contactId != null && String.isNotBlank(email)) {
                Contact con = new Contact(
                    Id          = contactId,
                Email       = email,
                MobilePhone = mobile
                    );
                update con;
            }
            
            if (accountId != null) {
                Account acc = new Account(
                    Id                      = accountId,
                Secondary_Mobile_No__c  = secmobile,
                Email__c = email
                    );
                update acc;
            }
            
        } catch (AuraHandledException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AuraHandledException(
                'Unable to update contact details. ' + ex.getMessage()
                );
        }
    }
    
    /**
     * Returns other Opportunities that share the same Contact__c as the
     * current Opportunity (excludes the current record itself).
     */
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getRelatedOpportunities(Id recordId) {
        try {
            if (recordId == null) return new List<Opportunity>();
            
            Opportunity current = [
                SELECT Id, Contact__c
                FROM   Opportunity
                WHERE  Id = :recordId
                LIMIT  1
            ];
            
            if (current.Contact__c == null) return new List<Opportunity>();
            
            return [
                SELECT Id,
                       Name,
                       Apartment__r.Name,
                       Booking_Reference_Number__c,
                       Booking_Date__c,
                       StageName,
                       Total_Sale_Consideration_GST__c,
                       Amount_Due__c
                FROM   Opportunity
                WHERE  Contact__c = :current.Contact__c
                AND    Id        != :recordId
                ORDER  BY Booking_Date__c DESC NULLS LAST
            ];
        } catch (Exception ex) {
            throw new AuraHandledException(
                'Unable to fetch related opportunities. ' + ex.getMessage()
                );
        }
    }
    
    public class NotesAndFilesWrapper {
        @AuraEnabled public List<ContentNote>    notes { get; set; }
        @AuraEnabled public List<ContentVersion> files { get; set; }
        
        public NotesAndFilesWrapper() {
            this.notes = new List<ContentNote>();
            this.files = new List<ContentVersion>();
        }
    }
    
    public class OpportunityWithBankDetails {
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public Project__c  project;
        @AuraEnabled public Token__c  eoi;
    }
}