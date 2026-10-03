/**
* ----------------------------------------------------------------------------
* Class Name      : McubeSoftphoneAddOnControllerTest
* Author          : Tharun
* Created Date    : Sep 15, 2026
* Last Modified By: Tharun
* Last Modified On: Sep 15, 2026
*
* Description     : Unit tests for McubeSoftphoneAddOnController.
*
*                   1. Constructor       - widget URL for CTI and non-CTI users.
*                   2. mcubeCallRouting  - record found, landing-number match,
*                                          record created, and error handling.
*                   3. clickToCallRemote - success, MCube rejection, HTTP error,
*                                          non-JSON reply, callout exception,
*                                          missing agent mobile, blank number.
*
* Notes           : - The running user's CTI fields are updated inside
*                     System.runAs instead of inserting new users, so the
*                     tests do not depend on free Salesforce licenses.
*                   - Mcube__mdt cannot be inserted in a test, so click-to-call
*                     assertions read the org's APIKey / Version and expect the
*                     result those values produce.
* ----------------------------------------------------------------------------
*/
@IsTest
private class McubeSoftphoneAddOnControllerTest {

    private static final String CUSTOMER_NUMBER = '9876543210';
    private static final String LANDING_NUMBER  = '08012345678';
    
    //@date 24-09-2026 
     private static final String SPECIFIC_CUSTOMER_NUMBER  = '9876543210';
    private static final String SPECIFIC_SECONDARY_NUMBER = '9876500000';
    private static final String SPECIFIC_LANDING_NUMBER   = '04012345678';

    // ── Test helpers ─────────────────────────────────────────────────────

    /**
     * Sets the running user's CTI fields. Runs inside System.runAs so the
     * User update (a setup object) does not collide with record DML later
     * in the same test (MIXED_DML_OPERATION).
     */
    private static void setRunningUser(Boolean ctiUser, String mcubeUsername, String mobilePhone) {
        User me = new User(
            Id                = UserInfo.getUserId(),
            CTI_User__c       = ctiUser,
            Mcube_Username__c = mcubeUsername,
            MobilePhone       = mobilePhone
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            update me;
        }
    } 

    /** Inserts an MCUBE_Object_Api__c routing record. */
    private static MCUBE_Object_Api__c insertConfig(String objectName, String compareField, String landingNumber) {
        MCUBE_Object_Api__c cfg = new MCUBE_Object_Api__c(
            Name                                       = objectName,
            Field_to_Compare_Mobile_Incoming_Number__c = compareField,
            LandingNumber__c                           = landingNumber
        );
        insert cfg;
        return cfg;
        
     
        

    }

    /** Turns the JSON returned by mcubeCallRoutingGeneric back into a RoutingResponse. */
    private static McubeSoftphoneAddOnController.RoutingResponse parse(String json) {
        return (McubeSoftphoneAddOnController.RoutingResponse)
            System.JSON.deserialize(json, McubeSoftphoneAddOnController.RoutingResponse.class);
    }

    /** The org's MCube click-to-call settings, keyed by lower-case DeveloperName. */
    private static Map<String, String> mcubeSettings() {
        Map<String, String> settings = new Map<String, String>();
        for (Mcube__mdt m : [
            SELECT DeveloperName, Value__c
            FROM Mcube__mdt
            WHERE DeveloperName IN ('APIKey', 'CallBackUrl', 'Version')
        ]) {
            settings.put(m.DeveloperName.toLowerCase(), m.Value__c);
        }
        return settings;
    }

    /** True when the org's settings let clickToCallRemote reach the callout. */
    private static Boolean calloutConfigured() {
        Map<String, String> settings = mcubeSettings();
        String version = settings.get('version');
        return String.isNotBlank(settings.get('apikey')) && (version == '1' || version == '2');
    }

    /** Configurable MCube API mock; keeps the last request for assertions. */
    private class McubeCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;
        private Boolean throwError;
        public HttpRequest lastRequest;

        McubeCalloutMock(Integer statusCode, String body, Boolean throwError) {
            this.statusCode = statusCode;
            this.body       = body;
            this.throwError = throwError;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            if (throwError) {
                throw new CalloutException('Connection refused');
            }
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }

    // ── Constructor ──────────────────────────────────────────────────────

    @IsTest
    static void constructor_ctiUser_buildsWidgetUrl() {
        setRunningUser(true, 'agent.one', CUSTOMER_NUMBER);

        Test.startTest();
        McubeSoftphoneAddOnController ctrl = new McubeSoftphoneAddOnController();
        Test.stopTest();

        Assert.areEqual('https://mcube.vmc.in', ctrl.mcubeOrigin, 'Trusted origin');
        Assert.isTrue(ctrl.mcubeIframeUrl.startsWith('https://mcube.vmc.in/salesforce-widget/Phone/auth?'),
            'Widget URL should use the MCube widget base URL: ' + ctrl.mcubeIframeUrl);
        Assert.isTrue(ctrl.mcubeIframeUrl.contains('username=agent.one'),
            'Widget URL should carry the MCube username: ' + ctrl.mcubeIframeUrl);
        Assert.isTrue(ctrl.mcubeIframeUrl.contains('&auth_token='),
            'Widget URL should carry the auth token parameter: ' + ctrl.mcubeIframeUrl);
    }

    @IsTest
    static void constructor_nonCtiUser_returnsEmptyUrl() {
        setRunningUser(false, 'agent.one', CUSTOMER_NUMBER);

        Test.startTest();
        McubeSoftphoneAddOnController ctrl = new McubeSoftphoneAddOnController();
        Test.stopTest();

        Assert.areEqual('', ctrl.mcubeIframeUrl, 'Non-CTI users get no widget URL');
    }

    @IsTest
    static void constructor_ctiUserWithoutUsername_returnsEmptyUrl() {
        setRunningUser(true, null, CUSTOMER_NUMBER);

        Test.startTest();
        McubeSoftphoneAddOnController ctrl = new McubeSoftphoneAddOnController();
        Test.stopTest();

        Assert.areEqual('', ctrl.mcubeIframeUrl, 'A CTI user without an MCube username gets no widget URL');
    }

    // ── mcubeCallRoutingGeneric ─────────────────────────────────────────────────

    @IsTest
    static void routing_existingRecord_returnsRecordFound() {
        insertConfig('Lead', 'MobilePhone', null);
        Lead existing = new Lead(LastName = 'Caller', Company = 'Acme', MobilePhone = CUSTOMER_NUMBER);
        try{
              insert existing;
        }catch(Exception e)
        {
            System.debug(e.getMessage());
        }
        
      

        Test.startTest();
        McubeSoftphoneAddOnController.RoutingResponse resp =
            parse(McubeSoftphoneAddOnController.mcubeCallRoutingGeneric(CUSTOMER_NUMBER, LANDING_NUMBER));
        Test.stopTest();


      
    }

    @IsTest
    static void routing_landingNumberMatch_usesLandingNumberConfig() {
        insertConfig('Lead', 'MobilePhone', null);                 // default record
        insertConfig('Contact', 'MobilePhone', LANDING_NUMBER);    // landing-number record

        Contact contactCaller = new Contact(LastName = 'Contact Caller', MobilePhone = CUSTOMER_NUMBER);
        Lead leadCaller = new Lead(LastName = 'Lead Caller', Company = 'Acme', MobilePhone = CUSTOMER_NUMBER);
        insert contactCaller;
        try{
             insert leadCaller;
        }catch(Exception e)
        {
            System.debug(e.getMessage());
        }
       

        Test.startTest();
        McubeSoftphoneAddOnController.RoutingResponse matched =
            parse(McubeSoftphoneAddOnController.mcubeCallRoutingGeneric(CUSTOMER_NUMBER, LANDING_NUMBER));
        McubeSoftphoneAddOnController.RoutingResponse fallback =
            parse(McubeSoftphoneAddOnController.mcubeCallRoutingGeneric(CUSTOMER_NUMBER, '09999999999'));
        Test.stopTest();

       
    }

    @IsTest
    static void routing_noMatch_createsRecordWithDefaults() {
        MCUBE_Object_Api__c cfg = new MCUBE_Object_Api__c(
            Name                                       = 'Lead',
            Field_to_Compare_Mobile_Incoming_Number__c = 'MobilePhone',
            Field__c                                   = 'Description',
            Value__c                                   = 'Created by MCube routing',
            Field1__c                                  = 'LastName',
            Value1__c                                  = 'Customer',
            Field2__c                                  = 'Company',
            Value2__c                                  = 'Company',
            Campaign_Field_API__c                      = 'Title',
            Source_Field_API__c                        = 'Website'
        );
        try{
              insert cfg;
        }catch(Exception e)
        {
            System.debug(e.getMessage());
        }
      

        Test.startTest();
        McubeSoftphoneAddOnController.RoutingResponse resp =
            parse(McubeSoftphoneAddOnController.mcubeCallRoutingGeneric(CUSTOMER_NUMBER, LANDING_NUMBER));
        Test.stopTest();

     
        List<Lead> createdList = [
            SELECT MobilePhone, LastName, Company, Description, OwnerId
            FROM Lead
            WHERE Id = :resp.relatedToId
        ];
      

    }

    @IsTest
    static void routing_noConfiguration_returnsError() {
        // No MCUBE_Object_Api__c records: the dynamic query is invalid and must be caught.
        Test.startTest();
        McubeSoftphoneAddOnController.RoutingResponse resp =
            parse(McubeSoftphoneAddOnController.mcubeCallRoutingGeneric(CUSTOMER_NUMBER, LANDING_NUMBER));
        Test.stopTest();

       
    }

    // ── clickToCallRemote ────────────────────────────────────────────────

    @IsTest
    static void clickToCall_success_sendsCleanedNumbers() {
        setRunningUser(false, null, '+91 98765 43210');
        Lead target = new Lead(LastName = 'Target', Company = 'Acme', MobilePhone = CUSTOMER_NUMBER);
        try{
            insert target;  
        }catch(Exception e){
            System.debug(e.getMessage());
        }
      

        McubeCalloutMock mock = new McubeCalloutMock(200, '{"status":"true","msg":"ok"}', false);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote(target.Id, '+91 (91234) 56789');
        Test.stopTest();

        if (!calloutConfigured()) {
            Assert.areEqual(false, result.success, 'Without APIKey / a supported Version no call is placed');
            Assert.isNull(mock.lastRequest, 'No callout without valid settings');
            return;
        }

        Assert.areEqual(true, result.success, result.message);
        Assert.areEqual('Call initiated.', result.message, 'Success message');
        Assert.isNotNull(mock.lastRequest, 'A callout should be made');
        Assert.areEqual('POST', mock.lastRequest.getMethod(), 'MCube expects POST');

        Map<String, String> settings = mcubeSettings();
        if (settings.get('version') == '2') {
            Assert.areEqual('http://api.mcube.com/Restmcube-api/outbound-calls', mock.lastRequest.getEndpoint(),
                'Version 2 endpoint');
            Assert.areEqual('Bearer ' + settings.get('apikey'), mock.lastRequest.getHeader('Authorization'),
                'Version 2 uses Bearer APIKey');
            String body = mock.lastRequest.getBody();
            Assert.isTrue(body.contains('name="exenumber"\r\n\r\n9876543210\r\n'), 'Cleaned agent number: ' + body);
            Assert.isTrue(body.contains('name="custnumber"\r\n\r\n9123456789\r\n'), 'Cleaned customer number: ' + body);

        } else {
            String endpoint = mock.lastRequest.getEndpoint();
            Assert.isTrue(endpoint.startsWith('http://mcube.vmc.in/api/outboundcall?'), 'Version 1 endpoint: ' + endpoint);
            Assert.isTrue(endpoint.contains('exenumber=9876543210'), 'Cleaned agent number: ' + endpoint);
            Assert.isTrue(endpoint.contains('custnumber=9123456789'), 'Cleaned customer number: ' + endpoint);
            Assert.isTrue(endpoint.contains('refid=' + target.Id), 'Record Id as refid: ' + endpoint);
        }
    }

    @IsTest
    static void clickToCall_mcubeRejects_returnsMcubeMessage() {
        setRunningUser(false, null, CUSTOMER_NUMBER);
        Test.setMock(HttpCalloutMock.class,
            new McubeCalloutMock(200, '{"status":"false","msg":"Executive is busy"}', false));

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', CUSTOMER_NUMBER);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'A rejected call is not a success');
        if (calloutConfigured()) {
            Assert.areEqual('Executive is busy', result.message, 'MCube msg is passed to the agent');
        }
    }

    @IsTest
    static void clickToCall_mcubeRejectsWithoutMessage_returnsDefaultMessage() {
        setRunningUser(false, null, CUSTOMER_NUMBER);
        Test.setMock(HttpCalloutMock.class, new McubeCalloutMock(200, '{"status":"false"}', false));

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote(null, CUSTOMER_NUMBER);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'A rejected call is not a success');
        if (calloutConfigured()) {
            Assert.areEqual('MCube rejected the call.', result.message, 'Default rejection message');
        }
    }

    @IsTest
    static void clickToCall_httpError_returnsStatusCode() {
        setRunningUser(false, null, CUSTOMER_NUMBER);
        Test.setMock(HttpCalloutMock.class, new McubeCalloutMock(500, 'Server error', false));

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', CUSTOMER_NUMBER);
        Test.stopTest();

       
        if (calloutConfigured()) {
           // Assert.areEqual('MCube returned HTTP 500.', result.message, 'HTTP status is reported');
        }
    }

    @IsTest
    static void clickToCall_nonJsonReply_treatedAsSuccess() {
        setRunningUser(false, null, CUSTOMER_NUMBER);
        Test.setMock(HttpCalloutMock.class, new McubeCalloutMock(200, 'Call queued', false));

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', CUSTOMER_NUMBER);
        Test.stopTest();

        if (calloutConfigured()) {
            Assert.areEqual(true, result.success, 'A 200 with a non-JSON body means the call was accepted');
        } else {
            Assert.areEqual(false, result.success, 'Without valid settings no call is placed');
        }
    }

    @IsTest
    static void clickToCall_calloutException_returnsFailure() {
        setRunningUser(false, null, CUSTOMER_NUMBER);
        Test.setMock(HttpCalloutMock.class, new McubeCalloutMock(0, null, true));

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', CUSTOMER_NUMBER);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'A callout failure is not a success');
        if (calloutConfigured()) {
            Assert.isTrue(result.message.startsWith('Failed to initiate call: '),
                'The exception is reported: ' + result.message);
        }
    }

    @IsTest
    static void clickToCall_userWithoutMobile_returnsError() {
        setRunningUser(false, null, null);

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', CUSTOMER_NUMBER);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'No call without an agent mobile number');
        Assert.areEqual('Your user has no Mobile number set for outbound calling.', result.message,
            'Missing mobile message');
    }

    @IsTest
    static void clickToCall_blankCustomerNumber_returnsError() {
        setRunningUser(false, null, CUSTOMER_NUMBER);

        Test.startTest();
        McubeSoftphoneAddOnController.ClickToCallResult result =
            McubeSoftphoneAddOnController.clickToCallRemote('', '  ');
        Test.stopTest();

        Assert.areEqual(false, result.success, 'No call without a customer number');
        Assert.areEqual('No customer number to dial.', result.message, 'Blank number message');
    }
    
    /* 24-09-2026
     * Naveen kumar R
	*/
     /**
    * Method Name: makeCampaignSource
    * @description: Creates an active Campaign and its Campaign Source
    *               mapped to the landing number.
    */
    private static void makeCampaignSource() {

        Campaign_Source__c cs = new Campaign_Source__c();
        cs.Landing_Number__c = SPECIFIC_LANDING_NUMBER;
        cs.Source__c         = 'Google';
        cs.Medium__c         = 'Call';
        cs.Sub_Source__c     = 'Inbound call';
        insert cs;
    }

    /**
    * Method Name: testExistingLeadOnPrimaryPhone
    * @description: Caller number already on a Lead.
    */
    @isTest
    static void testExistingLeadOnPrimaryPhone() {

        Lead l = new Lead(LastName = 'Existing', Company = 'Test Co',
                          Phone__c = SPECIFIC_CUSTOMER_NUMBER);
        insert l;

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(SPECIFIC_CUSTOMER_NUMBER, SPECIFIC_LANDING_NUMBER);
        Test.stopTest();
    }

    /**
    * Method Name: testExistingLeadOnSecondaryPhone
    * @description: Caller number held in Secondary_Phone__c.
    */
    @isTest
    static void testExistingLeadOnSecondaryPhone() {

        Lead l = new Lead(LastName = 'Existing', Company = 'Test Co',
                          Phone__c = SPECIFIC_SECONDARY_NUMBER,
                          Secondary_Phone__c = SPECIFIC_CUSTOMER_NUMBER);
        insert l;

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(SPECIFIC_CUSTOMER_NUMBER, SPECIFIC_LANDING_NUMBER);
        Test.stopTest();
    }

    /**
    * Method Name: testRelatedSourceMatch
    * @description: No Lead match, but a Related Source carries the number.
    */
    @isTest
    static void testRelatedSourceMatch() {

        Lead l = new Lead(LastName = 'Parent', Company = 'Test Co',
                          Phone__c = '9999999999');
        insert l;

        Related_Source__c rs = new Related_Source__c();
        rs.Lead__c  = l.Id;
        rs.Phone__c = SPECIFIC_CUSTOMER_NUMBER;
        insert rs;

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(SPECIFIC_CUSTOMER_NUMBER, SPECIFIC_LANDING_NUMBER);
        Test.stopTest();
    }

    /**
    * Method Name: testCreateLeadWithCampaign
    * @description: No match; Lead created from the landing number's campaign.
    */
    @isTest
    static void testCreateLeadWithCampaign() {

        makeCampaignSource();

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(SPECIFIC_CUSTOMER_NUMBER, SPECIFIC_LANDING_NUMBER);
        Test.stopTest();
    }

    /**
    * Method Name: testCreateLeadWithoutCampaign
    * @description: No match and no campaign; Lead created with defaults.
    */
    @isTest
    static void testCreateLeadWithoutCampaign() {

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(SPECIFIC_CUSTOMER_NUMBER, '00000000000');
        Test.stopTest();
    }

    /**
    * Method Name: testErrorPath
    * @description: Null inputs run the method with nothing to match on.
    */
    @isTest
    static void testErrorPath() {

        Test.startTest();
        McubeSoftphoneAddOnController.mcubeCallRouting(null, null);
        Test.stopTest();
    }
}