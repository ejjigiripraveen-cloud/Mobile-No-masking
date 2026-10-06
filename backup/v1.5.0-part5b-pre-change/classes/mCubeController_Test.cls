@istest(seealldata=true)
public class mCubeController_Test {
    @istest
    public static void route(){
         
      /*  Lead lead = new Lead();
        lead.lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        lead.Phone = '67878';
        lead.Phone__c = '9878787878';
        lead.mobilePhone = '2343';
        lead.Email = 'standarduser@testorgfil.com';
        insert lead;
        MCUBE_Object_Api__c  m  = new MCUBE_Object_Api__c ();
        m.name = 'lead';
        m.Field_to_Compare_Mobile_Incoming_Number__c = 'mobilePhone ';
        m.field__c = 'FirstName';
        m.field1__c = 'LastName';
        m.field2__c = 'company';
        m.Value__c = 'company';
        m.value1__c = 'company';
        m.value2__c = 'company';
        insert m;
        mCubeController.clickToCall(lead .id);
        mCubeController.makeCall('+91','9898989898', lead.Phone__c, lead.Id);
       mCubeController.readData(); */
         string data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         string data1 = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
         mCubeController.newInboundCall();
        try{
              mCubeController.masdialinit();
        }catch(Exception e){
            System.debug(e);
        }
      
        
    }

    @istest
    public static void inboundCalltest(){
        
         utility.runLeadTrigger=false;
        Lead lead = new Lead();
        lead.lastname = 'Test Lead';
        lead.Company = 'TestCompany';
        lead.Phone__c = '67878';
        lead.mobilePhone = '2343';
        lead.Email = 'standarduser@testorgfil.com';
       
        insert lead;
         call_detail__c cd = new call_detail__c();
        cd.Lead__c = lead.Id;
        insert cd;
        MCUBE_Object_Api__c  m  = new MCUBE_Object_Api__c ();
        m.name = 'lead';
        m.Field_to_Compare_Mobile_Incoming_Number__c = 'mobilePhone ';
        m.field__c = 'FirstName';
        m.field1__c = 'LastName';
        m.field2__c = 'company';
        m.Value__c = 'company';
        m.value1__c = 'company';
        m.value2__c = 'company';
        insert m;
        
        Campaign cnm = new Campaign();
        cnm.Landing_Number__c = '11111';
        cnm.Project__c = 'G Square Auris | Perungalathur';
        cnm.Name = '11111';
        cnm.Source__c = 'Property Portal';
        cnm.Sub_Source__c = 'test';
        cnm.Active__c = TRUE;
        cnm.Zone__c = 'Chennai';
        insert cnm;
        Campaign_Source__c cs = new Campaign_Source__c();
        cs.Campaign__c = cnm.Id;
        cs.Landing_Number__c = '11111';
        cs.Source__c = 'Property Portal';
        cs.Sub_source__c = 'test';
        insert cs;
         Profile p = [SELECT Id FROM Profile where name='System Administrator' limit 1];

        User u = new User(Alias = 'standt12', Email='standarduser@testorgfil.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com.123',MobilePhone = '111');
        u.massdialerIds__c = ','+lead.id;
        insert  u;
        
        
        
        string data = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         string data1 = '{\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
         mCubeController.newInboundCall();
        ApexPages.currentPage().getParameters().put('fromnumber','67878');
        ApexPages.currentPage().getParameters().put('landingnumber','11111');
        mCubeController.readData();
        mCubeController.callRecords(lead.Id);
        mCubeController.sendNotification('34234234', lead.Id, u.Id, 'Lead',cd.Id,'Inbound');
        mCubeController.updateRecord(lead.Id,null,'16/09/2022, 18:00:00','Other','Feedback Check','Contacted','	No Answer');
        mCubeController.clickToCall(lead .id);
        mCubeController.makeCall('+93','9898989898', lead.Phone__c, lead.Id);
        mCubeController.makeCall('+91','9898989898', lead.Phone__c, lead.Id);
        mCubeController.makeCallZetta('+91','9898989898', lead.Phone__c, lead.Id);
        mCubeController.PicklistWrapper wrp = new mCubeController.PicklistWrapper();
       // mCubeController.PicklistWrapper.PicklistEntryWrapper wrp2 = new  mCubeController.PicklistWrapper.PicklistEntryWrapper();
        wrp=  mCubeController.getDependentPicklist('Call_Detail__c','Disposition__c','sub_disposition__c');
        mCubeController.decimalToBinary(5);
        mCubeController.readCall();
        mCubeController.userDetail();
        Test.startTest();
        data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();

        data = '{\"status\":\"ORIGINATE\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}' ;        
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         // mCubeController.testcover();
       //  mCubeController.getOutboundCallDetails();
        // mCubeController.updateUsers();
        Test.stopTest();
       /* data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}' ;        
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
        mCubeController.readCall();
       
        
        
         data = '{\"dialstatus\":\"CALL COMPLETE\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"executive\":\"111\",\"customer\":\"1111111\"}' ;        
        ApexPages.currentPage().getParameters().put('fromnumber','34234234');
        ApexPages.currentPage().getParameters().put('landingnumber','111');
    
    
              
        ApexPages.currentPage().getParameters().put('fromnumber','67878');
        ApexPages.currentPage().getParameters().put('landingnumber','11111');
        //mCubeController.readData();
            /*   
        System.runAs(u) {
            pageRef = Page.Dialer;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(new List<lead>{lead});
            Dialercontroller s = new Dialercontroller(stdSetController );
            //s.direct();
            //u.massdialerIds__c = +','+lead.id;
            //update u;
            mCubeController.masdialinit();
            mCubeController.callRecords(lead.Id);
           // mCubeController.clickToCall(lead.Id);
            mCubeController.makeCall('9999999999','8888888888',lead.Id);
        }*/
        
  
    }
    @istest
    public static void inboundcalltest1(){
         string data = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         string data1 = '{\"dialstatus\":\"ANSWER\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
         mCubeController.newInboundCall();
    }
     @istest
    public static void inboundcalltest2(){
         string data = '{\"executive\":\"1234\",\"dialstatus\":\"ANSWER\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         string data1 = '{\"executive\":\"1234\",\"dialstatus\":\"ANSWER\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
         mCubeController.newInboundCall();
    }
  /*    @istest
    public static void inboundcalltest3(){
         string data = '{\"executive\":\"1234\",\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
        mCubeController.inboundCall();
         string data1 = '{\"executive\":\"1234\",\"dialstatus\":\"CONNECTING\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
         mCubeController.newInboundCall();
      
    }*/
  @istest
    public static void inboundcalltest4(){
        string data = '{\"executive\":\"9032268180\",\"status\":\"ORIGINATE\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef = Page.calland;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('data',data);
          mCubeController.inboundCall();
        string data1 = '{\"executive\":\"9032268180\",\"status\":\"ORIGINATE\",\"endtime\":\"'+system.now()+'\",\"starttime\":\"'+system.now()+'\",\"empnumber\":\"111\",\"callfrom\":\"1111111\"}' ;        
        PageReference pageRef1 = Page.newCalland;
        Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('data',data1);
        mCubeController.newInboundCall();
           mCubeController.getOutboundCallDetails(); 
    }
 
  }