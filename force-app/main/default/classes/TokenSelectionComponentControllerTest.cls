@isTest
public with sharing class TokenSelectionComponentControllerTest 
{
    @isTest
    public static void getProjects()
    {
        Project__c pro = new Project__c();
        pro.Name = 'Test project';
        insert pro;
        Test.startTest();
        TokenSelectionComponentController.getProjects();
        System.assertEquals('Test project', pro.Name);

        delete pro;
        TokenSelectionComponentController.getProjects();
        Test.stopTest();
        
    }

    @isTest
    public static void getTokens()
    {
        Project__c pro = new Project__c();
        pro.Name = 'Test project';
        String facing = 'East';
        insert pro;
        Test.startTest();
            TokenSelectionComponentController.getTokens(pro.Id);
            TokenSelectionComponentController.getTokens(null);
            TokenSelectionComponentController.getPlcAmount(facing,pro.Id);

        //Test.stopTest();
        List<Project__c> listOfProject = [SELECT Id,PLC_Facing_1__c,PLC_Facing_2__c,PLC_Facing_3__c FROM Project__c WHERE Id =:pro.Id];
        listOfProject[0].PLC_Facing_2__c ='South';
        String facing2 = 'South';
        update listOfProject;
        TokenSelectionComponentController.getPlcAmount(facing2,pro.Id);

        List<Project__c> listOfProject1 = [SELECT Id,PLC_Facing_1__c,PLC_Facing_2__c,PLC_Facing_3__c FROM Project__c WHERE Id =:pro.Id];
        listOfProject1[0].PLC_Facing_3__c ='North';
        String facing3 = 'North';
        update listOfProject1;
        TokenSelectionComponentController.getPlcAmount(facing3,pro.Id);
        Test.stopTest();
    }
    
    @isTest
    public static void insertTokenAndReceipt()
    {
        Boolean check = false;
	
        ProjectWiseReceipt__c setting = new ProjectWiseReceipt__c();
        setting.Name = 'Test Mantri Manyata Lithos Project';
        setting.Starting_NUmber__c = 1;
        setting.Receipt_Format__c = 'ABCD-AVF';
        setting.Current_Receipt_Number__c = 1;
        insert setting;
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Contact TestContact = new Contact();
        TestContact.lastname = 'lastname';
        TestContact.Salutation='Mr.';
        //TestContact.Contact_Type__c = 'type';
        TestContact.Birthdate = Date.newInstance(1990,10,06);
        //TestContact.AccountId = AccountId;
        TestContact.OtherCity='India';  
        TestContact.OtherCountry='Delhi';
        TestContact.OtherStreet='chandni chowk';
        TestContact.OtherPostalCode='320222';
        TestContact.Nationality__c ='Indian';
        TestContact.Industry__c ='Riico';
        TestContact.Designation__c ='Doveloper';
        TestContact.Employed_at__c ='Google';
        TestContact.Profession__c='IT';
        TestContact.Resident_Status__c='PIO';
        TestContact.Relation_with_Applicant__c = 'N/A';
        TestContact.PAN_Card__c = 'ABCDE0011Q';
        insert TestContact;

        Project__c TestProject = new Project__c();
            TestProject.Name = 'Test Mantri Manyata Lithos Project';
            TestProject.Bank_Account_Name__c = 'Test Bank Account';
            TestProject.Bank_Account_Number__c = 1234567890;
            TestProject.Bank_Account_Type__c = 'test';
            TestProject.Bank_Name__c = 'Test Bank';
            TestProject.Grace_Period__c = 30;
            TestProject.Overdue_Available__c = true;
            TestProject.Overdue_penalty__c = 18;
            TestProject.Payment_Allocation__c = 'Inclusive First';
            TestProject.Project_Email__c = 'Test@test.com';
            TestProject.Summary_Quote_Notes__c = 'testeat';
            TestProject.Quotation_Approval__c = 'Above threshold?;Below Threshold;For all quotation';
            TestProject.With_Without_Inventory__c = 'With Inventory';
            insert TestProject;

        //Add by Prem Chand
        Block__c TestBlock = new Block__c();
            TestBlock.Name = 'testBlock';
            TestBlock.Project__c = TestProject.Id;
            Insert TestBlock;
        
        Opportunity TestOpportunity = new Opportunity();
        TestOpportunity.StageName = '1.Site Visit';
        TestOpportunity.Name = 'test Opp Name';
        TestOpportunity.CloseDate = Date.today();
        TestOpportunity.AccountId = acc.Id;
        TestOpportunity.Contact__c = TestContact.Id;
        //TestOpportunity.Apartment__c = TestApartment.Id;
        TestOpportunity.Minimum_Booking_Amount_Received__c =True;
        TestOpportunity.Encrypted_Email__c = 'test@test.com';
        // TestOpportunity.Template_Master__c = TestTemplateMaster.Id;
        // TestOpportunity.Component_Master__c = testComponentMaster.Id;
        insert TestOpportunity;

        TokenSelectionComponentController.wrapperForinventoryData wrapObj = new TokenSelectionComponentController.wrapperForinventoryData();
            wrapObj.size = 100.0;
            wrapObj.facing = 'East';
            wrapObj.basePrice = 500000.0;
            wrapObj.plc = 500.0;
            wrapObj.thresoldRate = 500.0;
            wrapObj.EOIFacing = 'East';
            wrapObj.EOIFacing = 'East';
            wrapObj.coumputationAmount = 0.0;
            wrapObj.plotDimension = 0.0;
            wrapObj.tokenDiscount = 0.0;
            wrapObj.tokenToalDiscountDiscount = 0.0;
            wrapObj.plotCostAfterDiscount = 0.0;
            wrapObj.projectPlcAmount = 10;
            wrapObj.totalReceiptAmount = 10;
            wrapObj.TokenProjectId = TestProject.Id;
            wrapObj.plotCostElevatedWithDiscount = 500000;
            wrapObj.PlotCostWithelevated =600000;
            wrapObj.EoiIncrementValue =10000;
            wrapObj.EoiTotalIncrement =10000;
            wrapObj.AreaRange = '500';
            

        Receipt__c testRecpt  = new Receipt__c(
           Name = 'Receipt',
           Opportunity__c= TestOpportunity.Id,
            Receipt_Date__c= System.today(),
           Project_Name__c= TestProject.Name,
            Status__c= 'Done',
            Mode_of_Payment__c= 'Cash',
            Payment_Category__c = 'Flat Cost',
            Amount__c =100
        );

        List<Receipt__c> listOfReceipt = new List<Receipt__c>();

        listOfReceipt.add(testRecpt);

        Token__c testToken = new Token__c();
        testToken.Name = 'Test Token';
        testToken.Start_Date__c = System.today();
        testToken.Token_Prefix__c = 'Test_Prefix';
        testToken.No_of_token_to_be_generate__c = 10;
        testToken.Token_Order__c =200;
        testToken.Last_Token_Id__c = null;
        testToken.Project__c = TestProject.Id;
        testToken.Email__c = 'test@test.com';
        testToken.Discount_in_Amt__c = 50000;
        insert testToken;
        AddInventoryOnTokenController.checkProjectidOnToken(testToken.Id);
      

        Test.startTest();
        
             //TokenSelectionComponentController.insertTokenAndReceipt(listOfReceipt,null,TestOpportunity.Id,check);
             //TokenSelectionComponentController.insertTokenAndReceipt(listOfReceipt,testToken.Id,opp.Id,check);

             //TokenSelectionComponentController.insertTokenAndReceipt(listOfReceipt,testToken.Id,TestOpportunity.Id,true); by Prem
             TokenSelectionComponentController.insertTokenAndReceipt(listOfReceipt,wrapObj,testToken.Id,TestOpportunity.Id,true,null); 
             TokenSelectionComponentController.ProjectWithInventoryOrWithout(TestOpportunity.Id);
             TokenSelectionComponentController.getProjectAreaRange(TestOpportunity.Id);
             TokenSelectionComponentController.getBlocks(TestProject.Id);
             TokenSelectionComponentController.getInventory(TestBlock.Id);
            
        Test.stopTest();
        // List<Token__c> token = [SELECT Id, Name, Last_Token_Id__c, Token_Order__c, Token_Prefix__c FROM Token__c WHERE Project__c =:pro.Id];
        
        
        // Integer tokenNumber =(integer) token[0].Token_Order__c + 1;
        // String tokenNameStr = token[0].Token_Prefix__c.toUppercase();
        
		// String name = tokenNameStr +' - '+ String.valueOf(tokenNumber);
        // System.debug(name);
        // System.assertEquals('TEST_PREFIX - 201',name);

        
    }

    @isTest
    public static void validateRequest()
    {
        List<TokenSelectionComponentController.wrapperForTokenDetailsPage> listOfWrapper = new List<TokenSelectionComponentController.wrapperForTokenDetailsPage>();
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today().addDays(1);
        opp.StageName = '1.Site Tour Completed';
        opp.LeadSource = 'Referral';
        opp.Referred_Opportunity__c = 'temp';
        insert opp;

        Test.startTest();

        listOfWrapper = TokenSelectionComponentController.validateRequest(opp.Id);
        System.assertEquals('Test Opportunity',listOfWrapper[0].Name);

        opp.Referred_Opportunity__c = '';
        opp.Referred_Employee__c = 'temp';
        update opp;

        listOfWrapper = TokenSelectionComponentController.validateRequest(opp.Id);
        //System.assertEquals('temp',listOfWrapper[0].source);

        opp.Referred_Employee__c = '';
        opp.Referred_by_Management__c = 'temp';
        update opp;

        listOfWrapper = TokenSelectionComponentController.validateRequest(opp.Id);
        //System.assertEquals('temp',listOfWrapper[0].source);

        listOfWrapper = TokenSelectionComponentController.validateRequest(null);

        Test.stopTest();
    }
    @isTest
    public static void fetchLookupData()
    {
        List<Project__c> listOfProject = new List<Project__c>();
        Project__c	project = new Project__c();
        project.Name = 'Test Mantri Manyata Lithos Project';
        project.Project_Approval_Status__c = 'YTA';
        insert project;

        String pro = 'Project__c';

        Test.startTest();
        listOfProject = TokenSelectionComponentController.fetchLookupData('test',pro);
        Test.stopTest();
        System.assertEquals('Test Mantri Manyata Lithos Project',listOfProject[0].Name);

        

    }
    
    @isTest
    public static void getTokensDetails()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Project__c pro = new Project__c();
        pro.Name = 'Test project';
        insert pro;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today().addDays(1);
        opp.StageName = '1.Site Tour Completed';
      //  opp.Encrypted_Email__c = 'test@test.com';
        insert opp;
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'Test Opportunity3232';
        opp1.AccountId = acc.Id;
        opp1.CloseDate = System.today().addDays(1);
        opp1.StageName = '1.Site Tour Completed';
      	//  opp.Encrypted_Email__c = 'test@test.com';
        insert opp1;

        Token__c testToken = new Token__c();
        testToken.Name = 'Test Token';
        testToken.Start_Date__c = System.today();
        testToken.Token_Prefix__c = 'Test_Prefix';
        testToken.No_of_token_to_be_generate__c = 10;
        testToken.Token_Order__c =200;
        testToken.Last_Token_Id__c = null;
        testToken.Project__c = pro.Id;
        testToken.Opportunity__c = opp.Id;
        testToken.Email__c = 'test@test.com';
        insert testToken;

        Test.startTest();
        	TokenSelectionComponentController.getTokensDetails(opp.Id);
        	TokenSelectionComponentController.getTokensDetails(null);
        Test.stopTest();
        List<Token__c> token = [SELECT Id, Name FROM Token__c WHERE Opportunity__c =:opp.Id];
        Integer size = token.size();
        System.assertEquals(1,size);
    }

    @isTest
    public static void checkingNumTokenGenerated()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Project__c pro = new Project__c();
        pro.Name = 'Test project';
        insert pro;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today().addDays(1);
        opp.StageName = '1.Site Tour Completed';
        opp.Referred_Opportunity__c = 'sdsd';
        //opp.Encrypted_Email__c = 'test@test.com';
        insert opp;

        Token__c testToken = new Token__c();
        testToken.Name = 'Test Token';
        testToken.Start_Date__c = System.today();
        testToken.Token_Prefix__c = 'Test_Prefix';
        testToken.No_of_token_to_be_generate__c = 10;
        testToken.Token_Order__c =200;
        testToken.Last_Token_Id__c = null;
        testToken.Project__c = pro.Id;
        testToken.Opportunity__c = opp.Id;
        testToken.No_of_token_to_be_generate__c = 5;
        testToken.Email__c = 'test1@test.com';
        insert testToken;
        Test.startTest();
        TokenSelectionComponentController.checkingNumTokenGenerated(testToken.Id);
        List<Token__c> listofRelatedTokens = [SELECT Id , No_of_token_to_be_generate__c FROM Token__c 
            WHERE Parent_Token__c =:testToken.Id];
            Integer sizeOfRelated = listofRelatedTokens.size();
        Test.stopTest();
        //System.assertEquals(0,sizeOfRelated);
    }
    
    @isTest
    public static void testcheckForTokenUpgradeDegrade()
    {
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Project__c pro = new Project__c();
        pro.Name = 'Test project';
        insert pro;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opportunity';
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today().addDays(1);
        opp.StageName = '1.Site Tour Completed';
        //opp.Main_Source__c = 'Pre sales';
        //opp.Encrypted_Email__c = 'test@test.com';
        insert opp;

        Token__c testToken = new Token__c();
        testToken.Name = 'Test Token';
        testToken.Start_Date__c = System.today();
        testToken.Token_Prefix__c = 'Test_Prefix';
        testToken.No_of_token_to_be_generate__c = 10;
        testToken.Token_Order__c =200;
        testToken.Last_Token_Id__c = null;
        testToken.Project__c = pro.Id;
        testToken.Opportunity__c = opp.Id;
        testToken.No_of_token_to_be_generate__c = 5;
        testToken.Email__c = 'test1@test.com';
        insert testToken;
        Test.startTest();
        TokenSelectionComponentController.checkForTokenUpgradeDegrade(opp.Id);
        Test.stopTest();
        //System.assertEquals(0,sizeOfRelated);
    }
     //Create Apartment PREM
    @isTest
     public static void apartmentGenerateForecastTest1() 
    {
        SetupTestData SetupTestDataAsCR = new SetupTestData(ProfileUtilities.ProfileType.SYSADMIN);
        System.runAs(SetupTestDataAsCR.TestUser) 
        {
            SetupTestDataAsCR.createTestAccount();
            SetupTestDataAsCR.createTestContact();
            Project__c testProj = SetupTestDataAsCR.createTestProject();
            Block__c testBlockObj = SetupTestDataAsCR.createTestBlock();
            SetupTestDataAsCR.createTestComponentMaster();
            SetupTestDataAsCR.createTestSubComponents();
            SetupTestDataAsCR.createTestTaxMaster();
            SetupTestDataAsCR.createTestTemplateMaster();
            list<Template__c> Testtemplates = SetupTestDataAsCR.createTestTemplates();
            SetupTestDataAsCR.createTestRateMaster();
           Apartment__c apt = SetupTestDataAsCR.createTestApartment();
           Token__c testToken = new Token__c();
            testToken.Name = 'Test Token';
            testToken.Inventory__c = apt.Id;
            insert testToken;
            AddInventoryOnTokenController.inventoryUpdateOnToken(testToken.Id,apt.Id);
            TokenSelectionComponentController.getInventoryValues(apt.Id);
        }
    }

    //Create Apartment
    @isTest
     public static void apartmentGenerateForecastTest() 
    {
        SetupTestData SetupTestDataAsCR = new SetupTestData(ProfileUtilities.ProfileType.SYSADMIN);
        System.runAs(SetupTestDataAsCR.TestUser) 
        {
            SetupTestDataAsCR.createTestAccount();
            SetupTestDataAsCR.createTestContact();
            Project__c testProj = SetupTestDataAsCR.createTestProject();
            Block__c testBlockObj = SetupTestDataAsCR.createTestBlock();
            SetupTestDataAsCR.createTestComponentMaster();
            SetupTestDataAsCR.createTestSubComponents();
            SetupTestDataAsCR.createTestTaxMaster();
            SetupTestDataAsCR.createTestTemplateMaster();
            list<Template__c> Testtemplates = SetupTestDataAsCR.createTestTemplates();
            SetupTestDataAsCR.createTestRateMaster();
           Apartment__c apt = SetupTestDataAsCR.createTestApartment();
        }
    }

    //Setup Data
      public class SetupTestData 
    {
        public User TestUser                                {get;set;}
        public User SomeUser                                {get;set;}
        public Account TestAccount                          {get;set;}
        public Account TestAccount2                         {get;set;}
        public Contact TestContact                          {get;set;}
        public Project__c TestProject                       {get;set;}
        public Block__c TestBlock                           {get;set;}
        public Component_Master__c testComponentMaster      {get;set;}
        public List<Sub_Component__c> testSubComponentList  {get;set;}
        public List<Tax_Master__c> TestTaxMasterList        {get;set;}
        public list<Rate_Master__c> Rate_Master_List        {get;set;}
        public Apartment__c TestApartment                   {get;set;}
        public Template_Master__c TestTemplateMaster        {get;set;}
        public list<Template__c> TestTemplateList           {get;set;}
        public Broker__c TestBroker                         {get;set;}
        public Offer__c testOffer                           {get;set;}
        public BrokerOfferUpdate__c testBrokerOfferUpdate   {get;set;}
        public Term_Master__c TestTermMaster                {get;set;}
        public Opportunity TestOpportunity                  {get;set;}
        public OpportunityDetail__c TestOpportunityDetail   {get;set;}
        public list<Installment__c> testinstlmntlst         {get;set;}
        public list<InstallmentDetail__c> testinstlmntdtllst {get;set;}
        public ForeCast__c TestForecast                     {get;set;}
        public list<Forecast_Installment__c> testFrcstinstlmntlst {get;set;}
        public Receipt__c testRecpt             {get;set;}
        public ProjectWiseReceipt__c testProjectWiseReceipt {get;set;}
        public Overdue_Detail__c testOverdueDetail  {get;set;}
        public Quotation__c testQuotation   				 {get;set;}

        public SetupTestData(ProfileUtilities.ProfileType profile_type) 
        {
            TestUser = UserTestData.getUserForTest().setProfile(ProfileUtilities.getInstance().getProfileName(profile_type)).save().getRecord();
            SomeUser = UserTestData.getUserForTest().setProfile(ProfileUtilities.getInstance().getProfileName(profile_type)).save().getRecord();
            TestAccount = new Account();
            TestAccount2 = new Account();
            TestContact = new Contact();
            TestProject = new Project__c();
            TestBlock = new Block__c();
            testComponentMaster = new Component_Master__c();
            testSubComponentList = new list<Sub_Component__c>();
            TestTaxMasterList = new List<Tax_Master__c>();
            Rate_Master_List = new list<Rate_Master__c>();
            TestApartment = new Apartment__c();
            TestTemplateMaster = new Template_Master__c();
            TestTemplateList = new list<Template__c>();
            TestBroker =  new Broker__c();
            testOffer = new Offer__c();
            testBrokerOfferUpdate = new BrokerOfferUpdate__c();
            TestTermMaster = new Term_Master__c();
            TestOpportunity = new Opportunity();
            TestOpportunityDetail = new OpportunityDetail__c();
            TestForecast = new ForeCast__c();
            testRecpt = new Receipt__c();
            testProjectWiseReceipt = new ProjectWiseReceipt__c();
            testOverdueDetail = new Overdue_Detail__c();
            testQuotation = new Quotation__c();
        }
        
        //Create Test Account
        public void createTestAccount() {
            TestAccount.Name = 'Test Acc Name';
            insert TestAccount;
        }
        
        //Create Test Account 2
        public Account createTestAccount2() {
            TestAccount2.Name = 'Test Acc Name2';
            insert TestAccount2;
            return TestAccount2;
        }
        
        //Create Test Contact
        public Contact createTestContact() {
            TestContact.lastname = 'lastname';
        TestContact.Salutation='Mr.';
        //TestContact.Contact_Type__c = 'type';
        TestContact.Birthdate = Date.newInstance(1990,10,06);
        //TestContact.AccountId = AccountId;
        TestContact.OtherCity='India';  
        TestContact.OtherCountry='Delhi';
        TestContact.OtherStreet='chandni chowk';
        TestContact.OtherPostalCode='320222';
        TestContact.Nationality__c ='Indian';
        TestContact.Industry__c ='Riico';
        TestContact.Designation__c ='Doveloper';
        TestContact.Employed_at__c ='Google';
        TestContact.Profession__c='IT';
        TestContact.Resident_Status__c='PIO';
        TestContact.Relation_with_Applicant__c = 'N/A';
        TestContact.PAN_Card__c = 'ABCDE0011Q';
            insert TestContact;
            return TestContact;
        }
        
        //Create Test Project
        public Project__c createTestProject()
        {
            TestProject.Name = 'Test Mantri Manyata Lithos Project';
            TestProject.Bank_Account_Name__c = 'Test Bank Account';
            TestProject.Bank_Account_Number__c = 1234567890;
            TestProject.Bank_Account_Type__c = 'test';
            TestProject.Bank_Name__c = 'Test Bank';
            TestProject.Grace_Period__c = 30;
            TestProject.Overdue_Available__c = true;
            TestProject.Overdue_penalty__c = 18;
            TestProject.Payment_Allocation__c = 'Inclusive First';
            TestProject.Project_Email__c = 'Test@test.com';
            TestProject.Summary_Quote_Notes__c = 'testeat';
            TestProject.Quotation_Approval__c = 'Above threshold?;Below Threshold;For all quotation';
            TestProject.Generate_quotation_for_units__c = 'Available;Blocked by management';
            insert TestProject;
            return TestProject;
        }
        
        //Create Test Block
        public Block__c createTestBlock()
        {
            TestBlock.Name = 'Test Block A';
            TestBlock.CRM_Name__c = 'XYZ';
            TestBlock.Date_Of_Possession__c = date.newinstance(2021, 8, 22);
            TestBlock.Project__c = TestProject.Id;
            TestBlock.Previous_Possession_Date__c = date.newinstance(2019, 8, 22);
            TestBlock.RM_email_Address__c = 'Test@test.com';
            TestBlock.RM_Phone_No__c = '98754387654';
            insert TestBlock;
            AddInventoryOnTokenController.getProjectRelatedBlocks(TestBlock.Id);
            String areaRange = '1000-2000';
            String facing = 'East';
            AddInventoryOnTokenController.getInventoriesRelatedBlock(TestBlock.Id,areaRange,facing);
            return TestBlock;
        }
        
        //Create Test Component Master
        public void createTestComponentMaster()
        {
            testComponentMaster.Name = 'Test Component Master';
            testComponentMaster.isStandardMaster__c = true;
            testComponentMaster.Project__c = TestProject.Id;
            insert testComponentMaster;
        }       
        
        //Create Test Sub Component
        public void createTestSubComponents()
        {
            testSubComponentList = new list<Sub_Component__c>();
            list<String> CompNameList = new list<String>{'Other','Construction Cost','Land Cost','Floor Rise Charges','Premium Charges','Car Park','Other6','Other7','Other8','Other9','Other10',
            'Other11','Other12','Other13','Other14','Other15','Other16','Other17','Other18','Other19','Other20'};
            for(integer i = 0;i<= 2;i++)
            {
                testSubComponentList.add(
                    new Sub_Component__c(
                        Name = CompNameList[i],
                        apartment_Comp__c = CompNameList[i],
                        Component_Master__c = testComponentMaster.id,
                        Display_Order__c = i+1,
                        Collection_Type__c = 'Inclusive',
                        Component_Rate_Type__c ='Franking'
                    )
                );
            }
            for(integer i = 3;i<= 9;i++)
            {
                testSubComponentList.add(
                    new Sub_Component__c(
                        Name = CompNameList[i],
                        apartment_Comp__c = CompNameList[i],
                        Component_Master__c = testComponentMaster.id,
                        Display_Order__c = i+1,
                        Collection_Type__c = 'On Possession'
                    )
                );
            }
            
            insert testSubComponentList;
            
        }
        //Create Test Tax Master
        public void createTestTaxMaster()
        {
            TestTaxMasterList = new list<Tax_Master__c>();
            list<String> TaxRateNameList = new list<String>{'Other','Construction Cost','Land Cost','Floor Rise Charges','Premium Charges','Car Park','Other6','Other7','Other8','Other9','Other10',
            'Other11','Other12','Other13','Other14','Other15','Other16','Other17','Other18','Other19','Other20'};
            for(integer i = 1;i <= 9;i++)
            {
                TestTaxMasterList.add(
                    new Tax_Master__c (
                        Name = TaxRateNameList[i]+' Tax',
                        From_Date__c = date.newinstance(2021, 1, 22),
                        To_Date__c = date.newinstance(2025, 1, 22),

                        Sub_Component__c = testSubComponentList[i].Id,
                        TC1_Change_Type__c = 'Receipt',
                        TC1_Appr__c = 40,
                        TC1_Available__c = true,
                        TC1_Name__c = 'ST',
                        TC1_Type__c = 'Inclusive',
                        TC1_Value__c = 12.36,
                        TC2_Change_Type__c = 'Receipt',
                        TC2_Appr__c = 100,
                        TC2_Available__c = true,
                        TC2_Name__c = 'VAT',
                        TC2_Type__c ='Inclusive',
                        TC2_Value__c = 4,
                        TC3_Change_Type__c = 'Receipt',
                        TC3_Appr__c = 100,
                        TC3_Available__c = true,
                        TC3_Name__c = 'VAT',
                        TC3_Type__c ='Inclusive',
                        TC3_Value__c = 4,
                        TC4_Change_Type__c = 'Receipt',
                        TC4_Appr__c = 100,
                        TC4_Available__c = true,
                        TC4_Name__c = 'VAT',
                        TC4_Type__c ='Inclusive',
                        TC4_Value__c = 4
                    )
                );
            }
            
            insert TestTaxMasterList;
        }
        
        //Create Test Template Master
        public Template_Master__c createTestTemplateMaster()
        {
            TestTemplateMaster.Name = 'Test Lithos Block A Template';
            TestTemplateMaster.Block__c = TestBlock.Id;
            TestTemplateMaster.Is_Construction_Link_Plan__c = true;
            TestTemplateMaster.Project__c = TestProject.Id;
            insert TestTemplateMaster;
            return TestTemplateMaster;
        }
        
        //Create Test Template 
        public list<Template__c> createTestTemplates()
        {
            TestTemplateList = new list<Template__c>();
            list<String> TemplateNameList = new list<String>{'On Booking','Agreement Signing','On Foundation','On First Floor Roof Slab','On Fourth Floor Roof Slab','On Seventh Floor Roof Slab','On Last Floor Roof Slab','On Possession','On Possession1','On Possession2','On Possession3'};
            for(integer i =0;i<=10;i++)
            {
                TestTemplateList.add(
                    new Template__c(
                        Name = TemplateNameList[i],
                        Display_Order__c = i+1,
                        Due_Date__c = (Date.today()).addDays(2),
                        Installment_Value__c = 10,
                        Generate_Demand_Letter__c = false,
                        Template_Master__c = TestTemplateMaster.Id,
                        Grace_Period__c = 2,
                        Overdue_Interest_Applicable__c = false
                    )
                );
            }
            insert TestTemplateList;
            return TestTemplateList;
        }
        
        //Create Test Rate_Master__c
        public void createTestRateMaster()
        {
            Rate_Master_List = new list<Rate_Master__c>();
            list<String> RateNameList = new list<String>{'Construction Cost','Land Cost','Premium Rate','Floor Rise Charges','Car Park','Apartment Cost'};
            list<String> RateTypeList = new list<String>{'','Normal','North Facing','1st Floor','Covered Car Park',''};
            for(integer i=0;i<=5;i++)
            {
                Rate_Master_List.add(
                    new Rate_Master__c(
                        Name = RateNameList[i],
                        Component_Name__c = RateNameList[i],
                        Component_Type__c = RateTypeList[i],
                        Project__c = TestProject.Id,
                        Rate__c = 3000+i,
                        Apartment_Rate_Consideration__c = 'Include Premium Charges'
                    )
                );
            }
            insert Rate_Master_List;
        }
        
        //Create Test Apartment
        public Apartment__c createTestApartment() {
            TestApartment.Name = 'Test Apartment';
            TestApartment.Additional_Sit_out_Area_SBUA__c = 120;
            TestApartment.Additional_Terrace_area__c = 30;
            TestApartment.Apartment_Master__c = Rate_Master_List[5].Id;
            TestApartment.Apartment_Cost__c = 4190;
            TestApartment.Apartment_Status__c = 'Available';
            TestApartment.Apartment_Sub_type__c =
            TestApartment.Apartment_Type__c = '2BHK';
            TestApartment.Block__c = TestBlock.Id;
            TestApartment.Built_Up_Area__c = 1145;
            TestApartment.Car_Park_Master__c = Rate_Master_List[4].Id;
            TestApartment.Car_Park_Rate__c = 3000;
            TestApartment.Car_Park_Type__c = 'Covered Car Park';
            TestApartment.No_of_car_park__c = 2;
            TestApartment.Carpet_Area__c = 1000;
            TestApartment.Construction_Cost_Master__c = Rate_Master_List[0].Id;
            TestApartment.Construction_Cost__c = 3000;
            TestApartment.Discount_Amount__c = 50;
            TestApartment.Discount_Type__c = 'Land Rate';
            TestApartment.Flat_No__c = '001';
            TestApartment.Floor_No__c ='1';
            TestApartment.Floor_Rate_Master__c = Rate_Master_List[3].Id;
            TestApartment.Floor_Rise_Charges__c = 2000;
            TestApartment.Floor_Rise_Charges_Per_Sqft__c = 90.00;
            TestApartment.Generate_Forecast__c = false;
            TestApartment.Land_Cost_Master__c = Rate_Master_List[1].Id;
            TestApartment.Land_Cost__c = 4000;
            TestApartment.Other_Area__c = 1200;
            TestApartment.Premium_Charges__c = 200;
            TestApartment.Premium_Rate_Master__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master2__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master3__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master4__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master5__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate__c = 3900;
            TestApartment.Take_Rate_from_Rate_Master__c = true;
            TestApartment.Terrace_Area__c = 200.00;
            TestApartment.UDS_Area__c = 100;
            TestApartment.ComponentMaster__c = testComponentMaster.Id;
            insert TestApartment;
            return TestApartment;
        }

        //Create Test Apartment
        public Apartment__c createTestApartment2() {
            TestApartment.Name = 'Test Apartment';
            TestApartment.Additional_Sit_out_Area_SBUA__c = 120;
            TestApartment.Additional_Terrace_area__c = 30;
            TestApartment.Apartment_Master__c = Rate_Master_List[5].Id;
            TestApartment.Apartment_Cost__c = 4190;
            TestApartment.Apartment_Status__c = 'Available';
            TestApartment.Apartment_Sub_type__c =
            TestApartment.Apartment_Type__c = '2BHK';
            TestApartment.Block__c = TestBlock.Id;
            TestApartment.Built_Up_Area__c = 1145;
            TestApartment.Car_Park_Master__c = Rate_Master_List[4].Id;
            TestApartment.Car_Park_Rate__c = 3000;
            TestApartment.Car_Park_Type__c = 'Covered Car Park';
            TestApartment.Carpet_Area__c = 1000;
            TestApartment.Construction_Cost_Master__c = Rate_Master_List[0].Id;
            TestApartment.Construction_Cost__c = 3000;
            TestApartment.Discount_Amount__c = 50;
            TestApartment.Discount_Type__c = 'Land Rate';
            TestApartment.Flat_No__c = '001';
            TestApartment.Floor_No__c ='1';
            TestApartment.Floor_Rate_Master__c = Rate_Master_List[3].Id;
            TestApartment.Floor_Rise_Charges__c = 2000;
            TestApartment.Floor_Rise_Charges_Per_Sqft__c = 90.00;
            TestApartment.Generate_Forecast__c = false;
            TestApartment.Land_Cost_Master__c = Rate_Master_List[1].Id;
            TestApartment.Land_Cost__c = 4000;
            TestApartment.Other_Area__c = 1200;
            TestApartment.Premium_Charges__c = 200;
            TestApartment.Premium_Rate_Master__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master2__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master3__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master4__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master5__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate__c = 3900;
            TestApartment.Take_Rate_from_Rate_Master__c = true;
            TestApartment.Terrace_Area__c = 200.00;
            TestApartment.UDS_Area__c = 100;
            TestApartment.ComponentMaster__c = testComponentMaster.Id;
            insert TestApartment;
            return TestApartment;
        }

        //Create Test Apartment
        public Apartment__c createTestApartment3() {
            TestApartment.Name = 'Test Apartment';
            TestApartment.Additional_Sit_out_Area_SBUA__c = 120;
            TestApartment.Additional_Terrace_area__c = 30;
            TestApartment.Apartment_Master__c = Rate_Master_List[5].Id;
            TestApartment.Apartment_Cost__c = 4190;
            TestApartment.Apartment_Status__c = 'Available';
            TestApartment.Apartment_Sub_type__c =
            TestApartment.Apartment_Type__c = '2BHK';
            TestApartment.Block__c = TestBlock.Id;
            TestApartment.Built_Up_Area__c = 1145;
            TestApartment.Car_Park_Rate__c = 3000;
            TestApartment.Car_Park_Type__c = 'Covered Car Park';
            TestApartment.No_of_car_park__c = 2;
            TestApartment.Carpet_Area__c = 1000;
            TestApartment.Construction_Cost_Master__c = Rate_Master_List[0].Id;
            TestApartment.Construction_Cost__c = 3000;
            TestApartment.Discount_Amount__c = 50;
            TestApartment.Discount_Type__c = 'Land Rate';
            TestApartment.Flat_No__c = '001';
            TestApartment.Floor_No__c ='1';
            TestApartment.Floor_Rate_Master__c = Rate_Master_List[3].Id;
            TestApartment.Floor_Rise_Charges__c = 2000;
            TestApartment.Floor_Rise_Charges_Per_Sqft__c = 90.00;
            TestApartment.Generate_Forecast__c = false;
            TestApartment.Land_Cost_Master__c = Rate_Master_List[1].Id;
            TestApartment.Land_Cost__c = 4000;
            TestApartment.Other_Area__c = 1200;
            TestApartment.Premium_Charges__c = 200;
            TestApartment.Premium_Rate_Master__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master2__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master3__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master4__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate_Master5__c = Rate_Master_List[2].Id;
            TestApartment.Premium_Rate__c = 3900;
            TestApartment.Take_Rate_from_Rate_Master__c = true;
            TestApartment.Terrace_Area__c = 200.00;
            TestApartment.UDS_Area__c = 100;
            TestApartment.ComponentMaster__c = testComponentMaster.Id;
            insert TestApartment;
            return TestApartment;
        }
        
        public Broker__c createtestBroker() 
        {
            TestBroker.Name = 'Test Broker Name';
            TestBroker.Service_Tax__c = 10;
            TestBroker.Start_Date__c = date.today();
            TestBroker.Email__c = 'Test@test.com';
            insert TestBroker;
            return TestBroker;
        }  
        
        public Offer__c createtestOffer()
        {
            testOffer.Name = 'Test offer';
            testOffer.Approval_Date__c = date.today();
            testOffer.Approval_Status__c = 'Approved';
            testOffer.End_Date__c = (date.today()).addDays(20);
            testOffer.Number_of_Customers__c = 3;
            testOffer.Offer_p__c = 2;
            testOffer.Start_Date__c = date.today();
            testOffer.Target_No_of_Opportunities__c = 2;
            insert testOffer;
            return testOffer;
        }
        
        
        public BrokerOfferUpdate__c createtestBrokerOfferUpdate()
        {
            testBrokerOfferUpdate.Broker__c = TestBroker.Id;
            testBrokerOfferUpdate.Offer__c = testOffer.Id;
            testBrokerOfferUpdate.Offer_Amount__c = 1000;
            testBrokerOfferUpdate.Offer_Paid__c = true;
            testBrokerOfferUpdate.target_Number_of_customer__c = 2;
            insert testBrokerOfferUpdate;
            return testBrokerOfferUpdate;
            
            
        }
        
        public Term_Master__c createtestTestTermMaster()
        {
            TestTermMaster.Name = 'Test Term master';
            TestTermMaster.Project__c = TestProject.Id;
            TestTermMaster.Start_Date__c = date.today();
            TestTermMaster.Total_Brokerage_Percent__c = 20;
            TestTermMaster.Term_Type__c = 'Slab Wise';
            TestTermMaster.Display_Order1__c = 1;
            TestTermMaster.Display_Order2__c = 2;
            TestTermMaster.Display_Order3__c = 3;
            TestTermMaster.Display_Order4__c = 4;
            TestTermMaster.Display_Order5__c = 5;
            TestTermMaster.Display_Order6__c = 6;
            TestTermMaster.Display_Order7__c = 7;
            TestTermMaster.Display_Order8__c = 8;
            TestTermMaster.Display_Order9__c = 9;
            TestTermMaster.Display_Order10__c = 10;
            TestTermMaster.Target_Payment_1__c = 0;
            TestTermMaster.Slab_Brokerage_1__c = 60;
            TestTermMaster.Slab_Brokerage_2__c = 40;
            TestTermMaster.Pay_Brokerage_1__c = 0;
            TestTermMaster.Pay_Brokerage_2__c = 0;
            TestTermMaster.Stage_Brokerage_1__c = 0;
            TestTermMaster.End_Date__c = date.today();
            TestTermMaster.Total_Brokerage_Percent__c = 3;
            insert TestTermMaster;
            return TestTermMaster;
        }
        
        
        //Create Test Opportunity without Apartment
        public Opportunity createTestOpportunity3(){
            TestOpportunity.StageName = '1.Site Visit';
            TestOpportunity.Name = 'test Opp Name';
            TestOpportunity.CloseDate = Date.today();
            TestOpportunity.AccountId = TestAccount.Id;
            TestOpportunity.Contact__c = TestContact.Id;
            //TestOpportunity.Apartment__c = TestApartment.Id;
            TestOpportunity.Minimum_Booking_Amount_Received__c =True;
            TestOpportunity.Template_Master__c = TestTemplateMaster.Id;
            TestOpportunity.Component_Master__c = testComponentMaster.Id;
            insert TestOpportunity;
            return TestOpportunity;
        }     
        
        public OpportunityDetail__c createTestOppDetail()
        {
            TestOpportunityDetail.Opportunity__c = TestOpportunity.Id;
            TestOpportunityDetail.Name = 'test Opp Name' + '-Detail';
            TestOpportunityDetail.Apartment__c = TestApartment.Id;
            TestOpportunityDetail.Component_Master__c = testComponentMaster.Id;
            TestOpportunityDetail.Booking_Date__c = Date.today();
            for(integer i = 1; i<=8;i++)
            {
                TestOpportunityDetail.put('Comp'+i+'_Tax__c',TestTaxMasterList[i].Id);
            }
            insert TestOpportunityDetail;
            return TestOpportunityDetail;
        }
        
        public list<Installment__c> createTestInstallmentList()
        {
            testinstlmntlst = new list<Installment__c>();
            list<string> namelst = new list<String>{'On Booking','Agreement Signing','On Foundation','On First Floor Roof Slab','On Fourth Floor Roof Slab','On Seventh Floor Roof Slab','On Last Floor Roof Slab','On Possession','On Possession1','On Possession2','On Possession3'};
            for(integer i=0;i<=10;i++)
            {
                testinstlmntlst.add(new Installment__c(Name = namelst[i],Opportunity__c = TestOpportunity.Id,
                                                        OpportunityDetail__c = TestOpportunityDetail.Id,
                                                        Template__c = TestTemplateList[i].Id,Display_Order__c = i+1,
                                                        Status__c = 'pending',
                                                        Component_Included__c = '1;2;3;4;5;6;7;8;9;10;11;12;13;14;15'));
            }
            
            insert testinstlmntlst;
            return testinstlmntlst;
        }
        
        public list<InstallmentDetail__c> createTestInstallmentdtlList()
        {
            testinstlmntdtllst = new list<InstallmentDetail__c>();
            list<string> namelst = new list<String>{'On Booking','Agreement Signing','On Foundation','On First Floor Roof Slab','On Fourth Floor Roof Slab','On Seventh Floor Roof Slab','On Last Floor Roof Slab','On Possession','On Possession1','On Possession2','On Possession3'};
            for(integer i=0;i<=10;i++)
            {
                testinstlmntdtllst.add(new InstallmentDetail__c(Name = namelst[i],Opportunity__c = TestOpportunity.Id,
                                                        OpportunityDetail__c = TestOpportunityDetail.Id,Total_Balance__c = 500,Status__c = 'Completed',
                                                        Incl_Tax1_Received__c = 0,Incl_Tax2_Received__c = 0,Incl_Tax3_Received__c = 0,Incl_Tax4_Received__c = 0,
                                                        Rec_Comp1_Basic__c = 1, Rec_Comp2_Basic__c = 0, Rec_Comp3_Basic__c = 0, Rec_Comp4_Basic__c = 0, Rec_Comp5_Basic__c = 0, Rec_Comp6_Basic__c = 0, Rec_Comp7_Basic__c = 0, 
                                                        Rec_Comp8_Basic__c = 0, Rec_Comp9_Basic__c = 0, Rec_Comp10_Basic__c =0,
                                                        Rec_Comp11_Basic__c = 0, Rec_Comp12_Basic__c = 0, Rec_Comp13_Basic__c = 0, Rec_Comp14_Basic__c = 0, Rec_Comp15_Basic__c = 0, 
                                                        Rec_Comp16_Basic__c = 0, Rec_Comp17_Basic__c = 0, Rec_Comp18_Basic__c = 0, Rec_Comp19_Basic__c = 0, Rec_Comp20_Basic__c = 0,
                                                        Rec_Comp1_Tax1_Amount__c = 0, Rec_Comp2_Tax1_Amount__c = 0, Rec_Comp3_Tax1_Amount__c = 0, Rec_Comp4_Tax1_Amount__c = 0, Rec_Comp5_Tax1_Amount__c = 0, 
                                                        Rec_Comp6_Tax1_Amount__c = 0, Rec_Comp7_Tax1_Amount__c = 0, Rec_Comp8_Tax1_Amount__c = 0, Rec_Comp9_Tax1_Amount__c = 0, Rec_Comp10_Tax1_Amount__c = 0,
                                                        Rec_Comp11_Tax1_Amount__c = 0, Rec_Comp12_Tax1_Amount__c = 0, Rec_Comp13_Tax1_Amount__c = 0, Rec_Comp14_Tax1_Amount__c = 0, Rec_Comp15_Tax1_Amount__c = 0, 
                                                        Rec_Comp16_Tax1_Amount__c = 0, Rec_Comp17_Tax1_Amount__c = 0, Rec_Comp18_Tax1_Amount__c = 0, Rec_Comp19_Tax1_Amount__c = 0, Rec_Comp20_Tax1_Amount__c = 0,
                                                        Rec_Comp1_Tax2_Amount__c = 0, Rec_Comp2_Tax2_Amount__c = 0, Rec_Comp3_Tax2_Amount__c = 0, Rec_Comp4_Tax2_Amount__c = 0, Rec_Comp5_Tax2_Amount__c = 0, 
                                                        Rec_Comp6_Tax2_Amount__c = 0, Rec_Comp7_Tax2_Amount__c = 0, Rec_Comp8_Tax2_Amount__c = 0, Rec_Comp9_Tax2_Amount__c = 0, Rec_Comp10_Tax2_Amount__c = 0,
                                                        Rec_Comp11_Tax2_Amount__c = 0, Rec_Comp12_Tax2_Amount__c = 0, Rec_Comp13_Tax2_Amount__c = 0, Rec_Comp14_Tax2_Amount__c = 0, Rec_Comp15_Tax2_Amount__c = 0, 
                                                        Rec_Comp16_Tax2_Amount__c = 0, Rec_Comp17_Tax2_Amount__c = 0, Rec_Comp18_Tax2_Amount__c = 0, Rec_Comp19_Tax2_Amount__c = 0, Rec_Comp20_Tax2_Amount__c = 0,
                                                        Rec_Comp1_Tax3_Amount__c = 0, Rec_Comp2_Tax3_Amount__c = 0, Rec_Comp3_Tax3_Amount__c = 0, Rec_Comp4_Tax3_Amount__c = 0, Rec_Comp5_Tax3_Amount__c = 0, 
                                                        Rec_Comp6_Tax3_Amount__c = 0, Rec_Comp7_Tax3_Amount__c = 0, Rec_Comp8_Tax3_Amount__c = 0, Rec_Comp9_Tax3_Amount__c = 0, Rec_Comp10_Tax3_Amount__c = 0,
                                                        Rec_Comp11_Tax3_Amount__c = 0, Rec_Comp12_Tax3_Amount__c = 0, Rec_Comp13_Tax3_Amount__c = 0, Rec_Comp14_Tax3_Amount__c = 0, Rec_Comp15_Tax3_Amount__c = 0, 
                                                        Rec_Comp16_Tax3_Amount__c = 0, Rec_Comp17_Tax3_Amount__c = 0, Rec_Comp18_Tax3_Amount__c = 0, Rec_Comp19_Tax3_Amount__c = 0, Rec_Comp20_Tax3_Amount__c = 0,
                                                        Rec_Comp1_Tax4_Amount__c = 0, Rec_Comp2_Tax4_Amount__c = 0, Rec_Comp3_Tax4_Amount__c = 0, Rec_Comp4_Tax4_Amount__c = 0, Rec_Comp5_Tax4_Amount__c = 0, 
                                                        Rec_Comp6_Tax4_Amount__c = 0, Rec_Comp7_Tax4_Amount__c = 0, Rec_Comp8_Tax4_Amount__c = 0, Rec_Comp9_Tax4_Amount__c = 0, Rec_Comp10_Tax4_Amount__c = 0,
                                                        Rec_Comp11_Tax4_Amount__c = 0, Rec_Comp12_Tax4_Amount__c = 0, Rec_Comp13_Tax4_Amount__c = 0, Rec_Comp14_Tax4_Amount__c = 0, Rec_Comp15_Tax4_Amount__c = 0, 
                                                        Rec_Comp16_Tax4_Amount__c = 0, Rec_Comp17_Tax4_Amount__c = 0, Rec_Comp18_Tax4_Amount__c = 0, Rec_Comp19_Tax4_Amount__c = 0, Rec_Comp20_Tax4_Amount__c = 0,
                                                        Rec_Comp1_Total__c = 0, Rec_Comp2_Total__c = 0, Rec_Comp3_Total__c = 0, Rec_Comp4_Total__c = 0, Rec_Comp5_Total__c = 0, Rec_Comp6_Total__c = 0, Rec_Comp7_Total__c = 0, 
                                                        Rec_Comp8_Total__c = 0, Rec_Comp9_Total__c = 0, Rec_Comp10_Total__c = 0, Rec_Comp11_Total__c = 0, Rec_Comp12_Total__c = 0, Rec_Comp13_Total__c = 0, Rec_Comp14_Total__c = 0, 
                                                        Rec_Comp15_Total__c = 0, Rec_Comp16_Total__c = 0, Rec_Comp17_Total__c = 0, Rec_Comp18_Total__c = 0, Rec_Comp19_Total__c = 0, Rec_Comp20_Total__c = 0, 
                                                        Bal_Comp1_Basic__c = 0, Bal_Comp2_Basic__c = 0, Bal_Comp3_Basic__c = 0, Bal_Comp4_Basic__c = 0, Bal_Comp5_Basic__c = 0, Bal_Comp6_Basic__c = 0, Bal_Comp7_Basic__c = 0, 
                                                        Bal_Comp8_Basic__c = 0, Bal_Comp9_Basic__c = 0, Bal_Comp10_Basic__c = 0, Bal_Comp11_Basic__c = 0, Bal_Comp12_Basic__c = 0, Bal_Comp13_Basic__c = 0, Bal_Comp14_Basic__c = 0, 
                                                        Bal_Comp15_Basic__c = 0, Bal_Comp16_Basic__c = 0, Bal_Comp17_Basic__c = 0, Bal_Comp18_Basic__c = 0, Bal_Comp19_Basic__c = 0, Bal_Comp20_Basic__c = 0, 
                                                        Bal_Comp1_Tax1_Amount__c = 0, Bal_Comp2_Tax1_Amount__c = 0, Bal_Comp3_Tax1_Amount__c = 0, Bal_Comp4_Tax1_Amount__c = 0, Bal_Comp5_Tax1_Amount__c = 0, 
                                                        Bal_Comp6_Tax1_Amount__c = 0, Bal_Comp7_Tax1_Amount__c = 0, Bal_Comp8_Tax1_Amount__c = 0, Bal_Comp9_Tax1_Amount__c = 0, Bal_Comp10_Tax1_Amount__c = 0,
                                                        Bal_Comp11_Tax1_Amount__c = 0, Bal_Comp12_Tax1_Amount__c = 0, Bal_Comp13_Tax1_Amount__c = 0, Bal_Comp14_Tax1_Amount__c = 0, Bal_Comp15_Tax1_Amount__c = 0, 
                                                        Bal_Comp16_Tax1_Amount__c = 0, Bal_Comp17_Tax1_Amount__c = 0, Bal_Comp18_Tax1_Amount__c = 0, Bal_Comp19_Tax1_Amount__c = 0, Bal_Comp20_Tax1_Amount__c = 0,
                                                        Bal_Comp1_Tax2_Amount__c = 0, Bal_Comp2_Tax2_Amount__c = 0, Bal_Comp3_Tax2_Amount__c = 0, Bal_Comp4_Tax2_Amount__c = 0, Bal_Comp5_Tax2_Amount__c = 0, 
                                                        Bal_Comp6_Tax2_Amount__c = 0, Bal_Comp7_Tax2_Amount__c = 0, Bal_Comp8_Tax2_Amount__c = 0, Bal_Comp9_Tax2_Amount__c = 0, Bal_Comp10_Tax2_Amount__c = 0,
                                                        Bal_Comp11_Tax2_Amount__c = 0, Bal_Comp12_Tax2_Amount__c = 0, Bal_Comp13_Tax2_Amount__c = 0, Bal_Comp14_Tax2_Amount__c = 0, Bal_Comp15_Tax2_Amount__c = 0, 
                                                        Bal_Comp16_Tax2_Amount__c = 0, Bal_Comp17_Tax2_Amount__c = 0, Bal_Comp18_Tax2_Amount__c = 0, Bal_Comp19_Tax2_Amount__c = 0, Bal_Comp20_Tax2_Amount__c = 0,
                                                        Bal_Comp1_Tax3_Amount__c = 0, Bal_Comp2_Tax3_Amount__c = 0, Bal_Comp3_Tax3_Amount__c = 0, Bal_Comp4_Tax3_Amount__c = 0, Bal_Comp5_Tax3_Amount__c = 0, 
                                                        Bal_Comp6_Tax3_Amount__c = 0, Bal_Comp7_Tax3_Amount__c = 0, Bal_Comp8_Tax3_Amount__c = 0, Bal_Comp9_Tax3_Amount__c = 0, Bal_Comp10_Tax3_Amount__c = 0,
                                                        Bal_Comp11_Tax3_Amount__c = 0, Bal_Comp12_Tax3_Amount__c = 0, Bal_Comp13_Tax3_Amount__c = 0, Bal_Comp14_Tax3_Amount__c = 0, Bal_Comp15_Tax3_Amount__c = 0, 
                                                        Bal_Comp16_Tax3_Amount__c = 0, Bal_Comp17_Tax3_Amount__c = 0, Bal_Comp18_Tax3_Amount__c = 0, Bal_Comp19_Tax3_Amount__c = 0, Bal_Comp20_Tax3_Amount__c = 0,
                                                        Bal_Comp1_Tax4_Amount__c = 0, Bal_Comp2_Tax4_Amount__c = 0, Bal_Comp3_Tax4_Amount__c = 0, Bal_Comp4_Tax4_Amount__c = 0, Bal_Comp5_Tax4_Amount__c = 0, 
                                                        Bal_Comp6_Tax4_Amount__c = 0, Bal_Comp7_Tax4_Amount__c = 0, Bal_Comp8_Tax4_Amount__c = 0, Bal_Comp9_Tax4_Amount__c = 0, Bal_Comp10_Tax4_Amount__c = 0,
                                                        Bal_Comp11_Tax4_Amount__c = 0, Bal_Comp12_Tax4_Amount__c = 0, Bal_Comp13_Tax4_Amount__c = 0, Bal_Comp14_Tax4_Amount__c = 0, Bal_Comp15_Tax4_Amount__c = 0, 
                                                        Bal_Comp16_Tax4_Amount__c = 0, Bal_Comp17_Tax4_Amount__c = 0, Bal_Comp18_Tax4_Amount__c = 0, Bal_Comp19_Tax4_Amount__c = 0, Bal_Comp20_Tax4_Amount__c = 0,
                                                        Bal_Comp1_Total__c = 0, Bal_Comp2_Total__c = 0, Bal_Comp3_Total__c = 0, Bal_Comp4_Total__c = 0, Bal_Comp5_Total__c = 0, Bal_Comp6_Total__c = 0, Bal_Comp7_Total__c = 0, 
                                                        Bal_Comp8_Total__c = 0, Bal_Comp9_Total__c = 0, Bal_Comp10_Total__c = 0, Bal_Comp11_Total__c = 0, Bal_Comp12_Total__c = 0, Bal_Comp13_Total__c = 0, Bal_Comp14_Total__c = 0, 
                                                        Bal_Comp15_Total__c = 0, Bal_Comp16_Total__c = 0, Bal_Comp17_Total__c = 0, Bal_Comp18_Total__c = 0, Bal_Comp19_Total__c = 0, Bal_Comp20_Total__c = 0,
                                                        Total_Basic_Received__c = 0,Total_Basic_Balance__c = 0,Total_Tax1_Received__c = 0,Total_Tax2_Received__c = 0,Total_Tax3_Received__c = 0,Total_Tax4_Received__c = 0,
                                                        Total_Tax1_Balance__c = 0,Total_Tax2_Balance__c = 0,Total_Tax3_Balance__c = 0,Total_Tax4_Balance__c = 0,Total_Received__c = 100,
                                                        Tax1_paid__c = 0,Tax2_paid__c = 0,Tax3_paid__c = 0,Tax4_paid__c = 0,
                                                        Installment__c = testinstlmntlst[i].Id,Display_Order__c = i+1));
            }
            
            insert testinstlmntdtllst;
            return testinstlmntdtllst;
        }
        
        
        public ForeCast__c createTestForecast()
        {
            TestForecast.Apartment__c = TestApartment.Id;
            TestForecast.Component_Master__c = testComponentMaster.Id;
            TestForecast.Template_Master__c = TestTemplateMaster.Id;
            insert TestForecast;
            return TestForecast;
        }
        
        public list<Forecast_Installment__c> createoneTestForecastInstallmentList() 
        {
            testFrcstinstlmntlst = new list<Forecast_Installment__c>();
            list<string> namelst = new list<String>{'On Booking','Agreement Signing','On Foundation','On First Floor Roof Slab','On Fourth Floor Roof Slab','On Seventh Floor Roof Slab','On Last Floor Roof Slab','On Possession','On Possession1','On Possession2','On Possession3'};
            for(integer i=0;i<1;i++)
            {
                testFrcstinstlmntlst.add(new Forecast_Installment__c(Name = namelst[i],
                                                        ForeCast__c = TestOpportunityDetail.Id,
                                                        Template__c = TestTemplateList[i].Id,Display_Order__c = i+1,
                                                        Component_Included__c = '1;2;3;4;5;6;7;8;9;10;11;12;13;14;15'));
            }
            
            insert testFrcstinstlmntlst;
            return testFrcstinstlmntlst;
        } 
        
        public Receipt__c createTestReceipt()
        {
            testRecpt.Name = 'Receipt';
            testRecpt.Opportunity__c= TestOpportunity.Id;
            testRecpt.Receipt_Date__c= System.today();
            //testRecpt.Project_Name__c= TestOpportunity.Project_Name__c;
            testRecpt.Status__c= 'Done';
            testRecpt.Mode_of_Payment__c= 'Cash';
            testRecpt.Payment_Category__c = 'Flat Cost';
            testRecpt.Amount__c =100;
            insert testRecpt;
            return testRecpt;
        }
        
        public ProjectWiseReceipt__c createProjectWiseReceipt()
        {
            testProjectWiseReceipt.Name = 'Test Mantri Manyata Lithos Project';
            testProjectWiseReceipt.Current_Receipt_Number__c = 1;
            testProjectWiseReceipt.Receipt_Format__c = 'MME';
            testProjectWiseReceipt.Starting_NUmber__c = 10;
            insert testProjectWiseReceipt;
            return testProjectWiseReceipt;
        }
        
        public Overdue_Detail__c createtestOverdueDetail()
        {
            testOverdueDetail.Allocated_Amount__c = 100;
            testOverdueDetail.Previous_Amount_Due__c = 60;
            testOverdueDetail.From_Date__c = system.today();
            testOverdueDetail.Installment__c = testinstlmntlst[0].Id;
            testOverdueDetail.Opportunity__c = TestOpportunity.Id;
            testOverdueDetail.Overdue_penalty__c = 3;
            testOverdueDetail.Previous_Receipt_ID__c = 'test';
            testOverdueDetail.Receipt__c = testRecpt.Id;
            testOverdueDetail.Receipt_Date__c = system.today();
            testOverdueDetail.Unique_key__c = 'abdhgt8';
            insert testOverdueDetail;
            return testOverdueDetail;
        }
        
        public Quotation__c createTestQuotation()
        {
           	testQuotation = new Quotation__c();
            testQuotation.Opportunity__c = TestOpportunity.Id;
            testQuotation.Inventory__c = TestApartment.Id;
            testQuotation.Total_Basic__c = 10000;
            testQuotation.Total_Balance__c = 2323;
            testQuotation.Inclusive_Amt_Total__c = 2323;
            testQuotation.Total_Tax1__c = 1222;
            testQuotation.Total_Tax2__c = 1222;
            testQuotation.Total_Tax3__c = 1222;
            testQuotation.Total_Tax4__c = 2122;
            testQuotation.Is_Final_Quotation__c = false;
            testQuotation.Standard_Booking_Amount__c = true;

            for(Sub_Component__c sub : testSubComponentList)
            {
                testQuotation.put('Component_'+sub.Display_Order__c+'_Name__c',sub.Name);
                testQuotation.put('Component_'+sub.Display_Order__c+'_Basic__c',100);
                testQuotation.put('Component_'+sub.Display_Order__c+'_Amount_After_Discount__c',100);
                testQuotation.put('Component_'+sub.Display_Order__c+'_Discount__c',100);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax1_Amount__c',100);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax2_Amount__c',100);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax3_Amount__c',100);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax4_Amount__c',100);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax1_Name__c','one');
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax2_Name__c','tow');
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax3_Name__c','three');
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax4_Name__c','four');
                testQuotation.put('Comp'+sub.Display_Order__c+'_Total__c',800);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Tax__c',null);
                testQuotation.put('Comp'+sub.Display_Order__c+'_Selection_Type__c',sub.apartment_Comp__c);
            }
            
            for(Integer compCount = 1; compCount<= TestTaxMasterList.size() ; compCount++)
            {
                  testQuotation.put('Comp'+compCount+'_Tax__c', TestTaxMasterList[compCount-1].Id);
                  testQuotation.put('Component_'+compCount+'_Amount_After_Discount__c',1000);
            }
            
            insert testQuotation;
            return testQuotation;
        }
    }
}