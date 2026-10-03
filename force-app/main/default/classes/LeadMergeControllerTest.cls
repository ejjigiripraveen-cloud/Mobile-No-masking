@isTest
public class LeadMergeControllerTest {

    @isTest
    public static void testLeadMerge(){
        utility.runLeadTrigger  = false;
        Lead ld = new Lead();
        ld.LastName='Test lead3';
        ld.Email = 'testlead34@gmail.com';
        ld.Phone__c = '9835598765';
        ld.Company = 'ABC Company';
        insert ld;
        
        Lead ld2 = new Lead();
        ld2.LastName='Test lead';
        ld2.Company = 'ABC Company';
        ld2.Email = 'testlead4@gmail.com';
        ld2.Phone__c = '9835598763';
        insert ld2;
        
        Follow_Up__c foll = new Follow_Up__c();
        foll.Name = 'test';
        foll.Scheduled_Date__c = system.today();
        foll.Follow_Up_Status__c = 'Scheduled';
        foll.Lead__c = ld.Id;
        insert foll;
        
        Site_Visit__c sr = new Site_Visit__c();
        sr.Date__c= system.today();
        sr.Project__c='G Square Auris | Perungalathur';
        sr.Lead__c = ld.Id;
        insert sr;
        
        Call_Detail__c cd2 = new Call_Detail__c();
         cd2.Call_Type__c = 'Outbound Call';
        cd2.Status__c = 'Call Complete';
        cd2.Call_From__c = ld.Phone__c;
        cd2.Call_To__c = '11111';
        cd2.Lead__c = ld.Id;
        insert cd2;
        
        Task tsk = new Task();
        tsk.ActivityDate = system.today();
        tsk.Subject='Sample Task';
        tsk.WhoId = ld.Id;
        tsk.OwnerId = UserInfo.getUserId();
        tsk.Status='Completed';
        insert tsk;
        
        Test.startTest();
        LeadMergeController.getLeads(ld.Id);
        LeadMergeController.getSearchLeads(ld.Id, 'test');
        LeadMergeController.mergeLead(ld.Id, ld2.Id); 
        Test.stopTest();
    }
}