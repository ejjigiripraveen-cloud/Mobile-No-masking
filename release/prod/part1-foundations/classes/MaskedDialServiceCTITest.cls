@IsTest
private class MaskedDialServiceCTITest {
    @TestSetup
    static void setup() {
        User rep;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep = PhoneTestDataFactory.createUser('Standard User');
        }
        PhoneTestDataFactory.insertLeads(PhoneTestDataFactory.buildLeads(1, rep.Id));
    }

    private static User rep() {
        return [SELECT Id FROM User WHERE Email LIKE 'mask.tester%' AND Profile.Name = 'Standard User' LIMIT 1];
    }

    private static Map<String, Object> parse(String json) {
        return (Map<String, Object>) System.JSON.deserializeUntyped(json);
    }

    @IsTest
    static void returnsRealNumberToSoftphoneAsJson() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead testLead = [SELECT Id, Phone__c FROM Lead LIMIT 1];

        String response;
        Test.startTest();
        System.runAs(rep()) {
            response = MaskedDialServiceCTI.resolveForDial(testLead.Id, PhoneTestDataFactory.FIELD_KEY_PRIMARY);
        }
        Test.stopTest();

        Map<String, Object> body = parse(response);
        Assert.areEqual(true, body.get('success'), 'Message: ' + body.get('message'));
        Assert.areEqual(testLead.Phone__c, body.get('phoneNumber'));
        Assert.areEqual(PhoneMaskUtil.mask(testLead.Phone__c), body.get('maskedNumber'));
        Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, body.get('outcome'));

        Phone_Access_Audit__c audit = [SELECT Channel__c, Action__c FROM Phone_Access_Audit__c LIMIT 1];
        Assert.areEqual(MaskedDialServiceCTI.DEFAULT_CHANNEL, audit.Channel__c);
        Assert.areEqual(MaskedDialService.ACTION_DIAL, audit.Action__c);
    }

    @IsTest
    static void acceptsFifteenCharacterId() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        String response;
        System.runAs(rep()) {
            response = MaskedDialServiceCTI.resolveForDial(String.valueOf(testLead.Id).left(15), PhoneTestDataFactory.FIELD_KEY_PRIMARY);
        }

        Assert.areEqual(true, parse(response).get('success'));
    }

    @IsTest
    static void rejectsInvalidRecordId() {
        PhoneTestDataFactory.useTestConfig(true, true);

        for (String badId : new List<String>{ null, '', 'not-an-id', '<script>' }) {
            Map<String, Object> body = parse(MaskedDialServiceCTI.resolveForDial(badId, PhoneTestDataFactory.FIELD_KEY_PRIMARY));
            Assert.areEqual(false, body.get('success'));
            Assert.areEqual(MaskedDialService.OUTCOME_DENIED, body.get('outcome'));
            Assert.isNull(body.get('phoneNumber'));
        }
        Assert.areEqual(0, [SELECT COUNT() FROM Phone_Access_Audit__c], 'Invalid ids never reach the service');
    }

    @IsTest
    static void deniesUnapprovedFieldWithoutNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];

        Map<String, Object> body;
        System.runAs(rep()) {
            body = parse(MaskedDialServiceCTI.resolveForDial(testLead.Id, 'Lead.Email'));
        }

        Assert.areEqual(false, body.get('success'));
        Assert.isNull(body.get('phoneNumber'));
    }

    @IsTest
    static void usesAssignedCallCenterNameAsChannel() {
        // Call centers are setup data, visible to tests without SeeAllData.
        List<CallCenter> centers = [SELECT Id, Name FROM CallCenter ORDER BY Name LIMIT 1];
        if (centers.isEmpty()) {
            return; // Org without call centers: covered by usesDefaultChannelWithoutCallCenter.
        }
        User rep = rep();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep.CallCenterId = centers[0].Id;
            update rep;
        }

        String channel;
        System.runAs(rep) {
            channel = MaskedDialServiceCTI.currentChannel();
        }
        Assert.areEqual(centers[0].Name, channel);
    }

    @IsTest
    static void usesDefaultChannelWithoutCallCenter() {
        String channel;
        System.runAs(rep()) {
            channel = MaskedDialServiceCTI.currentChannel();
        }
        Assert.areEqual(MaskedDialServiceCTI.DEFAULT_CHANNEL, channel);
    }
}
