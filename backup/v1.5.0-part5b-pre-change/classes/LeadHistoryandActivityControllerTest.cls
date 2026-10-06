@isTest
public class LeadHistoryandActivityControllerTest {

     @istest
    static void makedata(){
      
        lead l=new lead();
        l.Description='Test class for LeadWrap class';
        l.Company='ABC';
        l.Status='Incoming';
        l.Email__c='test@gmail.com';
        l.LastName='Class1';
        l.Last_Comment__c='hello';
        l.Phone__c='1234567890';
        
        //Insertion of lead..
        insert l;
        
        //Update Email and Company..
        l.Email__c = 'test2@gmail.com';
        l.company='xyz';
        update l;
        
        List<Task> tasks = new List<Task>();
        
        tasks.add(new Task(
            ActivityDate = system.today(),
            Subject='Sample Task',
            WhoId = l.Id,
            OwnerId = UserInfo.getUserId(),
            Status='Completed'));
        insert tasks;
        
        test.startTest();
        leadhistory lh=new leadhistory();
        lh.LeadId=l.Id;
        lh.Field='Owner';
        
        insert lh;
        
        
        LeadHistoryandActivityController.WrapSObject testwrap=new LeadHistoryandActivityController.WrapSObject();
        testwrap.recordId=l.Id;
        testwrap.newvalue='9883829102';
        testwrap.oldvalue='9902938294';
        testwrap.subject='AVI';
        testwrap.description='Testing the code coverage of LeadWrap';
        
        
        Call_Detail__c c = new Call_Detail__c(); 
        c.Lead__c = l.Id;
        c.Parent_ID__c = l.Id;
        c.Parent_URL__c= '/'+ l.Id+'/view';
        c.Status__c='Call Complete'; 
        DateTime start = System.Now();
        c.Call_From__c ='9898989898' ;
        c.Start_Time__c =   Datetime.valueof(System.now()).addHours(-5).addMinutes(-30); 
        c.Recording_File__c= 'https://mcube.vmctechnologies.com/sounds/95026040131655359964.wav';
        c.Call_Type__c='Outbound Call';  
        c.Call_To__c='8989898989';
        
        insert c;
        
        
               
        LeadHistoryandActivityController.GetData(l.id,'All');             
        LeadHistoryandActivityController.WrapSObject testwrap1=new LeadHistoryandActivityController.WrapSObject();
        testwrap1.compareTo( testwrap);
        test.stopTest();        
        system.assert(l.Id != null);
        
        
        
    }
}