/**
 * @description Reads the mobile number masking settings (Phone_Masking_Setting__mdt) and the
 *              approved phone field list (Masked_Phone_Field__mdt).
 *              Custom metadata reads do not use SOQL limits and are cached per transaction.
 *              Tests inject values through the @TestVisible overrides because custom metadata
 *              records cannot be inserted in tests.
 * @group       Phone Masking
 */
public inherited sharing class PhoneMaskingConfig {
    public static final String DEFAULT_SETTING_NAME = 'Default';

    private static final Integer DEFAULT_PREFIX_DIGITS = 2;
    private static final Integer DEFAULT_SUFFIX_DIGITS = 2;
    private static final String DEFAULT_MASK_CHARACTER = 'X';
    private static final String DEFAULT_COUNTRY_CODE = '91';

    @TestVisible
    private static Phone_Masking_Setting__mdt settingOverride;
    @TestVisible
    private static List<Masked_Phone_Field__mdt> fieldsOverride;

    private static Phone_Masking_Setting__mdt cachedSetting;
    private static Map<String, Masked_Phone_Field__mdt> cachedFields;

    /**
     * @description Returns the active setting record, or safe defaults if the record is missing.
     */
    public static Phone_Masking_Setting__mdt getSetting() {
        if (settingOverride != null) {
            return settingOverride;
        }
        if (cachedSetting == null) {
            cachedSetting = Phone_Masking_Setting__mdt.getInstance(DEFAULT_SETTING_NAME);
            if (cachedSetting == null) {
                cachedSetting = defaultSetting();
            }
        }
        return cachedSetting;
    }

    /**
     * @description Built-in defaults, used when no setting record exists.
     */
    public static Phone_Masking_Setting__mdt defaultSetting() {
        return new Phone_Masking_Setting__mdt(
            DeveloperName = DEFAULT_SETTING_NAME,
            Visible_Prefix_Digits__c = DEFAULT_PREFIX_DIGITS,
            Visible_Suffix_Digits__c = DEFAULT_SUFFIX_DIGITS,
            Mask_Character__c = DEFAULT_MASK_CHARACTER,
            Country_Code_To_Strip__c = DEFAULT_COUNTRY_CODE,
            Reveal_Seconds__c = 30,
            Audit_Retention_Days__c = 365,
            Resolve_Enabled__c = true,
            Audit_Enabled__c = true
        );
    }

    /**
     * @description Active approved phone fields keyed by lower-case field key, e.g. 'lead.phone__c'.
     */
    public static Map<String, Masked_Phone_Field__mdt> getActiveFields() {
        if (fieldsOverride == null && cachedFields != null) {
            return cachedFields;
        }
        List<Masked_Phone_Field__mdt> source = fieldsOverride != null
            ? fieldsOverride
            : Masked_Phone_Field__mdt.getAll().values();

        Map<String, Masked_Phone_Field__mdt> activeFields = new Map<String, Masked_Phone_Field__mdt>();
        for (Masked_Phone_Field__mdt fieldConfig : source) {
            if (fieldConfig.Active__c == true
                    && String.isNotBlank(fieldConfig.Object_API_Name__c)
                    && String.isNotBlank(fieldConfig.Field_API_Name__c)) {
                activeFields.put(fieldKey(fieldConfig.Object_API_Name__c, fieldConfig.Field_API_Name__c), fieldConfig);
            }
        }
        if (fieldsOverride == null) {
            cachedFields = activeFields;
        }
        return activeFields;
    }

    /**
     * @description Normalised key for an object/field pair, e.g. ('Lead', 'Phone__c') => 'lead.phone__c'.
     */
    public static String fieldKey(String objectName, String fieldName) {
        return (objectName + '.' + fieldName).toLowerCase();
    }

    public static Integer prefixDigits() {
        return toNonNegativeInteger(getSetting().Visible_Prefix_Digits__c, DEFAULT_PREFIX_DIGITS);
    }

    public static Integer suffixDigits() {
        return toNonNegativeInteger(getSetting().Visible_Suffix_Digits__c, DEFAULT_SUFFIX_DIGITS);
    }

    public static String maskCharacter() {
        String maskChar = getSetting().Mask_Character__c;
        return String.isBlank(maskChar) ? DEFAULT_MASK_CHARACTER : maskChar.left(1);
    }

    public static String countryCode() {
        String code = getSetting().Country_Code_To_Strip__c;
        return code == null ? '' : code.replaceAll('[^0-9]', '');
    }

    public static Boolean isResolveEnabled() {
        return getSetting().Resolve_Enabled__c == true;
    }

    public static Boolean isAuditEnabled() {
        return getSetting().Audit_Enabled__c == true;
    }

    private static Integer toNonNegativeInteger(Decimal value, Integer fallback) {
        if (value == null || value < 0) {
            return fallback;
        }
        return value.intValue();
    }
}
