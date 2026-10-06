/**
 * @description Resolves the real phone number behind a masked number, for server-side callers only
 *              (dialer adapters). The real number must never be returned to a browser component or logged.
 *
 *              A request is granted only when:
 *                1. the real-number lookup is switched on (Phone_Masking_Setting__mdt.Resolve_Enabled__c);
 *                2. the field is on the approved list (Masked_Phone_Field__mdt) for the requested action;
 *                3. the field belongs to the record's object;
 *                4. the user can read the object and can see the record (same access as today -
 *                   enforced by "with sharing"). Field-level security is intentionally not applied,
 *                   because reps cannot read the phone fields once masking is live.
 *
 *              Every request, granted or not, is written to Phone_Access_Audit__c with the masked
 *              number only. Bulk-safe: one query per object type and one insert for all audit rows.
 * @group       Phone Masking
 */
public with sharing class MaskedDialService {
    public static final String ACTION_DIAL = 'Dial';
    public static final String ACTION_REVEAL = 'Reveal';

    public static final String OUTCOME_SUCCESS = 'Success';
    public static final String OUTCOME_DENIED = 'Denied';
    public static final String OUTCOME_NOT_FOUND = 'Not Found';
    public static final String OUTCOME_ERROR = 'Error';

    @TestVisible
    private static final Integer MAX_REQUESTS = 200;

    // Deferred audit: callers that make an HTTP callout after resolving (e.g. MCube) must not write
    // to the database before the callout, so they defer the audit write and flush it afterwards.
    private static Boolean deferAudits = false;
    @TestVisible
    private static List<Phone_Access_Audit__c> pendingAudits = new List<Phone_Access_Audit__c>();

    /**
     * @description One request for a real number.
     */
    public class DialRequest {
        public Id recordId;
        public String fieldKey;
        public String channel;
        public String reason;

        public DialRequest(Id recordId, String fieldKey, String channel) {
            this.recordId = recordId;
            this.fieldKey = fieldKey;
            this.channel = channel;
        }
    }

    /**
     * @description Result of one request. phoneNumber holds the real number only when success = true.
     */
    public class DialResult {
        public Id recordId;
        public String fieldKey;
        public Boolean success = false;
        public String phoneNumber;
        public String maskedNumber;
        public String outcome;
        public String message;
    }

    /**
     * @description Resolves a single number for click-to-dial.
     */
    public static DialResult resolveOne(Id recordId, String fieldKey, String channel) {
        return resolve(new List<DialRequest>{ new DialRequest(recordId, fieldKey, channel) }, ACTION_DIAL)[0];
    }

    /**
     * @description Holds audit rows in memory instead of writing them, until flushAudits() is called.
     *              Use when an HTTP callout follows the lookup in the same transaction.
     */
    public static void deferAuditWrites() {
        deferAudits = true;
    }

    /**
     * @description Writes the held audit rows (one insert) and stops deferring.
     * @param note optional text added to the Message of rows that have none, e.g. the call result
     */
    public static void flushAudits(String note) {
        deferAudits = false;
        if (pendingAudits.isEmpty()) {
            return;
        }
        if (String.isNotBlank(note)) {
            for (Phone_Access_Audit__c audit : pendingAudits) {
                if (String.isBlank(audit.Message__c)) {
                    audit.Message__c = note.left(255);
                }
            }
        }
        List<Phone_Access_Audit__c> toWrite = pendingAudits;
        pendingAudits = new List<Phone_Access_Audit__c>();
        writeAudits(toWrite);
    }

    /**
     * @description Finds which approved dial field of the record shows the given masked value, for clicks
     *              that carry only the masked number (no field key). Returns null when no field or more than
     *              one field matches. The user must be able to see the record (with sharing). One query.
     */
    public static String fieldKeyForMaskedNumber(Id recordId, String maskedNumber) {
        if (recordId == null || String.isBlank(maskedNumber)) {
            return null;
        }
        Schema.DescribeSObjectResult objectDescribe =
            recordId.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
        if (!objectDescribe.isAccessible()) {
            return null;
        }
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Map<String, String> keyByField = new Map<String, String>();
        for (Masked_Phone_Field__mdt config : PhoneMaskingConfig.getActiveFields().values()) {
            Schema.SObjectField field = fieldMap.get(config.Field_API_Name__c);
            if (config.Allow_Dial__c == true && field != null
                    && objectDescribe.getName().equalsIgnoreCase(config.Object_API_Name__c)) {
                String fieldName = field.getDescribe().getName();
                keyByField.put(fieldName, objectDescribe.getName() + '.' + fieldName);
            }
        }
        if (keyByField.isEmpty()) {
            return null;
        }
        String soql = 'SELECT Id, ' + String.join(new List<String>(keyByField.keySet()), ', ')
            + ' FROM ' + objectDescribe.getName() + ' WHERE Id = :recordId LIMIT 1';
        List<SObject> records = Database.queryWithBinds(
            soql, new Map<String, Object>{ 'recordId' => recordId }, AccessLevel.SYSTEM_MODE
        );
        if (records.isEmpty()) {
            return null;
        }
        String target = maskedNumber.trim();
        String match;
        for (String fieldName : keyByField.keySet()) {
            String value = (String) records[0].get(fieldName);
            if (String.isNotBlank(value) && PhoneMaskUtil.mask(value) == target) {
                if (match != null) {
                    return null; // ambiguous: two fields show the same masked value
                }
                match = keyByField.get(fieldName);
            }
        }
        return match;
    }

    /**
     * @description Resolves many numbers at once. Results are returned in the same order as the requests.
     * @param requests list of requests (max 200 per call)
     * @param action   ACTION_DIAL or ACTION_REVEAL
     */
    public static List<DialResult> resolve(List<DialRequest> requests, String action) {
        List<DialResult> results = new List<DialResult>();
        if (requests == null || requests.isEmpty()) {
            return results;
        }

        Map<String, Masked_Phone_Field__mdt> approvedFields = PhoneMaskingConfig.getActiveFields();
        Boolean resolveEnabled = PhoneMaskingConfig.isResolveEnabled();
        Boolean tooManyRequests = requests.size() > MAX_REQUESTS;

        Map<Schema.SObjectType, Schema.DescribeSObjectResult> describeCache =
            new Map<Schema.SObjectType, Schema.DescribeSObjectResult>();
        Map<String, Set<Id>> idsByObject = new Map<String, Set<Id>>();
        Map<String, Set<String>> fieldsByObject = new Map<String, Set<String>>();
        List<String> objectNames = new List<String>();
        List<String> fieldNames = new List<String>();

        // 1. Validate every request and group the valid ones by object (no queries here).
        for (DialRequest request : requests) {
            DialResult result = new DialResult();
            result.recordId = request?.recordId;
            result.fieldKey = request?.fieldKey;
            results.add(result);
            objectNames.add(null);
            fieldNames.add(null);

            if (!resolveEnabled) {
                setOutcome(result, OUTCOME_DENIED, 'Real number lookup is switched off.');
                continue;
            }
            if (tooManyRequests) {
                setOutcome(result, OUTCOME_DENIED, 'Too many requests in one call (max ' + MAX_REQUESTS + ').');
                continue;
            }
            if (request == null || request.recordId == null || String.isBlank(request.fieldKey)) {
                setOutcome(result, OUTCOME_DENIED, 'Record and field are required.');
                continue;
            }
            Masked_Phone_Field__mdt fieldConfig = approvedFields.get(request.fieldKey.trim().toLowerCase());
            if (fieldConfig == null || !isAllowed(fieldConfig, action)) {
                setOutcome(result, OUTCOME_DENIED, 'Field is not approved for ' + action + '.');
                continue;
            }

            Schema.SObjectType objectType = request.recordId.getSObjectType();
            Schema.DescribeSObjectResult objectDescribe = describeCache.get(objectType);
            if (objectDescribe == null) {
                objectDescribe = objectType.getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
                describeCache.put(objectType, objectDescribe);
            }
            String objectName = objectDescribe.getName();
            if (!objectName.equalsIgnoreCase(fieldConfig.Object_API_Name__c)) {
                setOutcome(result, OUTCOME_DENIED, 'Field does not belong to this record.');
                continue;
            }
            if (!objectDescribe.isAccessible()) {
                setOutcome(result, OUTCOME_DENIED, 'No access to ' + objectName + '.');
                continue;
            }
            Schema.SObjectField field = objectDescribe.fields.getMap().get(fieldConfig.Field_API_Name__c);
            if (field == null) {
                setOutcome(result, OUTCOME_ERROR, 'Configured field does not exist.');
                continue;
            }

            String fieldName = field.getDescribe().getName();
            objectNames[objectNames.size() - 1] = objectName;
            fieldNames[fieldNames.size() - 1] = fieldName;
            if (!idsByObject.containsKey(objectName)) {
                idsByObject.put(objectName, new Set<Id>());
                fieldsByObject.put(objectName, new Set<String>());
            }
            idsByObject.get(objectName).add(request.recordId);
            fieldsByObject.get(objectName).add(fieldName);
        }

        // 2. Read the numbers: one query per object type (bounded by the approved list, normally only Lead).
        Map<Id, SObject> recordsById = queryRecords(idsByObject, fieldsByObject);

        // 3. Build results and audit rows.
        List<Phone_Access_Audit__c> audits = new List<Phone_Access_Audit__c>();
        for (Integer i = 0; i < results.size(); i++) {
            DialResult result = results[i];
            DialRequest request = requests[i];
            if (result.outcome == null) {
                SObject record = recordsById.get(request.recordId);
                String phoneNumber = record == null ? null : (String) record.get(fieldNames[i]);
                if (record == null) {
                    setOutcome(result, OUTCOME_DENIED, 'Record not found or no access.');
                } else if (String.isBlank(phoneNumber)) {
                    setOutcome(result, OUTCOME_NOT_FOUND, 'No number on this record.');
                } else {
                    result.success = true;
                    result.phoneNumber = phoneNumber;
                    result.maskedNumber = PhoneMaskUtil.mask(phoneNumber);
                    result.outcome = OUTCOME_SUCCESS;
                }
            }
            audits.add(buildAudit(request, result, action, objectNames[i]));
        }

        if (PhoneMaskingConfig.isAuditEnabled()) {
            if (deferAudits) {
                pendingAudits.addAll(audits);
            } else {
                writeAudits(audits);
            }
        }
        return results;
    }

    private static Map<Id, SObject> queryRecords(Map<String, Set<Id>> idsByObject, Map<String, Set<String>> fieldsByObject) {
        Map<Id, SObject> recordsById = new Map<Id, SObject>();
        for (String objectName : idsByObject.keySet()) {
            // Object and field names come from the schema describe, never from user input.
            String soql = 'SELECT Id, ' + String.join(new List<String>(fieldsByObject.get(objectName)), ', ')
                + ' FROM ' + objectName + ' WHERE Id IN :recordIds';
            // SYSTEM_MODE skips field-level security; record sharing still follows this class's "with sharing".
            recordsById.putAll(Database.queryWithBinds(
                soql,
                new Map<String, Object>{ 'recordIds' => idsByObject.get(objectName) },
                AccessLevel.SYSTEM_MODE
            ));
        }
        return recordsById;
    }

    private static Boolean isAllowed(Masked_Phone_Field__mdt fieldConfig, String action) {
        if (action == ACTION_DIAL) {
            return fieldConfig.Allow_Dial__c == true;
        }
        if (action == ACTION_REVEAL) {
            return fieldConfig.Allow_Reveal__c == true;
        }
        return false;
    }

    private static void setOutcome(DialResult result, String outcome, String message) {
        result.success = false;
        result.phoneNumber = null;
        result.outcome = outcome;
        result.message = message;
    }

    private static Phone_Access_Audit__c buildAudit(DialRequest request, DialResult result, String action, String objectName) {
        return new Phone_Access_Audit__c(
            Action__c = action,
            Outcome__c = result.outcome,
            User__c = UserInfo.getUserId(),
            Record_Id__c = result.recordId,
            Object_Name__c = objectName,
            Field_Key__c = result.fieldKey == null ? null : result.fieldKey.left(120),
            Masked_Number__c = result.maskedNumber,
            Channel__c = request?.channel == null ? null : request.channel.left(80),
            Reason__c = request?.reason == null ? null : request.reason.left(255),
            Message__c = result.message == null ? null : result.message.left(255),
            Event_Time__c = System.now()
        );
    }

    /**
     * @description Writes audit rows in one insert. Reps have no access to the audit object, so the insert
     *              runs in system mode. A failed audit row does not block the call; the failure is logged
     *              without any phone number.
     */
    private static void writeAudits(List<Phone_Access_Audit__c> audits) {
        List<Database.SaveResult> saveResults = Database.insert(audits, false);
        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess()) {
                System.debug(LoggingLevel.ERROR, 'Phone Access Audit insert failed: ' + saveResult.getErrors()[0].getMessage());
            }
        }
    }
}
