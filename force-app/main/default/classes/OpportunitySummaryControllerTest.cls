@isTest
public class OpportunitySummaryControllerTest {

    private static Opportunity createOpportunity() {

        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'old@test.com',
            MobilePhone = '9000000000',
            AccountId = acc.Id
        );
        insert con;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Contact__c = con.Id,
            PhoneNo__c = '9999999999',
            Mail_Validated__c = false
        );
        insert opp;

        Opportunity opp1 = new Opportunity(
            Name = 'Test Opportunity1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id,
            Contact__c = con.Id,
            PhoneNo__c = '9999994599',
            Mail_Validated__c = true
        );
        insert opp1;

        return opp;
    }

    @isTest
    static void testGetOpportunity() {

        Opportunity opp = createOpportunity();

        Test.startTest();
        OpportunitySummaryController.OpportunityWithBankDetails result =
            OpportunitySummaryController.getOpportunity(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.opp);
        System.assertEquals(opp.Id, result.opp.Id);
        // Project__c is a read-only/derived field and is blank for this Opportunity,
        // so no project match is expected.
        System.assertEquals(null, result.project);
    }

    @isTest
    static void testGetOpportunity1() {

        Opportunity opp = createOpportunity();

        Test.startTest();
        List<Opportunity> result = OpportunitySummaryController.getRelatedOpportunities(opp.Id);
        Test.stopTest();


    }

    @isTest
    static void testGetOpportunity_Null() {

        Test.startTest();
        OpportunitySummaryController.OpportunityWithBankDetails result =
            OpportunitySummaryController.getOpportunity(null);
        Test.stopTest();

        System.assertEquals(null, result);
    }

    @isTest
    static void testUpdateContactDetails() {

        Opportunity opp = createOpportunity();

        Contact con = [
            SELECT Id, Email, MobilePhone
            FROM Contact
            WHERE Id = :opp.Contact__c
        ];

        Test.startTest();

        OpportunitySummaryController.updateContactDetails(
            opp.Id,
            con.Id,
            opp.AccountId,
            'new@test.com',
            '8888888888',
            true,
            '9999999998',
            '8888888887'
        );

        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT PhoneNo__c, Mail_Validated__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Contact updatedCon = [
            SELECT Email, MobilePhone
            FROM Contact
            WHERE Id = :con.Id
        ];

        Account updatedAcc = [
            SELECT Secondary_Mobile_No__c
            FROM Account
            WHERE Id = :opp.AccountId
        ];

        System.assertEquals('8888888888', updatedOpp.PhoneNo__c);
        System.assertEquals(true, updatedOpp.Mail_Validated__c);
        System.assertEquals('new@test.com', updatedCon.Email);
        System.assertEquals('9999999998', updatedCon.MobilePhone);
        System.assertEquals('8888888887', updatedAcc.Secondary_Mobile_No__c);
    }

    @isTest
    static void testUpdateContactDetails_NoContact() {

        Opportunity opp = createOpportunity();

        Test.startTest();

        OpportunitySummaryController.updateContactDetails(
            opp.Id,
            null,
            null,
            null,
            '7777777777',
            false,
            null,
            null
        );

        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT PhoneNo__c, Mail_Validated__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertEquals('7777777777', updatedOpp.PhoneNo__c);
        System.assertEquals(false, updatedOpp.Mail_Validated__c);
    }

    @isTest
    static void testGetNotesAndFiles() {

        Opportunity opp = createOpportunity();

        // Create Content Note
        ContentNote note = new ContentNote(
            Title = 'Test Note',
            Content = Blob.valueOf('Sample Note')
        );
        insert note;

        ContentDocumentLink noteLink = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = note.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert noteLink;

        // Create File
        ContentVersion cv = new ContentVersion(
            Title = 'Agreement',
            PathOnClient = 'Agreement.pdf',
            VersionData = Blob.valueOf('Sample File')
        );
        insert cv;

        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        ContentDocumentLink fileLink = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert fileLink;

        Test.startTest();

        OpportunitySummaryController.NotesAndFilesWrapper wrapper =
            OpportunitySummaryController.getNotesAndFiles(
                opp.Id,
                new List<String>{ 'Agreement' }
            );

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assert(wrapper.notes.size() > 0);
        System.assert(wrapper.files.size() > 0);
    }

    @isTest
    static void testGetNotesAndFiles_NoFiles() {

        Opportunity opp = createOpportunity();

        Test.startTest();

        OpportunitySummaryController.NotesAndFilesWrapper wrapper =
            OpportunitySummaryController.getNotesAndFiles(
                opp.Id,
                new List<String>{ 'Agreement' }
            );

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals(0, wrapper.notes.size());
        System.assertEquals(0, wrapper.files.size());
    }

    @isTest
    static void testGetNotesAndFiles_NullId() {

        Test.startTest();

        OpportunitySummaryController.NotesAndFilesWrapper wrapper =
            OpportunitySummaryController.getNotesAndFiles(
                null,
                new List<String>{ 'Agreement' }
            );

        Test.stopTest();

        System.assertNotEquals(null, wrapper);
        System.assertEquals(0, wrapper.notes.size());
        System.assertEquals(0, wrapper.files.size());
    }

    @isTest
    static void testUpdateContactDetails_Exception() {

        Test.startTest();

        try {
            OpportunitySummaryController.updateContactDetails(
                null,
                null,
                null,
                null,
                null,
                false,
                null,
                null
            );
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {

        }

        Test.stopTest();
    }
}