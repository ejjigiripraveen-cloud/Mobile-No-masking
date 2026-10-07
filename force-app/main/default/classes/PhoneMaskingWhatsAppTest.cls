/**
 * @description Tests the masking added in v1.5.0 (Part 5e) to LeadMsgConversationController: numbers inside the
 *              WhatsApp conversation (message text, raw Messaging data, sender name) are masked for users who cannot
 *              see Lead.Phone__c. The conversation itself comes from the Salesforce Connect API, which tests cannot
 *              call, so the masking helper is tested directly. The existing test class is unchanged.
 */
@IsTest
private class PhoneMaskingWhatsAppTest {
    private static final String CUSTOMER = '919876543221';

    private static List<LeadMsgConversationController.ConversationWrapper> sampleConversation() {
        LeadMsgConversationController.ConversationWrapper fromCustomer = new LeadMsgConversationController.ConversationWrapper();
        fromCustomer.id = 'm1';
        fromCustomer.actorType = 'EndUser';
        fromCustomer.senderName = 'Test Lead';
        fromCustomer.message = 'Please call my other number 9123456780 after 5 pm';
        fromCustomer.rawJson = '{"sender":{"appType":"EndUser","subject":"whatsapp:+' + CUSTOMER + '"},"messageText":"hi"}';

        LeadMsgConversationController.ConversationWrapper fromAgent = new LeadMsgConversationController.ConversationWrapper();
        fromAgent.id = 'm2';
        fromAgent.actorType = 'Agent';
        fromAgent.senderName = 'Agent';
        fromAgent.message = 'Sure, we will call you on plot 42.';
        fromAgent.rawJson = null;

        return new List<LeadMsgConversationController.ConversationWrapper>{ fromCustomer, fromAgent };
    }

    @IsTest
    static void conversationMaskedForMaskedUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = true;
        List<LeadMsgConversationController.ConversationWrapper> rows = sampleConversation();

        LeadMsgConversationController.maskConversationForUser(rows);

        Assert.areEqual('Please call my other number 91XXXXXX80 after 5 pm', rows[0].message, 'Typed number masked');
        Assert.isFalse(rows[0].rawJson.contains(CUSTOMER), 'WhatsApp number removed from the raw data');
        Assert.isTrue(rows[0].rawJson.contains('98XXXXXX21'), 'Raw data keeps its shape, number masked');
        Assert.areEqual('Test Lead', rows[0].senderName);
        Assert.areEqual('Sure, we will call you on plot 42.', rows[1].message, 'Text without numbers unchanged');
        Assert.isNull(rows[1].rawJson);
    }

    @IsTest
    static void conversationUnchangedForOtherUsers() {
        PhoneMaskingConfig.settingOverride = PhoneMaskingConfig.defaultSetting();
        PhoneDisplayService.maskedUserOverride = false;
        List<LeadMsgConversationController.ConversationWrapper> rows = sampleConversation();

        LeadMsgConversationController.maskConversationForUser(rows);

        Assert.isTrue(rows[0].message.contains('9123456780'), 'Users who can see numbers: unchanged');
        Assert.isTrue(rows[0].rawJson.contains(CUSTOMER));
    }

    @IsTest
    static void handlesNullList() {
        PhoneDisplayService.maskedUserOverride = true;
        LeadMsgConversationController.maskConversationForUser(null);
        Assert.isTrue(true, 'No error on null');
    }
}
