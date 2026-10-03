@isTest
private class leadOpTest {

    @testSetup
    static void setupData() {
        Account acc = new Account(
            Name  = 'Test Account',
            Phone = '9999999999'
        );
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Contact',
            Phone     = '9999999999',
            AccountId = acc.Id
        );
        insert con;

        Lead ld = new Lead(
            FirstName   = 'Test',
            LastName    = 'Lead',
            Company     = 'Test Co',
            Phone       = '9999999999',
            MobilePhone = '9999999999'
        );
        insert ld;

        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        Case c = new Case(
            AccountId = acc.Id,
            Status    = 'New',
            Origin    = 'Phone'
        );
        insert c;
    }

    @isTest
    static void testGetValues_withAccount() {
        Lead ld = [SELECT Id FROM Lead WHERE Phone = '9999999999' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE Phone = '9999999999' LIMIT 1];

        Id[] fixedResults = new Id[]{ld.Id, con.Id};
        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
        String result = leadOp.getValues('9999999999');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testGetValues_noMatch() {
        Id[] fixedResults = new Id[]{};
        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
        String result = leadOp.getValues('0000000000');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
    }

    @isTest
    static void testSearchContact_found() {
        Lead ld = [SELECT Id FROM Lead WHERE Phone = '9999999999' LIMIT 1];

        Id[] fixedResults = new Id[]{ld.Id};
        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
        Lead found = leadOp.searchContact('9999999999');
        Test.stopTest();

        System.assertNotEquals(null, found, 'Lead should be found');
    }

    @isTest
    static void testSearchContact_notFound() {
        Id[] fixedResults = new Id[]{};
        Test.setFixedSearchResults(fixedResults);

        Test.startTest();
        Lead found = leadOp.searchContact('0000000000');
        Test.stopTest();

        System.assertEquals(null, found, 'Lead should be null');
    }

    @isTest
    static void testGetAccountByPhone_viaContact() {
        Test.startTest();
        Account acc = leadOp.getAccountByPhone('9999999999');
        Test.stopTest();

        System.assertNotEquals(null, acc, 'Account should be found via contact');
    }

    @isTest
    static void testGetAccountByPhone_directAccount() {
        Contact[] cons = [SELECT Id, Phone FROM Contact WHERE Phone = '9999999999'];
        for (Contact c : cons) {
            c.Phone = '0000000001';
        }
        update cons;

        Test.startTest();
        Account acc = leadOp.getAccountByPhone('9999999999');
        Test.stopTest();

        System.assertNotEquals(null, acc, 'Account should be found directly');
    }

    @isTest
    static void testGetAccountByPhone_notFound() {
        Test.startTest();
        Account acc = leadOp.getAccountByPhone('0000000000');
        Test.stopTest();

        System.assertEquals(null, acc, 'Should return null for unknown phone');
    }
}