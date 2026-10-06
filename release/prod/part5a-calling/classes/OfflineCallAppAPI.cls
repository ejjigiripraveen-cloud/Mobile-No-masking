/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 06-18-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class OfflineCallAppAPI {
    
    public class CallRequest {
        public String username;
        public String phone_number;
        public String lead_id;
        // public String callType;
    }
    
    public class CalloutJob implements Queueable, Database.AllowsCallouts {
        private String username;
        private String phoneNumber;
        private String leadId;
        // private String callType;
        
        public CalloutJob(String username, String phoneNumber, String leadId) {
            this.username = username;
            this.phoneNumber = phoneNumber;
            this.leadId = leadId;
            // this.callType = callType;
        }
        
        public void execute(QueueableContext context) {
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            req.setEndpoint('https://vj9uk6mfbg.execute-api.ap-south-1.amazonaws.com/prod/trigger-call');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            CallRequest callReq = new CallRequest();
            callReq.username = username;
            callReq.phone_number = phoneNumber;
            callReq.lead_id = leadId;
            
            String body = JSON.serialize(callReq);
            req.setBody(body);
            System.debug('Request Body: ' + body);
            try {
                HTTPResponse res = http.send(req);
                System.debug('Response Status: ' + res.getStatus());
                System.debug('Response Body: ' + res.getBody());
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }
        }
    }
    
    @AuraEnabled
    public static void triggerCall(String username, String phoneNumber, String leadId) {
        // Mobile number masking (v1.5.0): a masked number from the screen is resolved to the real one on the server.
        if (PhoneDisplayService.isMasked(phoneNumber)) {
            phoneNumber = resolveMaskedNumber(leadId, phoneNumber);
            if (phoneNumber == null) {
                AuraHandledException error = new AuraHandledException('The selected number could not be identified. Please refresh and try again.');
                error.setMessage('The selected number could not be identified. Please refresh and try again.');
                throw error;
            }
        }
        System.enqueueJob(new CalloutJob(username, phoneNumber, leadId));
    }

    // Mobile number masking (v1.5.0): real numbers of the Lead (or of the Opportunity's Lead), read on the server.
    private static String resolveMaskedNumber(String recordId, String maskedNumber) {
        Id parsedId;
        try {
            parsedId = Id.valueOf(recordId);
        } catch (Exception e) {
            return null;
        }
        Lead ld;
        if (parsedId.getSObjectType() == Opportunity.SObjectType) {
            List<Opportunity> opps = [SELECT Enquiry_Ref_No__c FROM Opportunity WHERE Id = :parsedId LIMIT 1];
            List<Lead> leads = opps.isEmpty() ? new List<Lead>()
                : [SELECT Phone__c, Secondary_Phone__c FROM Lead WHERE Lead_ID__c = :opps[0].Enquiry_Ref_No__c LIMIT 1];
            ld = leads.isEmpty() ? null : leads[0];
        } else {
            List<Lead> leads = [SELECT Phone__c, Secondary_Phone__c FROM Lead WHERE Id = :parsedId LIMIT 1];
            ld = leads.isEmpty() ? null : leads[0];
        }
        List<String> candidates = ld == null ? new List<String>() : new List<String>{ ld.Phone__c, ld.Secondary_Phone__c };
        return PhoneDisplayService.resolve(parsedId, maskedNumber, candidates, 'G-Talk');
    }
    
    
    @AuraEnabled
    public static Map<String, String> getLeadPhone(String leadId) {
        System.debug('leadId: ' + leadId);
        Map<String, String> phoneMap = new Map<String, String>();
        
        try {
            Lead ld = [SELECT Secondary_Phone__c, Phone__c, Lead_ID__c, NRI__c FROM Lead WHERE Id = :leadId LIMIT 1];
            
            phoneMap.put('PrimaryPhone', ld.Phone__c);phoneMap.put('SecondaryPhone', ld.Secondary_Phone__c);
            phoneMap.put('LeadId', ld.Lead_ID__c);phoneMap.put('Nri', String.valueOf(ld.NRI__c));
            
            List<Call_Detail__c> callList = [
            SELECT Id, Name 
            FROM Call_Detail__c 
            WHERE Lead__c = :leadId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
            
            if (!callList.isEmpty()) {
                Call_Detail__c cd = callList[0];
                phoneMap.put('callName', cd.Name);phoneMap.put('callId', cd.Id);
            } else {
                phoneMap.put('callName', null);phoneMap.put('callId', null);
            }
        } catch (Exception e) {
            System.debug('Error in getLeadPhone: ' + e.getMessage());
            phoneMap.put('PrimaryPhone', null);phoneMap.put('SecondaryPhone', null);
            phoneMap.put('LeadId', null);phoneMap.put('callName', null);
            phoneMap.put('callId', null);phoneMap.put('Nri', null);
        }
        
        PhoneDisplayService.maskValues(phoneMap, new List<String>{ 'PrimaryPhone', 'SecondaryPhone' }); // Mobile number masking (v1.5.0)
        return phoneMap;
    }
    
    @AuraEnabled
    public static Map<String, String> getOppPhone(String oppId) {
        System.debug('oppId: ' + oppId);
        Map<String, String> phoneMap = new Map<String, String>();
        
        Opportunity opp = [select id,Enquiry_Ref_No__c,Booking_Reference_Number__c from Opportunity where Id = :oppId limit 1];
        
        try {
            Lead ld = [SELECT Secondary_Phone__c, Phone__c, Lead_ID__c, NRI__c FROM Lead WHERE Lead_ID__c = :opp.Enquiry_Ref_No__c LIMIT 1];
            
            phoneMap.put('PrimaryPhone', ld.Phone__c);phoneMap.put('SecondaryPhone', ld.Secondary_Phone__c);
            phoneMap.put('LeadId', opp.Booking_Reference_Number__c);phoneMap.put('Nri', String.valueOf(ld.NRI__c));
            
            List<Opportunity_Call_Detail__c> callList = [
           select id,Name,Opportunity__c from Opportunity_Call_Detail__c 
            WHERE Opportunity__c = :oppId
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];
            
            if (!callList.isEmpty()) {
                Opportunity_Call_Detail__c cd = callList[0];
                phoneMap.put('callName', cd.Name);phoneMap.put('callId', cd.Id);
            } else {
                phoneMap.put('callName', null);
                phoneMap.put('callId', null);
            }
        } catch (Exception e) {
            System.debug('Error in getLeadPhone: ' + e.getMessage());
            phoneMap.put('PrimaryPhone', null);phoneMap.put('SecondaryPhone', null); phoneMap.put('LeadId', null);
            phoneMap.put('callName', null);phoneMap.put('callId', null);phoneMap.put('Nri', null);
        }
        
        PhoneDisplayService.maskValues(phoneMap, new List<String>{ 'PrimaryPhone', 'SecondaryPhone' }); // Mobile number masking (v1.5.0)
        return phoneMap;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Boolean isLeadRecentlyContacted(String leadId) {
        if (String.isBlank(leadId)) return false;
        Lead ld = [SELECT Last_Contacted_On__c  FROM Lead WHERE Id = :leadId LIMIT 1];
        if (ld.Last_Contacted_On__c == null) return false;
        
        Datetime threshold = Datetime.now().addMinutes(-30);
        return ld.Last_Contacted_On__c >= threshold;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getCurrentUsername() {
        return UserInfo.getUserName();
    }
    
    @AuraEnabled
    public static void createCallInitiatedTask(String leadId, String description , String subject) {
        if (String.isBlank(leadId)) return;
        system.debug('subject: ' + subject);
        Task t = new Task(
            Subject = subject,
        WhoId = leadId,
        status = 'Completed',
        Description = description,
        ActivityDate = Date.today()
            );
        insert t;
        system.debug('Task created with ID: ' + t.Id);
    }
    
    
    @AuraEnabled
    public static void updateCallDetailComment(Id callDetailId, String comment, String subDisposition, String disposition ) {
        if (String.isBlank(comment) || callDetailId == null) {
            throw new AuraHandledException('Missing data');
        }
        
        Call_Detail__c cd = [SELECT Id, Comments__c,Sub_Dispoisition__c,Disposition__c FROM Call_Detail__c WHERE Id = :callDetailId LIMIT 1];
        cd.Comments__c = comment;
        cd.Sub_Dispoisition__c = subDisposition;
        cd.Disposition__c = disposition;
        update cd;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> picklistValues = new List<String>();
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult describeResult = targetType.getDescribe();
        Schema.DescribeFieldResult fieldResult = describeResult.fields.getMap().get(fieldName).getDescribe();
        
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            picklistValues.add(entry.getLabel());
        }
        return picklistValues;
        
    }
    
    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }
    
   @AuraEnabled(cacheable=true)
public static Boolean isUserRecordOwner(Id recordId) {
    Lead leadRec = [
        SELECT Id, OwnerId, SV_User__c, Pre_Sales_User__c ,VDNB_Owner__c
        FROM Lead 
        WHERE Id = :recordId 
        LIMIT 1
    ];
    
    Id currentUserId = UserInfo.getUserId();
    
    // Compare safely as Strings
    return (String.valueOf(leadRec.OwnerId) == String.valueOf(currentUserId) || String.valueOf(leadRec.SV_User__c) == String.valueOf(currentUserId) 
         || String.valueOf(leadRec.Pre_Sales_User__c) == String.valueOf(currentUserId))|| String.valueOf(leadRec.VDNB_Owner__c) == String.valueOf(currentUserId);
}


    
}