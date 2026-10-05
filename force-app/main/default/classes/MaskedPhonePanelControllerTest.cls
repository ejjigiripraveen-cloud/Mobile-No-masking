@IsTest
private class MaskedPhonePanelControllerTest {
    @TestSetup
    static void setup() {
        User rep;
        User noAccess;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep = PhoneTestDataFactory.createUser('Standard User');
            noAccess = PhoneTestDataFactory.createUser('Minimum Access - Salesforce');
        }
        List<Lead> leads = PhoneTestDataFactory.buildLeads(2, rep.Id);
        leads[0].LastName = 'Panel Both Numbers';
        leads[1].LastName = 'Panel Primary Only';
        leads[1].Secondary_Phone__c = null;
        PhoneTestDataFactory.insertLeads(leads);
    }

    private static User userWithProfile(String profileName) {
        return [SELECT Id FROM User WHERE Email LIKE 'mask.tester%' AND Profile.Name = :profileName LIMIT 1];
    }

    private static Lead leadNamed(String lastName) {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    @IsTest
    static void returnsMaskedNumbersInDisplayOrder() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Both Numbers');

        List<MaskedPhonePanelController.PhoneRow> rows;
        Test.startTest();
        System.runAs(userWithProfile('Standard User')) {
            rows = MaskedPhonePanelController.getMaskedNumbers(lead.Id);
        }
        Test.stopTest();

        Assert.areEqual(2, rows.size());
        Assert.areEqual('Primary', rows[0].label);
        Assert.areEqual('Lead.Phone__c', rows[0].fieldKey);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), rows[0].maskedNumber);
        Assert.isTrue(rows[0].hasNumber);
        Assert.isTrue(rows[0].canDial);
        Assert.areEqual('Secondary', rows[1].label);
        Assert.areEqual('Lead.Secondary_Phone__c', rows[1].fieldKey);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Secondary_Phone__c), rows[1].maskedNumber);
    }

    @IsTest
    static void neverReturnsTheRealNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Both Numbers');

        List<MaskedPhonePanelController.PhoneRow> rows;
        System.runAs(userWithProfile('Standard User')) {
            rows = MaskedPhonePanelController.getMaskedNumbers(lead.Id);
        }

        String serialized = JSON.serialize(rows);
        Assert.isFalse(serialized.contains(lead.Phone__c), 'Primary number must not reach the browser');
        Assert.isFalse(serialized.contains(lead.Secondary_Phone__c), 'Secondary number must not reach the browser');
        Assert.isFalse(serialized.contains(lead.Phone__c.substring(2, 8)), 'Middle digits must not reach the browser');
    }

    @IsTest
    static void marksMissingNumberWithoutDial() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Primary Only');

        List<MaskedPhonePanelController.PhoneRow> rows;
        System.runAs(userWithProfile('Standard User')) {
            rows = MaskedPhonePanelController.getMaskedNumbers(lead.Id);
        }

        Assert.areEqual(2, rows.size());
        Assert.isTrue(rows[0].hasNumber);
        Assert.isFalse(rows[1].hasNumber);
        Assert.isFalse(rows[1].canDial);
        Assert.isNull(rows[1].maskedNumber);
    }

    @IsTest
    static void respectsAllowDialAndSortOrderAndSkipsBadConfig() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Second', 'Lead', 'Phone__c', null, 5, false, false, true),
            PhoneTestDataFactory.approvedField('First', 'Lead', 'Secondary_Phone__c', 'Alt', 1, true, true, true),
            PhoneTestDataFactory.approvedField('Broken', 'Lead', 'Does_Not_Exist__c', 'Broken', 2, true, true, true),
            PhoneTestDataFactory.approvedField('Other', 'Account', 'Phone', 'Account', 0, true, true, true)
        };
        Lead lead = leadNamed('Panel Both Numbers');

        List<MaskedPhonePanelController.PhoneRow> rows = MaskedPhonePanelController.getMaskedNumbers(lead.Id);

        Assert.areEqual(2, rows.size(), 'Broken and other-object configs are skipped');
        Assert.areEqual('Alt', rows[0].label, 'Sorted by Sort_Order__c');
        Assert.isTrue(rows[0].canDial);
        Assert.areEqual(Schema.SObjectType.Lead.fields.getMap().get('Phone__c').getDescribe().getLabel(), rows[1].label,
            'Falls back to the field label when no display label is set');
        Assert.isFalse(rows[1].canDial, 'Allow Dial unchecked');
    }

    @IsTest
    static void sortsByFieldNameWhenOrderIsEqual() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('B', 'Lead', 'Secondary_Phone__c', 'B', null, true, true, true),
            PhoneTestDataFactory.approvedField('A', 'Lead', 'Phone__c', 'A', null, true, true, true)
        };
        Lead lead = leadNamed('Panel Both Numbers');

        List<MaskedPhonePanelController.PhoneRow> rows = MaskedPhonePanelController.getMaskedNumbers(lead.Id);

        Assert.areEqual('Phone__c', rows[0].fieldKey.substringAfter('.'));
        Assert.areEqual('Secondary_Phone__c', rows[1].fieldKey.substringAfter('.'));
    }

    @IsTest
    static void returnsEmptyListWhenNoFieldApproved() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>();
        Lead lead = leadNamed('Panel Both Numbers');

        Assert.areEqual(0, MaskedPhonePanelController.getMaskedNumbers(lead.Id).size());
    }

    @IsTest
    static void rejectsNullRecordId() {
        PhoneTestDataFactory.useTestConfig(true, true);
        try {
            MaskedPhonePanelController.getMaskedNumbers(null);
            Assert.fail('Expected an error');
        } catch (AuraHandledException e) {
            Assert.areEqual('Record is required.', e.getMessage());
        }
    }

    @IsTest
    static void rejectsUserWithoutObjectAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Both Numbers');

        System.runAs(userWithProfile('Minimum Access - Salesforce')) {
            try {
                MaskedPhonePanelController.getMaskedNumbers(lead.Id);
                Assert.fail('Expected an error');
            } catch (AuraHandledException e) {
                Assert.areEqual('You do not have access to this record.', e.getMessage());
            }
        }
    }

    @IsTest
    static void rejectsDeletedRecord() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Primary Only');
        Utility.bypassLeadTrigger = true;
        delete lead;
        Utility.bypassLeadTrigger = false;

        try {
            MaskedPhonePanelController.getMaskedNumbers(lead.Id);
            Assert.fail('Expected an error');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Record not found'));
        }
    }

    @IsTest
    static void followsTodaysRecordAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User rep = userWithProfile('Standard User');
        List<Lead> adminLeads = PhoneTestDataFactory.buildLeads(1, UserInfo.getUserId());
        adminLeads[0].LastName = 'Panel Admin Lead';
        adminLeads[0].Phone__c = PhoneTestDataFactory.primaryNumber(700);
        adminLeads[0].Secondary_Phone__c = PhoneTestDataFactory.secondaryNumber(700);
        PhoneTestDataFactory.insertLeads(adminLeads);
        Boolean repCanRead = [
            SELECT RecordId, HasReadAccess FROM UserRecordAccess
            WHERE UserId = :rep.Id AND RecordId = :adminLeads[0].Id
        ].HasReadAccess;

        Boolean gotRows = false;
        System.runAs(rep) {
            try {
                gotRows = !MaskedPhonePanelController.getMaskedNumbers(adminLeads[0].Id).isEmpty();
            } catch (AuraHandledException e) {
                gotRows = false;
            }
        }

        Assert.areEqual(repCanRead, gotRows, 'Panel shows numbers only when the user can see the record');
    }

    @IsTest
    static void usesOneQueryPerCall() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Panel Both Numbers');

        Integer before = Limits.getQueries();
        MaskedPhonePanelController.getMaskedNumbers(lead.Id);

        Assert.areEqual(1, Limits.getQueries() - before);
        Assert.areEqual(0, Limits.getDmlStatements(), 'Panel never writes data');
    }
}
