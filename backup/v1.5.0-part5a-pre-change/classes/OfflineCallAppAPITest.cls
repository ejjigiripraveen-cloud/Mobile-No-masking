@IsTest
public without sharing class OfflineCallAppAPITest {
    
    @TestSetup
    static void setupTestData() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuserunique' + DateTime.now().getTime() + '@yahoo.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert testUser;
        
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Phone = '1234567890',
            MobilePhone = '0987654321',
            Phone__c = '1122334455'
        );
        insert testLead;
        
        Call_Detail__c cd2 = new Call_Detail__c(
            Call_Type__c = 'Outbound Call',
            Status__c = 'Originate',
            Call_From__c = testLead.Phone__c,
            Call_To__c = '343423',
            Lead__c = testLead.Id
        );
        insert cd2;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(30),
            Project_Collection_Status__c = 'RERA This Month'
        );
        insert opp;
        
        CRM__c cm = new CRM__c(
            Opportunity__c = opp.Id
        );
        insert cm;
         
        Opportunity_Call_Detail__c oppCd = new Opportunity_Call_Detail__c(
            Opportunity__c = opp.Id,
            OwnerId = testUser.Id,
            Call_Type__c = 'Inbound',
            CRM__c = cm.Id
        );
        insert oppCd;
    }
    
    @IsTest
    static void testTriggerCall() {
        Lead testLead = [SELECT Id, Phone,MobilePhone,Phone__c FROM Lead LIMIT 1];
        Call_Detail__c cd = [SELECT Id from Call_Detail__c LIMIT 1];
        Opportunity opp = [Select id from Opportunity where  Name = 'Test Opp' Limit 1];
        String username = UserInfo.getUserName();
        String phoneNumber = testLead.Phone;
        String mobileNumber = testLead.MobilePhone;
        String Phone = testLead.Phone__c;
        
        Test.startTest();
        OfflineCallAppAPI.triggerCall(username, phoneNumber, testLead.Id);
        OfflineCallAppAPI.triggerCall(username, mobileNumber, testLead.Id);
        OfflineCallAppAPI.triggerCall(username, Phone, testLead.Id);
        OfflineCallAppAPI.updateCallDetailComment(cd.Id,'CMT','Language Barrier','Contacted');
        OfflineCallAppAPI.getPicklistValues('Call_Detail__c', 'Disposition__c');
        OfflineCallAppAPI.createCallInitiatedTask(testLead.Id,'Test','Test');
        OfflineCallAppAPI.getOppPhone(opp.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetLeadPhone() {
        Lead testLead = [SELECT Id, Phone, MobilePhone, Phone__c FROM Lead LIMIT 1];
        
        Test.startTest();
        Map<String, String> phoneMap = OfflineCallAppAPI.getLeadPhone(testLead.Id);
        Boolean boo = OfflineCallAppAPI.isLeadRecentlyContacted(testLead.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testGetCurrentUsername() {
        Test.startTest();
        String username = OfflineCallAppAPI.getCurrentUsername();
        Test.stopTest();
        
        System.assertEquals(UserInfo.getUserName(), username, 'Current username should match');
    }
    
    @IsTest
    static void testCalloutJobExecute() {
        Lead testLead = [SELECT Id, Phone FROM Lead LIMIT 1];
        String username = UserInfo.getUserName();
        String phoneNumber = testLead.Phone;
        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setHeader('Content-Type', 'application/json');
        mockResponse.setBody('{"message":"Call triggered successfully"}');
        mockResponse.setStatusCode(200);
        
        Test.setMock(HttpCalloutMock.class, new OfflineCallAppAPIMock(mockResponse));
        
        Test.startTest();
        OfflineCallAppAPI.CalloutJob job = new OfflineCallAppAPI.CalloutJob(username, phoneNumber, testLead.Id);
        job.execute(null);
        Test.stopTest();
    }

    // 🔹 NEW METHOD 1: Cover getCurrentUserProfileName()
    @IsTest
    static void testGetCurrentUserProfileName() {
        Test.startTest();
        String profileName = OfflineCallAppAPI.getCurrentUserProfileName();
        Test.stopTest();

        User u = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertEquals(u.Profile.Name, profileName, 'Profile name should match current user');
    }





}