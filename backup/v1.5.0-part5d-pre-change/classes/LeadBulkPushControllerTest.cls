@isTest
public class LeadBulkPushControllerTest {

    @isTest
    public static void testLeadBulkPush()
    {
        Utility.runLeadTrigger = false;

        Lead ld = new Lead();
        ld.LastName = 'Test Lead';
        ld.Company = 'ABC Company';
        ld.Phone__c = '9876543210';
        insert ld;

        Utility.runLeadTrigger = true;

        List<Id> leadIds = new List<Id>{ ld.Id };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();

        LeadBulkPushController.getSelectedLeads(new List<String>{ ld.Id });

        LeadBulkPushController.pushBulkToDialer(leadIds, '1234567890',UserInfo.getUserId());

        LeadBulkPushController.pushBulkToDialer(new List<Id>(), '1234567890',UserInfo.getUserId());

        LeadBulkPushController.updateBulkLeadStatus(leadIds);

        Test.stopTest();

        Lead updatedLead = [SELECT Bulk_Call_initiated__c FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(true, updatedLead.Bulk_Call_initiated__c);

        LeadBulkPushController.getUserPicklistValues();

        ApexPages.StandardSetController DML= new ApexPages.StandardSetController(new list<Lead>{ld});
        
        LeadBulkPushController BDH = new LeadBulkPushController(DML);
    }
}