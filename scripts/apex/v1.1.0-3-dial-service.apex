// v1.1.0 Test 3 – Real-number lookup service.
// WRITES DATA: creates one Phone_Access_Audit__c row per call (5 rows in total). No other data changes.
// The real number is NEVER printed – the script only checks that it matches the record.
//
// Before running: replace the Id below with a test Lead that has Phone__c filled in.

Id leadId = '00Q000000000000AAA'; // <-- put a test Lead Id here

Lead l = [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead WHERE Id = :leadId];

// 3a. Primary number – expected: Success, masked 98XXXXXX21 style, real number matches the record
MaskedDialService.DialResult a = MaskedDialService.resolveOne(leadId, 'Lead.Phone__c', 'Anonymous test');
System.debug('3a Primary   | outcome ' + a.outcome + ' | masked ' + a.maskedNumber
    + ' | real number matches record: ' + (a.phoneNumber == l.Phone__c) + ' | message ' + a.message);

// 3b. Secondary number – expected: Success, or "Not Found" if the Lead has no secondary number
MaskedDialService.DialResult b = MaskedDialService.resolveOne(leadId, 'Lead.Secondary_Phone__c', 'Anonymous test');
System.debug('3b Secondary | outcome ' + b.outcome + ' | masked ' + b.maskedNumber
    + ' | real number matches record: ' + (b.phoneNumber == l.Secondary_Phone__c) + ' | message ' + b.message);

// 3c. Field not on the approved list – expected: Denied, no number
MaskedDialService.DialResult c = MaskedDialService.resolveOne(leadId, 'Lead.Email', 'Anonymous test');
System.debug('3c Not approved | outcome ' + c.outcome + ' | number released: ' + (c.phoneNumber != null) + ' | message ' + c.message);

// 3d. Softphone entry point – expected: success true; the phoneNumber value is removed before printing
Map<String, Object> cti = (Map<String, Object>) JSON.deserializeUntyped(
    MaskedDialServiceCTI.resolveForDial(String.valueOf(leadId), 'Lead.Phone__c'));
Boolean ctiMatches = cti.get('phoneNumber') == l.Phone__c;
cti.remove('phoneNumber');
System.debug('3d Softphone | ' + JSON.serialize(cti) + ' | real number matches record: ' + ctiMatches);

// 3e. Invalid record id through the softphone entry point – expected: Denied, no audit row
Map<String, Object> bad = (Map<String, Object>) JSON.deserializeUntyped(
    MaskedDialServiceCTI.resolveForDial('not-an-id', 'Lead.Phone__c'));
System.debug('3e Invalid id | outcome ' + bad.get('outcome') + ' | message ' + bad.get('message'));
