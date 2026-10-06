/**
 * @description Tests the masked paths added in v1.5.0 (Part 5b): call history (mCubeController.callRecords),
 *              History & Activity (LeadHistoryandActivityController.GetData + PhoneDisplayService helpers) and the
 *              masking of numbers in MCube logs (log__c). Field history rows are not created in Apex tests, so the
 *              history masking rule is tested through PhoneDisplayService.historyValueForDisplay.
 *              The existing test classes of these controllers are unchanged.
 */
@IsTest
private class PhoneMaskingHistoryTest {
    private static final String CUSTOMER = '9876543221';
    private static final String AGENT = '9898989898';

    private class OkMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"status":"true","custnumber":"' + CUSTOMER + '"}');
            return response;
        }
    }

    @TestSetup
    static void setup() {
        List<Lead> leads = PhoneTestDataFactory.buildLeads(1, UserInfo.getUserId());
        leads[0].Phone__c = CUSTOMER;
        PhoneTestDataFactory.insertLeads(leads);
        Call_Detail__c call = new Call_Detail__c(
            Lead__c = leads[0].Id,
            Parent_ID__c = leads[0].Id,
            Parent_URL__c = '/' + leads[0].Id + '/view',
            Status__c = 'Call Complete',
            Call_From__c = AGENT,
            Call_To__c = CUSTOMER,
            Start_Time__c = System.now().addHours(-1)
        );
        insert call;
    }

    private static Lead testLead() {
        return [SELECT Id FROM Lead LIMIT 1];
    }

    // ---------------- PhoneDisplayService helpers ----------------

    @IsTest
    static void forDisplayMasksOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = false;
        Assert.areEqual(CUSTOMER, PhoneDisplayService.forDisplay(CUSTOMER));
        PhoneDisplayService.maskedUserOverride = true;
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.forDisplay(CUSTOMER));
        Assert.isNull(PhoneDisplayService.forDisplay(null));
    }

    @IsTest
    static void historyValuesMaskedOnlyForPhoneFieldsAndMaskedUsers() {
        PhoneTestDataFactory.useTestConfig(true, true);

        PhoneDisplayService.maskedUserOverride = false;
        Assert.areEqual(CUSTOMER, PhoneDisplayService.historyValueForDisplay('Phone__c', CUSTOMER), 'Unmasked user: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.historyValueForDisplay('Phone__c', CUSTOMER));
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.historyValueForDisplay('SECONDARY_PHONE__C', CUSTOMER), 'Case-insensitive');
        Assert.areEqual('Old 98XXXXXX21, 91XXXXXX80', PhoneDisplayService.historyValueForDisplay('Secondary_Phones__c', 'Old 9876543221, 9123456780'));
        Assert.areEqual(CUSTOMER, PhoneDisplayService.historyValueForDisplay('Status', CUSTOMER), 'Non-phone fields unchanged');
        Assert.isNull(PhoneDisplayService.historyValueForDisplay('Phone__c', null));
        Assert.areEqual('null', PhoneDisplayService.historyValueForDisplay('Phone__c', 'null'));
        Assert.areEqual(CUSTOMER, PhoneDisplayService.historyValueForDisplay(null, CUSTOMER));
    }

    @IsTest
    static void historyValuesMaskedForApprovedConfiguredField() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Spouse', 'Lead', 'Spouse_Number__c', 'Spouse', 3, true, true, true)
        };
        PhoneDisplayService.maskedUserOverride = true;

        Assert.areEqual('98XXXXXX21', PhoneDisplayService.historyValueForDisplay('Spouse_Number__c', CUSTOMER));
    }

    // ---------------- call history list (mCubeLightningPage) ----------------

    @IsTest
    static void callRecordsMaskedOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Id leadId = testLead().Id;

        PhoneDisplayService.maskedUserOverride = false;
        List<Call_Detail__c> full = mCubeController.callRecords(leadId);
        PhoneDisplayService.maskedUserOverride = true;
        List<Call_Detail__c> masked = mCubeController.callRecords(leadId);

        Assert.areEqual(1, full.size());
        Assert.areEqual(CUSTOMER, full[0].Call_To__c, 'Unmasked users: unchanged');
        Assert.areEqual('98XXXXXX21', masked[0].Call_To__c);
        Assert.areEqual('98XXXXXX98', masked[0].Call_From__c);
        Assert.areEqual(CUSTOMER, [SELECT Call_To__c FROM Call_Detail__c LIMIT 1].Call_To__c, 'Masking is never saved');
    }

    // ---------------- History & Activity (LeadHistoryandActivityCmp) ----------------

    @IsTest
    static void historyCallsMaskedOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Id leadId = testLead().Id;

        PhoneDisplayService.maskedUserOverride = false;
        List<LeadHistoryandActivityController.WrapSObject> full = LeadHistoryandActivityController.GetData(leadId, 'Calls');
        PhoneDisplayService.maskedUserOverride = true;
        List<LeadHistoryandActivityController.WrapSObject> masked = LeadHistoryandActivityController.GetData(leadId, 'All');

        Assert.isFalse(full.isEmpty());
        Assert.areEqual(CUSTOMER, full[0].callto);
        Boolean foundCall = false;
        for (LeadHistoryandActivityController.WrapSObject row : masked) {
            if (row.type == 'Call') {
                foundCall = true;
                Assert.areEqual('98XXXXXX21', row.callto);
                Assert.areEqual('98XXXXXX98', row.callfrom);
            }
        }
        Assert.isTrue(foundCall, 'Call row returned');
    }

    // ---------------- MCube logs (log__c) ----------------

    @IsTest
    static void mcubeLogsNeverStoreTheFullNumber() {
        Id leadId = testLead().Id;
        Test.setMock(HttpCalloutMock.class, new OkMock());

        Test.startTest();
        mCubeController.makeCall('+91', AGENT, CUSTOMER, leadId);
        mCubeController.makeCallZetta('+91', AGENT, CUSTOMER, leadId);
        Test.stopTest();

        for (log__c logRow : [SELECT Request__c, Response__c FROM log__c]) {
            Assert.isFalse(String.valueOf(logRow.Request__c).contains(CUSTOMER), 'Request log is masked');
            Assert.isFalse(String.valueOf(logRow.Response__c).contains(CUSTOMER), 'Response log is masked');
        }
    }
}
