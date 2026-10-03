public with sharing class TokenSelectionComponentController {

    /*
    *  Purpose         :   Fetch projects.
    *  Created By      :   Ajay Singh
    *  Created Date    :   2/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static List<Project__c> getProjects(){
        try {
            
            List<Project__c> listOfProjects = [Select Id, Name,With_Without_Inventory__c,Increment_Type__c From Project__c limit 50000];

            if(!listOfProjects.isEmpty()){
                return listOfProjects;
            }else {
                return new List<Project__c>();
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    *  Purpose         :   Fetch token project wise.
    *  Created By      :   Ajay Singh
    *  Created Date    :   2/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static List<Token__c> getTokens(Id Id){
        try {
            System.debug(Id);
            if (Id == null){
                return new List<Token__c>();

            }
            List<Token__c> listOfTokens = [Select Id ,Start_Date__c ,End_Date__c, Name,Discount_in_Amt__c From Token__c Where  
            Project__c  =: Id And RecordType.Name = 'General Token' And Opportunity__c = Null And Start_Date__c <= TODAY AND End_Date__c >= TODAY AND Status__c != 'Cancelled' limit 50000];

            if(!listOfTokens.isEmpty()){
                return listOfTokens;
            }else {
                return new List<Token__c>();
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
    *  Purpose         :   Fetch token project wise.
    *  Created By      :   Ajay Singh
    *  Created Date    :   2/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static Token__c insertTokenAndReceipt(List<Receipt__c> receiptListToInsert, wrapperForinventoryData aptWrap,
        Id tokenId, Id oppId, Boolean tokenInsert, Map<String, List<String>> mapOfAttechments)
    {

      //  try
      //  {
            if (tokenId == null || oppId == null)
            {
                return null;
            }
            List<Token__c> listOftoken = [SELECT Id FROM Token__c WHERE Opportunity__c =: oppId AND Status__c != 'Cancelled'];
            Opportunity oppo = [SELECT Id, Token_Project_Id__c,Encrypted_Email__c,Price_Per_sft_cent__c FROM Opportunity WHERE Id =: oppId limit 1];
            RecordType rtObj = [SELECT Id, Name FROM RecordType WHERE sObjectType = 'Token__c' AND Name = 'Opportunity Token' LIMIT 1];
            Token__c tokenObj = [SELECT Token_Order__c, Name, Start_Date__c, RecordTypeId, Opportunity__c, Last_Token_Id__c, End_Date__c,
                Discount_in_Amt__c, Comp8_Unit_type__c, Comp8_discount__c, Comp7_Unit_type__c, Comp7_discount__c, Comp6_Unit_type__c,
                Comp6_discount__c, Comp5_Unit_type__c, Comp5_discount__c, Comp4_Unit_type__c, Comp4_discount__c, Comp3_Unit_type__c,
                Comp3_discount__c, Comp2_discount__c, Comp2_Unit_type__c, Comp1_discount__c, Comp1_Unit_type__c, Token_Prefix__c,
                Project__r.Name, Project__c, Size__c, Base_Price__c, EOI_Date__c, Price_Per_sft_cent__c
                FROM Token__c WHERE Id  =: tokenId AND Status__c != 'Cancelled' limit 1 FOR UPDATE];

            if(listOftoken.size() > 0 )
            {
                return null;
            }

            Integer tokenNumber = 0;
            Token__c tokenCloneForInsert = tokenObj.clone();

            if(tokenObj.Last_Token_Id__c == null)
            {
                tokenNumber = (integer) tokenObj.Token_Order__c + 1;
                tokenObj.Last_Token_Id__c = tokenNumber;
            }
            else
            {
                tokenNumber = (Integer)tokenObj.Last_Token_Id__c + 1;
                tokenObj.Last_Token_Id__c = tokenNumber;
            }
            
            String tokenNameStr = tokenObj.Token_Prefix__c.toUppercase();
            oppo.Token_Project_Id__c = tokenObj.Project__c;

            tokenCloneForInsert.Name = tokenNameStr + '-' + tokenNumber;
            tokenCloneForInsert.Opportunity__c = oppId;
            tokenCloneForInsert.Parent_Token__c = tokenObj.Id;
            tokenCloneForInsert.RecordTypeId = rtObj.Id;

            //System.debug('@@->' + oppo.Encrypted_Email__c);
            tokenCloneForInsert.Email__c = oppo.Encrypted_Email__c;
            //System.debug('@@->' + tokenCloneForInsert.Encrypted_Email__c);


            if(tokenInsert)
            {  
                Decimal receiptAmount = 0;      
                if(!receiptListToInsert.isEmpty())
                {
                    System.debug('ReceiptList==>Pc '+receiptListToInsert);
                    for(Receipt__c rc : receiptListToInsert){
                        receiptAmount += rc.Amount__c;
                    }
                    //Template_Controller.insertReceiptRecord(receiptListToInsert);
                }
                
                //apt code
                 System.debug('aptWrap pcc==> '+aptWrap);
                tokenCloneForInsert.Project__c = null;
                tokenCloneForInsert.Token_Prefix__c = null;

                List<Apartment__c> listOfApt = new List<Apartment__c>();
                tokenCloneForInsert.EOI_Date__c	 = aptWrap.eoiDate ?? null;
                if(aptWrap.apartmentId != null)
                {

                    tokenCloneForInsert.Size__c = aptWrap.size;
                    tokenCloneForInsert.Base_Price__c = aptWrap.basePrice;
                    tokenCloneForInsert.PLC__c = aptWrap.plc;
                    tokenCloneForInsert.Rack_Rate__c = aptWrap.thresoldRate;
                    tokenCloneForInsert.Facing__c = aptWrap.facing;
                    tokenCloneForInsert.Inventory__c = aptWrap.apartmentId;
                    tokenCloneForInsert.Receipt_Due_Amount__c = (tokenCloneForInsert.Discount_in_Amt__c - receiptAmount) <= 0 ? 0 : (tokenCloneForInsert.Discount_in_Amt__c - receiptAmount);
                    tokenCloneForInsert.EOI_Discount_Per_Sqft__c = aptWrap.tokenDiscount ?? 0;
                    tokenCloneForInsert.Plot_Cost_With_elevated_after_discount__c = aptWrap.plotCostElevatedWithDiscount ?? 0; // Prem Discount
                    tokenCloneForInsert.Plot_Cost_With_elevated_value__c = aptWrap.PlotCostWithelevated ?? 0; // Prem Discount
                    tokenCloneForInsert.EOI_Elevated_Price__c = aptWrap.EoiIncrementValue ?? 0; // Prem Discount
                    tokenCloneForInsert.EOI_Increment__c = aptWrap.EoiTotalIncrement ?? 0; // Prem Discount
                   // tokenCloneForInsert.Computed_Amount__c = String.valueOf(aptWrap.plotCostAfterDiscount);
                    tokenCloneForInsert.Computed_Amount__c = aptWrap.plotCostAfterDiscount;
                    if(tokenCloneForInsert.Plot_Cost_With_elevated_after_discount__c > 0 && tokenCloneForInsert.Size__c > 0){
                        tokenCloneForInsert.Price_Per_sft_cent__c = (tokenCloneForInsert.Plot_Cost_With_elevated_after_discount__c)/(tokenCloneForInsert.Size__c);
                    }
                    else if (tokenCloneForInsert.Computed_Amount__c > 0 && tokenCloneForInsert.Size__c > 0){
                        tokenCloneForInsert.Price_Per_sft_cent__c = (tokenCloneForInsert.Computed_Amount__c)/(tokenCloneForInsert.Size__c);
                    }
                    tokenCloneForInsert.Total_EOI_Discount__c = (tokenCloneForInsert.EOI_Discount_Per_Sqft__c * tokenCloneForInsert.Size__c);
                    //Get Inventory record and update Unit Status
                    listOfApt = [SELECT Id, Name, Apartment_Status__c,EOI_Blocking__c,Block__c FROM Apartment__c WHERE Id =:aptWrap.apartmentId limit 1];
                    System.debug('listOfApt==>'+listOfApt);
                    listOfApt[0].Apartment_Status__c = 'Blocked';
                    listOfApt[0].EOI_Blocking__c = true;
                    tokenCloneForInsert.Tower_Block__c = listOfApt[0].Block__c;
                    tokenCloneForInsert.Receipt_Amount_Paid__c	 = aptWrap.totalReceiptAmount ?? 0.0; //total receipt amount populate on token add 27/6/24
                }
                else if(aptWrap.AreaRange != null) {
                    tokenCloneForInsert.Area_Range__c = aptWrap.AreaRange;
                    tokenCloneForInsert.EOI_Facing__c = aptWrap.EOIFacing;
                    tokenCloneForInsert.Project__c = aptWrap.TokenProjectId;
                    tokenCloneForInsert.Receipt_Due_Amount__c = (tokenCloneForInsert.Discount_in_Amt__c - receiptAmount) <= 0 ? 0 : (tokenCloneForInsert.Discount_in_Amt__c - receiptAmount);
                  // tokenCloneForInsert.Computed_Amount__c = String.valueOf(aptWrap.coumputationAmount);
                    tokenCloneForInsert.Computed_Amount__c = aptWrap.coumputationAmount;
                    tokenCloneForInsert.Plot_Dimension__c = aptWrap.plotDimension ?? 0;
                    tokenCloneForInsert.EOI_Discount_Per_Sqft__c = aptWrap.tokenDiscount ?? 0;
                    tokenCloneForInsert.Total_EOI_Discount__c =  (tokenCloneForInsert.EOI_Discount_Per_Sqft__c * tokenCloneForInsert.Plot_Dimension__c);
                    tokenCloneForInsert.Project_Plc_Amount__c = aptWrap.projectPlcAmount ?? 0.0; //project plc amount on token add 27/6/24
                    tokenCloneForInsert.Receipt_Amount_Paid__c	 = aptWrap.totalReceiptAmount ?? 0.0; //total receipt amount populate on token add 27/6/24
                }
               // oppo.Price_Per_sft_cent__c = tokenCloneForInsert.Price_Per_sft_cent__c ?? 0;
                 if(!test.isRunningTest()){
                    oppo.Price_Per_sft_cent__c = tokenCloneForInsert.Price_Per_sft_cent__c ?? 0;
                }
                insert tokenCloneForInsert;
                update tokenObj;
                OpportunityBrokerHandler.byPassFromTokenCreation = true;
                update oppo;
                OpportunityBrokerHandler.byPassFromTokenCreation = false;
                update listOfApt;
                
                if(!receiptListToInsert.isEmpty()){
                    Template_Controller.insertReceiptRecord(receiptListToInsert, mapOfAttechments);
                }
                return tokenCloneForInsert;
            }
            else
            {
                return tokenCloneForInsert;
            }
      //  }
        // catch (Exception e) 
        // {
        //     throw new AuraHandledException(e.getMessage());
        // }
    }

    @AuraEnabled(cacheable=true)
    public static List<Block__c> getBlocks(String projectId) 
    {
        return [SELECT Id, Name FROM Block__c WHERE Project__c =: projectId LIMIT 50]; // Adjust the query as needed
    }

    @AuraEnabled
    public static List<Apartment__c> getInventory(String towerId) 
    {
        return [SELECT Id, Name, Block__c, Unit_Number__c, Apartment_Status__c 
                    FROM Apartment__c 
                    WHERE Block__c =: towerId 
                    AND Apartment_Status__c != 'Blocked by Management'
                    ORDER BY Unit_Number__c ASC]; // Adjust the query as needed
    }

    /*
    *  Purpose         :   Validate the request for access token  page.
    *  Created By      :   Ajay Singh
    *  Created Date    :   6/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */   
    @AuraEnabled(cacheable = true)
    public static List<wrapperForTokenDetailsPage> validateRequest(Id oppId) 
    {      
        List<Opportunity> oppList = new List<Opportunity>();
        List<wrapperForTokenDetailsPage> oppWrapperList = new List<wrapperForTokenDetailsPage>();

        if (oppId != null) 
        {
            List<Token__c> listOftoken = [SELECT Id FROM Token__c WHERE  Opportunity__c  =: oppId AND Status__c != 'Cancelled'];

            if(listOftoken.size() > 0 )
            {
                return null;
            }
            else 
            {
                oppList = [SELECT Id, Name, LeadSource, Main_Source__c, Channel_Partner_Name__c, Secondary_Source__c,
                Referred_Opportunity__c, Referred_Employee__c, Referred_by_Management__c, Prospect__c,
                Referred_By_Customer__c,StageName, Broker__c, Broker__r.Name, 
                referred_by_Lead_prospect__c, referred_by_Lead_prospect__r.Name  FROM Opportunity WHERE Id =: oppId];
                System.debug('oppList' + oppList);
                for(Opportunity opp : oppList)
                {
                    
                    String source, subSource;
                    if(opp.Main_Source__c == 'Pre sales' || opp.Main_Source__c == 'Presales' || opp.Main_Source__c == 'Direct')
                    {
                        source = opp.LeadSource;
                        subSource = opp.Secondary_Source__c;
                    }
                    else if (opp.Main_Source__c == 'Channel Partner'  && String.isNotBlank(opp.Broker__c))
                    {
                        source = opp.Broker__r.Name;
                    }
                    else if (opp.Main_Source__c == 'Reference')
                    {
                        if(String.isNotBlank(opp.Referred_Opportunity__c))
                        {
                                source = opp.Referred_Opportunity__c;
                        }
                        else if(String.isNotBlank(opp.Referred_Employee__c))
                        {
                                source = opp.Referred_Employee__c;
                        }
                        else if(String.isNotBlank(opp.Referred_by_Management__c))
                        {
                                source = opp.Referred_by_Management__c;
                        }
                        else if(String.isNotBlank(opp.Referred_By_Customer__c))
                        {
                                source = opp.Referred_By_Customer__r.Name;
                        }
                            else if(String.isNotBlank(opp.referred_by_Lead_prospect__c))
                        {
                                source = opp.referred_by_Lead_prospect__r.Name;
                        }
                    }
                    wrapperForTokenDetailsPage wrapperObj = new wrapperForTokenDetailsPage(); 

                    if(opp.StageName != '1.Site Tour Completed'){

                        System.debug('StageName' + opp.StageName);
                        wrapperObj.isOpportunityBooked = true;
                    }

                    
                    wrapperObj.Name = opp.Name;
                    wrapperObj.id = opp.Id;
                   // wrapperObj.oppEmail = opp.Email__c;
                    //wrapperObj.OppPhone = opp.Mobile__c;
                    //wrapperObj.leadId = opp.Enquiry_Ref_No__c;
                    //wrapperObj.mainSource = opp.Main_Source__c;
                    wrapperObj.source = source;
                    wrapperObj.subSource = subSource;
                    oppWrapperList.add(wrapperObj);
                }

                return oppWrapperList;

            }
        }
        else
        {
            return null;
        }
    }

    /*
    *  Purpose         :   fetch search data.
    *  Created By      :   Ajay Singh
    *  Created Date    :   6/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */   
    @AuraEnabled(cacheable=true)
    public static list<Project__c> fetchLookupData(string searchKey , string sObjectApiName) {    
        List < Project__c > returnList = new List < Project__c > ();
        string sWildCardText = '%' + searchKey + '%';
        
        // Updated Query with additional condition
        String sQuery = 'SELECT Id, Name, With_Without_Inventory__c ' + 
                        'FROM ' + sObjectApiName + 
                        ' WHERE Name LIKE :sWildCardText AND Project_Approval_Status__c = \'YTA\' ' +
                        'ORDER BY CreatedDate DESC LIMIT 5';
        
        for (Project__c obj: database.query(sQuery)) {
            returnList.add(obj);
        }
        
        return returnList;
    }
    /*
    *  Purpose         :   Fetch token Details.
    *  Created By      :   Ajay Singh
    *  Created Date    :   17/6/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static List<Token__c> getTokensDetails(Id oppId){
        try {
            System.debug(oppId);
            if (oppId == null){
                return new List<Token__c>();

            }
            Token__c token = [Select Id, Name,Discount_in_Amt__c From Token__c Where Opportunity__c =: oppId AND Status__c != 'Cancelled' ORDER By createdDate DESC];
          
            if(token != null){
                return new List<Token__c>{token};
            }else {
                return new List<Token__c>();
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*
    *  Purpose         :   Checking no. of tokens generated
    *  Created By      :   Anshul Sharma
    *  Created Date    :   05/06/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static Boolean checkingNumTokenGenerated(Id tokenId)
    {
        try{
            List<Token__c> listOfTokens = [SELECT Id , No_of_token_to_be_generate__c FROM Token__c 
            WHERE Id =:tokenId AND Status__c != 'Cancelled'];
            Decimal size = listOfTokens[0].No_of_token_to_be_generate__c;
            List<Token__c> listofRelatedTokens = [SELECT Id , No_of_token_to_be_generate__c FROM Token__c 
            WHERE Parent_Token__c =:tokenId AND Status__c != 'Cancelled'];
            Integer sizeOfRelated = listofRelatedTokens.size();
            if(size<=sizeOfRelated)
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*
    *  Purpose         :   Checking for token upgrade or degrade on existing token
    *  Created By      :   Anshul Sharma
    *  Created Date    :   05/12/2022
    *  Revision Logs   :   V_1.0 - Created
    */
    //this method return active token
    @AuraEnabled
    public static List<Token__c> checkForTokenUpgradeDegrade(Id oppId)
    {
        System.debug('Inside check for update method');
        List<Token__c> oppExistingToken = new List<Token__c>();
        if(oppId != null)
        {
            oppExistingToken = [Select Id, Name,Token_Upgrade_and_Degrade__c,Discount_in_Amt__c From Token__c Where Opportunity__c =:oppId order by LastModifiedDate DESC limit 1];
            System.debug('oppExistingToken'+oppExistingToken);
        }
        if(oppExistingToken.size() > 0)
        {
            System.debug('Inside size greater'+oppExistingToken);
            return oppExistingToken;
        }
        else
        {
            System.debug('Inside null');
            return null;
        }
    }

    /*
    *  Purpose         :   Get Project Related Towers/Block.
    *  Created By      :   Prem Chand
    *  Created Date    :   23/04/2023
    *  Revision Logs   :   V_1.0 - Created
    */ 
    @AuraEnabled
    public static List<Project__c> getProjectAreaRange(Id projId){

        List<Project__c> listOfProjects = new List<Project__c>();
        listOfProjects = [SELECT Id, Area_Range__c, Token_Rack_Rate__c, Project_Facing__c,Rack_Rate_Project_Level__c
                        FROM Project__c 
                        WHERE Id =:projId AND Area_Range__c != null];

        System.debug('lisOfBlocks==> '+listOfProjects);
        return listOfProjects;

    }
     /*
    *  Purpose         :   Project wise Configuration With Or Without Inventory.
    *  Created By      :   Prem Chand
    *  Created Date    :   24/04/2024
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static List<Project__c> ProjectWithInventoryOrWithout(Id Id){
        
        List<Project__c> listOfProjects = new List<Project__c>();
        listOfProjects = [SELECT Id, With_Without_Inventory__c, Area_Range__c,Increment_Type__c
                            FROM Project__c 
                            WHERE Id =:Id AND With_Without_Inventory__c != Null];

        return listOfProjects;
    }
    
    /*
    *  Purpose         :   Get Inventory velues
    *  Created By      :   Prem Chand
    *  Created Date    :   25/04/2024
    *  Revision Logs   :   V_1.0 - Created
    */
    @AuraEnabled
    public static List<Apartment__c> getInventoryValues(Id apartment){
        
        List<Apartment__c> listOfApartments = new List<Apartment__c>();
        listOfApartments = [SELECT Id, Built_Up_Area__c, Facing__c, Apartment_rate__c, Premium_Charges__c, Premium_Rate2__c,Elevated_Value__c,
                                Premium_Rate3__c, Premium_Rate4__c, Premium_Rate5__c, Threshold_Rate__c,  Apartment_Cost__c,Rack_Rate__c,Elevated_Price_per_sft__c
                                FROM Apartment__c 
                                WHERE Id =:apartment];
        if(!listOfApartments.isEmpty())
        {
            for(Apartment__c thisApt : listOfApartments)
            { 
                if(thisApt.Premium_Charges__c == null)
                {
                    thisApt.Premium_Charges__c = 0;
                }
                thisApt.Premium_Rate2__c = thisApt.Premium_Rate2__c ?? 0;
                thisApt.Premium_Rate3__c = thisApt.Premium_Rate3__c ?? 0;
                thisApt.Premium_Rate4__c = thisApt.Premium_Rate4__c ?? 0;
                thisApt.Premium_Rate5__c = thisApt.Premium_Rate5__c ?? 0;
            }
        }
       
        return listOfApartments;
    }

    @AuraEnabled
    public static Double getPlcAmount(String facing, Id projectId){
        
        Double plcAmt = 0.0;
        List<Project__c> listOfProjects = [SELECT Id,PLC_Facing_1__c,PLC_Facing_2__c,PLC_Facing_3__c,PLC_Facing_4__c,PLC_Facing_5__c,
                            PLC_Facing_6__c,PLC_Facing_7__c,PLC_Facing_8__c,PLC_Facing_9__c,PLC_Facing_1_Amount__c,
                            PLC_Facing_2_Amount__c,PLC_Facing_3_Amount__c,PLC_Facing_4_Amount__c,PLC_Facing_5_Amount__c,
                            PLC_Facing_6_Amount__c,PLC_Facing_7_Amount__c,PLC_Facing_8_Amount__c,PLC_Facing_9_Amount__c 
                        FROM Project__c WHERE Id =:projectId limit 1];
        
        if(!listOfProjects.isEmpty()){
            
            for(Project__c thisProject : listOfProjects){
                
                if(thisProject.PLC_Facing_1__c == facing){

                    plcAmt = thisProject.PLC_Facing_1_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_2__c == facing){ 
                    plcAmt = thisProject.PLC_Facing_2_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_3__c == facing){ 
                   plcAmt = thisProject.PLC_Facing_3_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_4__c == facing){ 
                   plcAmt = thisProject.PLC_Facing_4_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_5__c == facing){ 
                   plcAmt = thisProject.PLC_Facing_5_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_6__c == facing){ 
                    plcAmt = thisProject.PLC_Facing_6_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_7__c == facing){ 
                    plcAmt = thisProject.PLC_Facing_7_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_8__c == facing){ 
                    plcAmt = thisProject.PLC_Facing_8_Amount__c  ?? 0.0;
                }
                else if(thisProject.PLC_Facing_9__c == facing){ 
                    plcAmt = thisProject.PLC_Facing_9_Amount__c  ?? 0.0;
                }
            }
            System.debug('pcc plc==>'+plcAmt);
            return plcAmt;
        }
        else{
            System.debug('pcc plc==>'+plcAmt);
            return plcAmt;
        }
        
    }

    public class wrapperForTokenDetailsPage {
        
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String source {get;set;}
        @AuraEnabled public String subSource {get;set;}
        @AuraEnabled public Boolean isOpportunityBooked {get;set;}
        
        public wrapperForTokenDetailsPage() {
            
            this.Name ='';
            this.id ='';
            this.source = '';
            this.subSource = '';
            this.isOpportunityBooked = false;
        }
    }
    
    public class wrapperForinventoryData{

        @AuraEnabled public Id apartmentId{get;set;}
        @AuraEnabled public Decimal size{get;set;}
        @AuraEnabled public String facing{get;set;}
        @AuraEnabled public Decimal basePrice{get;set;}
        @AuraEnabled public Decimal plc{get;set;}
        @AuraEnabled public Decimal thresoldRate{get;set;}
        @AuraEnabled public String AreaRange{get;set;}
        @AuraEnabled public String EOIFacing{get;set;}
        @AuraEnabled public Id TokenProjectId{get;set;}
        @AuraEnabled public Decimal coumputationAmount{get;set;}
        @AuraEnabled public Decimal plotDimension{get;set;}
        @AuraEnabled public Decimal tokenDiscount{get;set;}
        @AuraEnabled public Decimal tokenToalDiscountDiscount{get;set;}
        @AuraEnabled public Decimal plotCostAfterDiscount{get;set;}
        @AuraEnabled public Decimal projectPlcAmount{get;set;}//add 27/06/24
        @AuraEnabled public Decimal totalReceiptAmount{get;set;}//add 27/06/24
        @AuraEnabled public Decimal plotCostElevatedWithDiscount{get;set;}// Prem Discount
        @AuraEnabled public Decimal PlotCostWithelevated {get;set;}// Prem Discount
        @AuraEnabled public Decimal EoiIncrementValue {get;set;}// Prem Discount
        @AuraEnabled public Decimal EoiTotalIncrement {get;set;}// Prem Discount
        @AuraEnabled public Date eoiDate{get;set;}
    }
}