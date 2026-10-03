@isTest
public class ProjectDocumentUploadControllerTest {

    @testSetup
    static void setupData() {

        Project__c project = new Project__c(Name = 'Test Project');
        insert project;

        Template_Master__c template = new Template_Master__c(
            Name = 'Template A',
            Project__c = project.Id
        );
        insert template;

        Block__c block = new Block__c(
            Name = 'Block A',
            Project__c = project.Id
        );
        insert block;

        Apartment__c apt = new Apartment__c(
            Name                = 'Test Apt',
            Block__c            = block.Id,
            Template_Master__c  = template.Id,
            Apartment_Status__c = 'Available',
            Apartment_rate__c   = 2000,
            Built_Up_Area__c    = 1000,
            Flat_No__c          = 'A101'
        );
        insert apt;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name         = 'Test Opp',
            StageName    = 'Prospecting',
            CloseDate    = Date.today(),
            AccountId    = acc.Id,
            Apartment__c = apt.Id,
            PhoneNo__c   = '9999999999'
        );
        insert opp;

        CRM__c crm = new CRM__c(
            Opportunity__c          = opp.Id,
            Sub_Registrar_Office__c = 'Test Office',
            Reg_Document_Number__c  = 'DOC123',
            Year_Of_Registration__c = '2023'
        );
        insert crm;
    }

    // ── getProjectPicklistValues ───────────────────────────────────────
    @isTest
    static void testGetProjectPicklistValues() {
        Test.startTest();
        List<String> values = ProjectDocumentUploadController.getProjectPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, values);
    }

    // ── searchOpportunity ─────────────────────────────────────────────
    @isTest
    static void testSearchOpportunity_Found() {
        Test.startTest();
        Opportunity result = ProjectDocumentUploadController.searchOpportunity(
            'Test Project', 'A101'
        );
        Test.stopTest();
    }

    @isTest
    static void testSearchOpportunity_NoResult() {
        Test.startTest();
        Opportunity result = ProjectDocumentUploadController.searchOpportunity(
            'Wrong Project', 'XXX'
        );
        Test.stopTest();

        System.assertEquals(null, result);
    }

    // ── searchOpportunityByMobile ─────────────────────────────────────
    @isTest
    static void testSearchOpportunityByMobile() {
        Test.startTest();
        List<ProjectDocumentUploadController.DetailsWrapper> results =
            ProjectDocumentUploadController.searchOpportunityByMobile('9999999999');
        Test.stopTest();

        System.assert(results.size() > 0, 'Should find opportunity by PhoneNo__c');

        // Verify opportunity fields using correct wrapper property: oppList
        Opportunity opp = results[0].oppList[0];
        System.assertEquals('9999999999', opp.PhoneNo__c);

        // Verify CRM fields using correct wrapper property: crmList
        System.assert(results[0].crmList.size() > 0, 'CRM record should be linked');
        System.assertEquals('Test Office', results[0].crmList[0].Sub_Registrar_Office__c);
        System.assertEquals('DOC123',      results[0].crmList[0].Reg_Document_Number__c);
        System.assertEquals('2023',        results[0].crmList[0].Year_Of_Registration__c);
    }

    @isTest
    static void testSearchOpportunityByMobile_Blank() {
        Test.startTest();
        List<ProjectDocumentUploadController.DetailsWrapper> results =
            ProjectDocumentUploadController.searchOpportunityByMobile('');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Blank mobile should return empty list');
    }

    @isTest
    static void testSearchOpportunityByMobile_NoMatch() {
        Test.startTest();
        List<ProjectDocumentUploadController.DetailsWrapper> results =
            ProjectDocumentUploadController.searchOpportunityByMobile('0000000000');
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Unknown mobile should return empty list');
    }

    // ── uploadFile ────────────────────────────────────────────────────
    @isTest
    static void testUploadFile_SalesDeed() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test PDF Content'));

        // Create mock Gsquare Connect user required by uploadFile method
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User gsquareUser = new User(
            FirstName          = 'Gsquare',
            LastName           = 'Connect',
            Email              = 'gsquare.connect@testorg.com',
            Username           = 'gsquare.connect@testorg.com.test',
            Alias              = 'gsqcon',
            TimeZoneSidKey     = 'America/Los_Angeles',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            ProfileId          = p.Id
        );
        insert gsquareUser;

        Test.startTest();
        ProjectDocumentUploadController.uploadFile(
            opp.Id, 'Sales Deed', base64Data, 'application/pdf'
        );
        Test.stopTest();

        List<ContentVersion> versions = [
            SELECT Id, Title FROM ContentVersion WHERE Title = 'Sales Deed'
        ];
        System.assertEquals(1, versions.size(), 'Sales Deed ContentVersion should be created');
    }

    @isTest
    static void testUploadFile_Encumbrance() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Encumbrance Content'));

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User gsquareUser = new User(
            FirstName          = 'Gsquare',
            LastName           = 'Connect',
            Email              = 'gsquare.connect2@testorg.com',
            Username           = 'gsquare.connect2@testorg.com.test',
            Alias              = 'gsqco2',
            TimeZoneSidKey     = 'America/Los_Angeles',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            ProfileId          = p.Id
        );
        insert gsquareUser;

        Test.startTest();
        ProjectDocumentUploadController.uploadFile(
            opp.Id, 'Encumbrance Certificate', base64Data, 'application/pdf'
        );
        Test.stopTest();

        List<ContentVersion> versions = [
            SELECT Id, Title FROM ContentVersion WHERE Title = 'Encumbrance Certificate'
        ];
        System.assertEquals(1, versions.size(), 'Encumbrance ContentVersion should be created');
    }

    // ── getAttachedFiles ──────────────────────────────────────────────
    @isTest
    static void testGetAttachedFiles_AfterUpload() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test Content'));

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User gsquareUser = new User(
            FirstName          = 'Gsquare',
            LastName           = 'Connect',
            Email              = 'gsquare.connect3@testorg.com',
            Username           = 'gsquare.connect3@testorg.com.test',
            Alias              = 'gsqco3',
            TimeZoneSidKey     = 'America/Los_Angeles',
            LocaleSidKey       = 'en_US',
            EmailEncodingKey   = 'UTF-8',
            LanguageLocaleKey  = 'en_US',
            ProfileId          = p.Id
        );
        insert gsquareUser;

        Test.startTest();
        ProjectDocumentUploadController.uploadFile(
            opp.Id, 'Sales Deed', base64Data, 'application/pdf'
        );
        List<ContentVersion> files =
            ProjectDocumentUploadController.getAttachedFiles(opp.Id);
        Test.stopTest();

        System.assert(files.size() > 0, 'Should return at least one attached file');
        System.assertEquals('Sales Deed', files[0].Title);
    }

    @isTest
    static void testGetAttachedFiles_NoFiles() {
        Account acc = new Account(Name = 'Empty Account');
        insert acc;

        Opportunity emptyOpp = new Opportunity(
            Name      = 'Empty Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        insert emptyOpp;

        Test.startTest();
        List<ContentVersion> files =
            ProjectDocumentUploadController.getAttachedFiles(emptyOpp.Id);
        Test.stopTest();

        System.assertEquals(0, files.size(), 'Should return empty list when no files attached');
    }
}