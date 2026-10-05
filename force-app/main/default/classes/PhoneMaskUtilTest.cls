@IsTest
private class PhoneMaskUtilTest {
    @IsTest
    static void masksTenDigitNumber() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('9876543221'));
    }

    @IsTest
    static void stripsIndianCountryCodeAndFormatting() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('919876543221'));
        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('+91 98765-43221'));
        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('00919876543221'));
        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('09876543221'));
        Assert.areEqual('9876543221', PhoneMaskUtil.normalize('+91 (98765) 43221'));
    }

    @IsTest
    static void masksInternationalNumberWithSameRule() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual('97XXXXXXXX67', PhoneMaskUtil.mask('+971501234567'));
        Assert.areEqual('65XXXXXXXX32', PhoneMaskUtil.mask('+658765465432'));
    }

    @IsTest
    static void handlesNullBlankAndShortInput() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.isNull(PhoneMaskUtil.mask(null));
        Assert.areEqual('', PhoneMaskUtil.mask(''));
        Assert.areEqual('', PhoneMaskUtil.mask('   '));
        Assert.areEqual('', PhoneMaskUtil.mask('no digits'));
        Assert.areEqual('XXXX', PhoneMaskUtil.mask('1234'), 'Too short to keep both ends visible: fully masked');
        Assert.areEqual('12X45', PhoneMaskUtil.mask('12345'));
        Assert.areEqual('', PhoneMaskUtil.normalize(null));
    }

    @IsTest
    static void usesConfiguredFormat() {
        Phone_Masking_Setting__mdt custom = PhoneMaskingConfig.defaultSetting();
        custom.Visible_Prefix_Digits__c = 3;
        custom.Visible_Suffix_Digits__c = 3;
        custom.Mask_Character__c = '*';
        custom.Country_Code_To_Strip__c = '';
        PhoneMaskingConfig.settingOverride = custom;

        Assert.areEqual('987****221', PhoneMaskUtil.mask('9876543221'));
        Assert.areEqual('919******221', PhoneMaskUtil.mask('919876543221'), 'No country code configured: nothing stripped');
    }

    @IsTest
    static void fallsBackWhenSettingValuesInvalid() {
        Phone_Masking_Setting__mdt broken = PhoneMaskingConfig.defaultSetting();
        broken.Visible_Prefix_Digits__c = null;
        broken.Visible_Suffix_Digits__c = -1;
        broken.Mask_Character__c = null;
        broken.Country_Code_To_Strip__c = null;
        PhoneMaskingConfig.settingOverride = broken;

        Assert.areEqual('98XXXXXX21', PhoneMaskUtil.mask('9876543221'));
    }

    @IsTest
    static void masksListInOrder() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<String> masked = PhoneMaskUtil.maskAll(new List<String>{ '9876543221', null, '9123456780' });
        Assert.areEqual(3, masked.size());
        Assert.areEqual('98XXXXXX21', masked[0]);
        Assert.isNull(masked[1]);
        Assert.areEqual('91XXXXXX80', masked[2]);
        Assert.areEqual(0, PhoneMaskUtil.maskAll(null).size());
    }

    @IsTest
    static void masksBulkListOf200() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        List<String> numbers = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            numbers.add(PhoneTestDataFactory.primaryNumber(i));
        }
        Test.startTest();
        List<String> masked = PhoneMaskUtil.maskAll(numbers);
        Test.stopTest();

        Assert.areEqual(200, masked.size());
        for (Integer i = 0; i < 200; i++) {
            Assert.areEqual(PhoneMaskUtil.mask(numbers[i]), masked[i]);
            Assert.isFalse(masked[i].contains(numbers[i].substring(2, 8)), 'Middle digits must be hidden');
        }
    }

    @IsTest
    static void masksNumbersInsideText() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.areEqual('Call 98XXXXXX21 today', PhoneMaskUtil.maskInText('Call 9876543221 today'));
        Assert.areEqual(
            'Primary 98XXXXXX21, alt 91XXXXXX80.',
            PhoneMaskUtil.maskInText('Primary +91 98765 43221, alt 9123456780.')
        );
        Assert.areEqual('Ref 98XXXXXX21', PhoneMaskUtil.maskInText('Ref 98765-43221'));
    }

    @IsTest
    static void masksTwoNumbersSeparatedBySpaceAsOneRun() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        String result = PhoneMaskUtil.maskInText('Numbers 9876543221 9123456780 end');
        Assert.isFalse(result.contains('76543'), 'First number must not leak');
        Assert.isFalse(result.contains('23456'), 'Second number must not leak');
        Assert.isTrue(result.startsWith('Numbers ') && result.endsWith(' end'));
    }

    @IsTest
    static void leavesShortNumbersAndDatesInText() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        String text = 'Visit on 2026-10-05, plot 1234, amount 45000000.';
        Assert.areEqual(text, PhoneMaskUtil.maskInText(text));
        Assert.isFalse(PhoneMaskUtil.containsPhoneNumber(text));
        Assert.isNull(PhoneMaskUtil.maskInText(null));
        Assert.areEqual('', PhoneMaskUtil.maskInText(''));
    }

    @IsTest
    static void detectsPhoneNumbersInText() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        Assert.isTrue(PhoneMaskUtil.containsPhoneNumber('Reach me at +91 98765 43221'));
        Assert.isFalse(PhoneMaskUtil.containsPhoneNumber(null));
        Assert.isFalse(PhoneMaskUtil.containsPhoneNumber('no number here'));
    }
}
