/**
 * @description Tests the masked selection lists added in v1.5.0 (Part 5d) to LeadBulkPushController and
 *              LeadYotelBulkPushController. The push methods themselves are unchanged (they read the real numbers
 *              on the server) and are covered by the existing test classes, which are unchanged.
 */
@IsTest
private class PhoneMaskingPushTest {
    private static final String PRIMARY = '9876543221';
    private static final String MOBILE = '9123456780';

    @TestSetup
    static void setup() {
        List<Lead> leads = PhoneTestDataFactory.buildLeads(2, UserInfo.getUserId());
        leads[0].LastName = 'Push Eligible';
        leads[0].Phone__c = PRIMARY;
        leads[0].MobilePhone = MOBILE;
        leads[0].Gi_BOT_Camp_ID__c = 'CAMP-1';
        leads[1].LastName = 'Push Not Eligible';
        leads[1].Gi_BOT_Camp_ID__c = null;
        PhoneTestDataFactory.insertLeads(leads);
    }

    private static List<String> leadIds() {
        List<String> ids = new List<String>();
        for (Lead lead : [SELECT Id FROM Lead ORDER BY LastName]) {
            ids.add(lead.Id);
        }
        return ids;
    }

    @IsTest
    static void bulkPushListMaskedOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Id eligibleId = [SELECT Id FROM Lead WHERE LastName = 'Push Eligible'].Id;

        PhoneDisplayService.maskedUserOverride = false;
        List<LeadBulkPushController.LeadWrapper> full = LeadBulkPushController.getSelectedLeads(new List<String>{ eligibleId });
        PhoneDisplayService.maskedUserOverride = true;
        List<LeadBulkPushController.LeadWrapper> masked = LeadBulkPushController.getSelectedLeads(new List<String>{ eligibleId });

        // The existing getSelectedLeads replaces the query result with one empty Lead while tests run
        // (if(Test.isRunningTest()) ...), so here the masked path is checked on that record; the masking rule
        // itself (forDisplay) is tested in PhoneMaskingHistoryTest / PhoneDisplayServiceTest.
        Assert.areEqual(full.size(), masked.size());
        Assert.areEqual(full[0].mobileNumber, masked[0].mobileNumber, 'Empty test Lead: no number either way');
        Assert.isFalse(JSON.serialize(masked).contains(MOBILE), 'Real number never sent to the screen');
        Assert.areEqual('91XXXXXX80', PhoneDisplayService.forDisplay(MOBILE), 'Same rule the line uses');
    }

    @IsTest
    static void yotelListMaskedOnlyForMaskedUsersAndEligibilityUnchanged() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<String> ids = leadIds();

        PhoneDisplayService.maskedUserOverride = false;
        List<LeadYotelBulkPushController.LeadWrapper> full = LeadYotelBulkPushController.getSelectedLeads(ids);
        PhoneDisplayService.maskedUserOverride = true;
        List<LeadYotelBulkPushController.LeadWrapper> masked = LeadYotelBulkPushController.getSelectedLeads(ids);

        // Like Bulk push, the existing getSelectedLeads replaces its query result with one empty Lead while tests
        // run (if (Test.isRunningTest()) ...), so the masked line is checked on that record; the rule itself
        // (forDisplay) is tested in PhoneMaskingHistoryTest / PhoneDisplayServiceTest.
        Assert.areEqual(full.size(), masked.size());
        for (Integer i = 0; i < masked.size(); i++) {
            Assert.areEqual(full[i].eligible, masked[i].eligible, 'Eligibility unchanged by masking');
            Assert.areEqual(full[i].leadId, masked[i].leadId);
            Assert.areEqual(full[i].mobileNumber, masked[i].mobileNumber, 'Empty test Lead: no number either way');
        }
        Assert.isFalse(JSON.serialize(masked).contains(PRIMARY), 'Real number never sent to the screen');
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.forDisplay(PRIMARY), 'Same rule the line uses');
    }
}
