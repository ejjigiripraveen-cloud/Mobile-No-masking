/**
 * @description Tests McubeSoftphoneAddOnController.clickToCallMasked (mobile number masking, v1.3.0).
 *              The MCube API is mocked; no real call is placed. Reads the org's Mcube__mdt settings
 *              (custom metadata is visible to tests without SeeAllData).
 */
@IsTest
private class McubeMaskedClickToCallTest {
    private static final String AGENT_MOBILE = '9000000001';

    /** Records every MCube request and answers with a configurable body. */
    private class McubeMock implements HttpCalloutMock {
        Integer calls = 0;
        String lastEndpoint = '';
        String lastBody = '';
        String responseBody;

        McubeMock(String responseBody) {
            this.responseBody = responseBody;
        }

        public HttpResponse respond(HttpRequest request) {
            calls++;
            lastEndpoint = request.getEndpoint();
            lastBody = request.getBody();
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(responseBody);
            return response;
        }
    }

    @TestSetup
    static void setup() {
        User rep;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep = PhoneTestDataFactory.createUser('Standard User');
            rep.MobilePhone = AGENT_MOBILE;
            update rep;
            PhoneTestDataFactory.createUser('Minimum Access - Salesforce');
        }
        PhoneTestDataFactory.insertLeads(PhoneTestDataFactory.buildLeads(1, rep.Id));
    }

    private static User userWithProfile(String profileName) {
        return [SELECT Id FROM User WHERE Email LIKE 'mask.tester%' AND Profile.Name = :profileName LIMIT 1];
    }

    private static Lead testLead() {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead LIMIT 1];
    }

    private static Boolean mcubeConfigured() {
        Set<String> names = new Set<String>();
        for (Mcube__mdt setting : [SELECT DeveloperName, Value__c FROM Mcube__mdt WHERE DeveloperName IN ('APIKey', 'Version')]) {
            if (String.isNotBlank(setting.Value__c)) {
                names.add(setting.DeveloperName);
            }
        }
        return names.contains('APIKey') && names.contains('Version');
    }

    private static List<Phone_Access_Audit__c> audits() {
        return [SELECT Outcome__c, Channel__c, Masked_Number__c, Message__c, Field_Key__c FROM Phone_Access_Audit__c];
    }

    @IsTest
    static void dialsRealNumberOnServerWithFieldKey() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        McubeMock mock = new McubeMock('{"status":"true","msg":"ok"}');
        Test.setMock(HttpCalloutMock.class, mock);

        McubeSoftphoneAddOnController.ClickToCallResult result;
        Test.startTest();
        System.runAs(userWithProfile('Standard User')) {
            result = McubeSoftphoneAddOnController.clickToCallMasked(
                lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, PhoneMaskUtil.mask(lead.Phone__c));
        }
        Test.stopTest();

        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(1, rows.size(), 'One audit row, written after the callout');
        Assert.areEqual('MCube', rows[0].Channel__c);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), rows[0].Masked_Number__c);
        if (mcubeConfigured()) {
            Assert.isTrue(result.success, 'Message: ' + result.message);
            Assert.areEqual(1, mock.calls);
            Assert.isTrue((mock.lastEndpoint + mock.lastBody).contains(lead.Phone__c), 'MCube receives the real number');
            Assert.isTrue((mock.lastEndpoint + mock.lastBody).contains(AGENT_MOBILE), 'MCube rings the agent mobile');
            Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, rows[0].Outcome__c);
            Assert.areEqual('MCube: Call initiated.', rows[0].Message__c);
        }
        Assert.isFalse(JSON.serialize(result).contains(lead.Phone__c), 'The page never receives the real number');
    }

    @IsTest
    static void identifiesFieldFromMaskedValueWhenNoFieldKey() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        McubeMock mock = new McubeMock('{"status":"true"}');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        System.runAs(userWithProfile('Standard User')) {
            McubeSoftphoneAddOnController.clickToCallMasked(lead.Id, '', PhoneMaskUtil.mask(lead.Secondary_Phone__c));
        }
        Test.stopTest();

        Phone_Access_Audit__c row = audits()[0];
        Assert.areEqual(PhoneTestDataFactory.FIELD_KEY_SECONDARY, row.Field_Key__c, 'Secondary identified from 97XXXXXX..');
        if (mcubeConfigured()) {
            Assert.isTrue((mock.lastEndpoint + mock.lastBody).contains(lead.Secondary_Phone__c));
        }
    }

    @IsTest
    static void reportsMcubeRejectionInResultAndAudit() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        Test.setMock(HttpCalloutMock.class, new McubeMock('{"status":"false","msg":"Agent busy"}'));

        McubeSoftphoneAddOnController.ClickToCallResult result;
        Test.startTest();
        System.runAs(userWithProfile('Standard User')) {
            result = McubeSoftphoneAddOnController.clickToCallMasked(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, null);
        }
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.isTrue(audits()[0].Message__c.startsWith('MCube: '), 'Call result recorded on the audit row');
    }

    @IsTest
    static void deniesUnapprovedFieldWithoutCallout() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        McubeMock mock = new McubeMock('{"status":"true"}');
        Test.setMock(HttpCalloutMock.class, mock);

        McubeSoftphoneAddOnController.ClickToCallResult result;
        System.runAs(userWithProfile('Standard User')) {
            result = McubeSoftphoneAddOnController.clickToCallMasked(lead.Id, 'Lead.Email', null);
        }

        Assert.isFalse(result.success);
        Assert.areEqual(0, mock.calls, 'No call placed');
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, audits()[0].Outcome__c);
    }

    @IsTest
    static void deniesUserWithoutLeadAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        McubeMock mock = new McubeMock('{"status":"true"}');
        Test.setMock(HttpCalloutMock.class, mock);

        McubeSoftphoneAddOnController.ClickToCallResult result;
        System.runAs(userWithProfile('Minimum Access - Salesforce')) {
            result = McubeSoftphoneAddOnController.clickToCallMasked(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, null);
        }

        Assert.isFalse(result.success);
        Assert.areEqual(0, mock.calls);
    }

    @IsTest
    static void rejectsInvalidRecordIdWithoutAudit() {
        PhoneTestDataFactory.useTestConfig(true, true);
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallMasked('not-an-id', PhoneTestDataFactory.FIELD_KEY_PRIMARY, null);

        Assert.isFalse(result.success);
        Assert.areEqual('Invalid record.', result.message);
        Assert.areEqual(0, audits().size());
    }

    @IsTest
    static void deniesWhenMaskedValueMatchesNoField() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        McubeMock mock = new McubeMock('{"status":"true"}');
        Test.setMock(HttpCalloutMock.class, mock);

        McubeSoftphoneAddOnController.ClickToCallResult result;
        System.runAs(userWithProfile('Standard User')) {
            result = McubeSoftphoneAddOnController.clickToCallMasked(lead.Id, '', '11XXXXXX00');
        }

        Assert.isFalse(result.success);
        Assert.areEqual(0, mock.calls);
    }
}
