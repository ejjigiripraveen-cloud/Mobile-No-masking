/**
 * @description Server side of the findByNumber LWC (v1.8.0). Finds the Leads that carry a phone number, for
 *              masked users who can no longer find a Lead by number in global search. Returns MASKED numbers
 *              only: the real number never leaves Apex.
 *
 *              Rules:
 *                1. the full number is required (10 to 15 digits after normalising), so numbers cannot be
 *                   probed with partial digits;
 *                2. only Leads the user can see are returned ("with sharing"). Field-level security is
 *                   intentionally not applied to the search, because masked users cannot read the phone fields;
 *                3. a Lead is returned only when one of its phone fields, or a phone on one of its Related
 *                   Sources, is exactly the searched number after normalising (no partial or fuzzy matches);
 *                4. every search, valid or not, is written to Phone_Access_Audit__c (Action = Search) with the
 *                   masked number only.
 *              Limits per search: one SOSL, at most one SOQL, one DML (audit).
 * @group       Phone Masking
 */
public with sharing class FindByNumberController {
    public static final String ACTION_SEARCH = 'Search';
    public static final String CHANNEL = 'Find by number';

    @TestVisible
    private static final Integer MAX_RESULTS = 50;
    private static final Integer MIN_DIGITS = 10;
    private static final Integer MAX_DIGITS = 15;
    // Digits, spaces, '+', '-', '(' and ')' only, e.g. '+91 98765-43221'.
    private static final Pattern ALLOWED_INPUT = Pattern.compile('^[0-9 +\\-()]+$');

    // Lead phone fields checked for an exact match, in the order they are reported.
    private static final List<Schema.SObjectField> LEAD_PHONE_FIELDS = new List<Schema.SObjectField>{
        Lead.Phone__c, Lead.Secondary_Phone__c, Lead.Phone, Lead.MobilePhone
    };
    private static final List<Schema.SObjectField> SOURCE_PHONE_FIELDS = new List<Schema.SObjectField>{
        Related_Source__c.Phone__c, Related_Source__c.Secondary_Phone__c
    };
    private static final String MATCHED_ON_SOURCE = 'Related Source';

    /**
     * @description One Lead found. Holds no real phone number.
     */
    public class LeadMatch {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String leadNumber;
        @AuraEnabled public String status;
        @AuraEnabled public String project;
        @AuraEnabled public String ownerName;
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String matchedOn;
        @AuraEnabled public String maskedNumber;
    }

    /**
     * @description Result of one search: the masked searched number and the Leads found (newest first).
     *              A rejected search returns errorMessage instead of throwing, so its audit row is kept
     *              (an exception would roll the audit insert back).
     */
    public class SearchResult {
        @AuraEnabled public String maskedNumber;
        @AuraEnabled public List<LeadMatch> leads = new List<LeadMatch>();
        @AuraEnabled public Boolean hasMore = false;
        @AuraEnabled public String errorMessage;
    }

    /**
     * @description Finds the Leads with this phone number. Not cacheable: every search is audited.
     * @param phoneNumber the full number as typed, e.g. '9876543221' or '+91 98765 43221'
     */
    @AuraEnabled
    public static SearchResult findLeads(String phoneNumber) {
        String national = PhoneMaskUtil.normalize(phoneNumber);
        String maskedNumber = PhoneMaskUtil.mask(national);
        SearchResult result = new SearchResult();
        result.maskedNumber = maskedNumber;

        if (!Schema.SObjectType.Lead.isAccessible()) {
            writeAudit(MaskedDialService.OUTCOME_DENIED, maskedNumber, null, 'No access to Lead.');
            result.errorMessage = 'You do not have access to Leads.';
            return result;
        }
        if (String.isBlank(phoneNumber)
                || !ALLOWED_INPUT.matcher(phoneNumber.trim()).matches()
                || national.length() < MIN_DIGITS
                || national.length() > MAX_DIGITS) {
            writeAudit(MaskedDialService.OUTCOME_DENIED, maskedNumber, null, 'Invalid or partial number.');
            result.errorMessage = 'Enter the full mobile number (10 digits, with or without +91).';
            return result;
        }

        // 1. Search index (finds the number in any format it was saved in). SOSL runs with sharing.
        String searchTerm = String.join(new List<String>(searchVariants(national)), ' OR ');
        List<List<SObject>> found = [
            FIND :searchTerm IN PHONE FIELDS
            RETURNING
                Lead(Id, Name, Lead_ID__c, Status, Project__c, Owner.Name, RecordType.Name, CreatedDate,
                    Phone__c, Secondary_Phone__c, Phone, MobilePhone
                    ORDER BY CreatedDate DESC LIMIT 200),
                Related_Source__c(Id, Lead__c, Phone__c, Secondary_Phone__c WHERE Lead__c != null LIMIT 200)
        ];

        // 2. Keep exact matches only.
        Map<Id, String> matchedOnById = new Map<Id, String>();
        Map<Id, Lead> leadsById = new Map<Id, Lead>();
        for (Lead candidate : (List<Lead>) found[0]) {
            String matchedOn = matchingField(candidate, LEAD_PHONE_FIELDS, national);
            if (matchedOn != null) {
                matchedOnById.put(candidate.Id, matchedOn);
                leadsById.put(candidate.Id, candidate);
            }
        }
        Set<Id> sourceLeadIds = new Set<Id>();
        for (Related_Source__c source : (List<Related_Source__c>) found[1]) {
            if (!matchedOnById.containsKey(source.Lead__c)
                    && matchingField(source, SOURCE_PHONE_FIELDS, national) != null) {
                sourceLeadIds.add(source.Lead__c);
                matchedOnById.put(source.Lead__c, MATCHED_ON_SOURCE);
            }
        }

        // 3. Leads found only through a Related Source: one query, still with sharing.
        if (!sourceLeadIds.isEmpty()) {
            for (Lead parent : [
                SELECT Id, Name, Lead_ID__c, Status, Project__c, Owner.Name, RecordType.Name, CreatedDate
                FROM Lead
                WHERE Id IN :sourceLeadIds
                ORDER BY CreatedDate DESC
                LIMIT 200
            ]) {
                leadsById.put(parent.Id, parent);
            }
        }

        List<Lead> ordered = leadsById.values();
        ordered.sort(new NewestFirst());
        for (Lead match : ordered) {
            if (result.leads.size() == MAX_RESULTS) {
                result.hasMore = true;
                break;
            }
            result.leads.add(toMatch(match, matchedOnById.get(match.Id), maskedNumber));
        }

        Integer count = ordered.size();
        writeAudit(
            count == 0 ? MaskedDialService.OUTCOME_NOT_FOUND : MaskedDialService.OUTCOME_SUCCESS,
            maskedNumber,
            count == 1 ? ordered[0].Id : null,
            count + (count == 1 ? ' lead found.' : ' leads found.')
        );
        return result;
    }

    /**
     * @description The forms a number may be saved in: '9876543221', '919876543221', '09876543221'.
     *              Digits only, so the SOSL term needs no escaping.
     */
    @TestVisible
    private static Set<String> searchVariants(String national) {
        Set<String> variants = new Set<String>{ national };
        String countryCode = PhoneMaskingConfig.countryCode();
        if (national.length() == MIN_DIGITS) {
            if (String.isNotBlank(countryCode)) {
                variants.add(countryCode + national);
            }
            variants.add('0' + national);
        }
        return variants;
    }

    private static String matchingField(SObject record, List<Schema.SObjectField> fields, String national) {
        for (Schema.SObjectField field : fields) {
            String value = (String) record.get(field);
            if (String.isNotBlank(value) && PhoneMaskUtil.normalize(value) == national) {
                return field.getDescribe().getLabel();
            }
        }
        return null;
    }

    private static LeadMatch toMatch(Lead record, String matchedOn, String maskedNumber) {
        LeadMatch match = new LeadMatch();
        match.recordId = record.Id;
        match.name = record.Name;
        match.leadNumber = record.Lead_ID__c;
        match.status = record.Status;
        match.project = record.Project__c;
        match.ownerName = record.Owner?.Name;
        match.recordTypeName = record.RecordType?.Name;
        match.createdDate = record.CreatedDate;
        match.matchedOn = matchedOn;
        match.maskedNumber = maskedNumber;
        return match;
    }

    /**
     * @description One audit row per search, masked number only. Reps have no access to the audit object,
     *              so the insert runs in system mode. A failed audit row does not block the search.
     */
    private static void writeAudit(String outcome, String maskedNumber, Id recordId, String message) {
        if (!PhoneMaskingConfig.isAuditEnabled()) {
            return;
        }
        Phone_Access_Audit__c audit = new Phone_Access_Audit__c(
            Action__c = ACTION_SEARCH,
            Outcome__c = outcome,
            User__c = UserInfo.getUserId(),
            Record_Id__c = recordId,
            Object_Name__c = 'Lead',
            Masked_Number__c = maskedNumber == null ? null : maskedNumber.left(40),
            Channel__c = CHANNEL,
            Message__c = message.left(255),
            Event_Time__c = System.now()
        );
        Database.SaveResult saveResult = Database.insert(audit, false);
        if (!saveResult.isSuccess()) {
            System.debug(LoggingLevel.ERROR, 'Phone Access Audit insert failed: ' + saveResult.getErrors()[0].getMessage());
        }
    }

    private class NewestFirst implements Comparator<Lead> {
        public Integer compare(Lead first, Lead second) {
            if (first.CreatedDate == second.CreatedDate) {
                return 0;
            }
            if (first.CreatedDate == null) {
                return 1;
            }
            if (second.CreatedDate == null) {
                return -1;
            }
            return first.CreatedDate > second.CreatedDate ? -1 : 1;
        }
    }
}
