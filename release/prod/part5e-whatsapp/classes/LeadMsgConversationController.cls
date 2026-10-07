/**
 *  Description     : LeadMsgConversationController
 *  Created By      : Ejjigiri Praveen
 *  Created Date    : 22-06-2026
 *  Revision Logs   : V1.0 - Created - Ejjigiri Praveen
 *                     V1.1 - Added Connect REST API fallback (getConversationViaConnectApi)
 *                            + self-refreshing token logic for SV_User__c / Sales_User__c /
 *                            Lead Owner who are not the toolkit session owner.
 **/
public class LeadMsgConversationController {
    
    /* ============================================================
    getMessagingSessionId
        ============================================================ */
        @AuraEnabled(cacheable=true)
    public static String getMessagingSessionId(String leadId) {
        try {
            System.debug('inside getMessagingSessionId::');
            if (String.isBlank(leadId)) return null;
            Lead leadObj = getAuthorizedLead(leadId);
            if (leadObj == null) return null;
            System.debug('leadObj::'+leadObj);
            String phoneNumber = leadObj.Full_phone_number__c;
            if (String.isBlank(phoneNumber)) return null;
            List<MessagingEndUser> meuList = [
                SELECT Id FROM MessagingEndUser WHERE MessagingPlatformKey = :phoneNumber
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            System.debug('meuList::'+meuList);
            if (meuList.isEmpty()) return null;
            List<MessagingSession> activeSessions = [ SELECT Id, Status, OwnerId, CreatedDate FROM MessagingSession WHERE MessagingEndUserId = :meuList[0].Id AND Status = 'Active' ORDER BY CreatedDate DESC LIMIT 1 ]; if (!activeSessions.isEmpty()) { return activeSessions[0].Id; } List<MessagingSession> sessions = [ SELECT Id, Status, OwnerId, CreatedDate FROM MessagingSession WHERE MessagingEndUserId = :meuList[0].Id ORDER BY CreatedDate DESC LIMIT 1 ];
            System.debug('sessions::'+sessions);
            if (sessions.isEmpty()) return null;
        if (sessions[0].Status != 'Active') return null;return sessions[0].Id;} catch (Exception e) {System.debug('ERROR : ' + e.getMessage()); return null; }
    }
    
    /* ============================================================
    getTransferContext
        ============================================================ */
        @AuraEnabled(cacheable=false)
    public static TransferContext getTransferContext(String leadId) {
        TransferContext ctx = new TransferContext();
        if (String.isBlank(leadId)) return ctx;
        
        Lead leadObj = getAuthorizedLead(leadId);
        if (leadObj == null) return ctx;
        
        ctx.currentUserId = UserInfo.getUserId();
        MessagingSession session = resolveSession(leadObj);
        if (session != null) {
            ctx.sessionId      = session.Id;
            ctx.sessionStatus  = session.Status;
            ctx.sessionOwnerId = session.OwnerId;
        }
        Id currentUserId = UserInfo.getUserId();
        
        Boolean isSVUser = currentUserId == leadObj.SV_User__c;
        Boolean isSalesUser = currentUserId == leadObj.Sales_User__c;
        Boolean isParticipant = isSessionParticipant(leadObj.Full_phone_number__c, currentUserId);
        
        ctx.canTransfer = isSVUser || isSalesUser || isParticipant;
        return ctx;
    }
    
    /* ============================================================
    transferMessagingSession
        ============================================================ */
        @AuraEnabled
    public static TransferContext transferMessagingSession(String leadId, String userType) {
        Lead leadObj = getAuthorizedLead(leadId);
        if (leadObj == null) {
            throw new AuraHandledException('You are not authorized for this Lead.');
        }
        
        Id targetUserId;
        if (userType == 'ME')    targetUserId = UserInfo.getUserId();
        
        if (targetUserId == null) {throw new AuraHandledException('No ' + userType + ' user is set on this Lead.');}
        
        MessagingSession session = resolveSession(leadObj);
        if (session == null) {
            throw new AuraHandledException('No messaging session found for this Lead.');
        }
        if (session.Status != 'Active') {
            throw new AuraHandledException('The conversation is not active, so it cannot be transferred.');
        }
        if (session.OwnerId == targetUserId) {
            throw new AuraHandledException('That user already owns this conversation.');
        }
        
        MessagingSession full = [SELECT Id, OwnerId FROM MessagingSession WHERE Id = :session.Id LIMIT 1]; full.OwnerId = targetUserId; update full; return getTransferContext(leadId);
    }
    
    /* ============================================================
    getSessionAttachments  — UNCHANGED, working as-is
        ============================================================ */
        @AuraEnabled(cacheable=false)
    public static List<AttachmentWrapper> getSessionAttachments(String leadId) {
        List<AttachmentWrapper> out = new List<AttachmentWrapper>();
        if (String.isBlank(leadId)) return out;
        
        Lead leadObj = getAuthorizedLead(leadId);
        if (leadObj == null) return out;
        
        List<MessagingEndUser> meus = [
            SELECT Id
            FROM MessagingEndUser
            WHERE MessagingPlatformKey = :leadObj.Full_phone_number__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (meus.isEmpty()) {return out;}
        Set<Id> sessionIds = new Set<Id>();
        
        for (MessagingSession ms : [
            SELECT Id
            FROM MessagingSession
            WHERE MessagingEndUserId = :meus[0].Id
        ]) { sessionIds.add(ms.Id);system.debug('sessionIds==>'+sessionIds);}
        if (sessionIds.isEmpty()) {
            return out;
        }
        Set<Id> docIds = new Set<Id>();for (ContentDocumentLink cdl : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :sessionIds]) {system.debug('cdl==>'+cdl);docIds.add(cdl.ContentDocumentId);system.debug('docIds==>'+docIds);}if (docIds.isEmpty()) return out;for (ContentVersion cv : [SELECT Id,  CreatedBy.Name, CreatedBy.Profile.Name,Title, FileType, FileExtension, ContentDocumentId, CreatedDate, ContentSize, VersionData FROM ContentVersion WHERE ContentDocumentId IN :docIds AND IsLatest = true ORDER BY CreatedDate ASC]) {system.debug('cv==>'+cv);String profileName = cv.CreatedBy.Profile != null ? cv.CreatedBy.Profile.Name : '';system.debug('profileName::'+profileName);String createdByName = cv.CreatedBy.Name != null ? cv.CreatedBy.Name : '';system.debug('createdByName::'+createdByName);AttachmentWrapper a = new AttachmentWrapper();a.contentVersionId = cv.Id; String rawTitle = (cv.Title == null ? '' : cv.Title); if (createdByName == 'Automated Process') {a.isOutbound = false;} else if (profileName == 'Sales' || profileName == 'Presales Outbound') {a.isOutbound = true;} else {a.isOutbound = rawTitle.startsWith(SENT_PREFIX);}String cleanTitle = rawTitle.startsWith(SENT_PREFIX) ? rawTitle.substring(SENT_PREFIX.length()) : rawTitle;a.fileExtension    = (cv.FileExtension == null ? '' : cv.FileExtension.toLowerCase());String displayTitle = cleanTitle; if (String.isNotBlank(a.fileExtension) && !displayTitle.toLowerCase().endsWith('.' + a.fileExtension)) { displayTitle += '.' + a.fileExtension;} a.title = displayTitle; a.createdDate      = String.valueOf(cv.CreatedDate.getTime());   a.downloadUrl = '/sfc/servlet.shepherd/version/download/' + cv.Id;String ext = a.fileExtension; a.isImage = (new Set<String>{'jpg','jpeg','png','gif','webp','bmp'}).contains(ext);a.isAudio = (new Set<String>{'mp3','ogg','wav','m4a','aac','opus'}).contains(ext);a.isVideo = (new Set<String>{'mp4','mov','avi','webm','3gp'}).contains(ext);if (a.isAudio && cv.VersionData != null) {a.dataUri = 'data:' + audioMime(ext) + ';base64,'+ EncodingUtil.base64Encode(cv.VersionData);}
            System.debug('AUDIO FILE => title=' + cv.Title
                + ' ext=' + a.fileExtension
                + ' size=' + cv.ContentSize
                + ' hasData=' + (cv.VersionData != null));
    out.add(a);system.debug('out==>'+out);} return out;}
    
    /* ============================================================
    getAuthorizedLead
        ============================================================ */
    @TestVisible private static Lead getAuthorizedLead(String leadId) {
        List<Lead> leads = [SELECT Id, Name, Phone__c, Full_phone_number__c, OwnerId, SV_User__c, Sales_User__c
                            FROM Lead WHERE Id = :leadId WITH SYSTEM_MODE LIMIT 1];
        return leads.isEmpty() ? null : leads[0];
    }
    
    /* ============================================================
    isSessionParticipant
        ============================================================ */
    @TestVisible private static Boolean isSessionParticipant(String phone, Id userId) {
        List<MessagingEndUser> meu = [
            SELECT Id FROM MessagingEndUser
            WHERE MessagingPlatformKey = :phone
            ORDER BY CreatedDate DESC LIMIT 1
        ];
        if (meu.isEmpty()) return false;
        
        List<MessagingSession> sessions = [
            SELECT OwnerId FROM MessagingSession
            WHERE MessagingEndUserId = :meu[0].Id
            ORDER BY CreatedDate DESC LIMIT 1
            ];
        if (sessions.isEmpty()) return false;
        
        return sessions[0].OwnerId == userId;
    }
        
        @TestVisible private static MessagingSession testSession;
        
        private static MessagingSession resolveSession(Lead leadObj) {
            if (Test.isRunningTest()) {
                return testSession;
            }
            
        if (leadObj == null || String.isBlank(leadObj.Full_phone_number__c)) return null;List<MessagingEndUser> meu = [SELECT Id FROM MessagingEndUser WHERE MessagingPlatformKey = :leadObj.Full_phone_number__c ORDER BY CreatedDate DESC LIMIT 1];if (meu.isEmpty()) return null;List<MessagingSession> activeSessions = [ SELECT Id, Status, OwnerId, CreatedDate FROM MessagingSession WHERE MessagingEndUserId = :meu[0].Id AND Status = 'Active' ORDER BY CreatedDate DESC LIMIT 1 ]; if (!activeSessions.isEmpty()) { return activeSessions[0]; } List<MessagingSession> sessions = [ SELECT Id, Status, OwnerId, CreatedDate FROM MessagingSession WHERE MessagingEndUserId = :meu[0].Id ORDER BY CreatedDate DESC LIMIT 1 ];return sessions.isEmpty() ? null : sessions[0];}
        
        /* ============================================================
        notifyLeadStakeholders
            ============================================================ */
            @AuraEnabled
        public static void notifyLeadStakeholders(Id leadId, String messagePreview) {
            if (leadId == null) return;
            
            Lead ld = [
            SELECT Id, Name, OwnerId, SV_User__c, Sales_User__c
            FROM Lead WHERE Id = :leadId LIMIT 1
        ];
            
            Set<String> recipientIds = new Set<String>();
            
            if (ld.OwnerId != null && String.valueOf(ld.OwnerId).startsWith('005')) {
                recipientIds.add(ld.OwnerId);
            }
            
            if (ld.SV_User__c   != null) recipientIds.add(ld.SV_User__c);
            if (ld.Sales_User__c != null) recipientIds.add(ld.Sales_User__c);
            if (recipientIds.isEmpty()) return;
            
            CustomNotificationType notifType = [SELECT Id
                                            FROM CustomNotificationType
                                            WHERE DeveloperName = 'Lead_Assignment_Notification' LIMIT 1
                                           ];
            
            Messaging.CustomNotification n = new Messaging.CustomNotification();
            n.setTitle('New WhatsApp message');
            String body = (String.isNotBlank(messagePreview) ? messagePreview : 'New WhatsApp message received')
                + ' — ' + ld.Name;
            if (body.length() > 750) body = body.substring(0, 747) + '...';
            n.setBody(body);
            n.setNotificationTypeId(notifType.Id);
            n.setTargetId(leadId);
            
            try {
        n.send(recipientIds);} catch (Exception e) {System.debug('CustomNotification send failed => ' + e.getMessage());}}
        
        private static final String SENT_PREFIX = '[SENT] ';
        
       
        /* ============================================================================
        ============================================================================
            === CONNECT REST API FALLBACK — START =====================================
            For SV_User__c / Sales_User__c / Lead Owner who are NOT the current toolkit
            session owner. getConversationLog (lightning/conversationToolkitApi) only
            works for the live Omni-Channel session owner, so this method reads the
            same data via the Connect REST API instead, using a self-refreshing token
            (see TOKEN REFRESH LOGIC below) instead of a static/expiring credential.
            
        queryDirection=FromStart + recordLimit=1000 ensures the FULL conversation
            history is returned (oldest -> newest), not just the most recent ~25.
            ============================================================================ */
            @AuraEnabled(cacheable=false)
        public static List<ConversationWrapper> getConversationViaConnectApi(String leadId) {
            system.debug('inside getConversationViaConnectApi::');
            List<ConversationWrapper> wrappersList = new List<ConversationWrapper>();
            try {if (String.isBlank(leadId)) return wrappersList; Lead leadObj = getAuthorizedLead(leadId);if (leadObj == null) return wrappersList;if (String.isBlank(leadObj.Full_phone_number__c)) return wrappersList;
                
                List<MessagingEndUser> meusList = [SELECT Id FROM MessagingEndUser WHERE MessagingPlatformKey = :leadObj.Full_phone_number__c ORDER BY CreatedDate DESC LIMIT 1];system.debug('meusList'+meusList);if (meusList.isEmpty()) return wrappersList;MessagingSession sessionRec;if (Test.isRunningTest()) {sessionRec = new MessagingSession();} else { List<MessagingSession> msList = [SELECT Id, ConversationId FROM MessagingSession WHERE MessagingEndUserId = :meusList[0].Id ORDER BY CreatedDate DESC LIMIT 1];system.debug('msList::'+msList);if (msList.isEmpty()) return wrappersList; sessionRec = msList[0];}
                
                String conversationIdentifier;if (Test.isRunningTest()) { conversationIdentifier = 'TEST_CONVERSATION';} else {if (sessionRec.ConversationId == null) return wrappersList;List<Conversation> convList = [SELECT Id, ConversationIdentifier FROM Conversation WHERE Id = :sessionRec.ConversationId LIMIT 1];system.debug('convList::'+convList);if (convList.isEmpty()) return wrappersList; conversationIdentifier = convList[0].ConversationIdentifier;system.debug('conversationIdentifier::'+conversationIdentifier);}
                
                // --- FIX 1: use a fresh, auto-refreshed token instead of a static Custom Label ---
                system.debug('before access token ::');
                String accessToken = getFreshAccessToken();system.debug('After access token ::');system.debug('accessToken'+accessToken);if (String.isBlank(accessToken)) { System.debug('getConversationViaConnectApi: could not obtain access token.');return wrappersList;
                }
                
                // --- FIX 2: queryDirection=FromStart added so the FULL history loads,
                //            not just the most recent ~25 entries ---
                String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v60.0/connect/conversation/' + conversationIdentifier + '/entries?queryDirection=FromStart&recordLimit=1000';HttpRequest req = new HttpRequest(); req.setEndpoint(endpoint);req.setMethod('GET'); req.setHeader('Authorization', 'Bearer ' + accessToken);req.setHeader('Content-Type', 'application/json');req.setTimeout(20000);HttpResponse res = new Http().send(req);
                System.debug('CONNECT API STATUS:: ' + res.getStatusCode());
                
                // If the token was stale/rejected, force one refresh and retry ONCE.
                if (res.getStatusCode() == 401) { System.debug('CONNECT API 401 — forcing token refresh and retrying once.'); clearCachedToken();accessToken = getFreshAccessToken();if (String.isBlank(accessToken)) return wrappersList;req.setHeader('Authorization', 'Bearer ' + accessToken); res = new Http().send(req); System.debug('CONNECT API RETRY STATUS:: ' + res.getStatusCode());}if (res.getStatusCode() == 200) { Map<String,Object> responseMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());System.debug('responseMap:: ' +responseMap); List<Object> entries = (List<Object>) responseMap.get('conversationEntries');System.debug('entries:: ' +entries); if (entries != null) {Map<String,String> wrapperIdToRelatedId = new Map<String,String>();  Set<String> relatedIdsToFetch = new Set<String>();
                        for (Object obj : entries) { Map<String,Object> entry = (Map<String,Object>) obj;     System.debug('RAW CONNECT ENTRY => ' + JSON.serializePretty(entry));ConversationWrapper wrapObj = new ConversationWrapper();wrapObj.id = entry.containsKey('identifier') ? String.valueOf(entry.get('identifier')) : ''; wrapObj.message = extractMessageText(entry); Boolean hasRelated = false; if (entry.containsKey('relatedRecords')) { Object relObj = entry.get('relatedRecords'); if (relObj instanceof List<Object>) { hasRelated = !((List<Object>) relObj).isEmpty(); } } wrapObj.hasAttachmentSignal = String.isBlank(wrapObj.message) && hasRelated; if (String.isBlank(wrapObj.message) && String.isNotBlank(wrapObj.id)) { String relatedId = extractRelatedRecordId(entry); if (String.isNotBlank(relatedId)) { wrapperIdToRelatedId.put(wrapObj.id, relatedId); relatedIdsToFetch.add(relatedId); } } wrapObj.rawJson = JSON.serializePretty(entry); String senderSubject = ''; if (entry.containsKey('sender')) {Map<String,Object> senderMap = (Map<String,Object>) entry.get('sender'); wrapObj.actorType = senderMap.containsKey('role') ? String.valueOf(senderMap.get('role')) : ''; wrapObj.actorName = senderMap.containsKey('appType') ? String.valueOf(senderMap.get('appType')) : '';senderSubject = senderMap.containsKey('subject') ? String.valueOf(senderMap.get('subject')) : ''; } wrapObj.senderName = senderSubject; wrapObj.createdDate = entry.containsKey('serverReceivedTimestamp')? String.valueOf(entry.get('serverReceivedTimestamp')) : '';wrappersList.add(wrapObj);}if (!relatedIdsToFetch.isEmpty() && !Test.isRunningTest()) { Map<String,String> relatedIdToMessage = buildRelatedIdToMessageMap(relatedIdsToFetch);if (!relatedIdToMessage.isEmpty()) { for (ConversationWrapper w : wrappersList) { if (String.isBlank(w.message) && wrapperIdToRelatedId.containsKey(w.id)) { String relId = wrapperIdToRelatedId.get(w.id); if (relatedIdToMessage.containsKey(relId)) { w.message = relatedIdToMessage.get(relId); } }}} }
                        
                        // === SENDER NAME RESOLUTION — same as your working version ===
            Set<Id> agentUserIds = new Set<Id>();for (ConversationWrapper w : wrappersList) { String at = (w.actorType == null) ? '' : w.actorType.toLowerCase(); if (at == 'agent' && String.isNotBlank(w.senderName)) { try { agentUserIds.add((Id) w.senderName); } catch (Exception ex) { /* not a User Id*/  }} } Map<Id, String> userIdToName = new Map<Id, String>();if (!agentUserIds.isEmpty()) {for (User u : [SELECT Id, Name FROM User WHERE Id IN :agentUserIds WITH SYSTEM_MODE]) { userIdToName.put(u.Id, u.Name);}} for (ConversationWrapper w : wrappersList) { String at = (w.actorType == null) ? '' : w.actorType.toLowerCase(); if (at == 'agent') {Id uId = null;try { uId = (Id) w.senderName; } catch (Exception ex) { /* keep null */ } w.senderName = (uId != null && userIdToName.containsKey(uId))? userIdToName.get(uId) : 'Agent';} else if (at == 'enduser') { w.senderName = leadObj.Name; } else if (at == 'chatbot') { w.senderName = 'Bot'; } else if (at == 'system') { w.senderName = 'System';} else {w.senderName = '';}}}} else {System.debug('CONNECT API ERROR:: ' + res.getStatusCode() + ' : ' + res.getBody());}} catch (Exception e) {System.debug('getConversationViaConnectApi ERROR:: ' + e.getMessage());System.debug('STACK:: ' + e.getStackTraceString()); }maskConversationForUser(wrappersList); return wrappersList; // Mobile number masking (v1.5.0 5e)
        }

        // Mobile number masking (v1.5.0 5e): for users who cannot see Lead.Phone__c, mask phone numbers inside the
        // conversation before it goes to the screen (message text, raw Messaging data, sender name).
        @TestVisible
        private static void maskConversationForUser(List<ConversationWrapper> rows) {
            if (rows == null || !PhoneDisplayService.isMaskedUser()) {
                return;
            }
            for (ConversationWrapper row : rows) {
                row.message = PhoneMaskUtil.maskInText(row.message);
                row.rawJson = PhoneMaskUtil.maskInText(row.rawJson);
                row.senderName = PhoneMaskUtil.maskInText(row.senderName);
            }
        }
        
        /* ---------------------------------------------------------------
        KEEP YOUR EXISTING extractMessageText / extractRelatedRecordId /
            buildRelatedIdToMessageMap implementations here instead of these
            stubs, if you already have them — they already work correctly
            per your screenshot. These stubs are only here so this file
            compiles standalone if those methods aren't in your class yet.
            --------------------------------------------------------------- */
        private static String extractMessageText(Map<String,Object> entry) {if (entry == null) return '';try {if (entry.containsKey('messageText')) return String.valueOf(entry.get('messageText')); Object valueObj = entry.get('value');if (valueObj instanceof Map<String,Object>) { Map<String,Object> valueMap = (Map<String,Object>) valueObj;Object contentObj = valueMap.get('content');if (contentObj instanceof Map<String,Object>) {Object t = ((Map<String,Object>) contentObj).get('text');if (t != null) return String.valueOf(t);}}Object contentObj2 = entry.get('content');if (contentObj2 instanceof Map<String,Object>) {Object t = ((Map<String,Object>) contentObj2).get('text');if (t != null) return String.valueOf(t);} else if (contentObj2 instanceof String) { return String.valueOf(contentObj2);}Object amObj = entry.get('abstractMessage');if (amObj instanceof Map<String,Object>) { Object scObj = ((Map<String,Object>) amObj).get('staticContent');if (scObj instanceof Map<String,Object>) {Object t = ((Map<String,Object>) scObj).get('text'); if (t != null) return String.valueOf(t);}}Object bodyObj = entry.get('body');if (bodyObj instanceof Map<String,Object>) {Object t = ((Map<String,Object>) bodyObj).get('text');if (t != null) return String.valueOf(t);}} catch (Exception ex) {System.debug('extractMessageText probe error => ' + ex.getMessage());} return '';}
        
        private static String extractRelatedRecordId(Map<String,Object> entry) {return null;  }
        
        private static Map<String,String> buildRelatedIdToMessageMap(Set<String> relatedIds) {return new Map<String,String>();}
        /* === CONNECT REST API FALLBACK — END ===================================== */

        private static final List<String> TOKEN_FIELD_NAMES = new List<String>{'Access_Token__c','Access_Token_Ext__c','Access_Token_Ext1__c','Access_Token_Ext2__c','Access_Token_Ext3__c','Access_Token_Ext4__c'};private static final Integer CHUNK_SIZE = 255;
        private static String getFreshAccessToken() {Lead_Msg_Token__c cached = Lead_Msg_Token__c.getInstance('Default');if (cached != null) {String joined = joinTokenParts(cached);if (String.isNotBlank(joined) && cached.Expires_At__c != null && System.now().getTime() < cached.Expires_At__c) {return joined;}}LeadMsgApiCreds__mdt creds = LeadMsgApiCreds__mdt.getInstance('Default');if (creds == null || String.isBlank(creds.Consumer_Key__c) || String.isBlank(creds.Consumer_Secret__c)) {System.debug('LeadMsgApiCreds__mdt "Default" record not configured.');return null;}HttpRequest tokenReq = new HttpRequest();tokenReq.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/oauth2/token');tokenReq.setMethod('POST');tokenReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');tokenReq.setBody('grant_type=client_credentials' + '&client_id=' + EncodingUtil.urlEncode(creds.Consumer_Key__c, 'UTF-8') + '&client_secret=' + EncodingUtil.urlEncode(creds.Consumer_Secret__c, 'UTF-8'));tokenReq.setTimeout(20000);HttpResponse tokenRes = new Http().send(tokenReq);if (tokenRes.getStatusCode() != 200) {System.debug('Token refresh failed => ' + tokenRes.getStatusCode() + ' : ' + tokenRes.getBody()); return null;}Map<String, Object> tokenJson = (Map<String, Object>) JSON.deserializeUntyped(tokenRes.getBody());String newToken = (String) tokenJson.get('access_token');if (String.isBlank(newToken)) return null;Integer maxCapacity = TOKEN_FIELD_NAMES.size() * CHUNK_SIZE;if (newToken.length() > maxCapacity) {System.debug('WARNING: access_token length ' + newToken.length()+ ' exceeds current ' + maxCapacity + '-char split capacity. Add another Ext field to TOKEN_FIELD_NAMES.');}Lead_Msg_Token__c toSave = Lead_Msg_Token__c.getInstance('Default');if (toSave == null) {toSave = new Lead_Msg_Token__c(Name = 'Default');}splitTokenIntoParts(newToken, toSave);toSave.Expires_At__c = System.now().getTime() + (90L * 60L * 1000L);upsert toSave;return newToken;}
        private static void clearCachedToken() {Lead_Msg_Token__c cached = Lead_Msg_Token__c.getInstance('Default');if (cached != null) {for (String fieldName : TOKEN_FIELD_NAMES) {cached.put(fieldName, null);}cached.Expires_At__c = null;upsert cached;}}
        private static void splitTokenIntoParts(String token, Lead_Msg_Token__c rec) {for (Integer i = 0; i < TOKEN_FIELD_NAMES.size(); i++) {Integer startIndex = i * CHUNK_SIZE;String chunk = (token != null && startIndex < token.length())? token.substring(startIndex, Math.min(startIndex + CHUNK_SIZE, token.length())): null;rec.put(TOKEN_FIELD_NAMES[i], chunk);}}
        private static String joinTokenParts(Lead_Msg_Token__c rec) {String result = '';for (String fieldName : TOKEN_FIELD_NAMES) { Object val = rec.get(fieldName);if (val != null) result += String.valueOf(val);}return result;}
        /* === TOKEN REFRESH LOGIC — END ============================================ */
        
        
        public class OutboundFileResult {@AuraEnabled public String contentVersionId;@AuraEnabled public String fileName; @AuraEnabled public String publicUrl;@AuraEnabled public Boolean nativeSent;}
        
        public class TransferContext {
            @AuraEnabled public Id     currentUserId;
            @AuraEnabled public Id     sessionId;
            @AuraEnabled public String sessionStatus;
            @AuraEnabled public Id     sessionOwnerId;
            @AuraEnabled public Boolean canTransfer;
        }
        
        public class AttachmentWrapper {
            @AuraEnabled public String  contentVersionId;
            @AuraEnabled public String  title;
            @AuraEnabled public String  fileExtension;
            @AuraEnabled public String  downloadUrl;
            @AuraEnabled public String  createdDate;
            @AuraEnabled public Boolean isImage;
            @AuraEnabled public Boolean isAudio;
            @AuraEnabled public Boolean isVideo;
            @AuraEnabled public Boolean isOutbound;
            @AuraEnabled public String dataUri;
        }
        
        /* === NEW: wrapper for Connect REST API rows — matches the row shape
        the LWC already expects (id, message, actorType, senderName, createdDate) === */
        public class ConversationWrapper {
            @AuraEnabled public String id;
            @AuraEnabled public String message;
            @AuraEnabled public String actorType;
            @AuraEnabled public String actorName;
            @AuraEnabled public String senderName;
            @AuraEnabled public String createdDate;
            @AuraEnabled public String rawJson;@AuraEnabled public Boolean hasAttachmentSignal; // NEW
        }
        
        private static String audioMime(String ext) {if (ext == 'mp3')  return 'audio/mpeg';if (ext == 'ogg' || ext == 'opus') return 'audio/ogg';if (ext == 'wav')  return 'audio/wav';if (ext == 'm4a')  return 'audio/mp4';if (ext == 'aac')  return 'audio/aac';return 'audio/mpeg';}
    }