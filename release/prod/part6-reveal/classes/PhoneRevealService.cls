/**
 * @description Mobile number masking (v1.6.0, design G5): Reveal for Team Leads, Heads and Admins.
 *              revealNumber returns the real number of an approved phone field when
 *                1. the user has the custom permission Reveal_Phone_Number (permission set Phone_Reveal),
 *                2. the reason is one of the 7 approved reasons, with a comment when the reason is "Other",
 *                3. MaskedDialService allows it (approved field with Allow Reveal, object access, record visible).
 *              Every attempt is written to Phone_Access_Audit__c (Action = Reveal, reason, comment, masked number).
 *              The panel shows the number for Reveal_Seconds__c (30) and then clears it.
 * @group       Phone Masking
 */
public with sharing class PhoneRevealService {
    public static final String PERMISSION = 'Reveal_Phone_Number';
    public static final String REASON_OTHER = 'Other';
    public static final String CHANNEL = 'Reveal (Phone Numbers panel)';
    private static final Integer DEFAULT_SECONDS = 30;

    /** The 7 approved reasons (design doc G5). */
    public static final List<String> REASONS = new List<String>{
        'Site visit coordination',
        'Booking / documentation follow-up',
        'Customer escalation / complaint',
        'Dialer down, manual call needed',
        'Number verification / correction',
        'Management review',
        REASON_OTHER
    };

    @TestVisible
    private static Boolean permissionOverride;

    /**
     * @description What the panel needs to show a revealed number.
     */
    public class RevealResult {
        @AuraEnabled public String phoneNumber;
        @AuraEnabled public Integer seconds;
    }

    /**
     * @description The approved reasons, in display order.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getReasons() {
        return REASONS;
    }

    /**
     * @description True when the current user may reveal numbers.
     */
    public static Boolean canReveal() {
        if (permissionOverride != null) {
            return permissionOverride;
        }
        return FeatureManagement.checkPermission(PERMISSION);
    }

    /**
     * @description Reveals one number. Throws an AuraHandledException with a readable message when refused.
     * @param recordId record shown on the page
     * @param fieldKey approved field key, e.g. 'Lead.Phone__c'
     * @param reason   one of REASONS
     * @param comment  free text; required when reason = 'Other'
     */
    @AuraEnabled
    public static RevealResult revealNumber(Id recordId, String fieldKey, String reason, String comment) {
        if (!canReveal()) {
            throw auraError('You do not have permission to reveal phone numbers.');
        }
        if (String.isBlank(reason) || !REASONS.contains(reason)) {
            throw auraError('Please choose a reason.');
        }
        String cleanComment = String.isBlank(comment) ? null : comment.trim();
        if (reason == REASON_OTHER && cleanComment == null) {
            throw auraError('Please enter a comment when the reason is "Other".');
        }

        MaskedDialService.DialRequest request = new MaskedDialService.DialRequest(recordId, fieldKey, CHANNEL);
        request.reason = reason;
        request.comment = cleanComment;
        MaskedDialService.DialResult result = MaskedDialService.resolve(
            new List<MaskedDialService.DialRequest>{ request }, MaskedDialService.ACTION_REVEAL
        )[0];
        if (!result.success) {
            throw auraError(result.message);
        }

        RevealResult revealed = new RevealResult();
        revealed.phoneNumber = result.phoneNumber;
        Decimal seconds = PhoneMaskingConfig.getSetting().Reveal_Seconds__c;
        revealed.seconds = (seconds == null || seconds < 1) ? DEFAULT_SECONDS : seconds.intValue();
        return revealed;
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }
}
