@IsTest
private class LeadYotelBulkPushControllerTest {

    /*
     * Mock HTTP success response for Yotel API
     */
    private class YotelSuccessMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');

            return res;
        }
    }

    /*
     * Mock HTTP failure response
     */
    private class YotelFailureMock implements HttpCalloutMock {

        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"error","message":"Invalid request"}');

            return res;
        }
    }

    /*
     * Create test Leads.
     * NOTE: Lead_ID__c is not writeable (formula/auto-number) - it is
     * populated automatically by Salesforce on insert, so it is not set
     * here. The controller now reads the campaign id directly from
     * Gi_BOT_Camp_ID__c (no more static project map).
     */
    private static List<Lead> createLeads() {

        List<Lead> leads = new List<Lead>();

        leads.add(new Lead(
            FirstName = 'John',
            LastName = 'Vrindavan',
            MobilePhone = '9876543210',
            Phone__c = '9876543210',
            Project_Interested__c = 'Vrindavan',
            Gi_BOT_Camp_ID__c = '077ba2ee-ebed-479c-b40e-ec8e09049a8b',
            Status = 'New'
        ));

        leads.add(new Lead(
            FirstName = 'Rahul',
            LastName = 'City',
            MobilePhone = '9876543211',
            Phone__c = '9876543211',
            Project_Interested__c = 'City 3.0',
            Gi_BOT_Camp_ID__c = '37e387e9-3091-4981-af8b-f77e1c429577',
            Status = 'New'
        ));

        leads.add(new Lead(
            FirstName = 'Arun',
            LastName = 'Kings',
            MobilePhone = '9876543212',
            Phone__c = '9876543212',
            Project_Interested__c = 'Kings Haven',
            Gi_BOT_Camp_ID__c = 'a9821f99-13e2-4aae-89f9-a4d87703bb79',
            Status = 'New'
        ));

        /*
         * Lead with no campaign id on the record - should be skipped.
         */
        leads.add(new Lead(
            FirstName = 'Test',
            LastName = 'NoCampaign',
            MobilePhone = '9876543213',
            Phone__c = '9876543213',
            Project_Interested__c = 'Unknown Project',
            Gi_BOT_Camp_ID__c = null,
            Status = 'New'
        ));

        /*
         * Lead without a phone number - should be excluded by the query filter.
         */
        leads.add(new Lead(
            FirstName = 'No',
            LastName = 'Mobile',
            MobilePhone = null,
            Phone__c = null,
            Project_Interested__c = 'Vrindavan',
            Gi_BOT_Camp_ID__c = '077ba2ee-ebed-479c-b40e-ec8e09049a8b',
            Status = 'New'
        ));

        insert leads;

        return leads;
    }

    /*
     * Test getSelectedLeads()
     */
    @IsTest
    static void testGetSelectedLeads() {

        List<Lead> leads = createLeads();

        List<String> leadIds = new List<String>();

        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        Test.startTest();

        List<LeadYotelBulkPushController.LeadWrapper> result =
            LeadYotelBulkPushController.getSelectedLeads(leadIds);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.isEmpty(), 'Should return at least one wrapper');
    }

    /*
     * Test getSelectedLeads with empty list
     */
    @IsTest
    static void testGetSelectedLeadsEmpty() {

        Test.startTest();

        List<LeadYotelBulkPushController.LeadWrapper> result =
            LeadYotelBulkPushController.getSelectedLeads(new List<String>());

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null even for empty input');
    }

    /*
     * Test pushBulkToYotel() success path.
     * Covers: multiple campaigns grouped correctly by Gi_BOT_Camp_ID__c,
     * lead with no campaign id skipped, successful HTTP callout via mock.
     */
    @IsTest
    static void testPushBulkToYotelSuccess() {

        List<Lead> leads = createLeads();

        List<Id> leadIds = new List<Id>();

        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        Test.setMock(HttpCalloutMock.class, new YotelSuccessMock());

        Test.startTest();

        String result = LeadYotelBulkPushController.pushBulkToYotel(leadIds);

        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(
            result.contains('pushed to campaign'),
            'Should report at least one successful campaign push: ' + result
        );
        System.assert(
            result.contains('Skipped'),
            'Should report the no-campaign-id lead as skipped: ' + result
        );
    }

    /*
     * Test pushBulkToYotel() failure path via HTTP mock.
     */
    @IsTest
    static void testPushBulkToYotelFailure() {

        List<Lead> leads = createLeads();

        List<Id> leadIds = new List<Id>();

        for (Lead l : leads) {

            if (
                l.Phone__c != null &&
                String.isNotBlank(l.Gi_BOT_Camp_ID__c)
            ) {
                leadIds.add(l.Id);
            }
        }

        Test.setMock(HttpCalloutMock.class, new YotelFailureMock());

        Test.startTest();

        String result = LeadYotelBulkPushController.pushBulkToYotel(leadIds);

        Test.stopTest();

       
    }

    /*
     * Test when no leads have a phone number
     */
    @IsTest
    static void testPushBulkNoMobile() {

        Lead l = new Lead(
            FirstName = 'No',
            LastName = 'Mobile',
            MobilePhone = null,
            Phone__c = null,
            Project_Interested__c = 'Vrindavan',
            Gi_BOT_Camp_ID__c = '077ba2ee-ebed-479c-b40e-ec8e09049a8b',
            Status = 'New'
        );

        insert l;

        Test.startTest();

        String result = LeadYotelBulkPushController.pushBulkToYotel(
            new List<Id>{ l.Id }
        );

        Test.stopTest();

        System.assertEquals(
            'No leads with a mobile number to push.',
            result,
            'Should return correct message when no phone number exists'
        );
    }

    /*
     * Test push where a lead has a phone number but no campaign id set
     */
    @IsTest
    static void testPushBulkNoCampaignId() {

        Lead l = new Lead(
            FirstName = 'No',
            LastName = 'Campaign',
            MobilePhone = '9876543299',
            Phone__c = '9876543299',
            Project_Interested__c = 'Vrindavan',
            Gi_BOT_Camp_ID__c = null,
            Status = 'New'
        );

        insert l;

        Test.startTest();

        String result = LeadYotelBulkPushController.pushBulkToYotel(
            new List<Id>{ l.Id }
        );

        Test.stopTest();

        System.assert(
            result.contains('Skipped'),
            'Should report the lead as skipped when no campaign id is set: ' + result
        );
    }

    /*
     * Test constructor
     */
    @IsTest
    static void testConstructor() {

        List<Lead> leads = createLeads();

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(
            Database.getQueryLocator([
                SELECT Id, Name
                FROM Lead
                WHERE Id IN :new Map<Id, Lead>(leads).keySet()
            ])
        );

        ssc.setSelected(new List<Lead>{ leads[0], leads[1], leads[2] });

        Test.startTest();

        LeadYotelBulkPushController controller = new LeadYotelBulkPushController(ssc);

        Test.stopTest();

        System.assertNotEquals(null, controller.selectedLeadIds, 'selectedLeadIds should be populated');
        System.assert(
            controller.selectedLeadIds.contains(leads[0].Id),
            'selectedLeadIds should include the first selected lead Id'
        );
    }
}