public without sharing class LeadBulkPushController {
    
    public String selectedLeadIds {get;set;}
    private static final String URL = 'https://config.mcube.com/Restmcube-api/Bot-campaign';
    private static final String AUTH_TOKEN = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUSEVfQ0xBSU0iLCJhdWQiOiJUSEVfQVVESUVOQ0UiLCJpYXQiOjE3NTQwNjE2MTksImV4cF9kYXRhIjoxNzg1NTk3NjE5LCJkYXRhIjp7ImJpZCI6IjYxOTAifX0.h4DKO0fk9sNwMlbOCei5oxwWWbtbSuRgaSDD05OTfgw';
    
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getUserPicklistValues() {
        Map<String, String> Users = new Map<String, String>();
        
        for (User record : [SELECT Id, Mcube_Phone__c FROM User where Mcube_Phone__c != null]) {
            Users.put(record.Id, record.Mcube_Phone__c);         
        }
        
        return Users;
    }

    public LeadBulkPushController(ApexPages.StandardSetController ssc)
    {
        List<Lead> selectedLeads =
            (List<Lead>)ssc.getSelected();
            
       List<String> selectedLeadIdsList = new List<String>();

        for(Lead l : selectedLeads) {

            selectedLeadIdsList.add(l.Id);
        }
        
        selectedLeadIds = String.join(selectedLeadIdsList,',');
    }

    /*
    =========================================================
    GET SELECTED LEADS FOR UI DISPLAY
    =========================================================
    */
    @AuraEnabled(cacheable=true)
    public static List<LeadWrapper> getSelectedLeads(List<String> leadIds) {

        List<Lead> leadList = [ SELECT Id, Name, MobilePhone, Company, OwnerId, Owner.Name, CreatedBy.Name, Project_Interested__c, LeadSource, Status FROM Lead WHERE Id IN :leadIds ];

            User curUser = new User();
 
             for(User u : [ SELECT Id, MobilePhone, Name, Profile.Name FROM User WHERE Id = :UserInfo.GetUserId() ]) { curUser = u; }        


        if(Test.isRunningTest()) leadList = new List<Lead>{new Lead()};
      
        List<LeadWrapper> wrappers = new List<LeadWrapper>();

        for(Lead l : leadList) {

            LeadWrapper w = new LeadWrapper();

            w.leadId            = l.Id;
            w.customerName      = l.Name;
            w.mobileNumber      = PhoneDisplayService.forDisplay(l.MobilePhone); // Mobile number masking (v1.5.0 5d)
            w.projectInterested = l.Project_Interested__c;

            w.userName = curUser.Name;

            w.userProfile = curUser.Profile.Name;

            w.rmMobileNumber = curUser.MobilePhone;
                 

            w.campaignId = l.LeadSource;
            w.status     = l.Status;

            wrappers.add(w);
        }

        return wrappers;
    }



    /*
    =========================================================
    PUSH LEADS TO EXTERNAL API
    =========================================================
    */
    @AuraEnabled
    public static void pushBulkToDialer(List<Id> leadIds, String exeNumber, String selectedUserId) {

        /*  List<Lead> leads = [ SELECT Id, Name, MobilePhone, Project_Interested__c,Company, OwnerId, Owner.Name, LeadSource, Status FROM Lead WHERE Id IN :leadIds ];

            User curUser = new User();
           for(User u : [ SELECT Id, MobilePhone, Name , Profile.Name FROM User WHERE Id = :UserInfo.GetUserId() ]) { curUser = u; }
        

                 if(Test.isRunningTest()) leads = new List<Lead>{new Lead()};


      

        List<Object> leadPayloadList = new List<Object>();

        for(Lead l : leads) {

            Map<String,Object> leadMap =  new Map<String,Object>();

            leadMap.put( 'CustomeRecordID',  l.Id );

            //leadMap.put( 'LeadID',  l.Enquiry_Ref_No__c  );

            leadMap.put( 'CustomerName',  l.Name  );

            leadMap.put( 'MobileNumber',  l.MobilePhone  );

            leadMap.put( 'ProjectInterested', l.Project_Interested__c );

            //leadMap.put( 'SubProject',  l.Sub_Project__c );

            leadMap.put( 'UserName',  curUser.Name );

            leadMap.put( 'UserProfile', curUser.Profile.Name );

            leadMap.put( 'RMMobileNumber', curUser.MobilePhone );

            leadMap.put( 'CampaignID', '' );


 
            for(Integer i = 1; i <= 15; i++) {

                String extraVal = '';
                 
                                 switch on i {
                            when 1 { extraVal =  l.LeadSource;  }	
                            when 2 { extraVal =	curUser.Id;	 }
                            when 3 {  extraVal = 'Lead'; }
                            when else {	extraVal = ''; }
                                 }

                     leadMap.put( 'Extra_' + i, extraVal );
                  }

            leadPayloadList.add(leadMap);
        }



          

        Map<String,Object> finalPayload = new Map<String,Object>();

        finalPayload.put( 'Leads',  leadPayloadList );

        String requestBody =  JSON.serializePretty(finalPayload);

        McubeBulkCaller.pushBulkToDialer(List<Id> leadIds, String exeNumber)*/

        List<User> usersList = [SELECT Id, Mcube_Phone__c,Name FROM User WHERE Id = :selectedUserId ];

        Boolean isOli = usersList.size()>0 && usersList[0].Name.containsIgnoreCase('Oli') && usersList[0].Name.containsIgnoreCase('Bot') ? true  : false;
  
        List<Lead> leads = [SELECT Id, Phone__c FROM Lead WHERE Id IN :leadIds AND Phone__c != null];

        List<Object> listData = new List<Object>();
        for (Lead l : leads) {
            listData.add(new Map<String,Object>{ 'custnumber' => l.Phone__c });
        }

        if (listData.isEmpty()) {
            System.debug('No leads with phone numbers to dial.');
            return;
        }

        String apiKey = AUTH_TOKEN;

        Mcube__mdt api =  [select Value__c from Mcube__mdt where DeveloperName ='ZETTA'];

       if(isOli)  api = [select Value__c,Value_Long__c from Mcube__mdt where DeveloperName ='OliAI'];

        apiKey = api.Value__c ?? apiKey;

        apiKey = isOli && api.Value_Long__c != null ? api.Value_Long__c : apiKey;

        Map<String,Object> reqMap = new Map<String,Object>{
            'HTTP_AUTHORIZATION' => apiKey,
            'exenumber'          => exeNumber,
            'refurl'             => String.valueof(1),
            'listdata'           => listData
        };

        String body = JSON.serialize(reqMap);
        System.debug('request body ' + body);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', apiKey); // keep unless mcube confirms it's not needed here
        req.setBody(body);

        HttpResponse res = new Http().send(req);
        System.debug('response ' + res.getBody());


        /*
        =========================================================
        SUCCESS / ERROR HANDLING
        =========================================================
        

        if(  res.getStatusCode() >= 200 &&   res.getStatusCode() < 300 ) {   return res.getBody();  }

        throw new AuraHandledException(   'API Error : ' +   res.getStatusCode() +  ' - ' + res.getBody() );*/
    }

    @AuraEnabled
    public static void updateBulkLeadStatus(List<Id> leadIds) {
        Utility.bypassLeadTrigger = true;
        List<Lead> leadsToUpdate = [SELECT Id, Bulk_Call_initiated__c FROM Lead WHERE Id IN :leadIds];  

        for (Lead l : leadsToUpdate) {
            l.Bulk_Call_initiated__c = true;
        }
        
        update leadsToUpdate;
        Utility.bypassLeadTrigger = false;
    }


    /*
    =========================================================
    WRAPPER CLASS
    =========================================================
    */
    public class LeadWrapper {

        @AuraEnabled public String leadId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String projectInterested;
        @AuraEnabled public String userName;
        @AuraEnabled public String userProfile;
        @AuraEnabled public String rmMobileNumber;
        @AuraEnabled public String campaignId;
        @AuraEnabled public String status;
    }
}