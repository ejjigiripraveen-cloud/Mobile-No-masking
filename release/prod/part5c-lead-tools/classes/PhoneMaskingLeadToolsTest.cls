/**
 * @description Tests the masked paths added in v1.5.0 (Part 5c): Lead Merge lists (LeadMergeController) and
 *              Update Contact Details (updateContactDetails) - including that a masked value sent back by the screen
 *              is never saved and that the primary number is locked for masked users.
 *              The existing test classes of these controllers are unchanged.
 */
@IsTest
private class PhoneMaskingLeadToolsTest {
    private static final String PRIMARY = '9876543221';
    private static final String SECONDARY = '9123456780';

    @TestSetup
    static void setup() {
        List<Lead> leads = PhoneTestDataFactory.buildLeads(2, UserInfo.getUserId());
        leads[0].LastName = 'Tools Lead One';
        leads[0].Phone__c = PRIMARY;
        leads[0].Secondary_Phone__c = SECONDARY;
        leads[0].Email = 'tools.one@example.com';
        leads[1].LastName = 'Tools Lead Two';
        leads[1].Phone__c = '9555555555';
        leads[1].Secondary_Phone__c = '9444444444';
        PhoneTestDataFactory.insertLeads(leads);
    }

    private static Lead leadNamed(String lastName) {
        return [SELECT Id, Phone__c, Secondary_Phone__c, Email, Secondary_Email__c FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    // ---------------- PhoneDisplayService.maskRecords ----------------

    @IsTest
    static void maskRecordsOnlyForMaskedUsersAndOnlyQueriedFields() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<Lead> plain = [SELECT Id, Phone__c FROM Lead WHERE LastName = 'Tools Lead One'];

        PhoneDisplayService.maskedUserOverride = false;
        PhoneDisplayService.maskRecords(plain, new List<String>{ 'Phone__c' });
        Assert.areEqual(PRIMARY, plain[0].Phone__c, 'Unmasked users: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        PhoneDisplayService.maskRecords(plain, new List<String>{ 'Phone__c', 'Secondary_Phone__c' });
        Assert.areEqual('98XXXXXX21', plain[0].Phone__c);
        Assert.isFalse(plain[0].getPopulatedFieldsAsMap().containsKey('Secondary_Phone__c'), 'Not-queried field skipped');
        PhoneDisplayService.maskRecords(null, null);
    }

    // ---------------- Lead Merge ----------------

    @IsTest
    static void mergeListsMaskedOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Lead one = leadNamed('Tools Lead One');

        PhoneDisplayService.maskedUserOverride = false;
        List<Lead> fullList = LeadMergeController.getLeads(one.Id);
        PhoneDisplayService.maskedUserOverride = true;
        List<Lead> maskedList = LeadMergeController.getLeads(one.Id);
        List<Lead> maskedSearch = LeadMergeController.getSearchLeads(one.Id, 'Tools Lead');

        Assert.areEqual('9555555555', fullList[0].Phone__c, 'Unmasked users: unchanged');
        Assert.areEqual('95XXXXXX55', maskedList[0].Phone__c);
        Assert.areEqual('94XXXXXX44', maskedList[0].Secondary_Phone__c);
        Assert.areEqual(1, maskedSearch.size());
        Assert.areEqual('95XXXXXX55', maskedSearch[0].Phone__c);
        Assert.areEqual('9555555555', [SELECT Phone__c FROM Lead WHERE LastName = 'Tools Lead Two'].Phone__c, 'Never saved');
    }

    // ---------------- Update Contact Details ----------------

    @IsTest
    static void contactDetailsMaskedOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Lead one = leadNamed('Tools Lead One');

        PhoneDisplayService.maskedUserOverride = false;
        Lead full = updateContactDetails.getcontactdetails(one.Id);
        PhoneDisplayService.maskedUserOverride = true;
        Lead masked = updateContactDetails.getcontactdetails(one.Id);

        Assert.areEqual(PRIMARY, full.Phone__c);
        Assert.areEqual('98XXXXXX21', masked.Phone__c);
        Assert.areEqual('91XXXXXX80', masked.Secondary_Phone__c);
    }

    @IsTest
    static void maskedValuesAreNeverSavedButEmailChangeIs() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = true;
        Lead one = leadNamed('Tools Lead One');

        Test.startTest();
        String result = updateContactDetails.savecontactdetails(one.Id, '98XXXXXX21', 'new.one@example.com', '91XXXXXX80', null);
        Test.stopTest();

        Assert.areEqual('Success', result);
        Lead saved = leadNamed('Tools Lead One');
        Assert.isTrue(saved.Phone__c.contains(PRIMARY.right(8)), 'Primary unchanged - never saved masked');
        Assert.isTrue(saved.Secondary_Phone__c.contains(SECONDARY.right(8)), 'Secondary unchanged - never saved masked');
        Assert.isFalse(saved.Phone__c.containsIgnoreCase('X'));
        Assert.areEqual('new.one@example.com', saved.Email, 'Email change saved');
    }

    @IsTest
    static void maskedUserCanChangeSecondary() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = true;
        Lead one = leadNamed('Tools Lead One');

        Test.startTest();
        String result = updateContactDetails.savecontactdetails(one.Id, '98XXXXXX21', one.Email, '9333333333', null);
        Test.stopTest();

        Assert.areEqual('Success', result);
        Assert.isTrue(leadNamed('Tools Lead One').Secondary_Phone__c.contains('33333333'), 'New secondary saved');
    }

    @IsTest
    static void maskedUserCannotChangePrimary() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = true;
        Lead one = leadNamed('Tools Lead One');

        String result = updateContactDetails.savecontactdetails(one.Id, '9000000000', one.Email, '91XXXXXX80', null);

        Assert.areEqual(LeadPhoneEntryHandler.PRIMARY_LOCKED_MESSAGE, result);
        Assert.isTrue(leadNamed('Tools Lead One').Phone__c.contains(PRIMARY.right(8)), 'Primary unchanged');
    }

    @IsTest
    static void unmaskedUserBehaviourUnchanged() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = false;
        Lead one = leadNamed('Tools Lead One');

        Test.startTest();
        String result = updateContactDetails.savecontactdetails(one.Id, '9000000001', one.Email, SECONDARY, null);
        Test.stopTest();

        Assert.areEqual('Success', result, 'Users who can see phone numbers can still change the primary');
        Assert.isTrue(leadNamed('Tools Lead One').Phone__c.contains('00000001'));
    }

    @IsTest
    static void prepareContactInputHandlesBadOrMissingRecords() {
        PhoneDisplayService.maskedUserOverride = true;

        PhoneDisplayService.ContactInput badId = PhoneDisplayService.prepareContactInput('not-an-id', '98XXXXXX21', null);
        Assert.areEqual('98XXXXXX21', badId.phone, 'Invalid record: unchanged (the existing code rejects it)');
        Assert.isNull(badId.error);

        Lead two = leadNamed('Tools Lead Two');
        Utility.bypassLeadTrigger = true;
        delete two;
        Utility.bypassLeadTrigger = false;
        PhoneDisplayService.ContactInput deleted = PhoneDisplayService.prepareContactInput(two.Id, '95XXXXXX55', null);
        Assert.areEqual('95XXXXXX55', deleted.phone);

        PhoneDisplayService.maskedUserOverride = false;
        PhoneDisplayService.ContactInput plain = PhoneDisplayService.prepareContactInput(two.Id, '9555555555', '9444444444');
        Assert.areEqual('9555555555', plain.phone, 'Unmasked user with real values: untouched, no query');
    }
}
