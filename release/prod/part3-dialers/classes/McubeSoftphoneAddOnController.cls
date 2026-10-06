/**
* ----------------------------------------------------------------------------
* Class Name      : McubeSoftphoneAddOnController
* Author          : Tharun
* Created Date    : Sep 15, 2026
* Last Modified By: Tharun
* Last Modified On: Sep 15, 2026
*
* Description     : Controller for the mcubeSoftphoneCTI Visualforce page,
*                   the Open CTI softphone adapter for MCube.
*
*                   1. Builds the authenticated MCube widget URL for the
*                      softphone iframe (CTI-enabled users only).
*                   2. mcubeCallRouting  - finds the record for a call by
*                      customer number and landing number, or creates one,
*                      and returns its Id so the page can open it.
*                   3. clickToCallRemote - places an outbound call through the
*                      MCube API when the agent clicks a phone number.
*
* Configuration   : Mcube__mdt          -> APIKey, CallBackUrl, Version
*                   MCUBE_Object_Api__c -> routing object, compare field,
*                                          landing number, field defaults
*                   User                -> CTI_User__c, Mcube_Username__c,
*                                          MobilePhone
* ----------------------------------------------------------------------------
*/
public class McubeSoftphoneAddOnController {
    
    // ── Constants ────────────────────────────────────────────────────────
    
    private static final String MCUBE_WIDGET_BASE_URL =
        'https://mcube.vmc.in/salesforce-widget/Phone/auth';
    
    // ── Properties (exposed to Visualforce) ──────────────────────────────
    
    /** Authenticated MCube iframe URL. Empty string if user is not CTI-enabled. */
    public String mcubeIframeUrl { get; private set; }
    
    /** Trusted origin for postMessage validation (e.g. https://mcube.vmc.in). */
    public String mcubeOrigin { get; private set; }
    
    // ── Constructor ──────────────────────────────────────────────────────
    
    /**
* Builds the MCube widget URL using the current user's CTI credentials.
* Non-CTI users receive an empty URL (the VF page shows a "not enabled" message).
*/
    public McubeSoftphoneAddOnController() {
        this.mcubeOrigin = 'https://mcube.vmc.in';
        
        User currentUser = [
            SELECT Id, CTI_User__c, Mcube_Username__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
            LIMIT 1
        ];
        
        if (currentUser.CTI_User__c && String.isNotBlank(currentUser.Mcube_Username__c)) {
            String authToken = configAuthToken();
            
            this.mcubeIframeUrl = MCUBE_WIDGET_BASE_URL
                + '?username=' + EncodingUtil.urlEncode(currentUser.Mcube_Username__c, 'UTF-8')
                + '&auth_token=' + EncodingUtil.urlEncode(authToken == null ? '' : authToken, 'UTF-8');
            System.debug(this.mcubeIframeUrl);
        } else {
            this.mcubeIframeUrl = '';
        }
    }
    
    
    
    // ── Call Routing ─────────────────────────────────────────────────────
    
    /**
* Resolves the Salesforce record for a call, the same way
* mCubeController.inboundCall does, so the softphone page can open it.
* Called from the page when an MCube OpenPanel event has no refid.
*
*   1. Picks the MCUBE_Object_Api__c record whose LandingNumber__c equals
*      the landing number; otherwise the first record (blank landing
*      numbers sort first).
*   2. Searches that object's compare field for the customer number and
*      returns the first match.
*   3. If nothing matches, creates a record of that object with the
*      configured field/value defaults and returns its Id.
*
* @param  customerNumber  The caller's phone number.
* @param  landingNumber   The DID / landing number the call came in on.
* @return RoutingResponse serialized as JSON:
*           RECORD_FOUND   - relatedToId holds the matched record
*           RECORD_CREATED - relatedToId holds the newly created record
*           NOT_RESOLVED   - no record could be resolved
*           ERROR          - hasError is true; message holds the exception
*/
    @RemoteAction
    public static String mcubeCallRoutingGeneric(String customerNumber, String landingNumber) {
        RoutingResponse resp = new RoutingResponse();
        resp.hasError = false;
        
        // Any failure (bad configuration, invalid query, insert error) is caught below
        // and returned to the page as an ERROR response instead of a raw exception.
        try {
            // The softphone page sends only these two values, so the wrapper is built from them.
            callWrapper cw = new callWrapper();
            cw.callfrom = customerNumber;
            cw.LandingNumber = landingNumber;
            
            // Load every MCUBE Object Api record; blank landing numbers sort first.
            List<MCUBE_Object_Api__c> mcubeObjectList =[select id,name,Campaign_Field_API__c, Source_Field_API__c,field__c,value__c,field1__c,value1__c,field2__c,value2__c, LandingNumber__c,  Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c order by  LandingNumber__c nulls first ];
            MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c();
            Boolean isLandingNumberExist = false;
            // Use the record configured for this landing number, if there is one;
            // otherwise fall back to the first record in the list.
            for(MCUBE_Object_Api__c mcubeObj : mcubeObjectList){
                if(mcubeObj.LandingNumber__c != null && mcubeObj.LandingNumber__c == landingNumber){
                    isLandingNumberExist = true;
                    mcubeObject = mcubeObj;
                    break;
                }
            }
            
            if(!isLandingNumberExist && mcubeObjectList.size() > 0){
                mcubeObject = mcubeObjectList[0];
            }  
            // Look for an existing record whose compare field equals the customer number.
            String xQuery =
                'SELECT Id FROM ' +
                mcubeObject.Name +
                ' WHERE ' +
                mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c +
                ' = \'' +
                String.escapeSingleQuotes(customerNumber) +
                '\'' +
                ' AND Owner.Name != \'Duplicate Lead Merged_Dont Touch\'';
            
            List<SObject> inboundList = Database.query(xQuery);
            
            if(inboundList.size() > 0){
                resp.relatedToId = inboundList[0].Id;
                resp.status      = 'RECORD_FOUND';
                resp.message     = 'Existing ' + mcubeObject.Name + ' record found.';
                return JSON.serialize(resp);
            }else{
                // No match: build a new record of the configured object, applying the
                // Field__c/Value__c, Field1__c/Value1__c and Field2__c/Value2__c defaults.
                sObject l = Schema.getGlobalDescribe().get(mcubeObject.Name).newSObject() ;  
                if(inboundList.size() == 0){  
                    if(mcubeObject.field__c != null && mcubeObject.value__c != null){
                        L.put(mcubeObject.field__c, mcubeObject.value__c);
                    }
                    if(mcubeObject.field1__c != null && mcubeObject.value1__c != null){
                        L.put(mcubeObject.field1__c, mcubeObject.value1__c);
                    }
                    if(mcubeObject.field2__c != null && mcubeObject.value2__c != null){
                        L.put(mcubeObject.field2__c, mcubeObject.value2__c);
                    }
                    // Owned by the agent; the compare field holds the caller's number.
                    // Campaign and source stay blank - the softphone page does not send them.
                    l.put('OwnerId',UserInfo.getUserId());  
                    l.put(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c,customerNumber);
                    system.debug(mcubeObject);
                    if(mcubeObject.Campaign_Field_API__c!=null)
                        l.put(mcubeObject.Campaign_Field_API__c,cw.campaign);
                    if(mcubeObject.Source_Field_API__c!=null)
                        l.put(mcubeObject.Source_Field_API__c,cw.source );  
                    insert l;  
                    resp.relatedToId = l.Id;
                    resp.status      = 'RECORD_CREATED';
                    resp.message     = 'No existing record found. New ' + mcubeObject.Name + ' created.';
                    return JSON.serialize(resp);
                }
                
                
                
            }
            // Not reached in practice (both branches above return); required by the compiler.
            resp.status  = 'NOT_RESOLVED';
            resp.message = 'No record could be resolved for this call.';
            return JSON.serialize(resp);
            
        } catch (Exception ex) {
            resp.hasError = true;
            resp.status   = 'ERROR';
            resp.message  = ex.getMessage();
            return JSON.serialize(resp);
        }
    }
    
    
        /**
     @date: 24-09-2026
    * Method Name: mcubeCallRouting
    * @author: Naveen Kumar R
    * @description: Resolves the Lead to open for an inbound call.
    * @param: customerNumber - caller's number
    * @param: landingNumber - MCube landing number the call came in on
    * @return: String - serialized RoutingResponse
    */
    @RemoteAction
    public static String mcubeCallRouting(String customerNumber, String landingNumber) {

        RoutingResponse resp = new RoutingResponse();
        resp.hasError = false;

        try {
            resp.relatedToId = getLeadId(customerNumber, landingNumber);
            resp.status      = 'RECORD_FOUND';
            resp.message     = 'Lead resolved for this call.';
        } catch (Exception ex) {
            resp.hasError = true;
            resp.status   = 'ERROR';
            resp.message  = ex.getMessage();
        }
        return JSON.serialize(resp);
    }

    /**
     * @date: 24-09-2026
    * Method Name: getLeadId
    * @author: Naveen Kumar R
    * @description: Matches the caller on Lead phone, then Related Source,
    *               and creates a Lead from the landing number's campaign
    *               when nothing matches.
    * @param: customerNumber - caller's number
    * @param: landingNumber - MCube landing number
    * @return: Id of the Lead
    */
    private static Id getLeadId(String customerNumber, String landingNumber) {

        // 1. Existing Lead on either phone number.
        List<Lead> ld = [
            SELECT Id
            FROM Lead
            WHERE Phone__c = :customerNumber
               OR Secondary_Phone__c = :customerNumber
            LIMIT 1
        ];
        if (!ld.isEmpty()) {
            return ld[0].Id;
        }

        // 2. Lead behind a Related Source.
        List<Related_Source__c> rs = [
            SELECT Id, Lead__c
            FROM Related_Source__c
            WHERE (Phone__c = :customerNumber OR Secondary_Phone__c = :customerNumber)
              AND Lead__c != NULL
            LIMIT 1
        ];
        if (!rs.isEmpty()) {
            return rs[0].Lead__c;
        }

        // 3. Create from the campaign mapped to the landing number.
        Lead l = new Lead();
        l.LastName          = 'customer';
        l.Company           = 'McubeLead';
        l.Phone__c          = customerNumber;
        l.Landing_Number__c = landingNumber;
        l.Lead_Assigned__c  = true;
        l.OwnerId           = UserInfo.getUserId();

        List<Campaign_Source__c> campList = [
            SELECT Id, Source__c, Medium__c, Sub_Source__c, Campaign__c,
                   Campaign__r.Project__c, Campaign__r.Zone__c,
                   Campaign__r.NRI_Campaign__c
            FROM Campaign_Source__c
            WHERE Landing_Number__c = :landingNumber
              AND Campaign__r.Active__c = TRUE
            LIMIT 1
        ];

        if (!campList.isEmpty()) {
            l.Campaign_Lookup__c    = campList[0].Campaign__c;
            l.LeadSource            = campList[0].Source__c;
            l.Sub_Source__c         = campList[0].Sub_Source__c;
            l.Medium__c             = campList[0].Medium__c;
            l.Interested_Project__c = campList[0].Campaign__r.Project__c;
            l.Zone__c               = campList[0].Campaign__r.Zone__c;
            l.NRI__c = (campList[0].Campaign__r.NRI_Campaign__c == true) ? 'Yes' : 'No';
        } else {
            l.LeadSource            = 'Mcube';
            l.Sub_Source__c         = 'Inbound call';
            l.Interested_Project__c = 'None';
        }

        insert l;
        return l.Id;
    }
    
    // ── Click to Call ────────────────────────────────────────────────────
    
    /**
* Places an outbound call through MCube, the same way
* mCubeController.clickToCallNumber does. Called from the Open CTI
* click-to-dial handler in the mcubeSoftphoneCTI page.
*
* Settings come from Mcube__mdt (APIKey, CallBackUrl, Version):
*   Version 1 → POST http://mcube.vmc.in/api/outboundcall with query-string params
*   Version 2 → POST http://api.mcube.com/Restmcube-api/outbound-calls as
*               multipart/form-data, authorised with Bearer APIKey
*   otherwise → error, no call is placed
*
* @param  recordId        The record the call is placed from (sent as refid); may be blank.
* @param  customerNumber  The number the agent clicked.
* @return ClickToCallResult { success, message } — the page reads both.
*/
    @RemoteAction
    public static ClickToCallResult clickToCallRemote(String recordId, String customerNumber) {
        try {
            // Get the details from metadata
            Map<String, String> settings = new Map<String, String>();
            for (Mcube__mdt m : [
                SELECT DeveloperName, Value__c
                FROM Mcube__mdt
                WHERE DeveloperName IN ('APIKey', 'CallBackUrl', 'Version')
            ]) {
                settings.put(m.DeveloperName.toLowerCase(), m.Value__c);
            }
            String apiKey      = settings.get('apikey');
            String callbackUrl = settings.get('callbackurl');
            String version     = settings.get('version');
            
            // Agent's number (exenumber) and the clicked customer number (custnumber)
            User u = [SELECT MobilePhone FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            String exeNumber  = cleanNumber(u.MobilePhone);
            String custNumber = cleanNumber(customerNumber);
            String refId      = String.isBlank(recordId) ? '' : recordId;
            
            if (String.isBlank(exeNumber)) {
                return new ClickToCallResult(false, 'Your user has no Mobile number set for outbound calling.');
            }
            if (String.isBlank(custNumber)) {
                return new ClickToCallResult(false, 'No customer number to dial.');
            }
            if (String.isBlank(apiKey)) {
                return new ClickToCallResult(false, 'MCube APIKey is not configured in the Mcube metadata.');
            }
            
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            
            if (version == '1') {
                request.setEndpoint('http://mcube.vmc.in/api/outboundcall'
                                    + '?apikey='     + EncodingUtil.urlEncode(apiKey, 'UTF-8')
                                    + '&exenumber='  + EncodingUtil.urlEncode(exeNumber, 'UTF-8')
                                    + '&custnumber=' + EncodingUtil.urlEncode(custNumber, 'UTF-8')
                                    + '&refid='      + EncodingUtil.urlEncode(refId, 'UTF-8')
                                    + '&url='        + EncodingUtil.urlEncode(
                                        (callbackUrl == null ? '' : callbackUrl) + '/calland?refid=' + refId, 'UTF-8'));
                
            } else if (version == '2') {
                String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
                request.setEndpoint('http://api.mcube.com/Restmcube-api/outbound-calls');
                request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
                request.setHeader('Authorization', 'Bearer ' + apiKey);
                request.setBody(
                    formField(boundary, 'exenumber', exeNumber)
                    + formField(boundary, 'custnumber', custNumber)
                    + formField(boundary, 'refid', refId)
                    + formField(boundary, 'refurl', '1')
                    + '--' + boundary + '--\r\n'
                );
                
            } else {
                return new ClickToCallResult(false, 'Unsupported MCube Version "' + version
                                             + '" in the Mcube metadata — expected 1 or 2.');
            }
            
            HttpResponse response = new Http().send(request);
            if (response.getStatusCode() != 200) {
                return new ClickToCallResult(false, 'MCube returned HTTP ' + response.getStatusCode() + '.');
            }
            
            // MCube answers 200 with {"status":"false","msg":"..."} when it rejects the call.
            Map<String, Object> responseMap = new Map<String, Object>();
            try {
                responseMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } catch (Exception parseEx) {
                // Not a JSON object — nothing to inspect; a 200 means the call was accepted.
            }
            if (String.valueOf(responseMap.get('status')) == 'false') {
                Object msg = responseMap.get('msg');
                return new ClickToCallResult(false, msg != null ? String.valueOf(msg) : 'MCube rejected the call.');
            }
            
            return new ClickToCallResult(true, 'Call initiated.');
            
        } catch (Exception ex) {
            return new ClickToCallResult(false, 'Failed to initiate call: ' + ex.getMessage());
        }
    }
    
    /**
* Masked click-to-dial (mobile number masking, v1.3.0). Called when the agent clicks a masked number
* (e.g. 98XXXXXX21) on the masked phone panel. The page sends only the record Id plus the field key
* (or the masked value); the real number is resolved here through MaskedDialService, which checks the
* approved field list and the user's record access and audits the request, and is then dialed through
* the existing clickToCallRemote. The real number is never returned to the page.
*
* @param  recordId      The record the call is placed from.
* @param  fieldKey      Approved field key, e.g. Lead.Phone__c; may be blank.
* @param  maskedNumber  The masked value clicked; used to identify the field when fieldKey is blank.
* @return ClickToCallResult { success, message } — same shape as clickToCallRemote.
*/
    @RemoteAction
    public static ClickToCallResult clickToCallMasked(String recordId, String fieldKey, String maskedNumber) {
        Id parsedId;
        try {
            parsedId = Id.valueOf(recordId);
        } catch (Exception e) {
            return new ClickToCallResult(false, 'Invalid record.');
        }
        if (String.isBlank(fieldKey)) {
            fieldKey = MaskedDialService.fieldKeyForMaskedNumber(parsedId, maskedNumber);
        }
        // The audit row is written after the MCube callout: no DML is allowed before a callout.
        MaskedDialService.deferAuditWrites();
        ClickToCallResult result;
        try {
            MaskedDialService.DialResult resolved = MaskedDialService.resolveOne(parsedId, fieldKey, 'MCube');
            result = resolved.success
                ? clickToCallRemote(recordId, resolved.phoneNumber)
                : new ClickToCallResult(false, resolved.message);
        } finally {
            MaskedDialService.flushAudits(result == null ? null : 'MCube: ' + result.message);
        }
        return result;
    }

    // ── Helpers ──────────────────────────────────────────────────────────
    
    /**
* Returns the MCube auth token passed to the softphone widget: the APIKey
* value in Mcube__mdt.
*
* @return The APIKey value, or null when that metadata record is missing.
*/
    private static String configAuthToken() {
        List<Mcube__mdt> keys = [SELECT Value__c FROM Mcube__mdt WHERE DeveloperName = 'APIKey' LIMIT 1];
        return keys.isEmpty() ? null : keys[0].Value__c;
    }
    
    /**
* Strips what MCube does not expect from a phone number, as mCubeController
* does: +91, +, brackets and spaces.
*
* @param  value  The raw phone number.
* @return The cleaned number, or '' when the input is blank.
*/
    private static String cleanNumber(String value) {
        if (String.isBlank(value)) return '';
        return value.replace('+91', '').replace('+', '').replace('(', '').replace(')', '').replace(' ', '');
    }
    
    /**
* Builds one part of a multipart/form-data request body.
*
* @param  boundary  The multipart boundary, without the leading "--".
* @param  name      The form field name.
* @param  value     The form field value.
* @return The encoded part, ending in CRLF.
*/
    private static String formField(String boundary, String name, String value) {
        return '--' + boundary + '\r\n'
            + 'Content-Disposition: form-data; name="' + name + '"\r\n\r\n'
            + value + '\r\n';
    }
    
    // ── Wrapper Classes ──────────────────────────────────────────────────
    
    /**
* Result returned to the softphone page's click-to-dial handler.
*   success - true when MCube accepted the call.
*   message - text shown to the agent in the softphone status bar.
*/
    public class ClickToCallResult {
        public Boolean success;
        public String  message;
        public ClickToCallResult(Boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }
    
    /**
* MCube call payload, with the same fields as mCubeController.callWrapper.
* mcubeCallRouting fills only callfrom and LandingNumber, because the
* softphone page sends just those two values.
*/
    public class callWrapper {
        String refid;
        String callid;
        String callfrom;
        String starttime;
        String filename;
        String calid;
        String pulse;
        String source;
        String custfeedback;
        String exefeedback;
        String dialstatus;
        String callerbusiness;
        String callername;
        String remark;
        String calleraddress;
        String caller_email;
        String rate;
        String empnumber;
        String endtime;
        String eid;
        String empid;
        String gid;
        String empemail;
        String status;
        String executive;
        String customer;
        String LandingNumber;
        String campaign;
    }
    
    /**
* Result of mcubeCallRouting, returned to the softphone page as JSON.
*   relatedToId - the matched or newly created record; null when unresolved.
*   hasError    - true when an exception was caught.
*   status      - RECORD_FOUND | RECORD_CREATED | NOT_RESOLVED | ERROR
*   message     - description of the result, or the exception message.
*/
    public class RoutingResponse {
        public String  relatedToId;
        public Boolean hasError;
        public String  status;
        public String  message;
    }
}