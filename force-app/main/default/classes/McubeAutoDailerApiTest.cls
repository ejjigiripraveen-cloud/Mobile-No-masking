@istest
public class McubeAutoDailerApiTest {

    @istest
    public static void testAutoDailer(){
         Test.setMock(HttpCalloutMock.class,new McubeAutodailerTestToo());
        Lead ld = new Lead();
        ld.LastName='Test8';
        ld.Email = 'test8lead@gmail.com';
        ld.Phone__c = '1276598765';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'G Square Auris | Perungalathur';
        ld.Allocated_Project__c = 'G Square Auris | Perungalathur';
        ld.zone__c='Chennai';
        insert ld;
        Test.startTest();
        McubeAutoDailerApi.pushToAutoDailer(ld.id);
        Test.stopTest();
        
    }
}