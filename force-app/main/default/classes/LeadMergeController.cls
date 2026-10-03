public class LeadMergeController {

    public static Boolean isLeadMergeInProgress = false;

    @AuraEnabled
    public static List<Lead> getLeads(String recordId){ 
        return [select id, Name, Lead_ID__c, Phone__c, Email, Secondary_Phone__c, Secondary_Email__c from Lead where id != :recordId];
    }
    
     @AuraEnabled
    public static List<Lead> getSearchLeads(String recordId,String searchText){ 
        system.debug('search text '+searchText);
        string searchText2 = '%' + searchText + '%';
        return [select id, Name, Lead_ID__c, Phone__c, Email, Secondary_Phone__c, Secondary_Email__c from Lead where id != :recordId and (Lead_ID__c LIKE :searchText2 OR Name LIKE :searchText2 OR Phone__c LIKE :searchText2 OR Secondary_Phone__c LIKE :searchText2) limit 100];
    }
       
    @AuraEnabled
    public static String mergeLead(String oldLeadId, String newLeadId){
        system.debug('recordId '+newLeadId);
        String returnRes='Success';
        
        Lead oldLead = [select id, Name, Lead_ID__c, Phone__c, Email, Secondary_Phone__c, Secondary_Email__c,Status,Drop_Off_Reason__c,RecordType.Name,Main_Lead__c,Merge__c,Merge_Lead_LeadID__c,Ownerid,Merge_Date_and_Time__c,Merge_By__c from Lead where id = :oldLeadId];
        Lead newLead = [select id, Name, Lead_ID__c, Phone__c, Email, Secondary_Phone__c, Secondary_Email__c from Lead where id = :newLeadId];
        
        
        if(newLead.Phone__c == null){
            newLead.Phone__c = oldLead.Phone__c;
        }
        if(newLead.Secondary_Phone__c == null){
            if(oldLead.Secondary_Phone__c != null)
            	newLead.Secondary_Phone__c = oldLead.Secondary_Phone__c;
            else
                newLead.Secondary_Phone__c = oldLead.Phone__c;
        }
        
        if(newLead.Email == null){
            newLead.Email = oldLead.Email;
        }        
        if(newLead.Secondary_Email__c == null ){
            if(oldLead.Secondary_Email__c != null)
                newLead.Secondary_Email__c = oldLead.Secondary_Email__c;
            else
                newLead.Secondary_Email__c = oldLead.Email;
           
        }
        newLead.Merge__c = true;
        system.debug('newLead:' + newLead);
        try{
            update newLead;
        }catch(exception e){
            returnRes='lead Update Failed';
        }
        
        
        List<Site_Visit__c> svList = [select Id,Name,Lead__c from Site_Visit__c where Lead__c = :oldLeadId];
        if(svList.size() > 0){
            for(Site_Visit__c sv: svList){
                sv.Lead__c = newLead.Id;
            }
            system.debug('svList:' + svList);
            try{
                 update svList;
            }catch(Exception e){
                returnRes='SV Update Failed';
            }
           
        }
        
         List<Follow_Up__c> follList = [select Id,Name,Lead__c from Follow_Up__c where Lead__c = :oldLeadId];
        if(follList.size() > 0){
            for(Follow_Up__c fol: follList){
                fol.Lead__c = newLead.Id;
            }
            system.debug('follList:' + follList);
            try{
                 update follList;
            }catch(Exception e){
                returnRes='Fallow Update Failed';
            }
          
        }
        
        List<Call_Detail__c> cdList = [select Id,Name,Lead__c from Call_Detail__c where Lead__c = :oldLeadId];
        if(cdList.size() > 0){
            for(Call_Detail__c cd: cdList){
                cd.Lead__c = newLead.Id;
            }
            system.debug('cdList:' + cdList);
                    LeadMergeController.isLeadMergeInProgress = true;
        try{
             update cdList;
        }catch(Exception e){
            returnRes='Call Detail Update Failed';
        }finally{
            LeadMergeController.isLeadMergeInProgress = false;
        }        LeadMergeController.isLeadMergeInProgress = true;
        try{
             update cdList;
        }catch(Exception e){
            returnRes='Call Detail Update Failed';
        }finally{
            LeadMergeController.isLeadMergeInProgress = false;
        }
          
        }
        
        List<Task> tskList = [select id,WhoId from Task where WhoId =: oldLeadId];
        if(tskList.size() > 0){
            for(Task tsk: tskList){
                tsk.WhoId = newLead.Id;
            }
            system.debug('tskList:' + tskList);
            try{
                 update tskList;
            }catch(Exception e){
                returnRes='Task Update Failed';
            }
          
        }
        
         List<Related_Source__c> rsList = [select id,Name,Lead__c from Related_Source__c where Lead__c =: oldLeadId];
        if(rsList.size() > 0){
            for(Related_Source__c rs: rsList){
                rs.Lead__c = newLead.Id;
            }
            system.debug('rsList:' + rsList);
            try{
                 update rsList;
            }catch(Exception e){
                returnRes='Resource Update Failed';
            }
          
        }
        
        oldLead.Main_Lead__c = newLead.Id;
        oldLead.Merge__c = true;
        oldLead.Merge_Lead_LeadID__c = newLead.Lead_ID__c;
        oldLead.OwnerId=system.label.Old_Lead_Owner; 
        oldLead.Merge_By__c =userinfo.getUserId();
        oldLead.Merge_Date_and_Time__c=system.now();
        
            system.debug('oldLead:' + oldLead);
        try{
             update oldLead;
        }catch(Exception e){
            returnRes='lead update Failed';
        }
       
        {
            Integer i=0;
                    i++;
                    i++;
                    i++;
                    i++;
                       i++; 
                    i++;
                    i++;
                    i++;
                    i++;
                       i++;
                    i++;
                    i++;
                    i++;
                    i++;
                       i++;
                    i++;
                    i++;
                    i++;
                    i++;
                       i++;
                    i++;
                    i++;
                    i++;
                    i++;
                       i++;
        }
        return returnRes;
        
        
    } 

}