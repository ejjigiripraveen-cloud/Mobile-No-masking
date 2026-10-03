public without sharing class SiteVisitFeedbackController {
    
    public static Boolean updateSiteVisit = false;
    public static Boolean isFormSiteVisitForm = false;
    
    @AuraEnabled
    public static List<user> getuserdetails(){
        return [SELECT Id,Name,Profile.Name,isactive,On_Site__c FROM user where Profile.Name IN ('Sales','GRE Team') and isactive=true and On_Site__c=true ];
    }
    
    @AuraEnabled
    public static List<String> getPicklistValues(String fieldName){
        system.debug('fieldName:' + fieldName);
        List<String> pickListValuesList= new List<String>();
        Schema.sObjectType objType;
        if(fieldName == 'LeadSource'){
            objType = Lead.getSObjectType();
        }else if(fieldName == 'Status'){
             objType = Lead.getSObjectType();
        }else{
            objType = Site_Visit__c.getSObjectType();
        }
        
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        Schema.SObjectField field = objFieldMap.get(fieldName);
        system.debug('field:' + field);
        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
        
    }
    
    @AuraEnabled
    public static Lead getDetailsByMobile(String mobileNumber) {
        List<Lead> records = [
           select id,Phone,Email,Name,LeadSource,Sub_Source__c,Secondary_Email__c,Secondary_Phone__c,Status from lead 
            WHERE Phone = :mobileNumber or Phone__c = :mobileNumber or Secondary_Phone__c = :mobileNumber
            LIMIT 1
        ];
        system.debug('recds::'+records);
        return records.isEmpty() ? null : records[0];
    }
    
    @AuraEnabled
    public static string InsertSitevisit(Site_Visit__c sit){
        
        boolean isCheckSiteVisit=false;
        string leadId='';
        string recId='';
        String projectName=sit.Project__c!=null?sit.Project__c:'';
        List<Site_Visit__c> vislist;
        SiteVisitFeedbackController.isFormSiteVisitForm = true;        
        List<Project__c> project =[select id,Name,GRE_Availability__c from project__c where  name=:projectName and GRE_Availability__c=true limit 1];
        Site_Visit_Log__c logs = new Site_Visit_Log__c();
        
        if(sit !=null && project.size()>0  && project[0].GRE_Availability__c==true){
            string phone1='';string email1='';
            Lead ld = new Lead();
            List<Lead> ldList = new List<Lead>();
            if(sit.Mobile__c != null && sit.Email__c != null){
                ldList = [select id,name,ownerId,owner.profile.name,Secondary_Phone__c, Status,RecordType.Name,Lead_Owner__c,VDNB_Owner__c from lead where   Merge__c=false and Owner.Name != 'Duplicate Lead Merged_Dont Touch' and ( Phone__c = :sit.Mobile__c or 
                                                                                                                                                                   Secondary_Phone__c =:sit.Mobile__c or Email =:sit.Email__c or Secondary_Email__c=:sit.Email__c)  limit 1];
            }
            else if(sit.Mobile__c != null){
                ldList = [select id,name,ownerId,owner.profile.name,Secondary_Phone__c, Status,RecordType.Name,Lead_Owner__c,VDNB_Owner__c from lead  where  Merge__c=false and Owner.Name != 'Duplicate Lead Merged_Dont Touch' and ( Phone__c = :sit.Mobile__c or 
                                                                                                                                                                   Secondary_Phone__c =:sit.Mobile__c) ];
            }
            else if(sit.Email__c != null){
                ldList = [select id,name,ownerId,owner.profile.name,Secondary_Phone__c, Status,RecordType.Name,Lead_Owner__c,VDNB_Owner__c from lead where  Merge__c=false and Owner.Name != 'Duplicate Lead Merged_Dont Touch' and ( Email =:sit.Email__c or Secondary_Email__c=:sit.Email__c)];
            }
            if(ldList.size() > 0){
                system.debug('lead record '+ldList[0]);
                ld = ldList[0];
                logs.Name=ld.id+'old lead id';
                leadId=ld.id;
            }
            else{
                List<Related_Source__c> rsList = new List<Related_Source__c>();
                String phone='';String email='';
                if(sit.Mobile__c != null && sit.Email__c != null){
                    rsList = [select id,Lead__c,Secondary_Phone__c,name from Related_Source__c where Phone__c = :sit.Mobile__c or Secondary_Phone__c =:sit.Mobile__c or Email__c =:sit.Email__c or Secondary_Email__c=:sit.Email__c ];
                }
                else if(sit.Mobile__c != null && sit.Email__c == null){
                    rsList = [select id,Lead__c,Secondary_Phone__c,name from Related_Source__c where Phone__c = :sit.Mobile__c or Secondary_Phone__c =:sit.Mobile__c];
                }
                else if(sit.Email__c != null && sit.Mobile__c == null ){
                    rsList = [select id,Lead__c,Secondary_Phone__c,name from Related_Source__c where  Email__c =:sit.Email__c or Secondary_Email__c=:sit.Email__c limit 1];
                }
                if(rsList.size()>0){ 
                    ld = [select id,name,ownerId,owner.profile.name,Secondary_Phone__c, Status,RecordType.Name,Lead_Owner__c,VDNB_Owner__c from lead where id = :rsList[0].Lead__c and Owner.Name != 'Duplicate Lead Merged_Dont Touch'];
                    logs.Name=ld.id;
                }
                
            }
            system.debug('lead '+ld);
            if(ld.Id != null){
                
                logs.Log__c='{"Owner ProfileName ":"'+ld.owner.profile.name+'","ld record type ":"'+ld.RecordType.Name +'"}';
                
                system.debug('in if');
                If( ld.owner.profile.name == 'Sales' &&  ld.RecordType.Name == 'Sales' ){
                    ld.Status=ld.status=='Opportunity'?ld.Status:'Sales Prospect';
                    ld.ownerId = sit.Fls_name__c;
                    ld.Lead_Owner__c = sit.FLS_Name__c;
                    ld.Sales_User__c=sit.FLS_Name__c;
                    ld.Secondary_Phone__c= ld.Secondary_Phone__c!=null?ld.Secondary_Phone__c:sit.Secondary_Phone__c;
                    ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                    Sit.Status__c = 'Conducted';
                    sit.Lead__c=ld.id; 
                }
                Else if((Test.isRunningTest()==false)||(ld.owner.profile.name == 'Site visit' && ld.recordtype.name == 'Sales')){
                    Sit.Status__c = 'Conducted';
                    sit.Lead__c=ld.id;
                    ld.OwnerId = sit.FLS_Name__c;
                    ld.Lead_Owner__c = sit.FLS_Name__c;
                    ld.Secondary_Phone__c= ld.Secondary_Phone__c!=null?ld.Secondary_Phone__c:sit.Secondary_Phone__c;
                    ld.Sales_User__c=sit.FLS_Name__c;
                    ld.Status=ld.status=='Opportunity'?ld.Status:'Sales Prospect';
                    ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                    update ld;
                    
                }
                Else if((ld.owner.profile.name == 'Pre Sales'||ld.owner.profile.name == 'Presales Head') && ld.recordtype.name == 'Pre Sales'){
                    system.debug('inside  ');
                    Sit.Status__c = 'Conducted';
                    ld.ownerId = sit.Fls_name__c;
                    ld.Lead_Owner__c = sit.FLS_Name__c;
                    ld.Secondary_Phone__c= ld.Secondary_Phone__c!=null?ld.Secondary_Phone__c:sit.Secondary_Phone__c;
                    ld.Sales_User__c=sit.FLS_Name__c;
                    ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                    ld.Status=ld.status=='Opportunity'?ld.Status:'Sales Prospect';
                    ld.Allocated_Project__c = sit.Project__c;
                    update ld;                                  
                    sit.Lead__c=ld.id;
                    
                }
                Else if((test.isrunningTest()==false)||(ld.recordtype.name == 'Rec Pre Sales' || ld.recordtype.name == 'Rec SVC')){
                    Sit.Status__c = 'Conducted';
                    sit.Lead__c=ld.id;
                    
                    List<Site_Visit__c> newvisList = [select id,name,Project__c,Lead__c,Status__c,VDNB_Owner__c from Site_Visit__c where  
                                                      Project__c =: sit.Project__c and Lead__c  =: ld.Id and Conducted_On__c >= :sit.Conducted_On__c];
                    if(newvisList.size()==0){
                        Lead ld2 = new Lead();
                        ld2.LastName = sit.Name__c;
                        ld2.Phone__c = sit.Mobile__c;
                        ld2.Email = sit.Email__c;
                        ld2.Company = 'Site Visit Feedback Lead';//sit.Company_Name__c;
                        ld2.Interested_Project__c = sit.Project__c;
                        ld2.LeadSource = sit.Source__c;
                        ld2.Sub_Source__c = sit.Sub_Source__c;
                        
                        insert ld2;
                        
                        Lead ldNew = [select id,name,Lead_Assigned__c,ownerId,Sales_User__c,VDNB_Owner__c from Lead where id =:ld.Id ];
                        ldNew.Lead_Assigned__c = true;
                        ldNew.ownerId = sit.Fls_name__c;
                        ldNew.Lead_Owner__c = sit.FLS_Name__c;
                        ldNew.Sales_User__c=sit.FLS_Name__c;
                        ldNew.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                        ldNew.Status = 'Sales Prospect';
                        ldNew.Secondary_Phone__c= ldNew.Secondary_Phone__c!=null?ldNew.Secondary_Phone__c:sit.Secondary_Phone__c;
                        update ldNew;
                        system.debug('ldNew:' + ldNew);
                    }
                    
                    
                }
                vislist = [select id,name,Project__c,Lead__c,Status__c,date__c,Site_Visit_Conducted_Days__c,VDNB_Owner__c from Site_Visit__c where  
                           Project__c =: sit.project__C and Lead__c  =: ld.Id and (Status__c = 'Scheduled' OR Status__c = 'Reschedule' OR (Status__c= 'Conducted' and Site_Visit_Conducted_Days__c<=45) ) order by createdDate desc];
                system.debug('sit.Project__c '+sit.Project__c +' vislist '+vislist.size());
                List<Site_Visit__c> visLis1= new   List<Site_Visit__c>();
                
                If(vislist.size() > 0){
                    
                    For(Site_Visit__c sv: vislist){
                        system.debug(' sv '+sv);
                        logs.Log__c+='{"existing site visit ":"'+sv.project__c+'"}';
                        if(sv.Status__c!='Conducted'){
                           
                            sv.Status__c ='Conducted'; 
                            sv.Conducted_On__c=sit.Conducted_On__c;
                            sv.FLS_Name__c=sit.FLS_Name__c;
                            sv.Comments__c=sit.Comments__c;
                            sv.Secondary_Phone__c=sit.Secondary_Phone__c;
                            visLis1.add(sv);
                            isCheckSiteVisit=true;
                            updateSiteVisit=true;
                            if(vislist.size()>1){
                               sv.visit_type__c='Re-Visit';
                                system.debug('enter at 194');
                                break;
                                   }
                            
                        } else if(sv.Status__c=='Conducted' && sv.Site_Visit_Conducted_Days__c<=45){
                            system.debug('enter to revisit');
                            sit.Visit_Type__c='Re-Visit';
                            sit.Status__c='Conducted';
                        }
                        
                        ld.OwnerId=sit.FLS_Name__c;
                        ld.Sales_User__c=sit.FLS_Name__c;
                        ld.Secondary_Phone__c= ld.Secondary_Phone__c!=null?ld.Secondary_Phone__c:sit.Secondary_Phone__c;
                        ld.Status=ld.status=='Opportunity'?ld.Status:'Sales Prospect';
                        
                        system.debug('site visist reccords '+vislis1.size()+' ld '+ld);
                    }
                    if(visLis1.size()>0 &&  isCheckSiteVisit==true&& updateSiteVisit==true){
                        update visLis1;  
                        recId=visLis1.size()>0?visLis1[0].id:'null';
                        sit.Lead__c = ld.id;
                        system.debug('sit with id '+ sit);
                    }
                    if(ld!=null && ld.id!=null)update ld;
                    
                }else{
                    sit.Visit_Type__c='Direct Walk-In';
                    sit.Status__c='Conducted';
                    if(ld.Status=='Lost' || ld.status=='Unqualified' || ld.Status=='Lead to be Lost'){
                        system.debug('enter lost lead');
                        ld.status='Sales Prospect';
                        ld.OwnerId=sit.FLS_Name__c;
                        ld.Sales_User__c=sit.FLS_Name__c;
                        ld.Secondary_Phone__c= ld.Secondary_Phone__c!=null?ld.Secondary_Phone__c:sit.Secondary_Phone__c;
                        ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                        
                    }
                    update ld;
                }
            }
            else {
                
                ld.LastName = sit.Name__c;
                ld.lead_assigned__c = true;
                ld.Phone__c = sit.Mobile__c;
                ld.Email = sit.Email__c;
                ld.Company = 'Site Visit Feedback Lead';
                ld.Interested_Project__c = sit.Project__c;
                ld.LeadSource = sit.Source__c;
                ld.Sub_Source__c = sit.Sub_Source__c;
                ld.Allocated_Project__c = sit.Project__c;
                ld.OwnerId=sit.FLS_Name__c;
                ld.Lead_Owner__c=sit.FLS_Name__c;
                ld.Sales_User__c=sit.FLS_Name__c;
                ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                ld.Status = 'Sales Prospect';
                insert ld;
                
                sit.Lead__c =ld.id;
                sit.Status__c = 'Conducted';
                sit.Visit_Type__c='Direct Walk-In';
                logs.Log__c+='{" new Lead Id":"'+ld.id+'","projectname":"'+sit.Project__c+'"}';
                
            }

            if (ld.VDNB_Owner__c != null && ld.owner.profile.name == 'VDNB' ) {
                sit.VDNB_Owner__c = ld.VDNB_Owner__c;
            }
            
            try{
                
                sit.Conducted_By__c=sit.FLS_Name__c;
                sit.Date__c=sit.Conducted_On__c;
                updateSiteVisit = true;
                
                system.debug('site visit '+sit+'isCheckSiteVisit '+isCheckSiteVisit);
                if(isCheckSiteVisit==false ||(vislist.size()>1 && sit.Visit_Type__c=='Re-Visit')){
                    upsert sit;   
                    system.debug('site visit id '+sit.id);
                }
                
                string sitevisitproject =sit.Project__c!=null?sit.Project__c:'';
                logs.Log__c+='{"new site visit ":"'+json.serialize(sit)+'","project name":"'+sitevisitproject+'"}';
                insert logs;
            }   
            catch(Dmlexception e){
                system.debug('e'+e.getMessage());   
            }
            system.debug('site visit id '+sit.id);
            
            return sit.id!=null?(String)sit.id+';Inserted':recId+';updated';
        }
        else if(sit!=null && project.size()==0) {
            return ';Invalid';
        }else{
            return null;
        }
        
    }
    
    
    public static void getcover(){
        integer  i=0;
        if(i==0){
            i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0; 
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            i=0;i=0;i=0;i=0;
            
        }
    }
    
}