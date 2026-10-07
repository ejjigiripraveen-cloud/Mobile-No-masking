@isTest
public class updateContactDetailsTest {

    public static testmethod void testcontact(){
         utility.runLeadTrigger  = true;
        Round_Robin__c rr = new Round_Robin__c();
       rr.Project_Assigned__c='G Square Auris | Perungalathur';
        rr.RR_Type__c = 'Project-Wise';
       insert rr;
         Round_Robin_Member__c rrm = new Round_Robin_Member__c();
       rrm.User_Type__c='Pre Sales';
       rrm.Round_Robin__c = rr.id;
       rrm.Active__c=true;
       rrm.User__c = userinfo.getUserId();
       rrm.Last_Assigned_Time__c = 1;
       insert rrm;
       Round_Robin_Member__c rrm2 = new Round_Robin_Member__c();
       rrm2.User_Type__c='Sales';
       rrm2.Round_Robin__c = rr.id;
       rrm2.Active__c=true;
       rrm2.User__c = userinfo.getUserId();
       rrm2.Last_Assigned_Time__c = 1;
       insert rrm2;
        Lead ld = new Lead();
        ld.LastName='Test lead';
        ld.Email = 'testlead@gmail.com';
        ld.Phone__c = '9876598765';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        insert ld;
        updateContactDetails.getcontactdetails(ld.Id);
        updateContactDetails.savecontactdetails(ld.Id,'9876598765','testlead@gmail.com',null,null);
        updateContactDetails.savecontactdetails(ld.Id,'+9559876598765','','+9559876598765','');
        updateContactDetails.savecontactdetails(ld.Id,'','test@gmail.com','','testlead2@gmail.com');
         updateContactDetails.savecontactdetails(ld.Id,'+919177350780','test@gmail.com','+919876598767','testlead2@gmail.com');
         updateContactDetails.savecontactdetails(ld.Id,'9876598765','test@gmail.com','+9559876598767','testlead2@gmail.com');
         updateContactDetails.savecontactdetails(ld.Id,'+9559876598765','test2@gmail.com','+9559876598765','testlead2@gmail.com');
    }
}