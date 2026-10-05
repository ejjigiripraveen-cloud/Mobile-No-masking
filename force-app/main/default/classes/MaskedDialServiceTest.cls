@IsTest
private class MaskedDialServiceTest {
    private static final String REP_EMAIL_PREFIX = 'mask.tester';

    @TestSetup
    static void setup() {
        User rep;
        User noAccess;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep = PhoneTestDataFactory.createUser('Standard User');
            noAccess = PhoneTestDataFactory.createUser('Minimum Access - Salesforce');
        }
        // One Lead owned by the rep (rep can see it), with both numbers.
        List<Lead> repLeads = PhoneTestDataFactory.buildLeads(1, rep.Id);
        repLeads[0].LastName = 'Rep Owned Lead';
        // One Lead owned by the rep without a secondary number.
        List<Lead> noSecondary = PhoneTestDataFactory.buildLeads(1, rep.Id);
        noSecondary[0].LastName = 'No Secondary Lead';
        noSecondary[0].Phone__c = PhoneTestDataFactory.primaryNumber(500);
        noSecondary[0].Secondary_Phone__c = null;
        // One Lead owned by the running admin (visibility to the rep depends on org sharing).
        List<Lead> adminLeads = PhoneTestDataFactory.buildLeads(1, UserInfo.getUserId());
        adminLeads[0].LastName = 'Admin Owned Lead';
        adminLeads[0].Phone__c = PhoneTestDataFactory.primaryNumber(600);
        adminLeads[0].Secondary_Phone__c = PhoneTestDataFactory.secondaryNumber(600);

        List<Lead> allLeads = new List<Lead>();
        allLeads.addAll(repLeads);
        allLeads.addAll(noSecondary);
        allLeads.addAll(adminLeads);
        PhoneTestDataFactory.insertLeads(allLeads);
    }

    private static User rep() {
        return [SELECT Id FROM User WHERE Email LIKE :REP_EMAIL_PREFIX + '%' AND Profile.Name = 'Standard User' LIMIT 1];
    }

    private static User noAccessUser() {
        return [SELECT Id FROM User WHERE Email LIKE :REP_EMAIL_PREFIX + '%' AND Profile.Name = 'Minimum Access - Salesforce' LIMIT 1];
    }

    private static Lead leadNamed(String lastName) {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    private static List<Phone_Access_Audit__c> audits() {
        return [
            SELECT Action__c, Outcome__c, User__c, Record_Id__c, Object_Name__c, Field_Key__c,
                   Masked_Number__c, Channel__c, Message__c, Event_Time__c
            FROM Phone_Access_Audit__c
            ORDER BY Name
        ];
    }

    @IsTest
    static void resolvesPrimaryNumberForRecordOwner() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User rep = rep();
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        Test.startTest();
        System.runAs(rep) {
            result = MaskedDialService.resolveOne(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');
        }
        Test.stopTest();

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, result.outcome);
        Assert.areEqual(ownLead.Phone__c, result.phoneNumber, 'Real number returned to the server-side caller');
        Assert.areEqual(PhoneMaskUtil.mask(ownLead.Phone__c), result.maskedNumber);

        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(1, rows.size());
        Assert.areEqual(MaskedDialService.ACTION_DIAL, rows[0].Action__c);
        Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, rows[0].Outcome__c);
        Assert.areEqual(rep.Id, rows[0].User__c);
        Assert.areEqual(String.valueOf(ownLead.Id), rows[0].Record_Id__c);
        Assert.areEqual('Lead', rows[0].Object_Name__c);
        Assert.areEqual('MCube', rows[0].Channel__c);
        Assert.areEqual(result.maskedNumber, rows[0].Masked_Number__c);
        Assert.areNotEqual(ownLead.Phone__c, rows[0].Masked_Number__c, 'Audit never stores the real number');
        Assert.isNotNull(rows[0].Event_Time__c);
    }

    @IsTest
    static void resolvesSecondaryNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_SECONDARY, 'SlashRTC');
        }

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(ownLead.Secondary_Phone__c, result.phoneNumber);
    }

    @IsTest
    static void fieldKeyIsCaseInsensitiveAndTrimmed() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(ownLead.Id, '  lead.PHONE__c ', 'MCube');
        }

        Assert.isTrue(result.success, result.message);
    }

    @IsTest
    static void followsTodaysRecordAccessForOtherUsersLeads() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User rep = rep();
        Lead adminLead = leadNamed('Admin Owned Lead');
        // Expected result is whatever access the rep has today under the org's sharing settings.
        Boolean repCanRead = [
            SELECT RecordId, HasReadAccess FROM UserRecordAccess
            WHERE UserId = :rep.Id AND RecordId = :adminLead.Id
        ].HasReadAccess;

        MaskedDialService.DialResult result;
        System.runAs(rep) {
            result = MaskedDialService.resolveOne(adminLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');
        }

        Assert.areEqual(repCanRead, result.success, 'Dial access must match record access: ' + result.message);
        if (!repCanRead) {
            Assert.areEqual(MaskedDialService.OUTCOME_DENIED, result.outcome);
            Assert.isNull(result.phoneNumber, 'No number released without record access');
            Assert.areEqual(MaskedDialService.OUTCOME_DENIED, audits()[0].Outcome__c);
        }
    }

    @IsTest
    static void deniesUserWithoutLeadAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(noAccessUser()) {
            result = MaskedDialService.resolveOne(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');
        }

        Assert.isFalse(result.success);
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, result.outcome);
        Assert.isNull(result.phoneNumber);
        List<Phone_Access_Audit__c> rows = audits();
        Assert.areEqual(1, rows.size(), 'Denied requests are audited too');
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, rows[0].Outcome__c);
        Assert.isNull(rows[0].Masked_Number__c);
    }

    @IsTest
    static void deniesFieldNotOnApprovedList() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(ownLead.Id, 'Lead.Email', 'MCube');
        }

        Assert.isFalse(result.success);
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, result.outcome);
        Assert.isTrue(result.message.contains('not approved'));
    }

    @IsTest
    static void deniesInactiveOrDialDisabledField() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Lead_Phone', 'Lead', 'Phone__c', 'Primary', 1, false, true, true),
            PhoneTestDataFactory.approvedField('Lead_Secondary_Phone', 'Lead', 'Secondary_Phone__c', 'Secondary', 2, true, true, false)
        };
        Lead ownLead = leadNamed('Rep Owned Lead');

        List<MaskedDialService.DialResult> results;
        System.runAs(rep()) {
            results = MaskedDialService.resolve(new List<MaskedDialService.DialRequest>{
                new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube'),
                new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_SECONDARY, 'MCube')
            }, MaskedDialService.ACTION_DIAL);
        }

        Assert.isFalse(results[0].success, 'Dial not allowed on this field');
        Assert.isFalse(results[1].success, 'Inactive field');
    }

    @IsTest
    static void revealUsesAllowRevealFlag() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Lead_Phone', 'Lead', 'Phone__c', 'Primary', 1, true, false, true),
            PhoneTestDataFactory.approvedField('Lead_Secondary_Phone', 'Lead', 'Secondary_Phone__c', 'Secondary', 2, true, true, true)
        };
        Lead ownLead = leadNamed('Rep Owned Lead');

        List<MaskedDialService.DialResult> results;
        System.runAs(rep()) {
            MaskedDialService.DialRequest primary =
                new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Reveal');
            MaskedDialService.DialRequest secondary =
                new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_SECONDARY, 'Reveal');
            secondary.reason = 'Customer requested call back';
            results = MaskedDialService.resolve(
                new List<MaskedDialService.DialRequest>{ primary, secondary }, MaskedDialService.ACTION_REVEAL
            );
        }

        Assert.isFalse(results[0].success, 'Reveal not allowed on primary in this configuration');
        Assert.isTrue(results[1].success, results[1].message);
        List<Phone_Access_Audit__c> rows = [
            SELECT Action__c, Reason__c FROM Phone_Access_Audit__c WHERE Outcome__c = :MaskedDialService.OUTCOME_SUCCESS
        ];
        Assert.areEqual(1, rows.size());
        Assert.areEqual(MaskedDialService.ACTION_REVEAL, rows[0].Action__c);
        Assert.areEqual('Customer requested call back', rows[0].Reason__c);
    }

    @IsTest
    static void deniesUnknownAction() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        List<MaskedDialService.DialResult> results = MaskedDialService.resolve(
            new List<MaskedDialService.DialRequest>{
                new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Test')
            },
            'Export'
        );

        Assert.isFalse(results[0].success);
    }

    @IsTest
    static void deniesFieldFromAnotherObject() {
        PhoneTestDataFactory.useTestConfig(true, true);

        MaskedDialService.DialResult result =
            MaskedDialService.resolveOne(UserInfo.getUserId(), PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');

        Assert.isFalse(result.success);
        Assert.isTrue(result.message.contains('does not belong'));
    }

    @IsTest
    static void reportsErrorForMisconfiguredField() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Broken', 'Lead', 'Does_Not_Exist__c', 'Broken', 1, true, true, true)
        };
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result =
            MaskedDialService.resolveOne(ownLead.Id, 'Lead.Does_Not_Exist__c', 'MCube');

        Assert.isFalse(result.success);
        Assert.areEqual(MaskedDialService.OUTCOME_ERROR, result.outcome);
    }

    @IsTest
    static void returnsNotFoundWhenNumberIsBlank() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('No Secondary Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(lead.Id, PhoneTestDataFactory.FIELD_KEY_SECONDARY, 'MCube');
        }

        Assert.isFalse(result.success);
        Assert.areEqual(MaskedDialService.OUTCOME_NOT_FOUND, result.outcome);
    }

    @IsTest
    static void deniesDeletedRecord() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('No Secondary Lead');
        Utility.bypassLeadTrigger = true;
        delete lead;
        Utility.bypassLeadTrigger = false;

        MaskedDialService.DialResult result =
            MaskedDialService.resolveOne(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');

        Assert.isFalse(result.success);
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, result.outcome);
    }

    @IsTest
    static void deniesMissingRecordOrField() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        List<MaskedDialService.DialResult> results = MaskedDialService.resolve(
            new List<MaskedDialService.DialRequest>{
                null,
                new MaskedDialService.DialRequest(null, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube'),
                new MaskedDialService.DialRequest(ownLead.Id, ' ', 'MCube')
            },
            MaskedDialService.ACTION_DIAL
        );

        Assert.areEqual(3, results.size());
        for (MaskedDialService.DialResult result : results) {
            Assert.isFalse(result.success);
            Assert.areEqual(MaskedDialService.OUTCOME_DENIED, result.outcome);
        }
        Assert.areEqual(0, MaskedDialService.resolve(null, MaskedDialService.ACTION_DIAL).size());
        Assert.areEqual(0, MaskedDialService.resolve(new List<MaskedDialService.DialRequest>(), MaskedDialService.ACTION_DIAL).size());
    }

    @IsTest
    static void killSwitchDeniesEverything() {
        PhoneTestDataFactory.useTestConfig(false, true);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');
        }

        Assert.isFalse(result.success);
        Assert.isTrue(result.message.contains('switched off'));
        Assert.areEqual(1, audits().size(), 'Refusals are still audited');
    }

    @IsTest
    static void skipsAuditWhenAuditDisabled() {
        PhoneTestDataFactory.useTestConfig(true, false);
        Lead ownLead = leadNamed('Rep Owned Lead');

        MaskedDialService.DialResult result;
        System.runAs(rep()) {
            result = MaskedDialService.resolveOne(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube');
        }

        Assert.isTrue(result.success, result.message);
        Assert.areEqual(0, audits().size());
    }

    @IsTest
    static void deniesMoreThanMaxRequests() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead ownLead = leadNamed('Rep Owned Lead');
        List<MaskedDialService.DialRequest> requests = new List<MaskedDialService.DialRequest>();
        for (Integer i = 0; i <= MaskedDialService.MAX_REQUESTS; i++) {
            requests.add(new MaskedDialService.DialRequest(ownLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube'));
        }

        List<MaskedDialService.DialResult> results = MaskedDialService.resolve(requests, MaskedDialService.ACTION_DIAL);

        Assert.areEqual(MaskedDialService.MAX_REQUESTS + 1, results.size());
        for (MaskedDialService.DialResult result : results) {
            Assert.isFalse(result.success);
        }
    }

    @IsTest
    static void resolves200LeadsWithinLimits() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User rep = rep();
        List<Lead> bulkLeads = PhoneTestDataFactory.buildLeads(200, rep.Id);
        for (Integer i = 0; i < bulkLeads.size(); i++) {
            bulkLeads[i].LastName = 'Bulk Lead ' + i;
            bulkLeads[i].Phone__c = PhoneTestDataFactory.primaryNumber(1000 + i);
            bulkLeads[i].Secondary_Phone__c = PhoneTestDataFactory.secondaryNumber(1000 + i);
        }
        PhoneTestDataFactory.insertLeads(bulkLeads);

        List<MaskedDialService.DialRequest> requests = new List<MaskedDialService.DialRequest>();
        for (Lead bulkLead : bulkLeads) {
            requests.add(new MaskedDialService.DialRequest(bulkLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'MCube'));
        }

        List<MaskedDialService.DialResult> results;
        Integer queriesUsed;
        Integer dmlUsed;
        Test.startTest();
        System.runAs(rep) {
            Integer queriesBefore = Limits.getQueries();
            Integer dmlBefore = Limits.getDmlStatements();
            results = MaskedDialService.resolve(requests, MaskedDialService.ACTION_DIAL);
            queriesUsed = Limits.getQueries() - queriesBefore;
            dmlUsed = Limits.getDmlStatements() - dmlBefore;
        }
        Test.stopTest();

        Assert.areEqual(200, results.size());
        for (Integer i = 0; i < results.size(); i++) {
            Assert.isTrue(results[i].success, results[i].message);
            Assert.areEqual(bulkLeads[i].Phone__c, results[i].phoneNumber, 'Results keep request order');
        }
        Assert.areEqual(1, queriesUsed, 'One query for all 200 Leads');
        Assert.areEqual(1, dmlUsed, 'One insert for all 200 audit rows');
        Assert.areEqual(200, [SELECT COUNT() FROM Phone_Access_Audit__c]);
    }
}
