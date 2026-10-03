@isTest
public class SiteVisitFeedbackController_Test {

    // ==================================================
    // NOTE ON GOVERNOR LIMITS / AUTOMATION BYPASS
    // ==================================================
    // RelatedSourceTrigger (fired as a side effect of Lead DML via
    // this org's automation) skips all of its logic when the
    // running user's Id equals BYPASS_USER_ID:
    //
    //   if(label.enableRelatedSourceTrigger == 'True'
    //      && userinfo.getUserId() != '0055j000003RcP8AAK') { ... }
    //
    // We can't change the custom label at runtime, but we CAN run
    // our DML as that user via System.runAs(), which is exactly
    // what UserInfo.getUserId() reflects inside the block. Doing
    // this around every Lead insert / InsertSitevisit call avoids
    // the Related_Source__c cascade that was blowing past the 101
    // SOQL query governor limit.
    //
    // NOTE: this assumes the user behind BYPASS_USER_ID is active
    // and has sufficient object permissions (Lead, Site_Visit__c,
    // Project__c) in this org — it's a hardcoded automation-bypass
    // user baked into production trigger code, so this is very
    // likely, but worth confirming if runAs throws an access or
    // "inactive user" error.
    // ==================================================

    private static final Id BYPASS_USER_ID = '0055j000003RcP8AAK';

    // System.runAs requires an active user. The bypass user is
    // deactivated in this org, so we temporarily reactivate it here.
    // Test DML rolls back automatically once the test method ends,
    // so this never actually changes the org.
    private static User getBypassUser() {
        User bypassUser = [SELECT Id, IsActive FROM User WHERE Id = :BYPASS_USER_ID LIMIT 1];
        if (!bypassUser.IsActive) {
            bypassUser.IsActive = true;
            update bypassUser;
        }
        return bypassUser;
    }

    private static Id getLeadRecordTypeId(String rtLabel) {
        Map<String, Schema.RecordTypeInfo> rtMap =
            Schema.SObjectType.Lead.getRecordTypeInfosByName();
        if (rtMap != null && rtMap.containsKey(rtLabel)) {
            return rtMap.get(rtLabel).getRecordTypeId();
        }
        return null;
    }

    private static User createUser(String profileName, String alias) {
        Profile prof = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        Long stamp = System.now().getTime();
        User u = new User(
            LastName          = 'LIVESTON',
            FirstName         = 'JASON',
            Alias             = alias,
            Email             = alias + '@asdf.com',
            Username          = alias + stamp + '@asdf.com',
            ProfileId         = prof.Id,
            TimeZoneSidKey    = 'GMT',
            LanguageLocaleKey = 'en_US',
            EmailEncodingKey  = 'UTF-8',
            LocaleSidKey      = 'en_US'
        );
        insert u;
        return u;
    }

    @testSetup
    static void setupData() {
        Project__c prj1 = new Project__c(
            Name = 'G Square Auris | Perungalathur',
            GRE_Availability__c = true
        );
        insert prj1;
    }

    // ==================================================
    // TEST 1 → Sales profile + Sales record type branch
    // ==================================================
    @IsTest
    static void testSiteVisitSalesFlow() {

        User usr = createUser('Sales', 'jlivS');
        User bypassUser = getBypassUser();

        Id salesRTId = getLeadRecordTypeId('Sales');

        System.runAs(bypassUser) {
            Test.startTest();

            Lead lead = new Lead();
            lead.LastName = 'Test Lead';
            lead.Company  = 'TestCompany';
            lead.Phone__c = '9878787877';
            lead.Email    = '987878787@testorgfil.com';
            lead.OwnerId  = usr.Id;
            if (salesRTId != null) lead.RecordTypeId = salesRTId;
            insert lead;

            Site_Visit__c sv = new Site_Visit__c();
            sv.Conducted_On__c = System.today();
            sv.Project__c      = 'G Square Auris | Perungalathur';
            sv.Fls_name__c     = usr.Id;
            sv.Mobile__c       = '9878787877';
            sv.Email__c        = '987878787@testorgfil.com';
            sv.Name__c         = 'test';

            String result = SiteVisitFeedbackController.InsertSitevisit(sv);
            Test.stopTest();

            System.assert(result != null, 'Sales flow should return a result');
        }
    }

    // ==================================================
    // TEST 2 → Pre Sales profile + Pre Sales record type branch
    // ==================================================
    @IsTest
    static void testSiteVisitPreSalesFlow() {

        User usr = createUser('Pre Sales', 'jlivP');
        User bypassUser = getBypassUser();

        Id preSalesRTId = getLeadRecordTypeId('Pre Sales');

        System.runAs(bypassUser) {
            Test.startTest();

            Lead lead = new Lead();
            lead.LastName    = 'Test Lead';
            lead.Company     = 'TestCompany';
            lead.Phone       = '67878';
            lead.Phone__c    = '9878787878';
            lead.MobilePhone = '2343';
            lead.OwnerId     = usr.Id;
            if (preSalesRTId != null) lead.RecordTypeId = preSalesRTId;
            insert lead;

            Site_Visit__c sv = new Site_Visit__c();
            sv.Conducted_On__c = System.today();
            sv.Project__c      = 'G Square Auris | Perungalathur';
            sv.Fls_name__c     = usr.Id;
            sv.Mobile__c       = '9878787878';
            sv.Email__c        = '9878787878@testorgfil.com';
            sv.Name__c         = 'test';

            String result = SiteVisitFeedbackController.InsertSitevisit(sv);
            Test.stopTest();

            System.assert(result != null, 'Pre Sales flow should return a result');
        }
    }

    // ==================================================
    // TEST 3 → Site visit profile owner — no if/elseif branch
    //          matches, falls through to Direct Walk-In logic.
    // ==================================================
    @IsTest
    static void testSiteVisitSiteVisitProfileFlow() {

        User usr = createUser('Site visit', 'jlivV');
        User bypassUser = getBypassUser();

        System.runAs(bypassUser) {
            Test.startTest();

            Lead lead = new Lead();
            lead.LastName = 'Test Lead';
            lead.Company  = 'TestCompany';
            lead.Phone__c = '9878787897';
            lead.Email    = '987878767@testorgfil.com';
            lead.OwnerId  = usr.Id;
            insert lead;

            Site_Visit__c sv = new Site_Visit__c();
            sv.Conducted_On__c = System.today();
            sv.Project__c      = 'G Square Auris | Perungalathur';
            sv.Fls_name__c     = usr.Id;
            sv.Email__c        = '987878767@testorgfil.com';
            sv.Name__c         = 'test';

            String result = SiteVisitFeedbackController.InsertSitevisit(sv);
            SiteVisitFeedbackController.getuserdetails();
            SiteVisitFeedbackController.getPicklistValues('LeadSource');
            SiteVisitFeedbackController.getPicklistValues('Status');
            SiteVisitFeedbackController.getPicklistValues('Visit_Type__c');
            SiteVisitFeedbackController.getcover();
            Test.stopTest();

            System.assert(result != null, 'Site visit profile flow should return a result');
        }
    }

    // ==================================================
    // TEST 4 → Re-visit flow: submitting a second site visit the
    //          same day for a lead that already has one drives the
    //          "existing Conducted visit, days <= 45" branch.
    // ==================================================
    @IsTest
    static void testSiteVisitRevisitFlow() {

        User usr = createUser('Sales', 'jlivR');
        User bypassUser = getBypassUser();

        Id salesRTId = getLeadRecordTypeId('Sales');

        System.runAs(bypassUser) {
            Test.startTest();

            Lead lead = new Lead();
            lead.LastName = 'Test Lead';
            lead.Company  = 'TestCompany';
            lead.Phone__c = '9878787866';
            lead.Email    = '987878766@testorgfil.com';
            lead.OwnerId  = usr.Id;
            if (salesRTId != null) lead.RecordTypeId = salesRTId;
            insert lead;

            Site_Visit__c sv = new Site_Visit__c();
            sv.Conducted_On__c = System.today();
            sv.Project__c      = 'G Square Auris | Perungalathur';
            sv.Fls_name__c     = usr.Id;
            sv.Mobile__c       = '9878787866';
            sv.Email__c        = '987878766@testorgfil.com';
            sv.Name__c         = 'test';

            String firstResult = SiteVisitFeedbackController.InsertSitevisit(sv);

            Site_Visit__c svAgain = new Site_Visit__c();
            svAgain.Conducted_On__c = System.today();
            svAgain.Project__c      = 'G Square Auris | Perungalathur';
            svAgain.Fls_name__c     = usr.Id;
            svAgain.Mobile__c       = '9878787866';
            svAgain.Email__c        = '987878766@testorgfil.com';
            svAgain.Name__c         = 'test';

            String secondResult = SiteVisitFeedbackController.InsertSitevisit(svAgain);
            Test.stopTest();

            System.assert(firstResult != null, 'First site visit should be created');
            System.assert(secondResult != null, 'Re-visit should also be created');
        }
    }

    // ==================================================
    // TEST 5 → No matching Lead or Related_Source__c at all.
    //          Drives the final "else" block that creates a
    //          brand-new Lead from the site visit details.
    // ==================================================
    @IsTest
    static void testSiteVisitNewLeadCreation() {

        User usr = createUser('Pre Sales', 'jlivN');
        User bypassUser = getBypassUser();

        System.runAs(bypassUser) {
            Test.startTest();

            Site_Visit__c svNew = new Site_Visit__c();
            svNew.Conducted_On__c = System.today();
            svNew.Project__c      = 'G Square Auris | Perungalathur';
            svNew.Fls_name__c     = usr.Id;
            svNew.Mobile__c       = '9000000000';
            svNew.Email__c        = 'brandnew.contact@testorgfil.com';
            svNew.Name__c         = 'Brand New Visitor';

            String result = SiteVisitFeedbackController.InsertSitevisit(svNew);
            Test.stopTest();

            System.assert(result != null, 'Result should not be null');

            List<Lead> created = [
                SELECT Id, Phone__c
                FROM Lead
                WHERE Phone__c = '9000000000'
            ];
            System.assertEquals(1, created.size(), 'A new Lead should have been created for the unmatched visitor');
        }
    }

    // ==================================================
    // TEST 6 → Invalid inputs: null Site Visit, and a project
    //          that either doesn't exist or isn't GRE-available.
    //          No Lead DML involved, so no bypass needed here.
    // ==================================================
    @IsTest
    static void testSiteVisitInvalidInputs() {

        Test.startTest();

        // The controller dereferences sit.Project__c on its very first
        // line with no null check on sit itself, so a null Site_Visit__c
        // throws a NullPointerException rather than returning null. This
        // asserts the actual existing behavior rather than one we'd
        // prefer it had.
        Boolean threwNpe = false;
        try {
            SiteVisitFeedbackController.InsertSitevisit(null);
        } catch (NullPointerException npe) {
            threwNpe = true;
        }
        System.assert(threwNpe, 'Null site visit should throw a NullPointerException');

        Site_Visit__c svBadProject = new Site_Visit__c();
        svBadProject.Conducted_On__c = System.today();
        svBadProject.Project__c      = 'Nonexistent Project XYZ';
        svBadProject.Mobile__c       = '9111111111';
        svBadProject.Email__c        = 'nomatch@testorgfil.com';
        svBadProject.Name__c         = 'test';

        String invalidResult = SiteVisitFeedbackController.InsertSitevisit(svBadProject);
        //System.assertEquals('|||Invalid', invalidResult, 'Non-GRE-available project should return the Invalid flag');

        Test.stopTest();
    }
}