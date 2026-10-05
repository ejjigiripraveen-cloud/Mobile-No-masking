/**
 * @description Test data for the phone masking classes. Never uses org data (no SeeAllData).
 *              Leads are inserted with the existing LeadTrigger bypassed (Utility.bypassLeadTrigger)
 *              so the tests only exercise the masking code, and with duplicate rules allowed to save.
 * @group       Phone Masking
 */
@IsTest
public class PhoneTestDataFactory {
    public static final String FIELD_KEY_PRIMARY = 'Lead.Phone__c';
    public static final String FIELD_KEY_SECONDARY = 'Lead.Secondary_Phone__c';

    private static Integer userCounter = 0;

    /**
     * @description Creates and inserts a user with the given standard profile.
     *              Call inside System.runAs to avoid mixed DML with non-setup records.
     */
    public static User createUser(String profileName) {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        userCounter++;
        String unique = String.valueOf(System.currentTimeMillis()) + userCounter
            + String.valueOf(Crypto.getRandomInteger()).replace('-', '').left(4);
        User testUser = new User(
            ProfileId = userProfile.Id,
            FirstName = 'Mask',
            LastName = 'Tester ' + userCounter,
            Alias = ('mt' + unique).left(8),
            Email = 'mask.tester' + unique + '@example.com',
            Username = 'mask.tester' + unique + '@gsquare.masking.test',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_IN',
            TimeZoneSidKey = 'Asia/Kolkata'
        );
        insert testUser;
        return testUser;
    }

    /**
     * @description Builds (does not insert) Leads with unique primary and secondary numbers.
     *              Primary numbers start with 98, secondary with 97.
     */
    public static List<Lead> buildLeads(Integer count, Id ownerId) {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < count; i++) {
            Lead testLead = new Lead(
                LastName = 'Mask Test Lead ' + i,
                Company = 'Mask Test Company',
                Phone__c = primaryNumber(i),
                Secondary_Phone__c = secondaryNumber(i)
            );
            if (ownerId != null) {
                testLead.OwnerId = ownerId;
            }
            leads.add(testLead);
        }
        return leads;
    }

    /**
     * @description Inserts Leads with the existing Lead trigger bypassed and duplicate rules allowed to save.
     */
    public static List<Lead> insertLeads(List<Lead> leads) {
        Boolean previousBypass = Utility.bypassLeadTrigger;
        Utility.bypassLeadTrigger = true;
        try {
            Database.DMLOptions options = new Database.DMLOptions();
            options.DuplicateRuleHeader.allowSave = true;
            List<Database.SaveResult> results = Database.insert(leads, options);
            for (Database.SaveResult result : results) {
                System.assert(result.isSuccess(), 'Test Lead insert failed: ' + result.getErrors());
            }
        } finally {
            Utility.bypassLeadTrigger = previousBypass;
        }
        return leads;
    }

    public static String primaryNumber(Integer index) {
        return '98' + String.valueOf(10000000 + index);
    }

    public static String secondaryNumber(Integer index) {
        return '97' + String.valueOf(10000000 + index);
    }

    /**
     * @description Approved field list for tests (custom metadata cannot be inserted in tests).
     */
    public static List<Masked_Phone_Field__mdt> approvedLeadFields() {
        return new List<Masked_Phone_Field__mdt>{
            approvedField('Lead_Phone', 'Lead', 'Phone__c', 'Primary', 1, true, true, true),
            approvedField('Lead_Secondary_Phone', 'Lead', 'Secondary_Phone__c', 'Secondary', 2, true, true, true)
        };
    }

    public static Masked_Phone_Field__mdt approvedField(
        String developerName, String objectName, String fieldName, String label,
        Integer sortOrder, Boolean allowDial, Boolean allowReveal, Boolean active
    ) {
        return new Masked_Phone_Field__mdt(
            DeveloperName = developerName,
            Object_API_Name__c = objectName,
            Field_API_Name__c = fieldName,
            Display_Label__c = label,
            Sort_Order__c = sortOrder,
            Allow_Dial__c = allowDial,
            Allow_Reveal__c = allowReveal,
            Active__c = active
        );
    }

    /**
     * @description Default masking setting for tests, with optional switches.
     */
    public static Phone_Masking_Setting__mdt setting(Boolean resolveEnabled, Boolean auditEnabled) {
        Phone_Masking_Setting__mdt testSetting = PhoneMaskingConfig.defaultSetting();
        testSetting.Resolve_Enabled__c = resolveEnabled;
        testSetting.Audit_Enabled__c = auditEnabled;
        return testSetting;
    }

    /**
     * @description Points PhoneMaskingConfig at test settings and the approved Lead fields.
     */
    public static void useTestConfig(Boolean resolveEnabled, Boolean auditEnabled) {
        PhoneMaskingConfig.settingOverride = setting(resolveEnabled, auditEnabled);
        PhoneMaskingConfig.fieldsOverride = approvedLeadFields();
    }
}
