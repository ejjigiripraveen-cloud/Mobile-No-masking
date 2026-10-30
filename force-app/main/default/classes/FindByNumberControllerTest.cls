@IsTest
private class FindByNumberControllerTest {
    private static final String SOURCE_NUMBER = '9555500001';

    @TestSetup
    static void setup() {
        User rep;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            rep = PhoneTestDataFactory.createUser('Standard User');
            PhoneTestDataFactory.createUser('Minimum Access - Salesforce');
        }
        List<Lead> leads = PhoneTestDataFactory.buildLeads(3, rep.Id);
        leads[0].LastName = 'Find Primary';
        leads[1].LastName = 'Find Other';
        leads[2].LastName = 'Find Via Source';
        PhoneTestDataFactory.insertLeads(leads);

        // The existing Related Source trigger updates the Lead; bypass the Lead trigger as for the Lead inserts.
        Boolean previousBypass = Utility.bypassLeadTrigger;
        Utility.bypassLeadTrigger = true;
        try {
            insert new Related_Source__c(Lead__c = leads[2].Id, Phone__c = SOURCE_NUMBER, OwnerId = rep.Id);
        } finally {
            Utility.bypassLeadTrigger = previousBypass;
        }
    }

    private static User userWithProfile(String profileName) {
        return [SELECT Id FROM User WHERE Email LIKE 'mask.tester%' AND Profile.Name = :profileName LIMIT 1];
    }

    private static Lead leadNamed(String lastName) {
        return [SELECT Id, Phone__c, Secondary_Phone__c FROM Lead WHERE LastName = :lastName LIMIT 1];
    }

    private static List<Phone_Access_Audit__c> searchAudits() {
        return [
            SELECT Action__c, Outcome__c, Record_Id__c, Object_Name__c, Masked_Number__c, Channel__c, Message__c, User__c
            FROM Phone_Access_Audit__c
            WHERE Action__c = :FindByNumberController.ACTION_SEARCH
        ];
    }

    private static FindByNumberController.SearchResult searchAsRep(String phoneNumber) {
        FindByNumberController.SearchResult result;
        System.runAs(userWithProfile('Standard User')) {
            result = FindByNumberController.findLeads(phoneNumber);
        }
        return result;
    }

    @IsTest
    static void findsLeadByPrimaryInAnyFormat() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });
        String typed = '+91 ' + lead.Phone__c.left(5) + '-' + lead.Phone__c.right(5);

        Test.startTest();
        FindByNumberController.SearchResult result = searchAsRep(typed);
        Test.stopTest();

        Assert.isNull(result.errorMessage);
        Assert.areEqual(1, result.leads.size());
        Assert.areEqual(lead.Id, result.leads[0].recordId);
        Assert.areEqual('Find Primary', result.leads[0].name);
        Assert.areEqual(Lead.Phone__c.getDescribe().getLabel(), result.leads[0].matchedOn);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), result.leads[0].maskedNumber);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), result.maskedNumber);
        Assert.isFalse(result.hasMore);

        List<Phone_Access_Audit__c> audits = searchAudits();
        Assert.areEqual(1, audits.size());
        Assert.areEqual(MaskedDialService.OUTCOME_SUCCESS, audits[0].Outcome__c);
        Assert.areEqual(String.valueOf(lead.Id), audits[0].Record_Id__c);
        Assert.areEqual('Lead', audits[0].Object_Name__c);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Phone__c), audits[0].Masked_Number__c);
        Assert.areEqual(FindByNumberController.CHANNEL, audits[0].Channel__c);
        Assert.areEqual('1 lead found.', audits[0].Message__c);
        Assert.areEqual(userWithProfile('Standard User').Id, audits[0].User__c);
    }

    @IsTest
    static void findsLeadBySecondary() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });

        FindByNumberController.SearchResult result = searchAsRep('0' + lead.Secondary_Phone__c);

        Assert.areEqual(1, result.leads.size());
        Assert.areEqual(Lead.Secondary_Phone__c.getDescribe().getLabel(), result.leads[0].matchedOn);
        Assert.areEqual(PhoneMaskUtil.mask(lead.Secondary_Phone__c), result.leads[0].maskedNumber);
    }

    @IsTest
    static void findsLeadThroughRelatedSource() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Via Source');
        Related_Source__c source = [SELECT Id FROM Related_Source__c WHERE Lead__c = :lead.Id LIMIT 1];
        Test.setFixedSearchResults(new List<Id>{ source.Id });

        FindByNumberController.SearchResult result = searchAsRep(SOURCE_NUMBER);

        Assert.areEqual(1, result.leads.size());
        Assert.areEqual(lead.Id, result.leads[0].recordId);
        Assert.areEqual('Related Source', result.leads[0].matchedOn);
        Assert.areEqual(PhoneMaskUtil.mask(SOURCE_NUMBER), result.leads[0].maskedNumber);
    }

    @IsTest
    static void ignoresLeadsWithADifferentNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead target = leadNamed('Find Primary');
        Lead other = leadNamed('Find Other');
        // The search index can return near matches; only exact numbers may be listed.
        Test.setFixedSearchResults(new List<Id>{ target.Id, other.Id });

        FindByNumberController.SearchResult result = searchAsRep(target.Phone__c);

        Assert.areEqual(1, result.leads.size());
        Assert.areEqual(target.Id, result.leads[0].recordId);
    }

    @IsTest
    static void neverReturnsTheRealNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });

        String serialized = JSON.serialize(searchAsRep(lead.Phone__c));

        Assert.isFalse(serialized.contains(lead.Phone__c), 'Primary number must not reach the browser');
        Assert.isFalse(serialized.contains(lead.Secondary_Phone__c), 'Secondary number must not reach the browser');
        Assert.isFalse(serialized.contains(lead.Phone__c.substring(2, 8)), 'Middle digits must not reach the browser');
    }

    @IsTest
    static void rejectsPartialOrInvalidNumbers() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });

        List<String> invalidInputs = new List<String>{
            lead.Phone__c.left(5), '', null, 'abc' + lead.Phone__c, lead.Phone__c + '*', '1234567890123456'
        };
        for (String input : invalidInputs) {
            FindByNumberController.SearchResult result = searchAsRep(input);
            Assert.isNotNull(result.errorMessage, 'Input must be rejected: ' + input);
            Assert.areEqual(0, result.leads.size());
        }

        List<Phone_Access_Audit__c> audits = searchAudits();
        Assert.areEqual(invalidInputs.size(), audits.size());
        for (Phone_Access_Audit__c audit : audits) {
            Assert.areEqual(MaskedDialService.OUTCOME_DENIED, audit.Outcome__c);
            Assert.isNull(audit.Record_Id__c);
        }
    }

    @IsTest
    static void reportsNotFound() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Test.setFixedSearchResults(new List<Id>());

        FindByNumberController.SearchResult result = searchAsRep('9000099999');

        Assert.isNull(result.errorMessage);
        Assert.areEqual(0, result.leads.size());
        Assert.areEqual('90XXXXXX99', result.maskedNumber);
        List<Phone_Access_Audit__c> audits = searchAudits();
        Assert.areEqual(1, audits.size());
        Assert.areEqual(MaskedDialService.OUTCOME_NOT_FOUND, audits[0].Outcome__c);
        Assert.areEqual('0 leads found.', audits[0].Message__c);
    }

    @IsTest
    static void deniesUserWithoutLeadAccess() {
        PhoneTestDataFactory.useTestConfig(true, true);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });

        FindByNumberController.SearchResult result;
        System.runAs(userWithProfile('Minimum Access - Salesforce')) {
            result = FindByNumberController.findLeads(lead.Phone__c);
        }

        Assert.areEqual('You do not have access to Leads.', result.errorMessage);
        Assert.areEqual(0, result.leads.size());
        List<Phone_Access_Audit__c> audits = searchAudits();
        Assert.areEqual(1, audits.size());
        Assert.areEqual(MaskedDialService.OUTCOME_DENIED, audits[0].Outcome__c);
    }

    @IsTest
    static void capsResultsForManyLeadsWithTheSameNumber() {
        PhoneTestDataFactory.useTestConfig(true, true);
        User rep = userWithProfile('Standard User');
        List<Lead> leads = PhoneTestDataFactory.buildLeads(200, rep.Id);
        for (Lead lead : leads) {
            lead.Phone__c = '9444400001';
        }
        PhoneTestDataFactory.insertLeads(leads);
        Test.setFixedSearchResults(new List<Id>(new Map<Id, Lead>(leads).keySet()));

        Test.startTest();
        FindByNumberController.SearchResult result = searchAsRep('9444400001');
        Test.stopTest();

        Assert.areEqual(FindByNumberController.MAX_RESULTS, result.leads.size());
        Assert.isTrue(result.hasMore);
        List<Phone_Access_Audit__c> audits = searchAudits();
        Assert.areEqual(1, audits.size(), 'One audit row per search, not per lead');
        Assert.areEqual('200 leads found.', audits[0].Message__c);
        Assert.isNull(audits[0].Record_Id__c);
    }

    @IsTest
    static void writesNoAuditWhenAuditIsOff() {
        PhoneTestDataFactory.useTestConfig(true, false);
        Lead lead = leadNamed('Find Primary');
        Test.setFixedSearchResults(new List<Id>{ lead.Id });

        FindByNumberController.SearchResult result = searchAsRep(lead.Phone__c);

        Assert.areEqual(1, result.leads.size());
        Assert.areEqual(0, searchAudits().size());
    }

    @IsTest
    static void searchesTheFormsANumberMayBeSavedIn() {
        PhoneTestDataFactory.useTestConfig(true, true);

        Set<String> national = FindByNumberController.searchVariants('9810000000');
        Set<String> international = FindByNumberController.searchVariants('447700900123');

        Assert.areEqual(new Set<String>{ '9810000000', '919810000000', '09810000000' }, national);
        Assert.areEqual(new Set<String>{ '447700900123' }, international);
    }
}
