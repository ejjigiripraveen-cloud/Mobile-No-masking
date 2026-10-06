/**
 * @description Mobile number masking (v1.4.0). Users who cannot see Lead.Phone__c / Secondary_Phone__c type
 *              numbers into the entry fields Phone_Entry__c / Secondary_Phone_Entry__c. Before save, this
 *              handler copies them into the real fields and clears the entry fields, so they are always empty
 *              after save. Called first in LeadTrigger (before insert / before update), so the existing number
 *              formatting, duplicate check and validation rules see the number exactly as before.
 *
 *              Rules:
 *                - Primary: set on create, or when the Lead has no primary yet. Once a primary exists it is
 *                  locked: an entry value that would change it is rejected with an error on the entry field.
 *                  (Administrators who can edit Phone__c directly are not affected.)
 *                - Secondary: always copied (add or change).
 *              In-memory only: no SOQL, no DML; bulk-safe for any batch size.
 * @group       Phone Masking
 */
public inherited sharing class LeadPhoneEntryHandler {
    public static final String PRIMARY_LOCKED_MESSAGE =
        'The primary number cannot be changed once it is set. Add the new number as the secondary number, or ask your administrator.';

    /**
     * @description Before insert / before update.
     * @param newLeads Trigger.new
     * @param oldMap   Trigger.oldMap (null on insert)
     */
    public static void beforeSave(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        if (newLeads == null || newLeads.isEmpty()) {
            return;
        }
        for (Lead lead : newLeads) {
            Lead oldLead = (oldMap == null || lead.Id == null) ? null : oldMap.get(lead.Id);
            copyPrimary(lead, oldLead);
            copySecondary(lead);
        }
    }

    private static void copyPrimary(Lead lead, Lead oldLead) {
        if (lead.Phone_Entry__c == null) {
            return;
        }
        String entered = lead.Phone_Entry__c.trim();
        if (entered.length() == 0) {
            lead.Phone_Entry__c = null;
            return;
        }
        String existing = oldLead == null ? null : oldLead.Phone__c;
        Boolean isLocked = String.isNotBlank(existing)
            && PhoneMaskUtil.normalize(existing) != PhoneMaskUtil.normalize(entered);
        if (isLocked) {
            lead.Phone_Entry__c.addError(PRIMARY_LOCKED_MESSAGE);
            return;
        }
        lead.Phone__c = entered;
        lead.Phone_Entry__c = null;
    }

    private static void copySecondary(Lead lead) {
        if (lead.Secondary_Phone_Entry__c == null) {
            return;
        }
        String entered = lead.Secondary_Phone_Entry__c.trim();
        if (entered.length() > 0) {
            lead.Secondary_Phone__c = entered;
        }
        lead.Secondary_Phone_Entry__c = null;
    }
}
