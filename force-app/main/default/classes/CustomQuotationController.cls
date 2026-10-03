/**
 * 
 *  Purpose         :   this class use for in custom quotation 
 *
 *  Revision Logs   :   V_1.0 - Created - By Noorulain Ashrafi
 *						
 * 
**/
public class CustomQuotationController
{
     /**
    *  @description    :  This method is used find all projects
    *  @args           :   
    *  @return         :   List ofObject Wrapper
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   21/06/2021
    **/
	@AuraEnabled
    public static List<objectWrapper> getProjects(String projectId, String recId, String objName){

        List<objectWrapper> projectList = new List<objectWrapper>();
        List<Project__c>listOfpro=  new List<Project__c>();
        List<String> aptStatusToCheck = new List<String>();

        System.debug('projectIdnnnnn = '+projectId);
        System.debug('objName = '+objName);
        if(String.isNotBlank(projectId))
        {
            listOfpro = [Select Id, Name, Allow_To_Create_Quote_Summary__c, Generate_quotation_for_units__c from Project__c Where Id =:projectId];
        }else{
            system.debug('recId---'+recId);
            if(String.isNotBlank(recId) && recId.startsWith('006')){
                Opportunity opp = [Select Id, Name, StageName,Probability from Opportunity WHERE Id =:recId];
                system.debug('opp----'+opp);
                if(opp.Probability >= 70){
                   throw new AuraHandledException('You do not have permission to create a new Quotation on this Opportunity');
                }
            }
            listOfpro = [Select Id, Name, Allow_To_Create_Quote_Summary__c, Generate_quotation_for_units__c from Project__c WHERE Project_Approval_Status__c = 'Approved' order by lastmodifiedDate asc Limit 1000];
        }

        if(listOfpro.size() > 0)
        {
            if(String.isNotBlank(listOfpro[0].Generate_quotation_for_units__c)){
                aptStatusToCheck.addAll(listOfpro[0].Generate_quotation_for_units__c.split(';'));
            }
        
            system.debug('IN---'+recId);
            if(String.isNotBlank(objName) && objName == 'Apartment__c' && aptStatusToCheck.size() > 0)
            {
                system.debug('recId---'+recId);
                system.debug('aptStatusToCheck---'+aptStatusToCheck);

                List<Apartment__c> aptObj = [Select Id from Apartment__c WHERE Id =:recId AND Apartment_Status__c =:aptStatusToCheck AND Project_ID__c =:listOfpro[0].Id];
                system.debug('aptObj----'+aptObj);

                if(aptObj.Size() == 0 ){
                throw new AuraHandledException('You do not have permission to create a new Quotation on this Unit');
                }
            }
        }
        System.debug('listOfpronnnnn = '+listOfpro);
        for(Project__c proj :listOfpro){
            objectWrapper obj = new objectWrapper();
            obj.label = proj.Name;
            obj.value = proj.Id;
            obj.sObjectName = 'Project__c';
            obj.quoteSummaryAllowed = proj.Allow_To_Create_Quote_Summary__c;
            projectList.add(obj);
        }
        return projectList;
    }
    
     /**
    *  @description    :  This method is used find block
    *  @args           :   
    *  @return         :   List ofObject Wrapper
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   21/06/2021
    **/
    @AuraEnabled
    public static List<objectWrapper> getBlocks(Id projectId,String blockRecId){

        List<objectWrapper> blockList = new List<objectWrapper>();
        List<Block__c> listOfBlock = new List<Block__c>();

        if(String.isNotBlank(blockRecId))
        {
            listOfBlock = [Select Id, Name from Block__c Where Id =:blockRecId];
        }else{
            listOfBlock = [Select Id, Name from Block__c Where Project__c =:projectId order by lastmodifiedDate asc Limit 1000];
        }

        for(Block__c block : listOfBlock){
            objectWrapper obj = new objectWrapper();
            obj.label = block.Name;
            obj.value = block.Id;
            obj.sObjectName = 'Block__c';
            blockList.add(obj);
        }

        return blockList;
    }
    /**
    *  @description    :  This method is used find all apartment
    *  @args           :   
    *  @return         :   List ofObject Wrapper
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   21/06/2021
    **/
    @AuraEnabled
    public static List<objectWrapper> getAvailableApartments(Id blockId,String apartmentId){

        List<objectWrapper> apartmentList = new List<objectWrapper>();
        List<Apartment__c> listOfApartment = new List<Apartment__c>();
		system.debug('blockId---'+blockId);
        if(String.isNotBlank(apartmentId))
        {
            listOfApartment = [Select Id, Name,Apartment_Status__c,Project_ID__c,Block__c from Apartment__c Where Id =:apartmentId];
        }else{
            listOfApartment = [Select Id, Name,Apartment_Status__c,Project_ID__c,Block__c from Apartment__c Where Block__c =:blockId order by lastmodifiedDate asc Limit 2000];
        }

        for(Apartment__c apart : listOfApartment){
            objectWrapper obj = new objectWrapper();
            obj.label = apart.Name;
            obj.value = apart.Id;
            obj.unit = apart;
            obj.sObjectName = 'Apartment__c';
            apartmentList.add(obj);
        }
        system.debug('apartmentList==='+apartmentList);
        return apartmentList;
    }

    /**
    *  @description    :  This method is used for get quote summary table data
    *  @args           :   
    *  @return         :   List ofObject Wrapper
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   21/06/2021
    **/
    @AuraEnabled
    public static List<searchUnitWrapper> getQuoteSummaryData(String searchString,String statusFilter, Id projectId, Id blockId,String apartmnetRecId )
    {

        List<searchUnitWrapper> listOfsearchUnitWrapper = new List<searchUnitWrapper>();

        List<String> apertmentStatusFilterList = new List<String>();

        //List<QuoteSummaryWrapper> listOfWrapperData = new List<QuoteSummaryWrapper>();
        String query ='';
        List<Apartment__c> listOfApartment = new List<Apartment__c>();
        
        // query on custom metadata type record for summary quote
        Custom_Quotation_Field_Details__mdt summaryQuoteMdtRec = [Select Object_Name__c,Type__c,Field_List__c From Custom_Quotation_Field_Details__mdt Where Type__c = 'Summary Quote' AND Object_Name__c ='Apartment__c' LIMIT 1];

        // query on custom metadata type record for summary quote
        Custom_Quotation_Field_Details__mdt queryFilterMdtRec = [Select Object_Name__c,Type__c,Field_List__c From Custom_Quotation_Field_Details__mdt Where Type__c = 'Query Filter' AND Object_Name__c ='Apartment__c' LIMIT 1];
        
        Project__c proj = getProjectRec(projectId);
        
        // call the method for creating dynamic query string
        query = getDynamicQuery(queryFilterMdtRec,summaryQuoteMdtRec,searchString);
        
        if(query !='')
        {
            query += /*( Project_ID__c = ' +'\'' + projectId + '\'' +' OR Project_ID__c ='+'\''+String.valueOf(projectId).substring(0,15)+'\''+ ') AND*/' Block__c = '+'\'' + blockId + '\'';

            if(String.isNotBlank(apartmnetRecId))
            {
                query +=' AND Id = '+'\'' + apartmnetRecId + '\' ';
            }
            if(String.isNotBlank(statusFilter))
            {
                query +=' AND Apartment_Status__c = '+'\'' + statusFilter + '\'';

            }/*else{
                if(proj.Generate_quotation_for_units__c !=null && proj.Generate_quotation_for_units__c !='')
                {
                    for(String str : proj.Generate_quotation_for_units__c.split(';'))
                    {
                        String formattedString = '\''+str +'\'';
                        apertmentStatusFilterList.add(formattedString);
                    }
                }

                if(apertmentStatusFilterList.size()>0)
                {
                    query += ' AND Apartment_Status__c IN '+ apertmentStatusFilterList;
                }
            }*/

            system.debug('query--'+query);
            listOfApartment = Database.query(query);
            
            Set<Id> setOfUnitIds = new Set<Id>();
            Map<Id,Opportunity> mapOfOppIdWithApt = new Map<Id,Opportunity>();

            for(Apartment__c apt : listOfApartment)
            {
                //searchUnitWrapper obj = new searchUnitWrapper();

                //obj.apartmentRec = apt;
                //obj.oppId ='';
                if(apt.Apartment_Status__c =='Booked')
                {
                    setOfUnitIds.add(apt.Id);
                    //mapOfOppIdWithApt.put(apt.Id,  new Opportunity());
                }

                //listOfsearchUnitWrapper.add(obj);
            }

            // getting opportunity which booked apartment
            System.debug('ppp@@ '+setOfUnitIds);
            if(setOfUnitIds.size()>0)
            {
                for(Opportunity opp : [Select Id,Name,Apartment__c From Opportunity Where Apartment__c IN :setOfUnitIds])
                {
                    
                    mapOfOppIdWithApt.put(opp.Apartment__c, opp);

                }
            }
            System.debug('kkkk@@'+mapOfOppIdWithApt);
            // fill wrapper
            for(Apartment__c apt : listOfApartment)
            {
                searchUnitWrapper obj = new searchUnitWrapper();

                obj.apartmentRec = apt;
                obj.FloorNo = apt.Floor_No__c;
                
                if(mapOfOppIdWithApt.size()>0 && mapOfOppIdWithApt.containsKey(apt.Id) && apt.Apartment_Status__c =='Booked')
                {
                    obj.oppId = mapOfOppIdWithApt.get(apt.Id).Id;
                    
                }

                listOfsearchUnitWrapper.add(obj);
            }

        }

        //return listOfApartment;
        return listOfsearchUnitWrapper;
    }

    /**
    *  @description    :  This method is used for making dynamic query string
    *  @args           :   
    *  @return         :   String query
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   22/06/2021
    **/
    public static String getDynamicQuery(Custom_Quotation_Field_Details__mdt queryFilterMdtRec, Custom_Quotation_Field_Details__mdt summaryQuoteMdtRec, String searchString)
    {
        List<String> searchingFieldsList = new List<String>();
        String query ='';

        if(queryFilterMdtRec!=null && queryFilterMdtRec.Field_List__c !=null && queryFilterMdtRec.Field_List__c !='')
        {
            searchingFieldsList.addAll(queryFilterMdtRec.Field_List__c.split(','));
        }

        //if(String.isNotBlank(searchString) && searchingFieldsList.size() >0)
        //{
            query = 'Select Id,Name,ComponentMaster__c,Undivided_Land_Area__c,Apartment_Finish__c,FOM_Bare_Shell__c,Template_Master__c,Area_in_Sq_Mts__c,Threshold_Rate__c,Standard_Booking_Amount__c,Apartment_Cost__c,Take_Rate_from_Rate_Master__c,Apartment_Status__c,Block__r.Name,Built_Up_Area__c,Project_ID__c,Apartment_Sub_type__c,Block__c,Tower__c,Floor_No__c,Facing__c,Carpet_Area__c,Super_Builtup_Area_in_Sft_Q__c,Apartment_rate__c, Apartment_Type__c,Unit_Type__c,Unit_Number__c, Premium_Charges__c,Apartment_Rate_Formula__c,Allow_Standard_Plan_Editing__c, Elevated_Price_per_sft__c,Rack_Rate__c ';
            
            /*if(summaryQuoteMdtRec !=null && summaryQuoteMdtRec.Field_List__c !=null && summaryQuoteMdtRec.Field_List__c!='')
            {
                query+= summaryQuoteMdtRec.Field_List__c;
            }else{
                query+= 'Id,Name,Project_ID__c ';
            }*/
            query+= ' From '+ summaryQuoteMdtRec.Object_Name__c ;

            if(String.isNotBlank(searchString) && searchingFieldsList.size() >0)
            {
                query +=' Where ( ';
                for(String fieldApiName : searchingFieldsList)
                {
                    query += fieldApiName +' LIKE '+ '\'%' + searchString + '%\'' +'  OR ';
                }
                query = query.removeEnd('OR ');
                query += ' ) AND';
            }
            else
            {
                query += ' Where ';
            }
                
        return query;
    }

    
    /**
    *  @description    :  This method is used for get Opportunity Lead page 6  table data
    *  @args           :   
    *  @return         :   List of wrapper
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   23/06/2021
    **/
    @AuraEnabled
    public static List<Opportunity> getOppForComparativeQuote(String searchString, String oppRecId , List<String> setOfOppIds, Id projectId)
    {    
        List<Opportunity> listOfOpp = new List<Opportunity>();
        String OpportunityQueryStr ='';
        List<String> opportunityStageFilterList = new List<String>();

        Project__c proj = getProjectRec(projectId);

        if(proj.Opportunity_Stage_to_share_Quote__c !=null && proj.Opportunity_Stage_to_share_Quote__c !='')
        {
            for(String str : proj.Opportunity_Stage_to_share_Quote__c.split(';'))
            {
                String formattedString = '\''+str +'\'';
                opportunityStageFilterList.add(formattedString);
            }
        }

        System.debug('setOfOppIds ==== '+ setOfOppIds);
        System.debug('opportunityStageFilterList ==== '+ opportunityStageFilterList);
        System.debug('proj.Opportunity_Stage_to_share_Quote__c ==== '+ proj.Opportunity_Stage_to_share_Quote__c);

        // query on custom metadata type record for summary quote
        Custom_Quotation_Field_Details__mdt summaryQuoteMdtRec = [Select Object_Name__c,Type__c,Field_List__c From 
            Custom_Quotation_Field_Details__mdt Where Type__c = 'Summary Quote' AND Object_Name__c ='Opportunity' LIMIT 1];
        
        OpportunityQueryStr = 'SELECT '+ summaryQuoteMdtRec.Field_List__c + ' From ' + summaryQuoteMdtRec.Object_Name__c;

        if(String.isNotBlank(searchString))
        {    
            OpportunityQueryStr += ' Where (( Name LIKE \'%'+searchstring+'%\') ';
        }
        else if(String.isNotBlank(oppRecId) && oppRecId.startsWith('006') && setOfOppIds.isEmpty())
        {
            OpportunityQueryStr += ' Where (Id ='+'\'' + oppRecId + '\'';
        }
        if(opportunityStageFilterList.size()>0)
        {
            OpportunityQueryStr += ' AND StageName IN '+opportunityStageFilterList +')';
        }
        if(opportunityStageFilterList.size() == 0 || opportunityStageFilterList.isEmpty())
        {
            OpportunityQueryStr += ')';
        }
        if(setOfOppIds !=null && setOfOppIds.size()>0)
        {
            OpportunityQueryStr += ' OR Id IN'+setOfOppIds;
        }
        
        System.debug('OpportunityQueryStr = '+ OpportunityQueryStr);

        //system.assert(false,OpportunityQueryStr);
        if(OpportunityQueryStr !='')
        {
            for(Opportunity opp : Database.query(OpportunityQueryStr))
            {
                listOfOpp.add(opp);
            }
        }
        return listOfOpp;
    }

    /**
    *  @description    :  This method is used for get Opportunity Lead page 6 table data
    *  @args           :   
    *  @return         :   List of wrapper
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   23/06/2021
    **/

    @AuraEnabled
    public static List<OppLeadTableWrapper> getOppLeadTableData(String searchString, String projectId, String oppRecId, List<String> setOfOppIds, List<String> setOfLeadIds)
    {
        List<String> leadStatusFilterList = new List<String>();
        List<String> opportunityStageFilterList = new List<String>();
        String leadQueryStr = '';
        String OpportunityQueryStr ='';

        system.debug('leadStatusFilterList = '+ leadStatusFilterList);
        system.debug('setOfOppIds = '+ setOfOppIds);
        system.debug('oppRecId = '+ oppRecId);
        system.debug('searchString = '+ searchString);


        Project__c proj = getProjectRec(projectId);

        if(proj.Lead_stage_to_share_Quote__c !=null && proj.Lead_stage_to_share_Quote__c !='')
        {
            for(String str : proj.Lead_stage_to_share_Quote__c.split(';'))
            {
                if(str == 'Site Tour Completed'){
                    str = 'Site Visit Happened';
                }
                String formattedString = '\''+str +'\'';
                leadStatusFilterList.add(formattedString);
            }
        }

        if(proj.Opportunity_Stage_to_share_Quote__c !=null && proj.Opportunity_Stage_to_share_Quote__c !='')
        {
            for(String str : proj.Opportunity_Stage_to_share_Quote__c.split(';'))
            {
                String formattedString = '\''+str +'\'';
                opportunityStageFilterList.add(formattedString);
            }
        }

        
        // query on custom metadata type record for summary quote
        Custom_Quotation_Field_Details__mdt summaryQuoteMdtRec = [Select Object_Name__c,Type__c,Field_List__c From 
            Custom_Quotation_Field_Details__mdt Where Type__c = 'Comparative Quote' AND Object_Name__c ='Lead' LIMIT 1];

        // query on custom metadata type record for summary quote
        Custom_Quotation_Field_Details__mdt summaryQuoteMdtRec1 = [Select Object_Name__c,Type__c,Field_List__c From 
            Custom_Quotation_Field_Details__mdt Where Type__c = 'Summary Quote' AND Object_Name__c ='Opportunity' LIMIT 1];
        
        OpportunityQueryStr = 'SELECT '+ summaryQuoteMdtRec1.Field_List__c + ' From ' + summaryQuoteMdtRec1.Object_Name__c;

        List<OppLeadTableWrapper> listOfOppLeadWrapperData = new List<OppLeadTableWrapper>();

        leadQueryStr = 'SELECT '+ summaryQuoteMdtRec.Field_List__c + ' From ' + summaryQuoteMdtRec.Object_Name__c;

        if(String.isNotBlank(searchString) || (String.isNotBlank(oppRecId) && oppRecId.startsWith('00Q')))
        {
            if(String.isNotBlank(searchString))
            {
                leadQueryStr += ' Where ( Name LIKE \'%'+searchstring+'%\') ';

                if(leadStatusFilterList.size() > 0)
                {
                    leadQueryStr += ' AND Status IN '+leadStatusFilterList ;
                }
            }
            else if(String.isNotBlank(oppRecId) && oppRecId.startsWith('00Q') && setOfOppIds.isEmpty())
            {
                leadQueryStr += ' Where (Id ='+'\'' + oppRecId + '\'';
                
                if(leadStatusFilterList.size() > 0)
                {
                    leadQueryStr += ' AND Status IN '+leadStatusFilterList +')';
                }
            }

        }

        // if(setOfLeadIds !=null && setOfLeadIds.size()>0)
        // {
        //     leadQueryStr += ' AND Id IN '+setOfLeadIds;
        // }
        if(String.isNotBlank(searchString))
        {
            OpportunityQueryStr += ' Where (( Name LIKE \'%'+searchstring+'%\') ';
        }
        else if(String.isNotBlank(oppRecId) && oppRecId.startsWith('006') && setOfOppIds.isEmpty())
        {
            OpportunityQueryStr += ' Where (Id ='+'\'' + oppRecId + '\'';
        }
        if(opportunityStageFilterList.size()>0)
        {
            if(String.isNotBlank(searchString) || (String.isNotBlank(oppRecId) && oppRecId.startsWith('006') && setOfOppIds.isEmpty()))
            {
                OpportunityQueryStr += ' AND StageName IN '+opportunityStageFilterList +')';
            }
            else 
            {
                OpportunityQueryStr += ' Where StageName IN '+opportunityStageFilterList ;
            }
        }
        if(setOfOppIds !=null && setOfOppIds.size()>0)
        {
            OpportunityQueryStr += ' OR Id IN '+setOfOppIds ;   
        }
        
        leadQueryStr +=  ' LIMIT 10';
        OpportunityQueryStr +=  ' LIMIT 10';
        
        System.debug('OpportunityQueryStr ==== '+ OpportunityQueryStr);
        System.debug('leadQueryStr ===== '+ leadQueryStr);
        //system.assert(false,OpportunityQueryStr);
        if(String.isNotBlank(searchString) || (String.isNotBlank(oppRecId) && oppRecId.startsWith('00Q'))){
            if(String.isNotBlank(leadQueryStr))
            {
                for(Lead ld : Database.query(leadQueryStr))
                {
                    OppLeadTableWrapper obj = new OppLeadTableWrapper();
                    obj.id = ld.Id;
                    obj.name = ld.Name;
                    obj.status = ld.Status;
                    obj.email = ld.Email;
                    obj.mobile = ld.MobilePhone;
                    obj.type = 'Lead';
                    obj.commnet = '';

                    listOfOppLeadWrapperData.add(obj);
                }
            }
        }

        if(String.isNotBlank(searchString) || (String.isNotBlank(oppRecId) && oppRecId.startsWith('006')))
        {
            for(Opportunity opp : Database.query(OpportunityQueryStr))
            {
                OppLeadTableWrapper obj2 = new OppLeadTableWrapper();
                obj2.id = opp.Id;
                obj2.name = opp.Name;
                obj2.status = opp.StageName;
                obj2.stage = opp.StageName;
                obj2.email = opp.Email__c;
                obj2.mobile = opp.Mobile__c;
                obj2.type = 'Opportunity';
                obj2.commnet = opp.Remarks__c;

                listOfOppLeadWrapperData.add(obj2);
            }
        }
        return listOfOppLeadWrapperData;
        
    }

    /**
    *  @description    :  This method is used for get project record
    *  @args           :   
    *  @return         :   project instance
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   23/06/2021
    **/
    @AuraEnabled
    public static Project__c getProjectRec(String projectId)
    {
        Project__c proj = new Project__c();

        if(String.isNotBlank(projectId))
        {
            proj = [Select Id, Name, Lead_stage_to_share_Quote__c, Sub_comp_to_reduce_total_discount__c, 
                    Overdue_Available__c, Taxes_Required_Not_Required_for_quotatio__c, Quotation_Approval__c, 
                    Allow_Threshold_Rate__c, Show_Discount_on_Quotation__c, Component_Wise_Discount__c, Allow_User_To_Select_Sub_Comp__c,
                    Calculate_Threshold_By_SQFT__c,Allow_value_below_threshold__c, Discount_Threshold__c,Discount_Type__c,For_Manual_PPS__c,
                    Generate_Quotation__c,Grace_Period__c, Generate_quotation_for_units__c, Opportunity_Stage_to_share_Quote__c, 
                    SubComp_to_include_in_Threshold__c, Allow_Std_Amt_for_manual_PPS__c, Show_monthly_pps__c,
                    Allow_Component_Percentage_Editing__c, Allow_Standard_Plan_Editing__c,Increment_Type__c
                    From Project__c Where Id = :projectId ];
        }
        return proj;

    }

    @AuraEnabled
    public static String getBaseUrl () 
    {
            return system.URL.getSalesforceBaseUrl().toExternalForm();
    }

    /**
    *  @description    :  This method is used for create quote summary
    *  @args           :   
    *  @return         :   
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   24/06/2021
    **/
    @AuraEnabled
    public static void createQuoteSummary(List<Lead> leadList, String oppId, List<Apartment__c> apartmentList, String leadOppData)
    {
        List<OppLeadTableWrapper> leadOppWrapperData  =  (List<OppLeadTableWrapper>)JSON.deserialize(leadOppData, List<OppLeadTableWrapper>.class);
       
        // get project 
        set<String> aptIds = new Set<String>();
        set<String> leadIds = new Set<String>();
        set<String> oppIds = new Set<String>();
        for(Apartment__c apt: apartmentList){
            aptIds.add(apt.Id);
        }

        List<Shared_Quote__c> sharedQuotList = new List<Shared_Quote__c>();
        sharedQuotList.addAll(createSharedQuoteRecAndActivity(leadOppWrapperData,apartmentList));

        Set<Id> setOfSharedQIds = new Set<Id>();
        for(Shared_Quote__c shQ : sharedQuotList)
        {
            setOfSharedQIds.add(shQ.Id);
        }

        if(sharedQuotList.size()>0)
        {
            shared_Quote__c sQ  = sharedQuotList[0];
        
            PageReference pageObj = page.GenerateQuoteSummary;
            pageObj.getParameters().put('aptIds',JSON.serialize(aptIds));

            if(String.isNotBlank(sQ.Lead__c)){
                pageObj.getParameters().put('leadIds',JSON.serialize(sQ.Lead__c));
            }
            if(String.isNotBlank(sQ.Opportunity__c)){
                pageObj.getParameters().put('oppIds',JSON.serialize(sQ.Opportunity__c));
            }
            Blob body;
            if(Test.isRunningTest()) 
            { 
                body = blob.valueOf('Unit.Test');
            }else{
                
                body = pageObj.getContent();
            }                
            attachPDF(leadOppWrapperData,body,sharedQuotList);
        }

        // send email alert to customer
        sendEmailToCustomer(leadOppWrapperData,apartmentList,setOfSharedQIds); 
    }

    public static void sendEmailToCustomer(List<OppLeadTableWrapper> wrapperData, List<Apartment__c> apartmentList, Set<Id> setOfSharedQIds)
    {
        System.debug('qq@@@@@@@ = '+ wrapperData);
        System.debug('qq@@@@@@@ = '+ apartmentList);

        Map<Id,Attachment> mapOfAttachmentWithParentId = new Map<Id,Attachment>();
        Set<Id> setOfLeadOppIds = new Set<Id>();
        Map<Id,Shared_Quote__c> mapOfOppIdWithShareQ = new Map<Id,Shared_Quote__c>();

        List<String> listOfToAddress = new List<String>();

        if(setOfSharedQIds.size()>0)
        {
            System.debug('qq@@@@@@@ = '+ setOfSharedQIds);

            for(Attachment att : [Select Id,parentId,Name,body From Attachment Where parentId IN :setOfSharedQIds])
            {
                mapOfAttachmentWithParentId.put(att.parentId,att);
            }

            for(Shared_Quote__c shQ : [Select Id,name ,Opportunity__r.name,Opportunity__r.email__c,Lead__r.Name,Lead__r.email from Shared_Quote__c where Id IN : setOfSharedQIds])
            {
                if(shQ.Opportunity__c !=null)
                {
                    mapOfOppIdWithShareQ.put(shQ.Opportunity__c,shQ);
                }else if(shQ.Lead__c !=null)
                {
                    mapOfOppIdWithShareQ.put(shQ.Lead__c,shQ);
                }
                
            }
            
        }

        if(mapOfAttachmentWithParentId.size()>0)
        {
            System.debug('qq@@@@@@@ = '+ mapOfAttachmentWithParentId);
            List<messaging.Email> emails = new List<messaging.Email>();

            for(OppLeadTableWrapper wr : wrapperData)
            {
                if (wr.email !=null && wr.email !='')
                {
                    System.debug('qq@@@@@@@11111 = ');
                    listOfToAddress.add(wr.email);
                    messaging.SingleEmailMessage singleEmail = new messaging.SingleEmailMessage();
                    singleEmail.setToAddresses(listOfToAddress);
       
                    singleEmail.setSubject('Svasa Homes, Price Offer '+date.today().format());
                    String name = '';

                    System.debug('NAME -> '+(mapOfAttachmentWithParentId.get(mapOfOppIdWithShareQ.get(wr.id).Id).Name));
                    if(mapOfAttachmentWithParentId.get(mapOfOppIdWithShareQ.get(wr.id).Id).Name.contains('.'))
                    {
                        name = (mapOfAttachmentWithParentId.get(mapOfOppIdWithShareQ.get(wr.id).Id).Name).substringBefore('.');
                    }
                    

                    String htmlBody = 'Dear '+  name + ','+
                    '<p>Greetings from Svasa Homes!</p>'+

                    'Your journey with us so far has been deeply fulfilling and enriching. We hope and wish that the feeling is mutual!</p>'+

                    '<p>I take pleasure in taking our conversation forward and sharing the quotation of your preferred units as requested.</p> '+
                    
                    '<p>We look forward to seeing you join the impact-making community at Svasa Homes and take joy in welcoming you home to experience a completely unique and holistic way of living.</p>'+
                    
                    '<p>Please feel free to get back for clarifications. Will be happy to be of further assistance.</p>'+
                    
                    '<p>Warm Regards</p>';

                    singleEmail.setHtmlBody(htmlBody);
                    singleEmail.setSaveAsActivity(true);

                    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                    attach.Body = mapOfAttachmentWithParentId.get(mapOfOppIdWithShareQ.get(wr.id).Id).body;
                    attach.setContentType('application/pdf');
                    attach.setFileName(mapOfAttachmentWithParentId.get(mapOfOppIdWithShareQ.get(wr.id).Id).Name);
                    singleEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {attach} );

                    //system.assert(false,singleEmail);
                    System.debug('qq@@@@@@@33333 = '+singleEmail);
                    emails.add(singleEmail);

                    // reinitialize to address list
                    listOfToAddress = new List<String>();
                }
            }
            try
            {
                System.debug('qq@@@@@@@444444 = '+emails);
                //EmailStop
                //messaging.sendEmail(emails);
            }catch(Exception e)
            {     
                system.assert(false,e.getMessage());
            }
        }

    }
    public static List<Shared_Quote__c> createSharedQuoteRecAndActivity(List<OppLeadTableWrapper> wrapperData, List<Apartment__c> apartmentList)
    {
        List<Shared_Quote__c> listOfSharedQuote = new List<Shared_Quote__c>();
        List<Task> listOfTask = new List<Task>();
        Map<Id,Task> mapOfIdWithTask = new Map<Id,Task>();

        for(Apartment__c apt : apartmentList)
        {
            for(OppLeadTableWrapper wr : wrapperData)
            {
                
                Shared_Quote__c sharedQuote = new Shared_Quote__c();
                sharedQuote.Type__c = 'Summary';
                //sharedQuote.Name = wr.name;
                sharedQuote.Inventory__c = apt.Id;
                sharedQuote.Shared_with_Customer__c = true;

                // create task
                Task tsk = new Task();
                tsk.Subject = 'Shared Quote';
                //This is the default...
                tsk.OwnerId = UserInfo.getUserId();
                tsk.Status = 'Completed';
                tsk.Type = 'Email';
                tsk.Description = 'Shared Quote';
                tsk.ActivityDate = system.today();
                
                if(wr.type =='Opportunity')
                {
                    sharedQuote.Opportunity__c= wr.id;
                    tsk.WhatId  =wr.Id;
                }
                if(wr.type =='Lead')
                {
                    sharedQuote.Lead__c = wr.id;
                    tsk.WhoId =wr.Id;
                }
                if(!mapOfIdWithTask.containsKey(wr.Id))
                {
                    mapOfIdWithTask.put(wr.Id,tsk);
                }
                listOfSharedQuote.add(sharedQuote);     
            }
        }
        List<Shared_Quote__c> listOfSharedQuoteToInsert = new List<Shared_Quote__c>();
        try
        {
            if(mapOfIdWithTask.values().size() > 0)
            {
                insert mapOfIdWithTask.values();
            }
           

            for(Shared_Quote__c sq: listOfSharedQuote)
            {
                if(sq.Opportunity__c != null)
                    sq.Task_Id__c = String.valueOf(mapOfIdWithTask.get(sq.Opportunity__c).Id);
                else if(sq.Lead__c != null ){
                    sq.Task_Id__c =  String.valueOf(mapOfIdWithTask.get(sq.Lead__c).Id);
                }
                listOfSharedQuoteToInsert.add(sq);
            }
            if(listOfSharedQuoteToInsert.size()>0)
            {
                insert listOfSharedQuoteToInsert;
            }
           
        }catch(Exception e)
        {     
            system.assert(false,e.getMessage() );
        }

        return listOfSharedQuoteToInsert;
    }

    public static boolean attachPDF(List<OppLeadTableWrapper> wrapperData, Blob pdfContent,List<Shared_Quote__c> sharedQuoteList)
    {

        Map<Id,Attachment> leadOppIdWithAttachment = new Map<Id,Attachment>();

        List<Attachment> listOfAtt = new List<Attachment>();

        for(OppLeadTableWrapper wr : wrapperData)
        {
            //String str = '<h5 align="right" style="float: right;">Customer Detail:</h5> <p align="right" style="font-size:8px;float: right;">Name: '+wr.name+' <br/> Email: '+wr.email+' <br/>Mobile: '+wr.mobile+'</p></div>';
            Attachment attachmentPDF = new Attachment();
            //attachmentPDF.parentId = wr.id;
            attachmentPDF.Name = 'QuoteSummary.pdf';
            attachmentPDF.body = pdfContent ;//Blob.toPDF(pdfContent +str); //This creates the PDF content
            leadOppIdWithAttachment.put(wr.Id,attachmentPDF);
            //listOfAtt.add(attachmentPDF);
        }

        for(Shared_Quote__c shQ : sharedQuoteList)
        {
            Attachment att = new Attachment();
            Attachment attForTask = new Attachment();
            if(leadOppIdWithAttachment.size()>0)
            {
                if(leadOppIdWithAttachment.containsKey(shQ.Opportunity__c))
                {
                    att =   leadOppIdWithAttachment.get(shQ.Opportunity__c).clone();
                    att.parentId = shQ.Id;
                    attForTask =   leadOppIdWithAttachment.get(shQ.Opportunity__c).clone();
                    attForTask.parentId = shQ.Task_Id__c;
                    
                }
                if(leadOppIdWithAttachment.containsKey(shQ.Lead__c))
                {
                    att =  leadOppIdWithAttachment.get(shQ.Lead__c).clone();
                    att.parentId = shQ.Id;

                    attForTask =  leadOppIdWithAttachment.get(shQ.Lead__c).clone();
                    attForTask.parentId = shQ.Task_Id__c;
                }
                
            }
            listOfAtt.add(att);
            listOfAtt.add(attForTask);
        }

        try
        {
            system.System.debug('nn11@@ = '+ listOfAtt);
            if(listOfAtt.size()>0)
            {
                insert listOfAtt;


                return true;

                // created shered quote record
            }
            
        }catch(Exception e)
        {     
            system.assert(false,e.getMessage());
        }

        return false;
    }

    /**
    *  @description    :  calculate  sub componnets 
    *  @args           :   
    *  @return         :   Quotation__c
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   18/08/2021
    **/
	@AuraEnabled
    public static Quotation__c calculateDetails ( List<Apartment__c> listOfApartment)
    {
        
        if(/*oppRecId !=null && oppRecId !=''  &&*/listOfApartment !=null && listOfApartment.size()>0)
        {
            //Opportunity oppRec = [Select Id,Name,Apartment_Rate_after_Discount__c From Opportunity Where Id = :oppRecId];
            Map<Id,List<Tax_Master__c> > subCompTaxMap = new Map<Id,List<Tax_Master__c> >();
            Map<Id, List<Sub_Component__c>> compSubMap = new Map<Id, List<Sub_Component__c>>();


            Set<Id> setOfApartmentId = new Set<Id>();
            List<Apartment__c> aptList = new List<Apartment__c>();
            Map<id,Apartment__c> apartmentMap = new Map<Id,Apartment__c>();

            for ( Apartment__c  apt : listOfApartment)
            {
                setOfApartmentId.add(apt.Id);
            }

            List<Sub_Component__c> subCompList = [Select id, name, Area_wise_Amount__c, Collection_Type__c,Land_Cost_Type__c,
                                                  Premium_Cost_Type__c,Component_Master__c,Component_Rate_Type__c, 
                                                  Display_Order__c,Duration__c, Lumpsum_Amount__c, Formula_Field__c,
                                                  apartment_Comp__c ,Franking_Charge_Rate__c,Franking_Amount__c,
                                                  Is_Franking_charge_on_Aggregate_value__c, Maintenance_Rate__c,
                                                  Premium_Charges_Order__c,Lookup_Charges_Order__c,Construction_Cost_Percentage__c,

                                                  (SELECT id, Sub_Component__c, name, From_Date__c,To_Date__c,TC1_Name__c, 
                                                   TC1_Type__c, TC1_Value__c,TC1_Appr__c,TC1_Available__c,TC2_Name__c, 
                                                   TC2_Type__c, TC2_Value__c,TC2_Appr__c,TC2_Available__c,TC3_Name__c, 
                                                   TC3_Type__c, TC3_Value__c,TC3_Appr__c,TC3_Available__c,TC4_Name__c, TC4_Type__c,
                                                   TC4_Value__c,TC4_Appr__c,TC4_Available__c FROM Taxes_Master__r )
                                                    // (Select Id,Name,TDS_Percentage__c,Start_Date__c From TDS_Masters__r) 
                                                  FROM Sub_Component__c WHERE Component_Master__c = : listOfApartment[0].ComponentMaster__c
                                                  ORDEr by Display_Order__c ];

            if(setOfApartmentId.size()>0)
            {
                aptList = [SELECT id,Extra_Plot_Area__c,Area_in_Sq_Mts__c,Terrace_Area__c,Planter_Area__c,Garden_Area__c, Built_up_Area__c,
                           Carpet_Area__c, UDS_Area__c,Other_Area__c,Construction_Cost__c,Floor_Rise_Charges_Per_Sqft__c,Apartment_Cost__c,
                           Apartment_rate__c,Take_Rate_from_Rate_Master__c,Land_Cost__c,Premium_Charges__c,Car_Park_Rate__c,
                           Apt_Formula_field__c,Construction_Cost_Master__c,Construction_Cost_Master__r.Apartment_Rate_Consideration__c,Apartment_Master__r.Apartment_Rate_Consideration__c ,Apartment_Rate_Formula__c,
                           Standard_Booking_Amount__c,Unit_Number__c,Block__c,Apartment_Type__c,Apartment_Master__c,Car_Park_Master__c,
                           Floor_Rate_Master__c,ComponentMaster__c,Premium_Rate_Master__c,Template_Master__c,Undivided_Land_Area__c,
                           isTDSApplicable__c, Premium_Rate_Per__c,Premium_Rate2__c,Premium_Rate3__c,Premium_Rate4__c,Premium_Rate5__c,
                           Premium_Rate2_per__c,Premium_Rate3_per__c,Premium_Rate4_per__c,Premium_Rate5_per__c,Apt_Formula_field_2__c,
                           Apt_Formula_field_3__c,Apt_Formula_field_4__c,Apt_Formula_field_5__c,Premium_Rate_Master__r.Premium_Rate__c,
                           Apartment_Finish__c,Allow_Standard_Plan_Editing__c, Lookup_Master_1__c, Lookup_Master_1_Rate__c, Lookup_Master_2__c,
                           Lookup_Master_2_Rate__c, Lookup_Master_3__c, Lookup_Master_3_Rate__c,Elevated_Price_per_sft__c,Rack_Rate__c
                           FROM Apartment__c WHERE Id IN: setOfApartmentId];
            }
            
            if(aptList.size()>0)
            {
                apartmentMap = new Map<Id, Apartment__c>(aptList);
            }

            for(Sub_Component__c sub : subCompList)
            {
                System.debug('The component is :' + sub);
                system.debug('The taxes are :' + sub.Taxes_Master__r);
                if(!compSubMap.containsKey(sub.Component_Master__c))
                {
                    compSubMap.put(sub.Component_Master__c, new List<Sub_Component__c>());
                }
                compSubMap.get(sub.Component_Master__c).add(sub);   
                
                if(sub.Taxes_Master__r.size() > 0)
                {
                    subCompTaxMap.put(sub.Id, sub.Taxes_Master__r);
                }   
            }


            /// 
            integer calculateAgainDisplayOrder = 0;
            integer calculateAgainDisplayOrderTwo = 0;
            
                Quotation__c quoteRec = new Quotation__c();
                //quoteRec.Name = 'Quotation';
                //System.debug('hhhh@@'+ oppRec);
                //quoteRec.Opportunity__c = oppRec.Id;
                quoteRec.Standard_Booking_Amount__c =false;
                quoteRec.Inventory__c = aptList[0].Id;
                quoteRec.Component_1_Discount__c = 0;
                quoteRec.Component_2_Discount__c = 0;
                quoteRec.Component_1_Amount_After_Discount__c = 0;
                quoteRec.Component_2_Amount_After_Discount__c = 0;
                
            	Apartment__c apartment = aptList[0];
                quoteRec.Unit_Rate_Per_SFT1__c = apartment.Apartment_Rate_Formula__c;

                system.debug('I am at 87');
                double aggregateValue = 0;
                double saleAgreedAmount = 0;
                double aptRate = apartment.Apartment_Rate_Formula__c;
                List<Sub_Component__c> subList = subCompList;
                Integer subSize = subList.size();
                Double totalBasic = 0;
                Double totalwithTax = 0;
                Double InclAmt = 0;
                Double totalTax1 = 0;
                Double totaltax2 = 0;
                Double totalTax3 = 0;
                Double totalTax4 = 0;
                system.debug('the sub component for this opp is' + subList);
                
                Double ConstructionCost = 0;
                Double CarParkCost = 0;
                Double FloorRiseCost = 0;
                Double PremiumCost = 0;
                Double LandCost = 0;
                
                for(Sub_Component__c sub : subList){
                    
                    if(sub.Display_Order__c >= 1 && sub.Display_Order__c <= 20)
                    {               
                        OpportunityDetailHandler.ComponentInfo info = new OpportunityDetailHandler.ComponentInfo();
                        system.debug('aggregateValue is----'+aggregateValue);
                        system.debug(sub.apartment_Comp__c+'---saleAgreedAmount is----'+saleAgreedAmount);

                        OpportunityDetailHandler.ComponentInfo cInfo = info.calculateTax(null,sub, sub.Taxes_Master__r, new List<TDS_Master__c>(), aptList[0] , system.today(),0,aggregateValue,saleAgreedAmount);
                        
                        System.debug('OUT -> ' + cInfo.Basic);
                        aggregateValue = cInfo.TotalAggregateValue;
                        saleAgreedAmount = cInfo.SaleAggregateValue;
                        system.debug('aggregateValue is----'+aggregateValue);
                        integer displayOrder = integer.valueOf(sub.Display_Order__c);
                        System.debug('calculateAgain@@@cus ' + cInfo.calculateAgain);
                        System.debug('displayOrder@@@cus ' + displayOrder);
                        if(cInfo.calculateAgain == true)
                        {
                            System.debug('incalculateAgiancus@@');
                            if(calculateAgainDisplayOrder == 0)
                            {
                                calculateAgainDisplayOrder = displayOrder;
                            }
                            else
                            {
                                calculateAgainDisplayOrderTwo = displayOrder;
                            }
                        }
                        if(sub.apartment_Comp__c == 'Construction Cost')    
                        {
                            ConstructionCost = cInfo.Basic;
                        }
                        if(sub.apartment_Comp__c == 'Premium Charges')
                        {
                            PremiumCost += cInfo.Basic;
                        }
                        if(sub.apartment_Comp__c == 'Floor Rise Charges')
                        {
                            FloorRiseCost += cInfo.Basic;
                        }
                        if(sub.apartment_Comp__c == 'Car Park')
                        {
                            CarParkCost = cInfo.Basic;
                        }
                        if(sub.apartment_Comp__c == 'Land Cost')
                        {
                            LandCost = cInfo.Basic;
                            System.debug('IN IF 971 -> '+ LandCost);
                        }
                            
                        quoteRec.put('Component_'+sub.Display_Order__c+'_Name__c',sub.Name);
                        quoteRec.put('Component_'+sub.Display_Order__c+'_Basic__c',cInfo.Basic);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax1_Amount__c',cInfo.Tax1);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax2_Amount__c',cInfo.Tax2);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax3_Amount__c',cInfo.Tax3);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax4_Amount__c',cInfo.Tax4);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax1_Name__c',cInfo.Tax1Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax2_Name__c',cInfo.Tax2Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax3_Name__c',cInfo.Tax3Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax4_Name__c',cInfo.Tax4Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Total__c',cInfo.Total);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax__c',(cInfo.Tax == null ? NULL : cInfo.Tax.id));
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Selection_Type__c',sub.apartment_Comp__c);
                        system.debug('quoteRec is -in-->> '+quoteRec);
                        totalBasic += cInfo.Basic;
                        system.debug(sub.Name+'<-->'+cInfo.Basic+'<---totalBasic is--->'+totalBasic);
                        totalwithTax += cInfo.Total;
                        if(sub.Collection_Type__c == 'Inclusive'){
                            InclAmt += cInfo.Total;
                        }

                        totalTax1 += cInfo.Tax1;
                        totaltax2 += cInfo.Tax2;
                        totalTax3 += cInfo.Tax3;
                        totalTax4 += cInfo.Tax4;
                        
                        
                        quoteRec.Total_Basic__c = totalBasic;
                        quoteRec.Total_Balance__c = totalwithTax;
                        quoteRec.Inclusive_Amt_Total__c = InclAmt;
                        
                        quoteRec.Total_Tax1__c = totalTax1;
                        quoteRec.Total_Tax2__c = totaltax2;
                        quoteRec.Total_Tax3__c = totalTax3;
                        quoteRec.Total_Tax4__c = totalTax4;
                      //  system.debug('quoteRec.Opportunity_Total__c is -in-->> '+quoteRec.Opportunity_Total__c);*/
                    }   
            
                }
                System.debug('calculateAgainDisplayOrderTwo@@1 ' + calculateAgainDisplayOrderTwo);
                System.debug('calculateAgainDisplayOrder@@2 ' + calculateAgainDisplayOrder);
                if(calculateAgainDisplayOrder != 0)
                {
                    for(Sub_Component__c sub : subList){
                        system.debug('sub is ---'+sub+'calculateAgainDisplayOrder is ---'+calculateAgainDisplayOrder);
                        System.debug('calculateAgainDisplayOrderTwo@@ ' + calculateAgainDisplayOrderTwo);
                        System.debug('calculateAgainDisplayOrder@@ ' + calculateAgainDisplayOrder);
                        if(sub.Display_Order__c == calculateAgainDisplayOrder || sub.Display_Order__c == 1)
                        {
                            system.debug('aptRate -> '+aptRate);
                            double basicAmt = 0;
                            Double totalCost = 0;
                            Double tempBasicAmt = 0;
                            System.debug('Percentage@#@Cal@ ' + sub.Construction_Cost_Percentage__c);
                            if(sub.apartment_Comp__c == 'Construction Cost' )
                            {
                                system.debug('LandCost is ----'+LandCost);
                                //basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - LandCost;
                                //added abhishek
                                if(sub.Land_Cost_Type__c == 'AggregateValue - LandCost')
                                {
                                    if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') != null)
                                    {
                                        if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Floor Rise Charges')
                                        {
                                            basicAmt = ((aptRate)*(apartmentMap.get(aptList[0].id).Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c))-LandCost+FloorRiseCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Premium Charges')
                                        {
                                            basicAmt = ((aptRate)*(apartmentMap.get(aptList[0].Id).Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c))-LandCost+PremiumCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Both')
                                        {
                                            basicAmt = ((aptRate)*(apartmentMap.get(aptList[0].Id).Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c))-LandCost+PremiumCost+FloorRiseCost ;
                                        }
                                        else
                                        {
                                            basicAmt = ((aptRate)*(apartmentMap.get(aptList[0].Id).Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c))-LandCost;
                                        }
                                    }
                                }
                                //end
                                else if(sub.Land_Cost_Type__c == '88/12' && sub.Construction_Cost_Percentage__c != null)
                                {
                                    System.debug('in88/12@@');
                                    if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r') != null && apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') != null)
                                    {
                                        if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Floor Rise Charges')
                                        {
                                            System.debug('inIF@#@1 ');
                                            totalCost = ((aptRate)*(apartmentMap.get(aptList[0].id).Built_up_Area__c == null ? 0 : apartmentMap.get(aptList[0].id).Built_up_Area__c));
                                            tempBasicAmt = (totalCost * sub.Construction_Cost_Percentage__c)/100;
                                            basicAmt = tempBasicAmt+FloorRiseCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Premium Charges')
                                        {
                                            System.debug('inIF@#@2 ');
                                            totalCost = ((aptRate)*(apartmentMap.get(aptList[0].id).Built_up_Area__c == null ? 0 : apartmentMap.get(aptList[0].id).Built_up_Area__c));
                                            tempBasicAmt = (totalCost * sub.Construction_Cost_Percentage__c)/100;
                                            basicAmt = tempBasicAmt+PremiumCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c')  == 'Include Both')
                                        {
                                            System.debug('inIF@#@3 ');
                                            totalCost = ((aptRate)*(apartmentMap.get(aptList[0].id).Built_up_Area__c == null ? 0 : apartmentMap.get(aptList[0].id).Built_up_Area__c));
                                            tempBasicAmt = (totalCost * sub.Construction_Cost_Percentage__c)/100;
                                            basicAmt = tempBasicAmt+FloorRiseCost+PremiumCost;
                                        }
                                        else
                                        {
                                            System.debug('Else@#@1 ');
                                            totalCost = ((aptRate)*(apartmentMap.get(aptList[0].id).Built_up_Area__c == null ? 0 : apartmentMap.get(aptList[0].id).Built_up_Area__c));
                                            tempBasicAmt = (totalCost * sub.Construction_Cost_Percentage__c)/100;
                                            basicAmt = tempBasicAmt;
                                        }
                                    }  
                                }
                            }
                            else if(sub.apartment_Comp__c == 'Land Cost')
                            {
                                System.debug('inLandCostCus@@');
                                if(sub.Land_Cost_Type__c == 'AggregateValue - (Construction Cost + FloorRise Cost)')
                                {
                                    if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r') != null && apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') != null)
                                    {
                                        if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Floor Rise Charges')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost+FloorRiseCost);
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Premium Charges')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost+PremiumCost);
                                        }
                                        else if(apartmentMap.get(aptList[0].Id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Both')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost+PremiumCost+FloorRiseCost);
                                            System.debug('1044 basicAmt - > ' +basicAmt);
                                            System.debug('1044 aptList[0].Built_up_Area__c - > ' +aptList[0].Built_up_Area__c);
                                            System.debug('1044 ConstructionCost - > ' +ConstructionCost);
                                            System.debug('1044 PremiumCost - > ' +PremiumCost);
                                            System.debug('1044 FloorRiseCost - > ' +FloorRiseCost);
                                        }
                                        else
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost);
                                        }
                                    }
                                    LandCost =  basicAmt;
                                }  
                                if(sub.Land_Cost_Type__c == 'AggregateValue - Development Charges')
                                {
                                    System.debug('inCalLandCost88/12@');
                                    if(apartmentMap.get(aptList[0].id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') != null)
                                    {
                                        if(apartmentMap.get(aptList[0].id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Floor Rise Charges')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - ConstructionCost+FloorRiseCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Premium Charges')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - ConstructionCost+PremiumCost;
                                        }
                                        else if(apartmentMap.get(aptList[0].id).getSobject('Apartment_Master__r').get('Apartment_Rate_Consideration__c') == 'Include Both')
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - ConstructionCost+PremiumCost+FloorRiseCost;
                                        }
                                        else
                                        {
                                            basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost);
                                        }
                                    }
                                } 
                                else
                                {
                                    basicAmt = (aptRate*(aptList[0].Built_up_Area__c == null ? 0 : aptList[0].Built_up_Area__c)) - (ConstructionCost);
                                    LandCost =  basicAmt;
                                }
                            }
                            
                            system.debug('basicAmt is@@ ----'+basicAmt);
                            
                            OpportunityDetailHandler.ComponentInfo info = new OpportunityDetailHandler.ComponentInfo();
                            system.debug('aggregateValue is----'+aggregateValue);
                            OpportunityDetailHandler.ComponentInfo cInfo = info.calculateTax(null,sub, sub.Taxes_Master__r, new List<TDS_Master__c>(), aptList[0],  system.today(),basicAmt, aggregateValue,saleAgreedAmount);

                            aggregateValue = cInfo.TotalAggregateValue;
                            saleAgreedAmount = cInfo.SaleAggregateValue;
                            system.debug('aggregateValue is----'+aggregateValue+'---'+saleAgreedAmount);
                            system.debug('cInfo is ----'+cInfo);
                            quoteRec.put('Component_'+calculateAgainDisplayOrder+'_Name__c',sub.Name);
                            quoteRec.put('Component_'+calculateAgainDisplayOrder+'_Basic__c',cInfo.Basic);
                            /*quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax1_Amount__c',cInfo.Tax1);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax2_Amount__c',cInfo.Tax2);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax3_Amount__c',cInfo.Tax3);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax4_Amount__c',cInfo.Tax4);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax1_Name__c',cInfo.Tax1Name);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax2_Name__c',cInfo.Tax2Name);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax3_Name__c',cInfo.Tax3Name);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax4_Name__c',cInfo.Tax4Name);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Total__c',cInfo.Total);
                            quoteRec.put('Comp'+calculateAgainDisplayOrder+'_Tax__c',(cInfo.Tax == null ? NULL : cInfo.Tax.id));*/
                            
                            totalBasic += cInfo.Basic;
                            system.debug(sub.Name+'<-->'+cInfo.Basic+'<---totalBasic is--->'+totalBasic);
                            totalwithTax += cInfo.Total;
                            if(sub.Collection_Type__c == 'Inclusive'){
                                InclAmt += cInfo.Total;
                            }
                            totalTax1 += cInfo.Tax1;
                            totaltax2 += cInfo.Tax2;
                            totalTax3 += cInfo.Tax3;
                            totalTax4 += cInfo.Tax4;
                            
                            quoteRec.Total_Basic__c = totalBasic;
                            quoteRec.Inclusive_Amt_Total__c = InclAmt;
                            /*quoteRec.Opportunity_Total__c = totalwithTax;
                            quoteRec.Inclusive_Amt_Total__c = InclAmt;
                            
                            quoteRec.Total_Tax1__c = totalTax1;
                            quoteRec.Total_Tax2__c = totaltax2;
                            quoteRec.Total_Tax3__c = totalTax3;
                            quoteRec.Total_Tax4__c = totalTax4;
                            
                            system.debug('quoteRec.Opportunity_Total__c is -in-->> '+quoteRec.Opportunity_Total__c);*/
                        }
                    }
                }
                
                //Calculating Franking Charges
                for(Sub_Component__c sub : subList)
                {
                    if(sub.Component_Rate_Type__c != null && sub.Component_Rate_Type__c.contains('Franking'))
                    {
                        
                        OpportunityDetailHandler.ComponentInfo info = new OpportunityDetailHandler.ComponentInfo();
                        system.debug('aggregateValue is----'+aggregateValue);
                        system.debug('saleAgreedAmount is----'+saleAgreedAmount);

                        OpportunityDetailHandler.ComponentInfo cInfo = info.calculateTax(null, sub, sub.Taxes_Master__r,new List<TDS_Master__c>(), aptList[0], system.today(), LandCost, aggregateValue, saleAgreedAmount);

                        quoteRec.put('Component_'+sub.Display_Order__c+'_Name__c',sub.Name);
                        quoteRec.put('Component_'+sub.Display_Order__c+'_Basic__c',cInfo.Basic);
                        /*quoteRec.put('Comp'+sub.Display_Order__c+'_Tax1_Amount__c',cInfo.Tax1);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax2_Amount__c',cInfo.Tax2);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax3_Amount__c',cInfo.Tax3);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax4_Amount__c',cInfo.Tax4);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax1_Name__c',cInfo.Tax1Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax2_Name__c',cInfo.Tax2Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax3_Name__c',cInfo.Tax3Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax4_Name__c',cInfo.Tax4Name);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Total__c',cInfo.Total);
                        quoteRec.put('Comp'+sub.Display_Order__c+'_Tax__c',(cInfo.Tax == null ? NULL : cInfo.Tax.id));*/
                        
                        totalBasic += cInfo.Basic;
                        system.debug(sub.Name+'<-->'+cInfo.Basic+'<---totalBasic is--->'+totalBasic);
                        totalwithTax += cInfo.Total;
                        if(sub.Collection_Type__c == 'Inclusive'){
                            InclAmt += cInfo.Total;
                        }
                        totalTax1 += cInfo.Tax1;
                        totaltax2 += cInfo.Tax2;
                        totalTax3 += cInfo.Tax3;
                        totalTax4 += cInfo.Tax4;
                        
                        quoteRec.Total_Basic__c = totalBasic;
                        quoteRec.Inclusive_Amt_Total__c = InclAmt;
                        /*quoteRec.Opportunity_Total__c = totalwithTax;
                        quoteRec.Inclusive_Amt_Total__c = InclAmt;
                        
                        quoteRec.Total_Tax1__c = totalTax1;
                        quoteRec.Total_Tax2__c = totaltax2;
                        quoteRec.Total_Tax3__c = totalTax3;
                        quoteRec.Total_Tax4__c = totalTax4;
                        
                        system.debug('quoteRec.Opportunity_Total__c is -in-->> '+quoteRec.Opportunity_Total__c);*/
                    }
                }

                System.debug('WWWW ->'+ quoteRec);
                return quoteRec;
        
        }
        ////
        return null;

    }
    
    /**
    *  @description    :   
    *  @args           :   
    *  @return         :   
    * 
    * 
    * Created By       :   Noorulain Ashrafi
    * 
    * Created Date     :   20/08/2021
    **/
	@AuraEnabled
    public static List<Quotation__c> createQuotationWithChild (String data, Project__c projectRec)
    {

        System.debug('cccc = '+ data);
        
        List<QuoteWithInstallmentWrapper> quoteWrapperData  =  (List<QuoteWithInstallmentWrapper>)JSON.deserialize(data, List<QuoteWithInstallmentWrapper>.class);

        System.debug('cccc = '+ data);
        System.debug('cccc = '+ quoteWrapperData);
        //List<Quotation__c> listOfQuotation = new List<Quotation__c>();
        //List<Quotation_Installment__c> listOfInstallment = new List<Quotation_Installment__c>();
        Map<Integer,List<Quotation_Installment__c>> mapOfIndexWithInstallment = new Map<Integer,List<Quotation_Installment__c>>();
        Map<Integer,Quotation__c> mapOfIndexWithQuote = new Map<Integer,Quotation__c>();
        Map<Integer,Id> mapOfIndexWithQuoteId = new Map<Integer,Id>();


        for(QuoteWithInstallmentWrapper obj : quoteWrapperData)
        {
            if(!mapOfIndexWithInstallment.containsKey(obj.indexVar))
            {
                mapOfIndexWithInstallment.put(obj.indexVar, new List<Quotation_Installment__c>());
            }
            mapOfIndexWithInstallment.get(obj.indexVar).addAll(obj.installmentsList);

            // for quotation map
            if(!mapOfIndexWithQuote.containsKey(obj.indexVar))
            {
                //added for not approval
                if(obj.quotation.Total_discount__c > 0 && obj.quotation.Quotation_Discount__c > 0) 
                {
                    obj.quotation.Status__c = 'Submitted';
                }
                //obj.quotation.Status__c = 'Submitted';
                mapOfIndexWithQuote.put(obj.indexVar,obj.quotation);
            }
        }

        // 18/08/2022 TDS Feature. Addedy By AJAY SINGH
        // Start
        Project__c projTDS = new Project__c();

        if(projectRec != null){
           projTDS = [Select Id,TDS_Limit__c From Project__c Where Id =: projectRec.Id];
        }

        Map<Integer,Quotation__c> mapOfIndexWithQuoteTDS = new Map<Integer,Quotation__c>();
        Map<Id,Id> mapOfInvIdComId = new Map<Id,Id>();
        Map<Id,Date> mapOfOppIdDateWise = new Map<Id,Date>();

        List<Id> listOfInvId = new List<Id>();
        List<Id> oppId = new List<Id>();
        List<Integer> listOfTDSApplicableNumber = new List<Integer>();


        for(Integer indexVar : mapOfIndexWithQuote.keySet()) {
         //   if(projTDS.TDS_Limit__c <= mapOfIndexWithQuote.get(indexVar).Total_Basic_After_Discount__c){
                listOfInvId.add(mapOfIndexWithQuote.get(indexVar).Inventory__c);
                oppId.add(mapOfIndexWithQuote.get(indexVar).Opportunity__c);
                listOfTDSApplicableNumber.add(indexVar);
          //  }
        }

        if(listOfInvId.size() > 0){
            List<Apartment__c> listOfInv = [Select Id , ComponentMaster__c From Apartment__c Where Id IN : listOfInvId];

            for(Apartment__c inv: listOfInv){
                mapOfInvIdComId.put(inv.id,inv.ComponentMaster__c);
            }
        }

        if(oppId.size() > 0) {
            List<Opportunity> listOfOpp = [Select Id,CloseDate From Opportunity Where Id IN : oppId];
            for(Opportunity opp: listOfOpp){
                mapOfOppIdDateWise.put(opp.id,opp.CloseDate);
            }
        }
        
        Map<Id,List<Map<Decimal,Sub_Component__c>>> mapOfSubCompId  = new Map<Id,List<Map<Decimal,Sub_Component__c>>>();
        System.debug('mapOfInvIdComId  '+mapOfInvIdComId );
         
        if(mapOfInvIdComId.size() > 0) {
            List<Sub_Component__c> subCompList = [Select id, name,Display_Order__c,Component_Master__c, (Select Id,Name,TDS_Percentage__c,Start_Date__c From TDS_Masters__r) from 
                                                  Sub_Component__c where Component_Master__c IN : mapOfInvIdComId.values() order by Display_Order__c ];

            for(Sub_Component__c subComp : subCompList){
               
                Map<Decimal,Sub_Component__c> mapOfData =  new Map<Decimal,Sub_Component__c>();
                mapOfData.put(subComp.Display_Order__c,subComp);

                if(!mapOfSubCompId.containsKey(subComp.Component_Master__c)){
                    mapOfSubCompId.put(subComp.Component_Master__c, new List<Map<Decimal,Sub_Component__c>>());
                }

                mapOfSubCompId.get(subComp.Component_Master__c).add(mapOfData);
            }                                      
        }

        System.debug('mapOfSubCompId '+mapOfSubCompId);

        Double tdsLimit = Double.valueOf(mapOfIndexWithQuote.get(0).Total_TDS_Count_After_Discount__c);
        for(Integer indexVar : mapOfIndexWithQuote.keySet()){
            if(projTDS.TDS_Limit__c <= mapOfIndexWithQuote.get(indexVar).Total_TDS_Count_After_Discount__c){
                Quotation__c qut = mapOfIndexWithQuote.get(indexVar);
                Id compId = mapOfInvIdComId.get(mapOfIndexWithQuote.get(indexVar).Inventory__c);
                List<Map<Decimal,Sub_Component__c>> listOfSubComMap = mapOfSubCompId.get(compId);
                System.debug('Hello@@1');
                for(Integer i =1 ; i<=15 ; i++){
                    List<TDS_Master__c> listOfTDS =  new List<TDS_Master__c>(); 
                    for(Map<Decimal,Sub_Component__c> mapOfSub: listOfSubComMap) {
                        if(mapOfSub.containsKey(Decimal.valueOf(i)) && mapOfSub.get(Decimal.valueOf(i)).name == qut.get('Component_'+i+'_Name__c')){
                            listOfTDS = mapOfSub.get(Decimal.valueOf(i)).TDS_Masters__r;
                            break;
                        }
                    }

                    TDS_Master__c selectedTDS = new TDS_Master__c();

                    if(listOfTDS == null || listOfTDS.isEmpty()) {
                       selectedTDS.TDS_Percentage__c = 0;
                    }
                    else if(listOfTDS.size() == 1) {
                        System.debug('InIf@@1');
                       selectedTDS = listOfTDS[0];
                    }
                    else if(listOfTDS.size() > 1) {
                        for(TDS_Master__c tds : listOfTDS){
                            if(mapOfOppIdDateWise.get(qut.Opportunity__c) >= tds.Start_Date__c && mapOfOppIdDateWise.get(qut.Opportunity__c) <= tds.End_Date__c){
                                selectedTDS = tds;
                                break;
                            }
                        }
                    }
                    System.debug(' selectedTDS '+selectedTDS);
                    Double tdsAmt = qut.get('Component_'+i+'_Amount_After_Discount__c') == null ? 0 : (Decimal.valueOf(Double.valueOf(qut.get('Component_'+i+'_Amount_After_Discount__c'))).setScale(4) * (SelectedTDS.TDS_Percentage__c/100));
                    Double bal = qut.get('Component_'+i+'_Amount_After_Discount__c') == null ? 0 : (Decimal.valueOf(Double.valueOf(qut.get('Component_'+i+'_Amount_After_Discount__c'))).setScale(4) - tdsAmt); 

                    qut.put('Comp_'+i+'_TDS_Amount__c',tdsAmt);
                    qut.put('Comp_'+i+'_TDS__c',selectedTDS.Id);	
                    qut.put('Comp_'+i+'_Total_Balance_Without_TDS__c',bal); 
                    
                    mapOfIndexWithQuoteTDS.put(indexVar,qut);
                } 
            }else
            {
                Quotation__c qut = mapOfIndexWithQuote.get(indexVar);
                Id compId = mapOfInvIdComId.get(mapOfIndexWithQuote.get(indexVar).Inventory__c);
                List<Map<Decimal,Sub_Component__c>> listOfSubComMap = mapOfSubCompId.get(compId);

                for(Integer i =1 ; i<=15 ; i++){
                    List<TDS_Master__c> listOfTDS =  new List<TDS_Master__c>(); 
                    for(Map<Decimal,Sub_Component__c> mapOfSub: listOfSubComMap) {
                        if(mapOfSub.containsKey(Decimal.valueOf(i)) && mapOfSub.get(Decimal.valueOf(i)).name == qut.get('Component_'+i+'_Name__c')){
                            listOfTDS = mapOfSub.get(Decimal.valueOf(i)).TDS_Masters__r;
                            break;
                        }
                    }

                    TDS_Master__c selectedTDS = new TDS_Master__c();

                    if(listOfTDS == null || listOfTDS.isEmpty()) {
                    selectedTDS.TDS_Percentage__c = 0;
                    }
                    else if(listOfTDS.size() == 1) {
                    selectedTDS = listOfTDS[0];
                    }
                    else if(listOfTDS.size() > 1) {
                        for(TDS_Master__c tds : listOfTDS){
                            if(mapOfOppIdDateWise.get(qut.Opportunity__c) >= tds.Start_Date__c && mapOfOppIdDateWise.get(qut.Opportunity__c) <= tds.End_Date__c){
                                selectedTDS = tds;
                                break;
                            }
                        }
                    }
                    qut.put('Comp_'+i+'_TDS__c',selectedTDS.Id);
                    qut.put('Comp_'+i+'_TDS_Amount__c',0);
                    qut.put('Comp_'+i+'_Total_Balance_Without_TDS__c',0);
                    mapOfIndexWithQuoteTDS.put(indexVar,qut);
                }
            }
        }

        for(Integer key : mapOfIndexWithQuoteTDS.keySet())
        {
            mapOfIndexWithQuote.put(key,mapOfIndexWithQuoteTDS.get(key));
        }

        
        for(Integer key : mapOfIndexWithInstallment.keySet()) {
            if(listOfTDSApplicableNumber.contains(key)){
                for(Quotation_Installment__c qutIns : mapOfIndexWithInstallment.get(key)) {
                    Id compId = mapOfInvIdComId.get(mapOfIndexWithQuote.get(key).Inventory__c);
                    List<Map<Decimal,Sub_Component__c>> listOfSubComMap = mapOfSubCompId.get(compId);
                    System.debug('Hello@@');
                    for(Integer i =1 ; i<=15 ; i++){
                        List<TDS_Master__c> listOfTDS =  new List<TDS_Master__c>(); 
                      
                        for(Map<Decimal,Sub_Component__c> mapOfSub: listOfSubComMap) {
                            if(mapOfSub.containsKey(Decimal.valueOf(i)) && mapOfSub.get(Decimal.valueOf(i)).name == qutIns.get('Comp'+i+'_Name__c')){
                                listOfTDS = mapOfSub.get(Decimal.valueOf(i)).TDS_Masters__r;
                                break;
                            }
                        }
    
                        TDS_Master__c selectedTDS = new TDS_Master__c();
                        
                        if(listOfTDS == null || listOfTDS.isEmpty()) {
                           selectedTDS.TDS_Percentage__c = 0;
                        }
                        else if(listOfTDS.size() == 1) {
                            System.debug('InIf@@@');
                           selectedTDS = listOfTDS[0];
                        }
                        else if(listOfTDS.size() > 1) {
                            for(TDS_Master__c tds : listOfTDS){
                                if(mapOfOppIdDateWise.get(mapOfIndexWithQuote.get(key).Opportunity__c) >= tds.Start_Date__c 
                                   && mapOfOppIdDateWise.get(mapOfIndexWithQuote.get(key).Opportunity__c) <= tds.End_Date__c){
                                    selectedTDS = tds;
                                    break;
                                }
                            }
                        }
   
                        System.debug(' selectedTDS '+selectedTDS);
    
                        Double tdsAmt = qutIns.get('Comp'+i+'_Basic__c') == null ? 0 : (Decimal.valueOf(Double.valueOf(qutIns.get('Comp'+i+'_Basic__c'))).setScale(4) * (SelectedTDS.TDS_Percentage__c/100));
                        Double bal = qutIns.get('Comp'+i+'_Basic__c') == null ? 0 : (Decimal.valueOf(Double.valueOf(qutIns.get('Comp'+i+'_Basic__c'))).setScale(4) - tdsAmt); 
    
                        if(projTDS.TDS_Limit__c <= tdsLimit)
                        {
                            qutIns.put('Comp_'+i+'_TDS_Amount__c',tdsAmt);
                            qutIns.put('Comp_'+i+'_TDS__c',selectedTDS.Id);	
                            qutIns.put('Comp_'+i+'_Total_Balance_Without_TDS__c',bal);
                        }
                        else
                        {
                            qutIns.put('Comp_'+i+'_TDS__c',selectedTDS.Id);	
                            qutIns.put('Comp_'+i+'_TDS_Amount__c',0);
                            qutIns.put('Comp_'+i+'_Total_Balance_Without_TDS__c',0);
                        }
                    } 
                } 
            }
        }
        
        // END

        if(mapOfIndexWithQuote.size()>0)
        {   
            System.debug(mapOfIndexWithQuote);
            //insert mapOfIndexWithQuote.values();
            Database.SaveResult[] saResult = Database.insert(mapOfIndexWithQuote.values(), false);

            integer i = 0;
            // Iterate through each returned result
            for (Database.SaveResult sr : saResult) 
            {
                if (sr.isSuccess()) 
                {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully record inserted ID: ' + sr.getId());
                    mapOfIndexWithQuoteId.put(i,sr.getId());

                }else{
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) 
                    {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('fields that affected this error: ' + err.getFields());
                    }
                }
                i++;
            }

            // insert installment
            if(mapOfIndexWithQuoteId.size()>0)
            {
                List<Quotation_Installment__c> listOfInstallmentToBeInsert = new List<Quotation_Installment__c>();
                System.debug('mapOfIndexWithInstallment === '+ mapOfIndexWithInstallment);
                System.debug('mapOfIndexWithQuoteId === '+ mapOfIndexWithQuoteId);
                for(Integer key : mapOfIndexWithInstallment.keySet())
                {
                    for(Quotation_Installment__c ins : mapOfIndexWithInstallment.get(key))
                    {
                        ins.Quotation__c = mapOfIndexWithQuoteId.get(key);
                        listOfInstallmentToBeInsert.add(ins);

                    } 
                }

                if(listOfInstallmentToBeInsert.size()>0)
                {
                    system.System.debug('ccccc222 = '+listOfInstallmentToBeInsert);
                    InstallmentHandler1.bypassTrigger = true;
                    insert listOfInstallmentToBeInsert;
                }

                // validate quotation record for approval 
                for(Id quotationId : validateforApproval(quoteWrapperData , projectRec))
                {
                    if(!Test.isRunningTest()) {
                        submitForApproval(quotationId, 'Submitted for approval');
                    }
                }

                // create shared quote rec
                List<Shared_Quote__c> sharedQuotList = new List<Shared_Quote__c>();
                //sharedQuotList.addAll(createSharedQuoteRecAndActivity(mapOfIndexWithQuote.values()));

                //GenerateComprativeQuotePageController obj = new GenerateComprativeQuotePageController(mapOfIndexWithQuote.values(),sharedQuotList,quoteWrapperData);
                //PageReference pageObj = page.GenerateComprativeQuote;
		        //pageObj.getParameters().put('listOfQuotation',JSON.Serialize( mapOfIndexWithQuote.values()));
                //pageObj.getParameters().put('listOfSharedQuote',JSON.Serialize(sharedQuotList));
                //pageObj.getParameters().put('listOfWrapper',JSON.Serialize( mapOfIndexWithQuote.values()));
                
                
                Map<Id,Set<Id>> mapOfOppIdWithQuotationIds = new Map<Id,Set<Id>>();
                for(Quotation__c qt : mapOfIndexWithQuote.values())
                {
                    if(!mapOfOppIdWithQuotationIds.containsKey(qt.Opportunity__c))
                    {
                        mapOfOppIdWithQuotationIds.put(qt.Opportunity__c, new Set<Id>());
                    }
                    mapOfOppIdWithQuotationIds.get(qt.Opportunity__c).add(qt.Id);
                }
                System.debug('mapOfOppIdWithQuotationIds = '+mapOfOppIdWithQuotationIds);

                // for generating pdf
              
                //CustomQuotationController.generateQuote(mapOfIndexWithQuoteId);
                //CustomQuotationController.generateQuote(JSON.Serialize(mapOfOppIdWithQuotationIds),JSON.Serialize(sharedQuotList));
            }
        }
        return mapOfIndexWithQuote.values();
    }
    

    // validate  quotaion record for approval
    public static Set<Id> validateforApproval(List<QuoteWithInstallmentWrapper> wrapperData , Project__c projectRec)
    {
        System.debug('ccccwrapperData = '+ wrapperData);
        System.debug('ccccprojectRec = '+ projectRec);
        Set<Id> setofQuotationId = new Set<Id>();
        if(wrapperData.size()>0)
        {
            //Project__c projectRec = projectRecord;
           // Set<Id> setofQuotationId = new Set<Id>();

            for(QuoteWithInstallmentWrapper obj : wrapperData)
            {
                System.debug('obj.quotation.Status__c@@@ ' + obj.quotation.Status__c);
                System.debug('obj.quotaApproval@@@ ' + projectRec.Quotation_Approval__c);
                if(obj.quotation.Status__c != 'Approved')
                {
                    if(String.isNotBlank(projectRec.Quotation_Approval__c))
                    {
                        System.debug('isNotBlankcondition@@');
                        if(projectRec.Quotation_Approval__c.contains('Above threshold?'))
                        {
                            if(obj.apartment.Threshold_Rate__c > obj.quotation.Final_Inventory_Cost__c)
                            {
                                //obj.quotation.Status__c = 'Submitted';
                                setofQuotationId.add(obj.quotation.Id);
                            }
                        }
    
                        if(projectRec.Quotation_Approval__c.contains('Below Threshold'))
                        {
                            if(obj.apartment.Threshold_Rate__c < obj.quotation.Final_Inventory_Cost__c)
                            {
                                //obj.quotation.Status__c = 'Submitted';
                                setofQuotationId.add(obj.quotation.Id);
                            }
                        }
                        if(projectRec.Quotation_Approval__c.contains('For all quotation'))
                        {
                            //obj.quotation.Status__c = 'Submitted';
                            System.debug('forAll@@@ ');
                            setofQuotationId.add(obj.quotation.Id);
                        }
                        
                    }
                }
                    
            }
            System.debug('setofQuotationId@@@# ' + setofQuotationId);
            if(setofQuotationId.size()>0)
            {
                return setofQuotationId;
            }
        }

        return setofQuotationId;
    }


    // create  shared quotes for comparativ quote
    public static List<Shared_Quote__c> createSharedQuoteRecAndActivity(List<Quotation__c> listOfQuotationRec)
    {
        List<Shared_Quote__c> listOfSharedQuote = new List<Shared_Quote__c>();
        List<Task> listOfTask = new List<Task>();

        for(Quotation__c wr : listOfQuotationRec)
        {
            Shared_Quote__c sharedQuote = new Shared_Quote__c();
            sharedQuote.Type__c = 'Comparative';
            sharedQuote.Inventory__c = wr.Inventory__c;
            sharedQuote.Opportunity__c= wr.Opportunity__c;
            sharedQuote.Quotation__c = wr.Id;

            // create task
            Task tsk = new Task();
            tsk.Subject = 'Shared Quote';
            //This is the default...
            tsk.OwnerId = UserInfo.getUserId();
            tsk.Status = 'New';
            tsk.Type = 'Email';
            tsk.Description = 'Shared Quote';
            tsk.ActivityDate = system.today();
            tsk.WhatId  =wr.Opportunity__c;
            

            listOfSharedQuote.add(sharedQuote);
            listOfTask.add(tsk);
        }

        try
        {
            if(listOfSharedQuote.size()>0)
            {
                //insert listOfSharedQuote;
            }
            if(listOfTask.size()>0)
            {
                insert listOfTask;
            }
        }catch(Exception e)
        {     
            system.assert(false,e.getMessage() );
        }

        return listOfSharedQuote;
    }

    /**
    *  @description    :  This method is used to submitting approval request
    * 
    *  @args           :   sObject record id
    * 
    *  @return         :   void
    * 
    * Created By       :   Noorulain Ashrafi
    **/
    public static void submitForApproval(Id recId, String comments)
    {
        // Create an approval request for the quotaion
        System.debug('inApproval@@ ' + recId);
        System.debug('inApproval@@ ' + comments);
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(comments);
        req1.setObjectId(recId);
        
        // Submit the approval request for the account
        Approval.ProcessResult result = Approval.process(req1);
        
        // Verify the result
        System.assert(result.isSuccess());
        
        System.assertEquals(
            'Pending', result.getInstanceStatus(),
            'Instance Status'+result.getInstanceStatus());        
        
    }
    @future(callout=true)
    //public static void generateQuote(Map<Integer,Id> mapOfIndexWithQuoteId)
    public static void generateQuote(String data,String sharedQuoteListData)
    {

        System.debug('nnnnnn1  ='+ data);
        //wrapperDataForQuotation obj = (wrapperDataForQuotation)JSON.deserialize(data, wrapperDataForQuotation.class);
        map<Id,Set<Id>> mapOfOppIdWithQuotationId = (map<Id,Set<Id>>)JSON.deserialize(data, map<Id,Set<Id>>.class);

        List<Shared_Quote__c> sharedQuotList = (List<Shared_Quote__c>)JSON.deserialize(sharedQuoteListData, List<Shared_Quote__c>.class);

        System.debug('nnnbbbb = '+ sharedQuotList);
        //  map of shared quote id with quotaion id
        Map<Id,Id> mapOfSharedQWithQuotationId = new Map<Id,Id>();
        for(Shared_Quote__c sq : sharedQuotList)
        {
            mapOfSharedQWithQuotationId.put(sq.Quotation__c,sq.Id);
        }

        System.debug('nnnnn2 = '+ mapOfOppIdWithQuotationId);
        List<Attachment>attList = new List<Attachment>();

        for(Id oppId : mapOfOppIdWithQuotationId.keySet())
        {
            String quotationIdsString = '';
            /*for(Id qtId : mapOfOppIdWithQuotationId.get(oppId))
            {
                quotationIdsString += qtId +',';
            }
            quotationIdsString.removeEnd(',');*/

            System.debug('nnnnnn2  ='+ quotationIdsString);
           

            Blob body;
           

            for(Id qtId : mapOfOppIdWithQuotationId.get(oppId))
            {
                PageReference pageObj = page.GenerateComprativeQuote;
                pageObj.getParameters().put('data',qtId);
                if(Test.isRunningTest()) 
                { 
                    body = blob.valueOf('Unit.Test');
                }else{
                    
                    body = pageObj.getContent();
                }
                Attachment attach = new Attachment();
                attach.Body = body;
                attach.IsPrivate = false;
                // attach the pdf to the account
                attach.ParentId = qtId;//mapOfSharedQWithQuotationId.get(qtId);// id of shared quote
                attach.Name = 'ComparativeQuote.pdf';//name of pdf
                //insert attach;//insertion of pdf
                attList.add(attach);

            }
        }



        /*for(Id qt : mapOfIndexWithQuoteId.values())
        {
            //wrapperDataForQuotation obj = new wrapperDataForQuotation();
            //obj.setofQuotationId.add(qt.Id);
            PageReference pageObj = page.GenerateComprativeQuote;
            //pageObj.getParameters().put('data',JSON.Serialize(obj));
            pageObj.getParameters().put('data',qt);
            
            Blob body;
            body = pageObj.getContent();
                system.debug('body---'+body);
            Attachment attach = new Attachment();
            attach.Body = body;
            attach.IsPrivate = false;
            // attach the pdf to the account
            attach.ParentId = qt;// id of current page
            attach.Name = 'TestReport.pdf';//name of pdf
            //insert attach;//insertion of pdf
            attList.add(attach);
        }*/

        if(attList.size() >0)
        {
            insert attList;
        }
    }

    //Wrapper to create value and Id  
    public class objectWrapper {
        
        @AuraEnabled public String label  {get;set;}
        @AuraEnabled public String value  {get;set;}
        @AuraEnabled public Apartment__c unit  {get;set;}
        @AuraEnabled public String sObjectName  {get;set;}
        @AuraEnabled public Boolean quoteSummaryAllowed  {get;set;}
      
        public objectWrapper() {
            
             this.label ='';
             this.value = '';
             this.unit = new Apartment__c();
             this.sObjectName = '';
             this.quoteSummaryAllowed = false;
        }
    }

    public class OppLeadTableWrapper
    {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String stage {get;set;}
        @AuraEnabled public String email {get;set;}
        @AuraEnabled public String mobile {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public String commnet {get;set;}
        

        public OppLeadTableWrapper() 
        {
            this.id = '';
            this.name ='';
            this.status ='';
            this.stage = '';
            this.email ='';
            this.mobile = '';
            this.type = '';
            this.commnet = '';
       }
    }

    public class QuoteWithInstallmentWrapper
    {
        @AuraEnabled public Integer indexVar {get;set;}
        @AuraEnabled public Quotation__c quotation {get;set;}
        @AuraEnabled public List<Quotation_Installment__c> installmentsList {get;set;}
        @AuraEnabled public Apartment__c apartment {get;set;}
        @AuraEnabled public Opportunity oppDetail {get;set;}
        @AuraEnabled public Project__c projectRecord {get;set;}
        
        public QuoteWithInstallmentWrapper() 
        {
            this.indexVar = 0;
            this.quotation = new Quotation__c();
            this.installmentsList = new List<Quotation_Installment__c>();
            this.apartment = new Apartment__c();
            this.oppDetail = new Opportunity();
            this.projectRecord = new Project__c();
       }
    }

    // for search unit page wrapper data
    public class searchUnitWrapper
    {
        @AuraEnabled public Apartment__c apartmentRec {get;set;}
        @AuraEnabled public String oppId {get;set;}
        @AuraEnabled public Boolean isSelected {get;set;}
        @AuraEnabled public String FloorNo {get;set;}

        public searchUnitWrapper() 
        {
            this.apartmentRec = new Apartment__c();
            this.oppId ='';
            this.isSelected = false;
            this.FloorNo = '';
       }
    }

    Public Class wrapperDataForQuotation{

        
        public Map<Id,Set<Id>> mapOfOppIdWithQuotationId{get;set;}
       
        public wrapperDataForQuotation() {
            
            this.mapOfOppIdWithQuotationId = new Map<Id,Set<Id>>();
        }
    }

    @AuraEnabled
    public static Opportunity getOpportunityObject(String recordId)
    {
        if(String.isNotBlank(recordId))
        {
            List<Opportunity> opportunityList = [SELECT Id, Name, Apartment__c, StageName, Probability FROM Opportunity WHERE Id =:recordId];

            if(opportunityList.size() > 0)
            {
                Opportunity oppObject = opportunityList[0];
                
                if(oppObject.StageName != '2.Blocking' && oppObject.StageName != '1.Site Tour Completed')
                {
                   throw new AuraHandledException('You do not have permission to create a new Quotation on this Opportunity');
                }
                if(oppObject.Apartment__c != null && oppObject.StageName == '2.Blocking')
                {
                    return oppObject;
                }
            }
        }

        return null;
    }

}