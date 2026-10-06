/**
 * @description Tests the masked paths added in v1.5.0 to MakeCallController (MakeCall screen) and
 *              OfflineCallAppAPI (G-Talk screens). The existing test classes of those controllers are unchanged.
 *              Callouts (MCube, G-Talk) are mocked; no real call is placed.
 */
@IsTest
private class PhoneMaskingCallScreensTest {
    private class OkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"status":"true"}');
            return response;
        }
    }

    @TestSetup
    static void setup() {
        List<Lead> leads = PhoneTestDataFactory.buildLeads(1, UserInfo.getUserId());
        leads[0].Phone__c = '9876543221';
        leads[0].Secondary_Phone__c = '9123456780';
        PhoneTestDataFactory.insertLeads(leads);
    }

    private static Lead testLead() {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead LIMIT 1];
    }

    private static List<Phone_Access_Audit__c> audits() {
        return [SELECT Outcome__c, Channel__c, Masked_Number__c, Message__c FROM Phone_Access_Audit__c];
    }

    // ---------------- MakeCall ----------------

    @IsTest
    static void makeCallListIsMaskedOnlyForMaskedUsers() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        PhoneDisplayService.maskedUserOverride = false;
        List<String> full = MakeCallController.readContacts(lead.Id);
        PhoneDisplayService.maskedUserOverride = true;
        List<String> masked = MakeCallController.readContacts(lead.Id);

        Assert.areEqual(2, full.size());
        Assert.isTrue(full[0].endsWith(lead.Phone__c), 'Unmasked users: same list as before');
        Assert.areEqual(2, masked.size());
        Assert.isFalse(String.join(masked, ',').contains(lead.Phone__c), 'Masked users never get the real number');
        Assert.isTrue(masked[0].endsWith(PhoneMaskUtil.mask(lead.Phone__c)));
    }

    @IsTest
    static void makeCallResolvesMaskedSelectionAndAuditsAfterCallout() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneDisplayService.maskedUserOverride = true;
        Lead lead = testLead();
        String selected = MakeCallController.readContacts(lead.Id)[0];
        Test.setMock(HttpCalloutMock.class, new OkMock());

        String result;
        Test.startTest();
        result = MakeCallController.callCustomer(lead.Id, selected);
        Test.stopTest();

        Assert.areNotEqual('The selected number could not be identified. Please refresh and try again.', result);
        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(1, rows.size());
        Assert.areEqual(PhoneDisplayService.OUTCOME_SUCCESS, rows[0].Outcome__c);
        Assert.areEqual('MCube (MakeCall)', rows[0].Channel__c);
        Assert.isTrue(rows[0].Masked_Number__c.contains('X'));
        if (result != null) {
            Assert.isTrue(rows[0].Message__c.startsWith('MakeCall: '), 'Call result recorded after the callout');
        }
    }

    @IsTest
    static void makeCallRejectsUnknownMaskedNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        String result = MakeCallController.callCustomer(lead.Id, '+91 11XXXXXX00');

        Assert.areEqual('The selected number could not be identified. Please refresh and try again.', result);
        Assert.areEqual(PhoneDisplayService.OUTCOME_NOT_FOUND, audits()[0].Outcome__c);
    }

    // ---------------- G-Talk ----------------

    @IsTest
    static void gTalkPhonesAreMaskedOnlyForMaskedUsers() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        PhoneDisplayService.maskedUserOverride = false;
        Map<String, String> full = OfflineCallAppAPI.getLeadPhone(lead.Id);
        PhoneDisplayService.maskedUserOverride = true;
        Map<String, String> masked = OfflineCallAppAPI.getLeadPhone(lead.Id);

        Assert.areEqual(lead.Phone__c, full.get('PrimaryPhone'), 'Unmasked users: unchanged');
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), masked.get('PrimaryPhone'));
        Assert.areEqual(PhoneMaskUtil.mask(lead.Secondary_Phone__c), masked.get('SecondaryPhone'));
    }

    @IsTest
    static void gTalkTriggerCallResolvesMaskedNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        Test.setMock(HttpCalloutMock.class, new OkMock());

        Test.startTest();
        OfflineCallAppAPI.triggerCall('agent@example.com', PhoneMaskUtil.mask(lead.Secondary_Phone__c), lead.Id);
        OfflineCallAppAPI.triggerCall('agent@example.com', 'XXXXXX' + lead.Phone__c.right(4), lead.Id);
        Test.stopTest();

        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(2, rows.size());
        for (Phone_Access_Audit__c row : rows) {
            Assert.areEqual(PhoneDisplayService.OUTCOME_SUCCESS, row.Outcome__c);
            Assert.areEqual('G-Talk', row.Channel__c);
        }
    }

    @IsTest
    static void gTalkTriggerCallRejectsUnknownOrInvalid() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        for (String recordId : new List<String>{ lead.Id, 'not-an-id' }) {
            try {
                OfflineCallAppAPI.triggerCall('agent@example.com', '11XXXXXX00', recordId);
                Assert.fail('Expected an error');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('could not be identified'));
            }
        }
    }

    @IsTest
    static void gTalkUnmaskedNumberIsSentAsBefore() {
        Lead lead = testLead();
        Test.setMock(HttpCalloutMock.class, new OkMock());

        Test.startTest();
        OfflineCallAppAPI.triggerCall('agent@example.com', lead.Phone__c, lead.Id);
        Test.stopTest();

        Assert.areEqual(0, audits().size(), 'Normal calls are not changed and not audited');
    }
}
