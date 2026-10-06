/**
 * @description Mobile number masking (v1.5.0). One rule for every existing screen that shows phone numbers:
 *                - isMaskedUser(): true when the current user cannot read Lead.Phone__c (field-level security).
 *                  Users who can read it keep seeing full numbers, exactly as before.
 *                - maskForDisplay() / maskAllForDisplay() / maskValues(): mask numbers before they go to a screen.
 *                - resolve(): when a screen sends a masked number back (e.g. to place a call), finds the real
 *                  number on the server among the record's numbers, after checking the user can see the record,
 *                  and audits the access. The real number is returned to server code only.
 * @group       Phone Masking
 */
public with sharing class PhoneDisplayService {
    public static final String OUTCOME_SUCCESS = MaskedDialService.OUTCOME_SUCCESS;
    public static final String OUTCOME_DENIED = MaskedDialService.OUTCOME_DENIED;
    public static final String OUTCOME_NOT_FOUND = MaskedDialService.OUTCOME_NOT_FOUND;

    @TestVisible
    private static Boolean maskedUserOverride;

    /**
     * @description True when the current user cannot read Lead.Phone__c.
     */
    public static Boolean isMaskedUser() {
        if (maskedUserOverride != null) {
            return maskedUserOverride;
        }
        return !Schema.SObjectType.Lead.fields.Phone__c.isAccessible();
    }

    /**
     * @description True when the value is a masked number (contains X). Real numbers never contain X.
     */
    public static Boolean isMasked(String value) {
        return value != null && value.containsIgnoreCase('X');
    }

    /**
     * @description Masks one number for display, keeping a leading "+cc " prefix:
     *              "+91 9876543221" -> "+91 98XXXXXX21"; "9876543221" -> "98XXXXXX21".
     */
    public static String maskForDisplay(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        String trimmed = value.trim();
        Integer space = trimmed.lastIndexOf(' ');
        if (trimmed.startsWith('+') && space > 0) {
            return trimmed.substring(0, space + 1) + PhoneMaskUtil.mask(trimmed.substring(space + 1));
        }
        return PhoneMaskUtil.mask(trimmed);
    }

    /**
     * @description Masks a list for display, keeping the order. Null-safe.
     */
    public static List<String> maskAllForDisplay(List<String> values) {
        List<String> masked = new List<String>();
        if (values == null) {
            return masked;
        }
        for (String value : values) {
            masked.add(maskForDisplay(value));
        }
        return masked;
    }

    /**
     * @description For masked users, masks the given keys of a map in place (e.g. PrimaryPhone, SecondaryPhone).
     *              Does nothing for users who can see phone numbers.
     */
    public static void maskValues(Map<String, String> values, List<String> keys) {
        if (values == null || keys == null || !isMaskedUser()) {
            return;
        }
        for (String key : keys) {
            if (values.containsKey(key) && String.isNotBlank(values.get(key))) {
                values.put(key, maskForDisplay(values.get(key)));
            }
        }
    }

    /**
     * @description Returns the candidate shown on screen as maskedValue, or null when none or more than one matches.
     *              Accepts this project's mask (98XXXXXX21, +91 98XXXXXX21) and the older screen mask (XXXXXX4321).
     */
    public static String matchMasked(String maskedValue, List<String> candidates) {
        if (String.isBlank(maskedValue) || candidates == null) {
            return null;
        }
        String target = maskedValue.trim();
        Set<String> exact = new Set<String>();
        for (String candidate : candidates) {
            if (String.isNotBlank(candidate) && maskForDisplay(candidate) == target) {
                exact.add(candidate);
            }
        }
        if (!exact.isEmpty()) {
            return exact.size() == 1 ? new List<String>(exact)[0] : null;
        }
        // Fallback: compare the visible leading / trailing digits with the real numbers.
        String leading = target.substringBefore('X').substringBefore('x').replaceAll('[^0-9]', '');
        String trailing = target.substring(Math.max(target.lastIndexOfIgnoreCase('X') + 1, 0)).replaceAll('[^0-9]', '');
        if (trailing.length() == 0) {
            return null;
        }
        Set<String> partial = new Set<String>();
        for (String candidate : candidates) {
            if (String.isBlank(candidate)) {
                continue;
            }
            String digits = PhoneMaskUtil.normalize(candidate);
            String allDigits = candidate.replaceAll('[^0-9]', '');
            Boolean leadingOk = leading.length() == 0 || digits.startsWith(leading) || allDigits.startsWith(leading);
            if (leadingOk && digits.endsWith(trailing)) {
                partial.add(candidate);
            }
        }
        return partial.size() == 1 ? new List<String>(partial)[0] : null;
    }

    /**
     * @description True when the current user can read the record (today's sharing rules).
     */
    public static Boolean canSeeRecord(Id recordId) {
        if (recordId == null) {
            return false;
        }
        List<UserRecordAccess> access = [
            SELECT RecordId, HasReadAccess FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId = :recordId
        ];
        return !access.isEmpty() && access[0].HasReadAccess;
    }

    /**
     * @description Resolves a masked value sent back by a screen to the real number among candidates.
     *              Checks record access, audits the outcome (masked number only) and returns the real number,
     *              or null when access is denied or no single candidate matches.
     * @param recordId    record the numbers belong to (access is checked on it)
     * @param maskedValue value the user selected on screen
     * @param candidates  the record's real numbers, read on the server
     * @param channel     screen / dialer, for the audit row (e.g. 'MCube (MakeCall)')
     */
    public static String resolve(Id recordId, String maskedValue, List<String> candidates, String channel) {
        if (!canSeeRecord(recordId)) {
            MaskedDialService.logAccess(recordId, null, maskedValue, channel, OUTCOME_DENIED, 'Record not found or no access.');
            return null;
        }
        String real = matchMasked(maskedValue, candidates);
        if (real == null) {
            MaskedDialService.logAccess(recordId, null, maskedValue, channel, OUTCOME_NOT_FOUND, 'The selected number could not be identified.');
            return null;
        }
        MaskedDialService.logAccess(recordId, null, maskForDisplay(real), channel, OUTCOME_SUCCESS, null);
        return real;
    }
}
