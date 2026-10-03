@isTest
public class LeadTriggerHandlerTest {

    public static testmethod void testLeadHandler(){
        
        List<Lead> leadList = new List<Lead>();
         List<Lead> leadList2 = new List<Lead>();
         List<Lead> leadList3 = new List<Lead>();
         Lead nld = new Lead();
        nld.LastName='Test3 lead';
        nld.Email = 'testlead09@gmail.com';
        nld.Phone__c = '+919976598745';
        nld.Company = 'ABC Company';
        nld.Secondary_Phone__c = '+658700465432'; 
        nld.Secondary_Email__c = 'testlead14@gmail.com';
        insert nld;
         Lead ld = new Lead();
        ld.LastName='Test4 lead';
        ld.Email = 'testlead@gmail.com';
        ld.Phone__c = '+919876598765';
        ld.Company = 'ABC Company';
        ld.Secondary_Phone__c = '+658765465432'; 
        ld.Secondary_Email__c = 'testlead36@gmail.com';
        leadList.add(ld);
               
        Lead ld2 = new Lead();
        ld2.LastName='Test lead 2';
        ld2.Email = 'testlead02@gmail.com';
        ld2.Phone__c = '9876396641';
        ld2.Company = 'XYZ Company';
       	leadList.add(ld2);
        
        Lead ld5 = new Lead();
        ld5.LastName='Test lead 5';
        ld5.Email = 'testlead5@gmail.com';
        ld5.Phone__c = '+659876598723';
        ld5.Company = 'XYZ Company';
        ld5.Secondary_Phone__c = '+919876598723';
        ld5.Secondary_Email__c = 'testlead6@gmail.com';
        leadList.add(ld5);
        Lead ld6 = new Lead();
        ld6.LastName='Test1 lead 5';
        ld6.Email = 'testlead15@gmail.com';
        ld6.Phone__c = '+659876598723';
        ld6.Company = 'XYZ Company';
        ld6.Secondary_Phone__c = '+919881598723';
        ld6.Secondary_Email__c = 'testlead6232@gmail.com';
        leadList.add(ld6);
        insert leadList;
        
        LeadTriggerHandler.checkMobileNumber(leadList);
        //LeadTriggerHandler.duplicateCheck(leadList);
        
        /*Lead ld3 = new Lead();
        ld3.LastName='Test lead 3';
        ld3.Email = 'testlead3@gmail.com';
        ld3.Secondary_Email__c = 'testlead7@gmail.com';
        ld3.Phone__c = '9276598765';
        ld3.Secondary_Phone__c = '9276598769';
        ld3.Company = 'XYZ Company';
        ld3.Status = 'Unqualified';
        leadList2.add(ld3);
        
        Lead ld4 = new Lead();
        //ld4.Main_Lead__c = ld3.Id;
        ld4.LastName='Test lead 4';
        ld4.Email = 'testlead4@gmail.com';
        ld4.Phone__c = '9876381141';
        ld4.Company = 'XYZ Company';
        ld4.Secondary_Phone__c = '9876598723';
        ld4.Secondary_Email__c = 'testlead4@gmail.com';
        leadList2.add(ld4);
        
         Lead ld6 = new Lead();
        ld6.LastName='Test lead 5';
        ld6.Email = 'testlead3@gmail.com';
        ld6.Phone__c = '9876381241';
        ld6.Company = 'XYZ Company';
        ld6.Secondary_Phone__c = '9876381241';
        ld6.Secondary_Email__c = 'testlead32@gmail.com';
        leadList2.add(ld6);
        
        insert leadList2;
          LeadTriggerHandler.duplicateCheck(leadList2);
        
        */
          /*Lead ld7 = new Lead();
       ld7.LastName='Test lead 3';
        ld7.Email = 'testlead7@gmail.com';
        ld7.Secondary_Email__c = 'testlead3@gmail.com';
        ld7.Phone__c = '9276598765';
        ld7.Secondary_Phone__c = '9276598769';
        ld7.Company = 'XYZ Company';
        leadList3.add(ld7);
        
        Lead ld8 = new Lead();
        //ld4.Main_Lead__c = ld3.Id;
        ld8.LastName='Test lead 4';
        ld8.Email = 'testlead3@gmail.com';
        ld8.Phone__c = '9876598723';
        ld8.Company = 'XYZ Company';
        ld8.Secondary_Phone__c = '9876598723';
        ld8.Secondary_Email__c = 'testlead7@gmail.com';
        leadList3.add(ld8);
        
         Lead ld9 = new Lead();
        ld9.LastName='Test lead 5';
        ld9.Email = 'testlead3@gmail.com';
        ld9.Phone__c = '9876381241';
        ld9.Company = 'XYZ Company';
        ld9.Secondary_Phone__c = '9876381241';
        ld9.Secondary_Email__c = 'testlead3@gmail.com';*/
       // leadList3.add(ld9);
        
        
        //insert leadList3;
          //LeadTriggerHandler.duplicateCheck(leadList3);
    
        
       // LeadTriggerHandler.afterinsertLogic(leadList2);
        
    }
}