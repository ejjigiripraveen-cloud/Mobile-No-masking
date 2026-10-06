/**
 * @description Entry point for Open CTI softphones (sforce.opencti.runApex), which can only call
 *              global webservice methods. Delegates to MaskedDialService, so every check and the audit
 *              trail apply. The audit channel is the name of the user's assigned call center.
 *
 *              Response (JSON):
 *              {"success":true,"phoneNumber":"<real>","maskedNumber":"98XXXXXX21","outcome":"Success","message":null}
 * @group       Phone Masking
 */
global with sharing class MaskedDialServiceCTI {
    @TestVisible
    private static final String DEFAULT_CHANNEL = 'Open CTI';

    /**
     * @description Resolves the real number for click-to-dial.
     * @param recordId 15 or 18 character record Id
     * @param fieldKey approved field key, e.g. 'Lead.Phone__c'
     */
    webservice static String resolveForDial(String recordId, String fieldKey) {
        Id parsedId = parseId(recordId);
        if (parsedId == null) {
            MaskedDialService.DialResult invalid = new MaskedDialService.DialResult();
            invalid.fieldKey = fieldKey;
            invalid.outcome = MaskedDialService.OUTCOME_DENIED;
            invalid.message = 'Invalid record id.';
            return JSON.serialize(new Response(invalid));
        }
        return JSON.serialize(new Response(MaskedDialService.resolveOne(parsedId, fieldKey, currentChannel())));
    }

    private static Id parseId(String value) {
        if (String.isBlank(value)) {
            return null;
        }
        try {
            return Id.valueOf(value.trim());
        } catch (Exception e) {
            return null;
        }
    }

    @TestVisible
    private static String currentChannel() {
        try {
            List<User> users = [SELECT CallCenterId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if (users.isEmpty() || users[0].CallCenterId == null) {
                return DEFAULT_CHANNEL;
            }
            List<CallCenter> centers = [SELECT Name FROM CallCenter WHERE Id = :users[0].CallCenterId LIMIT 1];
            return centers.isEmpty() ? DEFAULT_CHANNEL : centers[0].Name;
        } catch (Exception e) {
            return DEFAULT_CHANNEL;
        }
    }

    private class Response {
        public Boolean success;
        public String phoneNumber;
        public String maskedNumber;
        public String outcome;
        public String message;

        Response(MaskedDialService.DialResult result) {
            this.success = result.success;
            this.phoneNumber = result.phoneNumber;
            this.maskedNumber = result.maskedNumber;
            this.outcome = result.outcome;
            this.message = result.message;
        }
    }
}
