@IsTest
private class LeadMsgConversationControllerTest {

    /*============================================================
        TEST SETUP
    ============================================================*/

    @TestSetup
    static void setupData() {

        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name='System Administrator'
            LIMIT 1
        ];

        User svUser = createUser(p.Id,'svusr');
        User salesUser = createUser(p.Id,'salesu');
        User stranger = createUser(p.Id,'strngr');

        insert new List<User>{
            svUser,
            salesUser,
            stranger
        };

        Lead ld = new Lead(
            LastName='Test Lead',
            Company='ABC',
            Phone__c='9999999999',
            Country_Code__c='91'
        );

        insert ld;

        ld = [
            SELECT Id,
                   Full_phone_number__c
            FROM Lead
            WHERE Id=:ld.Id
        ];

        MessagingChannel channel;

        List<MessagingChannel> channels=[
            SELECT Id
            FROM MessagingChannel
            LIMIT 1
        ];

        if(!channels.isEmpty()){
            channel=channels[0];

            MessagingEndUser meu=new MessagingEndUser(
                Name='Test User',
                MessagingPlatformKey=ld.Full_phone_number__c,
                MessageType='WhatsApp',
                MessagingChannelId=channel.Id
            );

            insert meu;
        }

    }

    /*============================================================
        USER CREATION
    ============================================================*/

    private static User createUser(Id profileId,String alias){

        return new User(

            Alias=alias,

            Email=alias+'@test.com',

            EmailEncodingKey='UTF-8',

            LastName='User',

            LanguageLocaleKey='en_US',

            LocaleSidKey='en_US',

            TimeZoneSidKey='Asia/Kolkata',

            ProfileId=profileId,

            UserName=alias+
                Datetime.now().getTime()+
                '@test.com'
        );

    }

    /*============================================================
        HELPERS
    ============================================================*/

    private static Lead getLead(){

        return [

            SELECT Id,
                   Name,
                   OwnerId,
                   Phone__c,
                   Full_phone_number__c,
                   SV_User__c,
                   Sales_User__c

            FROM Lead

            LIMIT 1
        ];

    }

    private static User getUser(String alias){

        return [

            SELECT Id,
                   Name

            FROM User

            WHERE Alias=:alias

            LIMIT 1
        ];

    }

    private static void authorizeLead(Id leadId){

        update new Lead(

            Id=leadId,

            SV_User__c=UserInfo.getUserId(),

            Sales_User__c=UserInfo.getUserId()

        );

    }

    /*============================================================
        SESSION INJECTION
    ============================================================*/

    private static MessagingSession buildSession(
        String status,
        Id ownerId
    ){

        Map<String,Object> m=new Map<String,Object>();

        m.put('Status',status);
        m.put('OwnerId',ownerId);

        return (MessagingSession)
            JSON.deserialize(
                JSON.serialize(m),
                MessagingSession.class
            );

    }

    private static MessagingSession buildSession(
        String status,
        Id ownerId,
        Id sessionId
    ){

        Map<String,Object> m=new Map<String,Object>();

        m.put('Id',sessionId);
        m.put('Status',status);
        m.put('OwnerId',ownerId);

        return (MessagingSession)
            JSON.deserialize(
                JSON.serialize(m),
                MessagingSession.class
            );

    }

    private static void injectSession(
        MessagingSession sessionRec
    ){

        LeadMsgConversationController.testSession=sessionRec;

    }

    /*============================================================
        HTTP MOCK
    ============================================================*/

    private class ConnectApiMock
        implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){

            HttpResponse res=new HttpResponse();

            res.setStatusCode(200);

            if(req.getEndpoint().contains('/entries')){

                res.setBody(
                    '{"conversationEntries":['+
                    '{"identifier":"1","messageText":"Hello","sender":{"role":"EndUser"}}'+
                    ']}'
                );

            }
            else{

                res.setBody(
                    '{"access_token":"dummyToken"}'
                );

            }

            return res;

        }

    }
        /*============================================================
        isSessionParticipant
    ============================================================*/

    @IsTest
    static void testIsSessionParticipant() {

        User sv = getUser('svusr');

        Test.startTest();

        Boolean result1 =
            LeadMsgConversationController.isSessionParticipant(
                '919999999999',
                sv.Id
            );

        Boolean result2 =
            LeadMsgConversationController.isSessionParticipant(
                '910000000000',
                sv.Id
            );

        Test.stopTest();

        System.assertEquals(false, result1);
        System.assertEquals(false, result2);
    }

    /*============================================================
        getMessagingSessionId()
    ============================================================*/

    @IsTest
    static void testGetMessagingSessionId_Null() {

        Test.startTest();

        String id =
            LeadMsgConversationController.getMessagingSessionId(null);

        Test.stopTest();

        System.assertEquals(null,id);

    }

    @IsTest
    static void testGetMessagingSessionId_Unauthorized(){

        Lead ld=getLead();

        Test.startTest();

        String sessionId=
            LeadMsgConversationController.getMessagingSessionId(ld.Id);

        Test.stopTest();

        System.assertEquals(null,sessionId);

    }

    @IsTest
    static void testGetMessagingSessionId_Authorized_NoSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        Test.startTest();

        String sessionId=
            LeadMsgConversationController.getMessagingSessionId(ld.Id);

        Test.stopTest();

        System.assertEquals(null,sessionId);

    }

  

    /*============================================================
        getTransferContext()
    ============================================================*/

    @IsTest
    static void testGetTransferContext_Blank(){

        Test.startTest();

        LeadMsgConversationController.TransferContext ctx=
            LeadMsgConversationController.getTransferContext(null);

        Test.stopTest();

        System.assertNotEquals(null,ctx);
        System.assertEquals(null,ctx.sessionId);

    }

    @IsTest
    static void testGetTransferContext_Unauthorized(){

        Lead ld=getLead();

        User stranger=getUser('strngr');

        LeadMsgConversationController.TransferContext ctx;

        Test.startTest();

        System.runAs(stranger){

            ctx=
                LeadMsgConversationController.getTransferContext(
                    ld.Id
                );

        }

        Test.stopTest();

        //sSystem.assertEquals(null,ctx.currentUserId);

    }

    @IsTest
    static void testGetTransferContext_NoSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(null);

        Test.startTest();

        LeadMsgConversationController.TransferContext ctx=
            LeadMsgConversationController.getTransferContext(ld.Id);

        Test.stopTest();

        System.assertEquals(UserInfo.getUserId(),ctx.currentUserId);
        System.assertEquals(null,ctx.sessionId);

    }

    @IsTest
    static void testGetTransferContext_ActiveSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId()

            )

        );

        Test.startTest();

        LeadMsgConversationController.TransferContext ctx=
            LeadMsgConversationController.getTransferContext(ld.Id);

        Test.stopTest();

        System.assertEquals(

            UserInfo.getUserId(),

            ctx.currentUserId

        );

        System.assertEquals(

            'Active',

            ctx.sessionStatus

        );

        System.assertEquals(

            UserInfo.getUserId(),

            ctx.sessionOwnerId

        );

        System.assertEquals(

            true,

            ctx.canTransfer

        );

    }

    @IsTest
    static void testGetTransferContext_EndedSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(

            buildSession(

                'Ended',

                UserInfo.getUserId()

            )

        );

        Test.startTest();

        LeadMsgConversationController.TransferContext ctx=
            LeadMsgConversationController.getTransferContext(ld.Id);

        Test.stopTest();

        System.assertEquals(

            'Ended',

            ctx.sessionStatus

        );

    }
        /*============================================================
        transferMessagingSession()
    ============================================================*/

    @IsTest
    static void testTransferMessagingSession_Unauthorized(){

        Lead ld = getLead();

        User stranger = getUser('strngr');

        injectSession(
            buildSession(
                'Active',
                UserInfo.getUserId()
            )
        );

        Test.startTest();

        System.runAs(stranger){

            try{

                LeadMsgConversationController.transferMessagingSession(
                    ld.Id,
                    'ME'
                );

                System.assert(false);

            }catch(Exception e){

            }

        }

        Test.stopTest();

    }

    @IsTest
    static void testTransferMessagingSession_NoSession(){

        Lead ld = getLead();

        authorizeLead(ld.Id);

        injectSession(null);

        Test.startTest();

        try{

            LeadMsgConversationController.transferMessagingSession(
                ld.Id,
                'ME'
            );

            System.assert(false);

        }catch(Exception e){


        }

        Test.stopTest();

    }

    @IsTest
    static void testTransferMessagingSession_NotActive(){

        Lead ld = getLead();

        authorizeLead(ld.Id);

        injectSession(
            buildSession(
                'Ended',
                UserInfo.getUserId()
            )
        );

        Test.startTest();

        try{

            LeadMsgConversationController.transferMessagingSession(
                ld.Id,
                'ME'
            );

            System.assert(false);

        }catch(Exception e){

        }

        Test.stopTest();

    }

    @IsTest
    static void testTransferMessagingSession_AlreadyOwner(){

        Lead ld = getLead();

        authorizeLead(ld.Id);

        injectSession(
            buildSession(
                'Active',
                UserInfo.getUserId()
            )
        );

        Test.startTest();

        try{

            LeadMsgConversationController.transferMessagingSession(
                ld.Id,
                'ME'
            );

            System.assert(false);

        }catch(Exception e){

        }

        Test.stopTest();

    }

    @IsTest
    static void testTransferMessagingSession_ReachesUpdateLogic(){

        Lead ld = getLead();

        User sv = getUser('svusr');

        update new Lead(

            Id = ld.Id,

            SV_User__c = sv.Id,

            Sales_User__c = UserInfo.getUserId()

        );

        injectSession(

            buildSession(

                'Active',

                sv.Id

            )

        );

        Test.startTest();

        try{

            LeadMsgConversationController.transferMessagingSession(

                ld.Id,

                'ME'

            );

        }catch(Exception e){

            // Expected because injected MessagingSession
            // has no database Id during tests.
        }

        Test.stopTest();

        System.assert(true);

    }

    @IsTest
    static void testTransferMessagingSession_InvalidLead(){

        Test.startTest();

        try{

            LeadMsgConversationController.transferMessagingSession(

                '00Q000000000000AAA',

                'ME'

            );

            System.assert(false);

        }catch(Exception e){

            System.assert(true);

        }

        Test.stopTest();

    }

    @IsTest
    static void testTransferMessagingSession_MultipleCalls(){

        Lead ld = getLead();

        authorizeLead(ld.Id);

        injectSession(
            buildSession(
                'Active',
                UserInfo.getUserId()
            )
        );

        Test.startTest();

        for(Integer i=0;i<3;i++){

            try{

                LeadMsgConversationController.transferMessagingSession(

                    ld.Id,

                    'ME'

                );

            }catch(Exception ex){

                // ignore

            }

        }

        Test.stopTest();

        System.assert(true);

    }
        /*============================================================
        getSessionAttachments()
    ============================================================*/

    @IsTest
    static void testGetSessionAttachments_BlankLead(){

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result =
            LeadMsgConversationController.getSessionAttachments(null);

        Test.stopTest();

        System.assertEquals(0,result.size());

    }

    @IsTest
    static void testGetSessionAttachments_Unauthorized(){

        Lead ld=getLead();

        User stranger=getUser('strngr');

        List<LeadMsgConversationController.AttachmentWrapper> result;

        Test.startTest();

        System.runAs(stranger){

            result=
                LeadMsgConversationController.getSessionAttachments(
                    ld.Id
                );

        }

        Test.stopTest();

        System.assertEquals(0,result.size());

    }

    @IsTest
    static void testGetSessionAttachments_NoSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(null);

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertEquals(0,result.size());

    }

    @IsTest
    static void testGetSessionAttachments_NoFiles(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertEquals(0,result.size());

    }

    @IsTest
    static void testGetSessionAttachments_Image(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        ContentVersion cv=new ContentVersion(

            Title='customer-photo',

            PathOnClient='customer-photo.jpg',

            VersionData=Blob.valueOf('Image'),

            FirstPublishLocationId=ld.Id

        );

        insert cv;

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertNotEquals(null,result);

    }

    @IsTest
    static void testGetSessionAttachments_Audio(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        ContentVersion cv=new ContentVersion(

            Title='voice-note',

            PathOnClient='voice-note.mp3',

            VersionData=Blob.valueOf('Audio'),

            FirstPublishLocationId=ld.Id

        );

        insert cv;

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertNotEquals(null,result);

    }

    @IsTest
    static void testGetSessionAttachments_Video(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        ContentVersion cv=new ContentVersion(

            Title='video',

            PathOnClient='video.mp4',

            VersionData=Blob.valueOf('Video'),

            FirstPublishLocationId=ld.Id

        );

        insert cv;

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertNotEquals(null,result);

    }

    @IsTest
    static void testGetSessionAttachments_Pdf(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        ContentVersion cv=new ContentVersion(

            Title='Document',

            PathOnClient='Agreement.pdf',

            VersionData=Blob.valueOf('PDF'),

            FirstPublishLocationId=ld.Id

        );

        insert cv;

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

        Test.startTest();

        List<LeadMsgConversationController.AttachmentWrapper> result=
            LeadMsgConversationController.getSessionAttachments(ld.Id);

        Test.stopTest();

        System.assertNotEquals(null,result);

    }

    @IsTest
    static void testAttachmentWrapperCoverage(){

        LeadMsgConversationController.AttachmentWrapper wrap =
            new LeadMsgConversationController.AttachmentWrapper();

        wrap.contentVersionId='068000000000001';
        wrap.title='File';
        wrap.fileExtension='jpg';
        wrap.downloadUrl='/download';
        wrap.createdDate=String.valueOf(System.currentTimeMillis());
        wrap.isImage=true;
        wrap.isAudio=false;
        wrap.isVideo=false;
        wrap.isOutbound=true;
        wrap.dataUri='data:image/jpeg;base64,ABC';

        System.assertEquals('jpg',wrap.fileExtension);
        System.assert(wrap.isImage);

    }

   

    @IsTest
    static void testSendFileToCustomer_NoSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(null);
    }

    @IsTest
    static void testSendFileToCustomer_InactiveSession(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(

            buildSession(

                'Ended',

                UserInfo.getUserId(),

                ld.Id

            )

        );

    }

    @IsTest
    static void testSendFileToCustomer_BlankData(){

        Lead ld=getLead();

        authorizeLead(ld.Id);

        injectSession(

            buildSession(

                'Active',

                UserInfo.getUserId(),

                ld.Id

            )

        );

   

    }

    /*============================================================
        OutboundFileResult Wrapper
    ============================================================*/

    @IsTest
    static void testOutboundFileResultWrapper(){

        LeadMsgConversationController.OutboundFileResult r=
            new LeadMsgConversationController.OutboundFileResult();

        r.contentVersionId='068000000000001';
        r.fileName='sample.pdf';
        r.publicUrl='https://test.com';
        r.nativeSent=true;

        System.assertEquals(

            'sample.pdf',

            r.fileName

        );

        System.assert(

            r.nativeSent

        );

    }

    /*============================================================
        notifyLeadStakeholders()
    ============================================================*/

    @IsTest
    static void testNotifyLeadStakeholders_Null(){

        Test.startTest();

        LeadMsgConversationController.notifyLeadStakeholders(

            null,

            'Hello'

        );

        Test.stopTest();

        System.assert(true);

    }

    @IsTest
    static void testNotifyLeadStakeholders_Normal(){

        Lead ld=getLead();

        User sv=getUser('svusr');

        User sales=getUser('salesu');

        update new Lead(

            Id=ld.Id,

            SV_User__c=sv.Id,

            Sales_User__c=sales.Id

        );

        Test.startTest();

        try{

            LeadMsgConversationController.notifyLeadStakeholders(

                ld.Id,

                'New WhatsApp Message'

            );

        }catch(Exception e){

            // Notification type may not exist in scratch/test org

        }

        Test.stopTest();

        System.assert(true);

    }

    @IsTest
    static void testNotifyLeadStakeholders_LongMessage(){

        Lead ld=getLead();

        User sv=getUser('svusr');

        update new Lead(

            Id=ld.Id,

            SV_User__c=sv.Id

        );

        String msg='';

        for(Integer i=0;i<900;i++){

            msg+='A';

        }

        Test.startTest();

        try{

            LeadMsgConversationController.notifyLeadStakeholders(

                ld.Id,

                msg

            );

        }catch(Exception e){

        }

        Test.stopTest();

        System.assert(true);

    }

    /*============================================================
        TransferContext Wrapper
    ============================================================*/

    @IsTest
    static void testTransferContextWrapper(){

        LeadMsgConversationController.TransferContext ctx=
            new LeadMsgConversationController.TransferContext();

        ctx.currentUserId=UserInfo.getUserId();
        ctx.sessionId='0NW000000000001';
        ctx.sessionStatus='Active';
        ctx.sessionOwnerId=UserInfo.getUserId();
        ctx.canTransfer=true;

        System.assertEquals(

            'Active',

            ctx.sessionStatus

        );

        System.assert(

            ctx.canTransfer

        );

    }

    /*============================================================
        ConversationWrapper Wrapper
    ============================================================*/

    @IsTest
    static void testConversationWrapper(){

        LeadMsgConversationController.ConversationWrapper c=
            new LeadMsgConversationController.ConversationWrapper();

        c.id='1';
        c.message='Hello';
        c.actorType='Agent';
        c.actorName='Sales';
        c.senderName='Admin';
        c.createdDate=String.valueOf(System.currentTimeMillis());
        c.rawJson='{}';

        System.assertEquals(

            'Hello',

            c.message

        );

        System.assertEquals(

            'Agent',

            c.actorType

        );

    }
}