global class leadOp {
    
    public class wrapperClass {
        String acc;
        String lead;
        String oppo;
        String contact;
        String caseId;
        String customLeadId;
    }
    
    public static Lead searchContact(String phone) {
        Lead leadData;
        // Added Lead_ID__c to the RETURNING clause
        List<List<SObject>> l = [FIND :phone IN Phone FIELDS RETURNING Lead(Id, Lead_ID__c LIMIT 1)];
        if (l.size() > 0 && l[0].size() > 0) {
            leadData = (Lead) l[0][0];
        }
        return leadData; 
    }
    
    public static String getValues(String phone) {
        wrapperClass wc = new wrapperClass();
        String accountId;
        
        String phoneWith91 = '91' + String.valueOf(phone);
        String phoneWith91Plus = '+91' + String.valueOf(phone);
        
        Account[] accountT = [
            SELECT Id, Name, Phone 
            FROM Account 
            WHERE Phone = :phone 
               OR Phone = :phoneWith91 
               OR Phone = :phoneWith91Plus 
            ORDER BY LastModifiedDate DESC 
            LIMIT 1
        ];
        
        if (accountT.size() > 0) {
            accountId = accountT[0].Id;
            wc.acc = accountId;
        }
        
        List<List<SObject>> contactT = [FIND :phone IN Phone FIELDS RETURNING Contact(Id LIMIT 1)];
        if (contactT.size() > 0 && contactT[0].size() > 0) {
            wc.contact = contactT[0][0].Id;
            Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = :wc.contact LIMIT 1];
            if (con.AccountId != null && accountId == null) {
                accountId = con.AccountId;
                wc.acc = accountId;
            }
        }
        
        List<List<SObject>> leadT = [FIND :phone IN Phone FIELDS RETURNING Lead(Id, Lead_ID__c ORDER BY CreatedDate DESC LIMIT 1)];
        if (leadT.size() > 0 && leadT[0].size() > 0) {
            Lead foundLead = (Lead)leadT[0][0];
            wc.lead = foundLead.Id;             // This is the 00Q... ID
            wc.customLeadId = foundLead.Lead_ID__c; // This is the L-06875904 ID
        }
        
        if (accountId != null) {
            Opportunity[] oppList = [
                SELECT Id, AccountId 
                FROM Opportunity 
                WHERE AccountId = :accountId 
                ORDER BY LastModifiedDate DESC 
                LIMIT 1
            ];
            if (oppList.size() > 0) {
                wc.oppo = oppList[0].Id;
            }
            
            Case[] caseList = [
                SELECT Id, AccountId 
                FROM Case 
                WHERE AccountId = :accountId 
                ORDER BY LastModifiedDate DESC 
                LIMIT 1
            ];
            if (caseList.size() > 0) {
                wc.caseId = caseList[0].Id;
            }
        }
        
        return JSON.serialize(wc);
    }
    
    public static Account getAccountByPhone(String phone) {
        String phoneWith91 = '91' + phone;
        String phoneWith91Plus = '+91' + phone;
        
        Contact[] contacts = [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE Phone = :phone 
               OR Phone = :phoneWith91 
               OR Phone = :phoneWith91Plus 
            LIMIT 1
        ];
        
        if (contacts.size() > 0 && contacts[0].AccountId != null) {
            return [SELECT Id, Name, Phone FROM Account WHERE Id = :contacts[0].AccountId LIMIT 1];
        }
        
        Account[] accounts = [
            SELECT Id, Name, Phone 
            FROM Account 
            WHERE Phone = :phone 
               OR Phone = :phoneWith91 
               OR Phone = :phoneWith91Plus 
            LIMIT 1
        ];
        
        if (accounts.size() > 0) {
            return accounts[0];
        }
        
        return null;
    }
}