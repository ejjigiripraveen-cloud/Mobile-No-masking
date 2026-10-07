@IsTest
private class PhoneRevealServiceTest {
    private static final String PRIMARY = '9876543221';

    @TestSetup
    static void setup() {
        User tl;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            tl = PhoneTestDataFactory.createUser('Standard User');
            PermissionSet revealSet = [SELECT Id FROM PermissionSet WHERE Name = 'Phone_Reveal' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = tl.Id, PermissionSetId = revealSet.Id);
        }
        List<Lead> leads = PhoneTestDataFactory.buildLeads(1, tl.Id);
        leads[0].Phone__c = PRIMARY;
        PhoneTestDataFactory.insertLeads(leads);
    }

    private static User teamLead() {
        return [SELECT Id FROM User WHERE Email LIKE 'mask.tester%' AND Profile.Name = 'Standard User' LIMIT 1];
    }

    private static Lead testLead() {
        return [SELECT Id, Phone__c FROM Lead LIMIT 1];
    }

    private static Phone_Access_Audit__c lastAudit() {
        return [SELECT Action__c, Outcome__c, Reason__c, Comment__c, Masked_Number__c, Channel__c, User__c
                FROM Phone_Access_Audit__c ORDER BY CreatedDate DESC, Name DESC LIMIT 1];
    }

    @IsTest
    static void permittedUserRevealsWithReasonAndIsAudited() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User tl = teamLead();
        Lead lead = testLead();

        PhoneRevealService.RevealResult result;
        Test.startTest();
        System.runAs(tl) {
            Assert.isTrue(PhoneRevealService.canReveal(), 'Phone_Reveal grants the custom permission');
            result = PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Site visit coordination', '  ');
        }
        Test.stopTest();

        Assert.areEqual(PRIMARY, result.phoneNumber);
        Assert.areEqual(30, result.seconds);
        Phone_Access_Audit__c audit = lastAudit();
        Assert.areEqual(MaskedDialService.ACTION_REVEAL, audit.Action__c);
        Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, audit.Outcome__c);
        Assert.areEqual('Site visit coordination', audit.Reason__c);
        Assert.isNull(audit.Comment__c, 'Blank comment stored as empty');
        Assert.areEqual('98XXXXXX21', audit.Masked_Number__c, 'Audit never stores the real number');
        Assert.areEqual(PhoneRevealService.CHANNEL, audit.Channel__c);
        Assert.areEqual(tl.Id, audit.User__c);
    }

    @IsTest
    static void otherReasonNeedsCommentAndStoresIt() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        System.runAs(teamLead()) {
            try {
                PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Other', null);
                Assert.fail('Comment required for Other');
            } catch (AuraHandledException e) {
                Assert.isTrue(e.getMessage().contains('comment'));
            }
            PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Other', ' Customer asked for a callback ');
        }

        Assert.areEqual('Customer asked for a callback', lastAudit().Comment__c);
    }

    @IsTest
    static void refusesUnknownReason() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = testLead();

        System.runAs(teamLead()) {
            for (String reason : new List<String>{ null, '', 'Curiosity' }) {
                try {
                    PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, reason, 'x');
                    Assert.fail('Reason must be one of the approved reasons');
                } catch (AuraHandledException e) {
                    Assert.areEqual('Please choose a reason.', e.getMessage());
                }
            }
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Phone_Access_Audit__c], 'Invalid input never reaches the service');
    }

    @IsTest
    static void refusesUserWithoutPermission() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneRevealService.permissionOverride = false;
        Lead lead = testLead();

        try {
            PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Management review', null);
            Assert.fail('Expected refusal');
        } catch (AuraHandledException e) {
            Assert.areEqual('You do not have permission to reveal phone numbers.', e.getMessage());
        }
    }

    @IsTest
    static void refusedByServiceIsAuditedAndReported() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.fieldsOverride = new List<Masked_Phone_Field__mdt>{
            PhoneTestDataFactory.approvedField('Lead_Phone', 'Lead', 'Phone__c', 'Primary', 1, true, false, true)
        };
        PhoneRevealService.permissionOverride = true;
        Lead lead = testLead();

        try {
            PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Management review', null);
            Assert.fail('Reveal not allowed on this field');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not approved'));
        }
        Phone_Access_Audit__c audit = lastAudit();
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, audit.Outcome__c);
        Assert.areEqual('Management review', audit.Reason__c);
    }

    @IsTest
    static void usesConfiguredSecondsAndListsReasons() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.settingOverride.Reveal_Seconds__c = 45;
        PhoneRevealService.permissionOverride = true;
        Lead lead = testLead();

        PhoneRevealService.RevealResult result =
            PhoneRevealService.revealNumber(lead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Number verification / correction', null);

        Assert.areEqual(45, result.seconds);
        Assert.areEqual(7, PhoneRevealService.getReasons().size());
        Assert.areEqual('Other', PhoneRevealService.getReasons()[6]);
    }

    @IsTest
    static void defaultSecondsWhenSettingMissing() {
        PhoneTestDataFactory.useTestConfig(true, true);
        PhoneMaskingConfig.settingOverride.Reveal_Seconds__c = null;
        PhoneRevealService.permissionOverride = true;

        PhoneRevealService.RevealResult result =
            PhoneRevealService.revealNumber(testLead().Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY, 'Management review', null);

        Assert.areEqual(30, result.seconds);
    }
}
