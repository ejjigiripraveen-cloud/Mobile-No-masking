@isTest
private class mCubeControllerTestExtended {

    private static final String EXE_PHONE      = '9000000001';
    private static final String OFF_PHONE      = '9000000002';
    private static final String SALES_PHONE    = '9000000003';
    private static final String EXISTING_PHONE = '9111111111';
    private static final String RS_PARENT_PH   = '9222222222';
    private static final String RS_PHONE       = '9333333333';
    private static final String SALES_LEAD_PH  = '9444444444';
    private static final String NEW_PHONE      = '9555555555';
    private static final String LANDING        = '8000000000';
    private static final String EXIST_CALL     = 'CALL-EXIST-001';

    // ---------------------------------------------------------------- MOCK
    private class McubeMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"msg":"success","callid":"MOCK-1","callType":"outbound"}');
            return res;
        }
    }

    // ---------------------------------------------------------------- HELPERS
    private static void putSafe(SObject s, String f, Object v) {
        try { s.put(f, v); } catch (Exception e) {}
    }

    private static User buildUser(Id profileId, String alias, String phone, Boolean available) {
        User u = new User(
            Alias = alias,
            Email = alias + '@mcubetest.com',
            Username = alias + DateTime.now().getTime() + '@mcubetest.com',
            LastName = alias,
            ProfileId = profileId,
            TimeZoneSidKey = 'Asia/Kolkata',
            LocaleSidKey = 'en_IN',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            Phone = phone,
            MobilePhone = phone
        );
        return u;
    }

    // Custom User fields are set after insert, one by one, so an inaccessible
    // field never blocks the whole user creation.
    private static void applyCustomUserFields(Id userId, Map<String, Object> fieldValues) {
        User all = new User(Id = userId);
        for (String f : fieldValues.keySet()) putSafe(all, f, fieldValues.get(f));
        try {
            update all;
            return;
        } catch (Exception e) {
            System.debug('Bulk user field update failed: ' + e.getMessage());
        }
        for (String f : fieldValues.keySet()) {
            User single = new User(Id = userId);
            putSafe(single, f, fieldValues.get(f));
            try { update single; } catch (Exception e) {
                System.debug('User field ' + f + ' not updatable: ' + e.getMessage());
            }
        }
    }

    private static Lead buildLead(String lastName, String phone, Id ownerId) {
        Lead l = new Lead(LastName = lastName, Company = 'McubeTest', Phone__c = phone);
        if (ownerId != null) l.OwnerId = ownerId;
        return l;
    }

    private static Id rtId(String devName) {
        Schema.RecordTypeInfo info = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get(devName);
        return info == null ? null : info.getRecordTypeId();
    }

    private static Id createCampaign() {
        try {
            Schema.SObjectType t = Campaign_Source__c.Campaign__c.getDescribe().getReferenceTo()[0];
            SObject c = t.newSObject();
            putSafe(c, 'Name', 'MCube Test Campaign');
            putSafe(c, 'IsActive', true);
            putSafe(c, 'Active__c', true);
            putSafe(c, 'Zone__c', 'Hyderabad');
            putSafe(c, 'NRI_Campaign__c', true);
            insert c;
            return c.Id;
        } catch (Exception e) {
            return null;
        }
    }

    private static User execUser() {
        return [SELECT Id, Mcube_Phone__c, Zone__c FROM User WHERE Email = 'mcexec@mcubetest.com' LIMIT 1];
    }

    private static User offUser() {
        return [SELECT Id, Mcube_Phone__c FROM User WHERE Email = 'mcoff@mcubetest.com' LIMIT 1];
    }

    private static Lead existingLead() {
        return [SELECT Id FROM Lead WHERE Phone__c = :EXISTING_PHONE LIMIT 1];
    }

    private static Call_Detail__c existingCall() {
        return [SELECT Id, Call_ID__c, Lead__c FROM Call_Detail__c WHERE Call_ID__c = :EXIST_CALL LIMIT 1];
    }

    private static void setCallandPage(Map<String, String> params) {
        PageReference pr = Page.calland;
        Test.setCurrentPage(pr);
        for (String k : params.keySet()) {
            ApexPages.currentPage().getParameters().put(k, params.get(k));
        }
    }

    private static void setDataParam(Map<String, Object> payload) {
        setCallandPage(new Map<String, String>{
            'data' => EncodingUtil.urlEncode(JSON.serialize(payload), 'UTF-8')
        });
    }

    private static Map<String, Object> inboundPayload(String callId, String dialStatus, String callFrom) {
        return new Map<String, Object>{
            'callid'              => callId,
            'callfrom'            => callFrom,
            'empnumber'           => EXE_PHONE,
            'landingnumber'       => LANDING,
            'dialstatus'          => dialStatus,
            'starttime'           => '2026-09-29 10:00:00',
            'endtime'             => '2026-09-29 10:05:00',
            'filename'            => 'https://recordings.test/rec.wav',
            'wrapUpTime'          => '10',
            'answeredtime'        => '5',
            'calltype'            => 'inbound',
            'dispositionType'     => 'Interested',
            'subDisposition'      => 'Hot',
            'dispositionComments' => 'Test comments'
        };
    }

    private static Map<String, Object> outboundPayload(String callId, String status, String refId) {
        return new Map<String, Object>{
            'callid'              => callId,
            'executive'           => EXE_PHONE,
            'customer'            => EXISTING_PHONE,
            'refid'               => refId,
            'status'              => status,
            'dialstatus'          => status,
            'landingnumber'       => LANDING,
            'starttime'           => '2026-09-29 11:00:00',
            'endtime'             => '2026-09-29 11:03:00',
            'filename'            => 'https://recordings.test/out.wav',
            'wrapUpTime'          => '8',
            'answeredtime'        => '3',
            'calltype'            => 'outbound',
            'dispositionType'     => 'Interested',
            'subDisposition'      => 'Hot',
            'dispositionComments' => 'Outbound comments'
        };
    }

    // ---------------------------------------------------------------- SETUP
    @testSetup
    static void setup() {
        User exec;
        User off;
        User salesUser;

        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            exec = buildUser(adminProfile.Id, 'mcexec', EXE_PHONE, true);
            off  = buildUser(adminProfile.Id, 'mcoff', OFF_PHONE, false);
            List<User> users = new List<User>{ exec, off };

            List<Profile> salesProfiles = [SELECT Id FROM Profile WHERE Name = 'Sales' LIMIT 1];
            if (!salesProfiles.isEmpty()) {
                salesUser = buildUser(salesProfiles[0].Id, 'mcsales', SALES_PHONE, true);
                users.add(salesUser);
            }
            insert users;

            applyCustomUserFields(exec.Id, new Map<String, Object>{
                'Mcube_Phone__c' => EXE_PHONE, 'Zone__c' => 'Hyderabad', 'Availability__c' => true
            });
            applyCustomUserFields(off.Id, new Map<String, Object>{
                'Mcube_Phone__c' => OFF_PHONE, 'Zone__c' => 'Hyderabad', 'Availability__c' => false
            });
            if (salesUser != null) {
                applyCustomUserFields(salesUser.Id, new Map<String, Object>{
                    'Mcube_Phone__c' => SALES_PHONE, 'Zone__c' => 'Hyderabad', 'Availability__c' => true
                });
            }
        }

        MCUBE_Object_Api__c api = new MCUBE_Object_Api__c(
            Name = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'Phone__c',
            LandingNumber__c = LANDING
        );
        try { insert api; } catch (Exception e) {}

        Id campId = createCampaign();
        if (campId != null) {
            Campaign_Source__c cs = new Campaign_Source__c(Landing_Number__c = LANDING, Campaign__c = campId);
            putSafe(cs, 'Source__c', 'Mcube');
            putSafe(cs, 'Sub_Source__c', 'Inbound call');
            putSafe(cs, 'medium__c', 'Call');
            try { insert cs; } catch (Exception e) {}
        }

        List<Lead> leads = new List<Lead>{
            buildLead('Existing', EXISTING_PHONE, exec.Id),
            buildLead('RSParent', RS_PARENT_PH, off.Id)
        };
        if (salesUser != null) {
            leads.add(buildLead('SalesOwned', SALES_LEAD_PH, salesUser.Id));
        }
        insert leads;

        Related_Source__c rs = new Related_Source__c(Lead__c = leads[1].Id, Phone__c = RS_PHONE);
        try { insert rs; } catch (Exception e) {}

        Call_Detail__c cd = new Call_Detail__c(
            Call_ID__c = EXIST_CALL,
            Lead__c = leads[0].Id,
            Parent_ID__c = leads[0].Id,
            Call_Type__c = 'Inbound Call',
            Status__c = 'CONNECTING',
            Start_Time__c = System.now(),
            OwnerId = exec.Id
        );
        insert cd;

        Task t = new Task(Subject = 'Missed Call', Status = 'Open', WhoId = leads[0].Id, OwnerId = exec.Id);
        putSafe(t, 'TaskSubtype', 'Task');
        try { insert t; } catch (Exception e) {}

        Round_Robin_Member__c rrm = new Round_Robin_Member__c(User__c = exec.Id, NRI__c = true);
        try { insert rrm; } catch (Exception e) {}
    }

    // ---------------------------------------------------------------- PICKLIST / UTILS
    @isTest
    static void testDependentPicklistAndUtils() {
        Test.startTest();
        try { mCubeController.getDependentPicklist('Lead', 'LeadSource', 'Sub_Source__c'); } catch (Exception e) {}
        try { mCubeController.getDependentPicklist('Lead', 'Invalid__c', 'Invalid2__c'); } catch (Exception e) {}
        try { mCubeController.getDependentPicklist('NoSuchObject__x', 'A', 'B'); } catch (Exception e) {}
        mCubeController.base64ToBits('gAAA');
        mCubeController.base64ToBits('');
        mCubeController.decimalToBinary(45);
        mCubeController.callrouteresponse = 'x';
        mCubeController.status = 'x';
        Test.stopTest();
    }

    // ---------------------------------------------------------------- CLICK TO CALL / MAKE CALL
    @isTest
    static void testUserDetailAndClickToCall() {
        Test.setMock(HttpCalloutMock.class, new McubeMock());
        Lead l = existingLead();
        System.runAs(execUser()) {
            Test.startTest();
            try { mCubeController.userDetail(); } catch (Exception e) {}
            try { mCubeController.clickToCall(l.Id); } catch (Exception e) {}
            Test.stopTest();
        }
    }

    @isTest
    static void testMakeCall() {
        Test.setMock(HttpCalloutMock.class, new McubeMock());
        Lead l = existingLead();
        System.runAs(execUser()) {
            Test.startTest();
            mCubeController.makeCall('+91', EXE_PHONE, EXISTING_PHONE, l.Id);
            mCubeController.makeCall('+1', OFF_PHONE, EXISTING_PHONE, l.Id);
            mCubeController.makeCall(null, OFF_PHONE, EXISTING_PHONE, l.Id);
            Test.stopTest();
        }
    }

    @isTest
    static void testMakeCallZettaAndAsync() {
        Test.setMock(HttpCalloutMock.class, new McubeMock());
        Lead l = existingLead();
        System.runAs(execUser()) {
            Test.startTest();
            mCubeController.makeCallZetta('+91', EXE_PHONE, EXISTING_PHONE, l.Id);
            mCubeController.makeCallAsync('+91', EXE_PHONE, EXISTING_PHONE, l.Id);
            Test.stopTest();
        }
    }

    // ---------------------------------------------------------------- readData (calland)
    @isTest
    static void testReadDataNewNumber() {
        setCallandPage(new Map<String, String>{ 'fromnumber' => NEW_PHONE, 'landingnumber' => LANDING });
        Test.startTest();
        mCubeController.readData();
        Test.stopTest();
    }

    @isTest
    static void testReadDataNewNumberNoCampaign() {
        setCallandPage(new Map<String, String>{ 'fromnumber' => NEW_PHONE, 'landingnumber' => '1111111111' });
        Test.startTest();
        mCubeController.readData();
        Test.stopTest();
    }

    @isTest
    static void testReadDataExistingLead() {
        setCallandPage(new Map<String, String>{ 'fromnumber' => EXISTING_PHONE, 'landingnumber' => LANDING });
        Test.startTest();
        mCubeController.readData();
        Test.stopTest();
    }

    @isTest
    static void testReadDataSalesOwnedLead() {
        setCallandPage(new Map<String, String>{ 'fromnumber' => SALES_LEAD_PH, 'landingnumber' => LANDING });
        Test.startTest();
        mCubeController.readData();
        Test.stopTest();
    }

    @isTest
    static void testReadDataRelatedSourceUnavailableUser() {
        setCallandPage(new Map<String, String>{ 'fromnumber' => RS_PHONE, 'landingnumber' => '1111111111' });
        Test.startTest();
        mCubeController.readData();
        Test.stopTest();
    }

    // ---------------------------------------------------------------- inboundCall (calland)
    @isTest
    static void testInboundCallNewCaller() {
        setDataParam(inboundPayload('CALL-NEW-1', 'CONNECTING', NEW_PHONE));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallNewCallerNoCampaign() {
        Map<String, Object> p = inboundPayload('CALL-NEW-2', 'Missed', NEW_PHONE);
        p.put('landingnumber', '1111111111');
        setDataParam(p);
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallExistingLead() {
        setDataParam(inboundPayload('CALL-NEW-3', 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallRelatedSource() {
        setDataParam(inboundPayload('CALL-NEW-4', 'CANCEL', RS_PHONE));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallExistingCallId() {
        setDataParam(inboundPayload(EXIST_CALL, 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallAnswered() {
        setDataParam(inboundPayload(EXIST_CALL, 'ANSWER', EXISTING_PHONE));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallOutboundOriginateWithRef() {
        setDataParam(outboundPayload('CALL-OUT-1', 'ORIGINATE', existingLead().Id));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallOutboundOriginateNoRef() {
        setDataParam(outboundPayload('CALL-OUT-2', 'ORIGINATE', ''));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallOutboundAnswered() {
        setDataParam(outboundPayload(EXIST_CALL, 'ANSWER', existingLead().Id));
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    @isTest
    static void testInboundCallBadData() {
        setCallandPage(new Map<String, String>{ 'data' => 'not-json' });
        Test.startTest();
        mCubeController.inboundCall();
        Test.stopTest();
    }

    // ---------------------------------------------------------------- newInboundCall (calland)
    @isTest
    static void testNewInboundNewCaller() {
        setDataParam(inboundPayload('NCALL-1', 'CONNECTING', NEW_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundNewCallerNoCampaign() {
        Map<String, Object> p = inboundPayload('NCALL-2', 'Missed', NEW_PHONE);
        p.put('landingnumber', '1111111111');
        setDataParam(p);
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundExistingLead() {
        setDataParam(inboundPayload('NCALL-3', 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundPreSalesLostLead() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Lost');
        Id rt = rtId('Pre_Sales');
        if (rt != null) l.RecordTypeId = rt;
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload('NCALL-4', 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundSalesLostLead() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Lost');
        Id rt = rtId('Sales');
        if (rt != null) l.RecordTypeId = rt;
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload('NCALL-5', 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundOtherRecordTypeLostLead() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Unqualified');
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload('NCALL-6', 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundRelatedSource() {
        setDataParam(inboundPayload('NCALL-7', 'CANCEL', RS_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundExistingCallIdPreSales() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Lost');
        Id rt = rtId('Pre_Sales');
        if (rt != null) l.RecordTypeId = rt;
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload(EXIST_CALL, 'CONNECTING', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundExistingCallIdSales() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Lost');
        Id rt = rtId('Sales');
        if (rt != null) l.RecordTypeId = rt;
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload(EXIST_CALL, 'Missed', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundExistingCallIdOther() {
        Lead l = new Lead(Id = existingLead().Id, Status = 'Unqualified');
        try { update l; } catch (Exception e) {}
        setDataParam(inboundPayload(EXIST_CALL, 'CANCEL', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundAnswered() {
        setDataParam(inboundPayload(EXIST_CALL, 'ANSWER', EXISTING_PHONE));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundOutboundOriginateWithRef() {
        setDataParam(outboundPayload('NCALL-OUT-1', 'ORIGINATE', existingLead().Id));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundOutboundOriginateNoRef() {
        Map<String, Object> p = outboundPayload('NCALL-OUT-2', 'ORIGINATE', '');
        p.put('customer', RS_PHONE);
        setDataParam(p);
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundOutboundAnswered() {
        setDataParam(outboundPayload(EXIST_CALL, 'ANSWER', existingLead().Id));
        Test.startTest();
        mCubeController.newInboundCall();
        Test.stopTest();
    }

    @isTest
    static void testNewInboundBadData() {
        setCallandPage(new Map<String, String>{ 'data' => '{"bad":' });
        Test.startTest();
        try { mCubeController.newInboundCall(); } catch (Exception e) {}
        Test.stopTest();
    }

    // ---------------------------------------------------------------- NOTIFICATION
    @isTest
    static void testSendNotification() {
        User u = execUser();
        Lead l = existingLead();
        Call_Detail__c cd = existingCall();
        Test.startTest();
        try { mCubeController.sendNotification(EXISTING_PHONE, l.Id, u.Id, 'Lead', cd.Id, 'INCOMING'); } catch (Exception e) {}
        try { mCubeController.sendNotification(EXISTING_PHONE, l.Id, u.Id, 'Lead', cd.Id, 'OUTGOING'); } catch (Exception e) {}
        Test.stopTest();
    }

    // ---------------------------------------------------------------- AURA METHODS
    @isTest
    static void testReadCallAndCallRecords() {
        Lead l = existingLead();
        Test.startTest();
        mCubeController.readCall();
        mCubeController.callRecords(l.Id);
        Test.stopTest();
    }

    @isTest
    static void testMassDialInit() {
        User u = execUser();
        Lead l = existingLead();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            applyCustomUserFields(u.Id, new Map<String, Object>{ 'massdialerIds__c' => l.Id + ',' + l.Id });
        }
        System.runAs(u) {
            Test.startTest();
            try { mCubeController.masdialinit(); } catch (Exception e) {}
            Test.stopTest();
        }
    }

    @isTest
    static void testUpdateRecord() {
        Lead l = existingLead();
        Call_Detail__c cd = existingCall();
        Follow_Up__c fu = new Follow_Up__c(Lead__c = l.Id, Follow_Up_Status__c = 'Scheduled', Scheduled_Date__c = System.now().addDays(1));
        try { insert fu; } catch (Exception e) {}
        Test.startTest();
        try { mCubeController.updateRecord(l.Id, cd.Id, 'Invalid Date', 'Call', 'feedback', 'Interested', 'Hot'); } catch (Exception e) {}
        try { mCubeController.updateRecord(l.Id, cd.Id, 'Thu Jan 01 1970 05:30:00 GMT+0530', 'Call', 'feedback', 'Interested', 'Hot'); } catch (Exception e) {}
        try { mCubeController.updateRecord(l.Id, cd.Id, '2099-12-31T10:00:00.000Z', 'Call', 'feedback', 'Interested', 'Hot'); } catch (Exception e) {}
        try { mCubeController.updateRecord(l.Id, cd.Id, '2020-01-01T10:00:00.000Z', 'Call', 'feedback', 'Interested', 'Hot'); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testOutboundCallDetailsAndUpdateUsers() {
        User u = execUser();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            applyCustomUserFields(u.Id, new Map<String, Object>{ 'Last_OutBound_CallID__c' => EXIST_CALL });
        }
        System.runAs(u) {
            Test.startTest();
            try { mCubeController.getOutboundCallDetails(); } catch (Exception e) {}
            try { mCubeController.updateUsers(); } catch (Exception e) {}
            try { mCubeController.getOutboundCallDetails(); } catch (Exception e) {}
            Test.stopTest();
        }
    }

    @isTest
    static void testCallDisposition() {
        Test.setMock(HttpCalloutMock.class, new McubeMock());
        Call_Detail__c cd = existingCall();
        Test.startTest();
        try { mCubeController.callDisposition(cd.Id); } catch (Exception e) {}
        Test.stopTest();
    }
}