/**
 * @description Server side of the maskedPhonePanel LWC. Returns the MASKED numbers of a record for display,
 *              one row per approved phone field (Masked_Phone_Field__mdt), in display order.
 *              The real number is never returned to the browser.
 *
 *              Access: the user must be able to read the object and see the record ("with sharing").
 *              Field-level security is intentionally not applied to the read, because users of the
 *              masked panel cannot read the phone fields themselves; only the masked value leaves Apex.
 *              One query per call. Nothing is written (no audit needed: no real number is released).
 * @group       Phone Masking
 */
public with sharing class MaskedPhonePanelController {

    /**
     * @description One masked number row shown in the panel.
     */
    public class PhoneRow {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldKey;
        @AuraEnabled public String maskedNumber;
        @AuraEnabled public Boolean hasNumber;
        @AuraEnabled public Boolean canDial;
        @AuraEnabled public Integer sortOrder;
    }

    /**
     * @description Masked numbers of the record, sorted by Sort_Order__c.
     * @param recordId the record shown on the page
     */
    @AuraEnabled(cacheable=true)
    public static List<PhoneRow> getMaskedNumbers(Id recordId) {
        if (recordId == null) {
            throw auraError('Record is required.');
        }
        Schema.DescribeSObjectResult objectDescribe =
            recordId.getSObjectType().getDescribe(Schema.SObjectDescribeOptions.DEFERRED);
        if (!objectDescribe.isAccessible()) {
            throw auraError('You do not have access to this record.');
        }

        List<FieldEntry> entries = approvedFieldsFor(objectDescribe);
        List<PhoneRow> rows = new List<PhoneRow>();
        if (entries.isEmpty()) {
            return rows;
        }

        Set<String> fieldNames = new Set<String>();
        for (FieldEntry entry : entries) {
            fieldNames.add(entry.fieldName);
        }
        // Names come from the schema describe, never from user input.
        String soql = 'SELECT Id, ' + String.join(new List<String>(fieldNames), ', ')
            + ' FROM ' + objectDescribe.getName() + ' WHERE Id = :recordId LIMIT 1';
        // SYSTEM_MODE skips field-level security; record sharing still follows "with sharing".
        List<SObject> records = Database.queryWithBinds(
            soql, new Map<String, Object>{ 'recordId' => recordId }, AccessLevel.SYSTEM_MODE
        );
        if (records.isEmpty()) {
            throw auraError('Record not found or you do not have access to it.');
        }

        SObject record = records[0];
        for (FieldEntry entry : entries) {
            String value = (String) record.get(entry.fieldName);
            PhoneRow row = new PhoneRow();
            row.label = String.isBlank(entry.config.Display_Label__c) ? entry.fieldLabel : entry.config.Display_Label__c;
            row.fieldKey = objectDescribe.getName() + '.' + entry.fieldName;
            row.hasNumber = String.isNotBlank(value);
            row.maskedNumber = row.hasNumber ? PhoneMaskUtil.mask(value) : null;
            row.canDial = row.hasNumber && entry.config.Allow_Dial__c == true;
            row.sortOrder = entry.sortOrder;
            rows.add(row);
        }
        return rows;
    }

    private static List<FieldEntry> approvedFieldsFor(Schema.DescribeSObjectResult objectDescribe) {
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<FieldEntry> entries = new List<FieldEntry>();
        for (Masked_Phone_Field__mdt config : PhoneMaskingConfig.getActiveFields().values()) {
            if (!objectDescribe.getName().equalsIgnoreCase(config.Object_API_Name__c)) {
                continue;
            }
            Schema.SObjectField field = fieldMap.get(config.Field_API_Name__c);
            if (field == null) {
                continue; // misconfigured record: skip rather than break the page
            }
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            entries.add(new FieldEntry(config, fieldDescribe.getName(), fieldDescribe.getLabel()));
        }
        entries.sort();
        return entries;
    }

    private static AuraHandledException auraError(String message) {
        AuraHandledException error = new AuraHandledException(message);
        error.setMessage(message);
        return error;
    }

    private class FieldEntry implements Comparable {
        Masked_Phone_Field__mdt config;
        String fieldName;
        String fieldLabel;
        Integer sortOrder;

        FieldEntry(Masked_Phone_Field__mdt config, String fieldName, String fieldLabel) {
            this.config = config;
            this.fieldName = fieldName;
            this.fieldLabel = fieldLabel;
            this.sortOrder = config.Sort_Order__c == null ? 999 : config.Sort_Order__c.intValue();
        }

        public Integer compareTo(Object other) {
            FieldEntry that = (FieldEntry) other;
            if (sortOrder != that.sortOrder) {
                return sortOrder < that.sortOrder ? -1 : 1;
            }
            return fieldName.compareTo(that.fieldName);
        }
    }
}
