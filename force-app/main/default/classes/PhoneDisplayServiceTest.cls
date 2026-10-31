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
    static void forDisplayMasksOnlyForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();

        PhoneDisplayService.maskedUserOverride = false;
        Assert.areEqual('9876543221', PhoneDisplayService.forDisplay('9876543221'), 'Unmasked user: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.forDisplay('9876543221'));
        Assert.isNull(PhoneDisplayService.forDisplay(null));
    }

    @IsTest
    static void masksHistoryValuesOfPhoneFieldsOnly() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride.add(
            PhoneTestDataFactory.approvedField('Lead_Custom_Phone', 'Lead', 'Custom_Phone__c', 'Custom', 3, true, true, true)
        );

        PhoneDisplayService.maskedUserOverride = false;
        Assert.areEqual('9876543221', PhoneDisplayService.historyValueForDisplay('Phone__c', '9876543221'), 'Unmasked user: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.historyValueForDisplay('Phone__c', '9876543221'));
        Assert.areEqual('Old: 98XXXXXX21', PhoneDisplayService.historyValueForDisplay('MobilePhone', 'Old: 9876543221'));
        Assert.areEqual('98XXXXXX21', PhoneDisplayService.historyValueForDisplay('Custom_Phone__c', '9876543221'), 'Approved field from metadata');
        Assert.areEqual('Ref 9876543221', PhoneDisplayService.historyValueForDisplay('Status', 'Ref 9876543221'), 'Not a phone field');
        Assert.isNull(PhoneDisplayService.historyValueForDisplay('Phone__c', null));
        Assert.areEqual('9876543221', PhoneDisplayService.historyValueForDisplay(' ', '9876543221'), 'No field name');
    }

    @IsTest
    static void masksQueriedRecordFieldsInMemoryForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<Lead> records = new List<Lead>{
            new Lead(LastName = 'A', Phone__c = '9876543221', Secondary_Phone__c = null),
            new Lead(LastName = 'B', Phone__c = '+91 9123456780')
        };
        List<String> fields = new List<String>{ 'Phone__c', 'Secondary_Phone__c', 'MobilePhone' };

        PhoneDisplayService.maskedUserOverride = false;
        PhoneDisplayService.maskRecords(records, fields);
        Assert.areEqual('9876543221', records[0].Phone__c, 'Unmasked user: unchanged');

        PhoneDisplayService.maskedUserOverride = true;
        PhoneDisplayService.maskRecords(records, fields);
        Assert.areEqual('98XXXXXX21', records[0].Phone__c);
        Assert.isNull(records[0].Secondary_Phone__c);
        Assert.areEqual('+91 91XXXXXX80', records[1].Phone__c);
        Assert.isNull(records[1].MobilePhone, 'Field not queried: skipped');
        PhoneDisplayService.maskRecords(null, fields);
        PhoneDisplayService.maskRecords(records, null);
    }

    @IsTest
    static void contactInputUnchangedForUnmaskedUserWithRealValues() {
        PhoneDisplayService.maskedUserOverride = false;

        PhoneDisplayService.ContactInput input = PhoneDisplayService.prepareContactInput(testLead().Id, '9000000001', '9000000002');

        Assert.areEqual('9000000001', input.phone);
        Assert.areEqual('9000000002', input.secondaryPhone);
        Assert.isNull(input.error);
    }

    @IsTest
    static void contactInputNeverSavesMaskedValues() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Lead stored = testLead();
        PhoneDisplayService.maskedUserOverride = false;

        PhoneDisplayService.ContactInput input = PhoneDisplayService.prepareContactInput(
            stored.Id, PhoneMaskUtil.mask(stored.Phone__c), PhoneMaskUtil.mask(stored.Secondary_Phone__c)
        );

        Assert.areEqual(stored.Phone__c, input.phone, 'Masked primary replaced by the stored number');
        Assert.areEqual(stored.Secondary_Phone__c, input.secondaryPhone, 'Masked secondary replaced by the stored number');
        Assert.isNull(input.error);
    }

    @IsTest
    static void contactInputLocksPrimaryForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Lead stored = testLead();
        PhoneDisplayService.maskedUserOverride = true;

        PhoneDisplayService.ContactInput changed = PhoneDisplayService.prepareContactInput(stored.Id, '9000000001', '9000000002');
        PhoneDisplayService.ContactInput sameNumber = PhoneDisplayService.prepareContactInput(stored.Id, '+91 ' + stored.Phone__c, '9000000002');

        Assert.areEqual(LeadPhoneEntryHandler.PRIMARY_LOCKED_MESSAGE, changed.error);
        Assert.isNull(sameNumber.error, 'Same primary in another format is not a change');
        Assert.areEqual('9000000002', sameNumber.secondaryPhone, 'Secondary can still be changed');
    }

    @IsTest
    static void contactInputUnchangedForInvalidOrMissingLead() {
        PhoneDisplayService.maskedUserOverride = true;

        PhoneDisplayService.ContactInput invalidId = PhoneDisplayService.prepareContactInput('not-an-id', '98XXXXXX21', null);
        PhoneDisplayService.ContactInput missingLead = PhoneDisplayService.prepareContactInput('00Q000000000000AAA', '98XXXXXX21', null);

        Assert.areEqual('98XXXXXX21', invalidId.phone);
        Assert.isNull(invalidId.error);
        Assert.areEqual('98XXXXXX21', missingLead.phone);
        Assert.isNull(missingLead.error);
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
