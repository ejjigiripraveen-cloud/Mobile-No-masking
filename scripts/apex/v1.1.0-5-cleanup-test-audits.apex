// v1.1.0 Optional cleanup – deletes ONLY the audit rows that Test 3 created:
// rows by you, in the last hour, from the anonymous test or the softphone entry point (3d).
// WRITES DATA (delete). Run only if you want the test rows removed.

Datetime oneHourAgo = System.now().addHours(-1);
List<Phone_Access_Audit__c> testRows = [
    SELECT Id, Name, Channel__c FROM Phone_Access_Audit__c
    WHERE User__c = :UserInfo.getUserId()
      AND CreatedDate >= :oneHourAgo
      AND Field_Key__c IN ('Lead.Phone__c', 'Lead.Secondary_Phone__c', 'Lead.Email')
];
for (Phone_Access_Audit__c row : testRows) {
    System.debug('Deleting ' + row.Name + ' (channel ' + row.Channel__c + ')');
}
delete testRows;
System.debug('Deleted ' + testRows.size() + ' test audit rows');
