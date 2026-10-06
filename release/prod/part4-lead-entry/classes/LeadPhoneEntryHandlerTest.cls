@IsTest
private class LeadPhoneEntryHandlerTest {
    private static final String PRIMARY = '9876543210';
    private static final String SECONDARY = '9123456780';

    private static Lead entryLead(String primaryEntry, String secondaryEntry) {
        return new Lead(
            LastName = 'Entry Test',
            Company = 'Entry Test Co',
            Phone_Entry__c = primaryEntry,
            Secondary_Phone_Entry__c = secondaryEntry
        );
    }

    // ---------------- handler rules (in memory) ----------------

    @IsTest
    static void copiesEntryFieldsOnCreateAndClearsThem() {
        Lead lead = entryLead('  ' + PRIMARY + ' ', SECONDARY);

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ lead }, null);

        Assert.areEqual(PRIMARY, lead.Phone__c, 'Trimmed and copied');
        Assert.areEqual(SECONDARY, lead.Secondary_Phone__c);
        Assert.isNull(lead.Phone_Entry__c, 'Entry field always empty after save');
        Assert.isNull(lead.Secondary_Phone_Entry__c);
        Assert.isFalse(lead.hasErrors());
    }

    @IsTest
    static void entryWinsOverDirectValueOnCreate() {
        Lead lead = entryLead(PRIMARY, null);
        lead.Phone__c = '9000000000';

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ lead }, null);

        Assert.areEqual(PRIMARY, lead.Phone__c, 'The number the user typed is saved');
    }

    @IsTest
    static void leavesRecordsWithoutEntryValuesUntouched() {
        Lead integrationLead = new Lead(LastName = 'API', Company = 'Co', Phone__c = PRIMARY, Secondary_Phone__c = SECONDARY);
        Lead blankEntries = entryLead('   ', '  ');
        blankEntries.Phone__c = PRIMARY;
        blankEntries.Secondary_Phone__c = SECONDARY;

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ integrationLead, blankEntries }, null);

        Assert.areEqual(PRIMARY, integrationLead.Phone__c, 'Integrations writing Phone__c are unaffected');
        Assert.areEqual(SECONDARY, integrationLead.Secondary_Phone__c);
        Assert.areEqual(PRIMARY, blankEntries.Phone__c, 'Blank entry does not wipe the number');
        Assert.areEqual(SECONDARY, blankEntries.Secondary_Phone__c);
        Assert.isNull(blankEntries.Phone_Entry__c);
        Assert.isNull(blankEntries.Secondary_Phone_Entry__c);
    }

    @IsTest
    static void locksPrimaryOnceSet() {
        Id fakeId = '00Q000000000001';
        Lead oldLead = new Lead(Id = fakeId, Phone__c = PRIMARY);
        Lead changed = new Lead(Id = fakeId, Phone__c = PRIMARY, Phone_Entry__c = '9000000000');

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ changed }, new Map<Id, Lead>{ fakeId => oldLead });

        Assert.isTrue(changed.hasErrors(), 'Changing the primary through the entry field is rejected');
        Assert.areEqual(LeadPhoneEntryHandler.PRIMARY_LOCKED_MESSAGE, changed.getErrors()[0].getMessage());
        Assert.areEqual(PRIMARY, changed.Phone__c, 'Primary unchanged');
    }

    @IsTest
    static void allowsSamePrimaryInAnyFormatAndSetsMissingPrimary() {
        Id idWithPrimary = '00Q000000000001';
        Id idWithoutPrimary = '00Q000000000002';
        Lead same = new Lead(Id = idWithPrimary, Phone__c = PRIMARY, Phone_Entry__c = '+91 98765 43210');
        Lead missing = new Lead(Id = idWithoutPrimary, Phone_Entry__c = PRIMARY);
        Map<Id, Lead> oldMap = new Map<Id, Lead>{
            idWithPrimary => new Lead(Id = idWithPrimary, Phone__c = PRIMARY),
            idWithoutPrimary => new Lead(Id = idWithoutPrimary)
        };

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ same, missing }, oldMap);

        Assert.isFalse(same.hasErrors(), 'Same number (formatted) is not a change');
        Assert.isNull(same.Phone_Entry__c);
        Assert.isFalse(missing.hasErrors());
        Assert.areEqual(PRIMARY, missing.Phone__c, 'Lead without a primary can get one');
    }

    @IsTest
    static void secondaryCanAlwaysBeChanged() {
        Id fakeId = '00Q000000000001';
        Lead updated = new Lead(Id = fakeId, Phone__c = PRIMARY, Secondary_Phone__c = SECONDARY, Secondary_Phone_Entry__c = '9555555555');

        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ updated }, new Map<Id, Lead>{ fakeId => new Lead(Id = fakeId, Phone__c = PRIMARY, Secondary_Phone__c = SECONDARY) });

        Assert.isFalse(updated.hasErrors());
        Assert.areEqual('9555555555', updated.Secondary_Phone__c);
        Assert.isNull(updated.Secondary_Phone_Entry__c);
    }

    @IsTest
    static void handlesNullAndEmptyInput() {
        LeadPhoneEntryHandler.beforeSave(null, null);
        LeadPhoneEntryHandler.beforeSave(new List<Lead>(), null);
        Lead noId = entryLead(PRIMARY, null);
        LeadPhoneEntryHandler.beforeSave(new List<Lead>{ noId }, new Map<Id, Lead>());
        Assert.areEqual(PRIMARY, noId.Phone__c);
    }

    @IsTest
    static void handles200RecordsWithoutQueriesOrDml() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 200; i++) {
            leads.add(entryLead('98' + String.valueOf(10000000 + i), '97' + String.valueOf(10000000 + i)));
        }
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDmlStatements();

        Test.startTest();
        LeadPhoneEntryHandler.beforeSave(leads, null);
        Test.stopTest();

        Assert.areEqual(queriesBefore, Limits.getQueries(), 'No SOQL');
        Assert.areEqual(dmlBefore, Limits.getDmlStatements(), 'No DML');
        for (Integer i = 0; i < 200; i++) {
            Assert.areEqual('98' + String.valueOf(10000000 + i), leads[i].Phone__c);
            Assert.isNull(leads[i].Phone_Entry__c);
        }
    }

    // ---------------- through LeadTrigger (real saves) ----------------

    @IsTest
    static void leadCreatedWithEntryFieldsOnlyPassesValidationAndStoresNumbers() {
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;
        Lead lead = entryLead(PRIMARY, SECONDARY);

        Test.startTest();
        Database.SaveResult result = Database.insert(lead, options);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Phone__c is filled before the validation rule runs: ' + result.getErrors());
        Lead saved = [SELECT Phone__c, Secondary_Phone__c, Phone_Entry__c, Secondary_Phone_Entry__c FROM Lead WHERE Id = :lead.Id];
        Assert.isNotNull(saved.Phone__c, 'Number stored in the real field');
        Assert.isTrue(saved.Phone__c.contains(PRIMARY.right(8)), 'Same number (existing formatting may adjust it)');
        Assert.isNotNull(saved.Secondary_Phone__c);
        Assert.isNull(saved.Phone_Entry__c, 'Entry fields never keep the number');
        Assert.isNull(saved.Secondary_Phone_Entry__c);
    }

    @IsTest
    static void updateThroughTriggerChangesSecondaryAndBlocksPrimary() {
        Database.DMLOptions options = new Database.DMLOptions();
        options.DuplicateRuleHeader.allowSave = true;
        Lead lead = entryLead(PRIMARY, null);
        Database.insert(lead, options);

        Test.startTest();
        Lead secondaryChange = new Lead(Id = lead.Id, Secondary_Phone_Entry__c = SECONDARY);
        Database.SaveResult okResult = Database.update(secondaryChange, options);
        Lead primaryChange = new Lead(Id = lead.Id, Phone_Entry__c = '9000000000');
        Database.SaveResult blocked = Database.update(primaryChange, false);
        Test.stopTest();

        Assert.isTrue(okResult.isSuccess(), 'Secondary change allowed: ' + okResult.getErrors());
        Assert.isFalse(blocked.isSuccess(), 'Primary change blocked');
        Assert.areEqual(LeadPhoneEntryHandler.PRIMARY_LOCKED_MESSAGE, blocked.getErrors()[0].getMessage());
        Lead saved = [SELECT Phone__c, Secondary_Phone__c, Phone_Entry__c, Secondary_Phone_Entry__c FROM Lead WHERE Id = :lead.Id];
        Assert.isTrue(saved.Phone__c.contains(PRIMARY.right(8)), 'Primary unchanged');
        Assert.isTrue(saved.Secondary_Phone__c.contains(SECONDARY.right(8)), 'Secondary changed');
        Assert.isNull(saved.Phone_Entry__c);
        Assert.isNull(saved.Secondary_Phone_Entry__c);
    }
}
