@IsTest
private class PhoneMaskingConfigTest {
    @IsTest
    static void returnsSettingFromMetadataOrDefaults() {
        Phone_Masking_Setting__mdt setting = PhoneMaskingConfig.getSetting();
        Assert.isNotNull(setting, 'A setting is always available (record or built-in defaults)');
        Assert.areSame(setting, PhoneMaskingConfig.getSetting(), 'Setting is cached per transaction');
    }

    @IsTest
    static void defaultSettingHasAgreedValues() {
        Phone_Masking_Setting__mdt defaults = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual(2, defaults.Visible_Prefix_Digits__c.intValue());
        Assert.areEqual(2, defaults.Visible_Suffix_Digits__c.intValue());
        Assert.areEqual('X', defaults.Mask_Character__c);
        Assert.areEqual('91', defaults.Country_Code_To_Strip__c);
        Assert.areEqual(30, defaults.Reveal_Seconds__c.intValue());
        Assert.areEqual(365, defaults.Audit_Retention_Days__c.intValue());
        Assert.isTrue(defaults.Resolve_Enabled__c);
        Assert.isTrue(defaults.Audit_Enabled__c);
    }

    @IsTest
    static void readsSwitchesAndFormatFromOverride() {
        Phone_Masking_Setting__mdt custom = PhoneTestDataFactory.setting(false, false);
        custom.Mask_Character__c = '#*';
        custom.Country_Code_To_Strip__c = '+44';
        PhoneMaskingConfig.settingOverride = custom;

        Assert.isFalse(PhoneMaskingConfig.isResolveEnabled());
        Assert.isFalse(PhoneMaskingConfig.isAuditEnabled());
        Assert.areEqual('#', PhoneMaskingConfig.maskCharacter(), 'Only the first character is used');
        Assert.areEqual('44', PhoneMaskingConfig.countryCode(), 'Non-digits are removed');
    }

    @IsTest
    static void keepsOnlyActiveCompleteFields() {
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Active', 'Lead', 'Phone__c', 'Primary', 1, true, true, true),
            PhoneTestDataFactory.approvedField('Inactive', 'Lead', 'Secondary_Phone__c', 'Secondary', 2, true, true, false),
            PhoneTestDataFactory.approvedField('Incomplete', 'Lead', null, 'Broken', 3, true, true, true)
        };

        Map<String, Masked_Phone_Field__mdt> active = PhoneMaskingConfig.getActiveFields();
        Assert.areEqual(1, active.size());
        Assert.isTrue(active.containsKey('lead.phone__c'));
    }

    @IsTest
    static void readsDeployedFieldListAndCachesIt() {
        Map<String, Masked_Phone_Field__mdt> first = PhoneMaskingConfig.getActiveFields();
        Assert.isNotNull(first);
        Assert.areSame(first, PhoneMaskingConfig.getActiveFields(), 'Field list is cached per transaction');
    }

    @IsTest
    static void buildsCaseInsensitiveFieldKey() {
        Assert.areEqual('lead.phone__c', PhoneMaskingConfig.fieldKey('Lead', 'Phone__c'));
    }
}
