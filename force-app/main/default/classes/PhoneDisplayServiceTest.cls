@IsTest
private class PhoneDisplayServiceTest {
    @TestSetup
    static void setup() {
        PhoneTestDataFactory.insertLeads(PhoneTestDataFactory.buildLeads(1, UserInfo.getUserId()));
    }

    private static Lead testLead() {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead LIMIT 1];
    }

    private static List<Phone_Access_Audit__c> audits() {
        return [SELECT Outcome__c, Channel__c, Masked_Number__c, Message__c FROM Phone_Access_Audit__c];
    }

    @IsTest
    static void masksForDisplayKeepingCountryPrefix() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual('+91 98XXXXXX21', PhoneDisplayService.maskForDisplay('+91 9876543221'));
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.maskForDisplay(' 9876543221 '));
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.maskForDisplay('+919876543221'));
        Assert.isNull(PhoneDisplayService.maskForDisplay(null));
        Assert.areEqual(' ', PhoneDisplayService.maskForDisplay(' '));
        List<String> all = PhoneDisplayService.maskAllForDisplay(new List<String>{ '+91 9876543221', '9123456780' });
        Assert.areEqual('+91 98XXXXXX21', all[0]);
        Assert.areEqual('91XXXXXX80', all[1]);
        Assert.areEqual(0, PhoneDisplayService.maskAllForDisplay(null).size());
    }

    @IsTest
    static void detectsMaskedValues() {
        Assert.isTrue(PhoneDisplayService.isMasked('98XXXXXX21'));
        Assert.isTrue(PhoneDisplayService.isMasked('xxxxxx4321'));
        Assert.isFalse(PhoneDisplayService.isMasked('9876543221'));
        Assert.isFalse(PhoneDisplayService.isMasked(null));
    }

    @IsTest
    static void maskedUserFollowsFieldAccessOrOverride() {
        Assert.areEqual(!Schema.SObjectType.Lead.fields.Phone__c.isAccessible(), PhoneDisplayService.isMaskedUser());
        PhoneDisplayService.maskedUserOverride = true;
        Assert.isTrue(PhoneDisplayService.isMaskedUser());
    }

    @IsTest
    static void masksMapValuesOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Map<String, String> values = new Map<String, String>{ 'PrimaryPhone' => '9876543221', 'SecondaryPhone' => null, 'LeadId' => 'L-1' };

        PhoneDisplayService.maskedUserOverride = false;
        PhoneDisplayService.maskValues(values, new List<String>{ 'PrimaryPhone', 'SecondaryPhone' });
        Assert.areEqual('9876543221', values.get('PrimaryPhone'), 'Unmasked user: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        PhoneDisplayService.maskValues(values, new List<String>{ 'PrimaryPhone', 'SecondaryPhone', 'Missing' });
        Assert.areEqual('98XXXXXX21', values.get('PrimaryPhone'));
        Assert.isNull(values.get('SecondaryPhone'));
        Assert.areEqual('L-1', values.get('LeadId'));
        PhoneDisplayService.maskValues(null, null);
    }

    @IsTest
    static void matchesExactAndOlderMasks() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<String> candidates = new List<String>{ '+91 9876543221', '+91 9123454321', null };

        Assert.areEqual('+91 9876543221', PhoneDisplayService.matchMasked('+91 98XXXXXX21', candidates));
        Assert.areEqual('+91 9123454321', PhoneDisplayService.matchMasked('XXXXXX4321', candidates), 'Older screen mask');
        Assert.areEqual('+91 9876543221', PhoneDisplayService.matchMasked('98XXXXXX21', candidates), 'Without prefix');
        Assert.isNull(PhoneDisplayService.matchMasked('11XXXXXX00', candidates));
        Assert.isNull(PhoneDisplayService.matchMasked('XXXXXXXXXX', candidates), 'No visible digits');
        Assert.isNull(PhoneDisplayService.matchMasked(' ', candidates));
        Assert.isNull(PhoneDisplayService.matchMasked('98XXXXXX21', null));
    }

    @IsTest
    static void returnsNullWhenAmbiguous() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.isNull(PhoneDisplayService.matchMasked('98XXXXXX21', new List<String>{ '9876543221', '9811111121' }), 'Two exact matches');
        Assert.isNull(PhoneDisplayService.matchMasked('XXXX21', new List<String>{ '9876543221', '9811111121' }), 'Two partial matches');
    }

    @IsTest
    static void checksRecordAccess() {
        Assert.isTrue(PhoneDisplayService.canSeeRecord(testLead().Id));
        Assert.isFalse(PhoneDisplayService.canSeeRecord(null));
    }

    @IsTest
    static void resolvesAndAuditsMaskedOnly() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        List<String> candidates = new List<String>{ lead.Phone__c, lead.Secondary_Phone__c };

        String real = PhoneDisplayService.resolve(lead.Id, PhoneMaskUtil.mask(lead.Phone__c), candidates, 'G-Talk');
        String none = PhoneDisplayService.resolve(lead.Id, '11XXXXXX00', candidates, 'G-Talk');

        Assert.areEqual(lead.Phone__c, real);
        Assert.isNull(none);
        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(2, rows.size());
        for (Phone_Access_Audit__c row : rows) {
            Assert.areEqual('G-Talk', row.Channel__c);
            Assert.isTrue(row.Masked_Number__c.contains('X'), 'Only masked numbers are audited');
        }
    }

    @IsTest
    static void deniesWithoutRecordAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();
        User other;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            other = PhoneTestDataFactory.createUser('Minimum Access - Salesforce');
        }

        String real;
        System.runAs(other) {
            real = PhoneDisplayService.resolve(lead.Id, PhoneMaskUtil.mask(lead.Phone__c), new List<String>{ lead.Phone__c }, 'MCube (MakeCall)');
        }

        Assert.isNull(real);
        Assert.areEqual(PhoneDisplayService.OUTCOME_DENIED, audits()[0].Outcome__c);
    }
}
