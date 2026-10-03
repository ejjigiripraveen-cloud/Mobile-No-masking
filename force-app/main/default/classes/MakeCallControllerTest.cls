@isTest
public class MakeCallControllerTest {

    public static testmethod void testCall(){
         Lead lead = new Lead();
        lead.lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        lead.Country_Code__c='91';
        lead.Phone__c = '9090909090';
        lead.Secondary_Country_Code__c='93';
        lead.Secondary_Phone__c = '9898989898';
        lead.Email = 'standarduser@testorgfil.com';
        insert lead;
        
        MakeCallController.readContacts(lead.Id);
        MakeCallController.callCustomer(lead.Id,'+91 9090909090');
        MakeCallController.callCustomer(lead.Id,'+93 9898989898');
        MakeCallController.readstatus(lead.Id);
        
        Task tsk = new Task();
        tsk.Subject = 'Call';
        tsk.WhoId = lead.Id;
        insert tsk;
        
        MakeCallController.saveCallSummary(tsk.Id, 'Test class running...');
    }
}