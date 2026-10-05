// v1.1.0 Test 2 – Settings and approved field list. READ-ONLY.

Phone_Masking_Setting__mdt s = PhoneMaskingConfig.getSetting();
System.debug('Setting record: ' + s.DeveloperName);
System.debug('Visible prefix / suffix digits: ' + s.Visible_Prefix_Digits__c + ' / ' + s.Visible_Suffix_Digits__c + '   (expected 2 / 2)');
System.debug('Mask character: ' + s.Mask_Character__c + '   (expected X)');
System.debug('Country code stripped: ' + s.Country_Code_To_Strip__c + '   (expected 91)');
System.debug('Reveal seconds: ' + s.Reveal_Seconds__c + '   (expected 30)');
System.debug('Audit retention days: ' + s.Audit_Retention_Days__c + '   (expected 365)');
System.debug('Real number lookup enabled: ' + s.Resolve_Enabled__c + '   (expected true)');
System.debug('Audit enabled: ' + s.Audit_Enabled__c + '   (expected true)');

Map<String, Masked_Phone_Field__mdt> fields = PhoneMaskingConfig.getActiveFields();
System.debug('Approved active fields: ' + fields.size() + '   (expected 2)');
for (String key : fields.keySet()) {
    Masked_Phone_Field__mdt f = fields.get(key);
    System.debug(' - ' + f.Object_API_Name__c + '.' + f.Field_API_Name__c + ' | label ' + f.Display_Label__c
        + ' | dial ' + f.Allow_Dial__c + ' | reveal ' + f.Allow_Reveal__c);
}
