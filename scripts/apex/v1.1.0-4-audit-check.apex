// v1.1.0 Test 4 – Check the audit rows written by Test 3. READ-ONLY.
// Expected: 4 new rows (3a, 3b, 3c, 3d); the invalid id in 3e is rejected before the service, so no row.
// Masked_Number__c must never contain a full number.

for (Phone_Access_Audit__c a : [
    SELECT Name, Event_Time__c, Action__c, Outcome__c, User__r.Name, Object_Name__c,
           Field_Key__c, Masked_Number__c, Channel__c, Message__c
    FROM Phone_Access_Audit__c
    ORDER BY CreatedDate DESC
    LIMIT 4
]) {
    System.debug(a.Name + ' | ' + a.Event_Time__c + ' | ' + a.Action__c + ' | ' + a.Outcome__c
        + ' | ' + a.User__r.Name + ' | ' + a.Field_Key__c + ' | masked ' + a.Masked_Number__c
        + ' | channel ' + a.Channel__c + ' | ' + a.Message__c);
}
