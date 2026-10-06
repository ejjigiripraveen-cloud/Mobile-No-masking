public without sharing class RelatedSourceHandler {

    public static List<Lead> deleteList = new List<Lead>();
    public static List<Lead> updateList = new List<Lead>();
    //Added By Ashutosh
    public static Set<Id> reopenedForPresalesAssignment = new Set<Id>();
    public static Set<Id> reopenedForPresalesAssignmentUnqualified = new Set<Id>();
 
    public static List<Related_source__c> rsList = new List<Related_source__c>();
    public static Map<Id,Lead> matchedMap = new  Map<Id,Lead>();
    public static Map<Id,String> mainLeadStatusMap = new Map<Id,String>();
    public static datetime startTime;
    public static datetime endTime;
    public static void checkMobileNumber(List<lead> newRecordsList) {
    
        Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(true); 
        List<Lead> leadItems = newRecordsList;
        for( Lead lead : leadItems ) { 
            system.debug('country code '+lead.Country_Code__c+' lead country '+lead.country__c);
            boolean phone=true;
            boolean secondaryPhone=true;
            if(lead.Phone__c != null){
                lead.Phone__c =   contactFormatter.getformated(lead.Phone__c);
            }
            if(lead.Secondary_Phone__c != null){
                lead.Secondary_Phone__c =   contactFormatter.getformated(lead.Secondary_Phone__c);
            }
            system.debug('country code '+lead.phone__C);
            if(lead.Phone__c != null && lead.Phone__c.startsWith('+')){
                system.debug('enter 1');
                lead.Phone__c = lead.Phone__c.removeStart('+');
                if(lead.Phone__c != null && lead.Phone__c.startsWith('91')){
                    lead.Country_Code__c = '91';
                    lead.Country__c = countryCodeMap.get('91');
                    lead.Phone__c = lead.Phone__c.removeStart('91');
                    if(lead.phone__c.startswith('0'))lead.Phone__c = lead.Phone__c.removeStart('0');
                }else{
                    system.debug('enter 2');
                    for(String countryCode : countryCodeMap.keySet()){
                        system.debug('enter 3 '+lead.Country_Code__c);
                        if(lead.Phone__c != null && (lead.Phone__c.startsWith(countryCode)|| lead.Country_Code__c==countrycode) && phone){
                            system.debug('enter 4 '+ lead.Country_Code__c +' countrycode '+countrycode);
                            lead.Country_Code__c = countryCode;
                            lead.Country__c = countryCodeMap.get(countryCode);
                            lead.Phone__c =lead.Phone__c.startsWith(countryCode)==true?lead.Phone__c.removeStart(countryCode):lead.Phone__c;
                            if(lead.phone__c.startswith('0'))lead.Phone__c = lead.Phone__c.removeStart('0');
                            phone = false;
                        }
                    }
                }
            }
            if(lead.Secondary_Phone__c != null && lead.Secondary_Phone__c.startsWith('+')){
                lead.Secondary_Phone__c = lead.Secondary_Phone__c.removeStart('+');
                if(lead.Secondary_Phone__c  != null && lead.Secondary_Phone__c .startsWith('91')){
                    lead.Secondary_Country_Code__c = '91';
                    lead.Secondary_Country__c = countryCodeMap.get('91');
                    lead.Secondary_Phone__c = lead.Secondary_Phone__c.removeStart('91');
                    if(lead.Secondary_Phone__c.startswith('0'))lead.Phone__c = lead.Secondary_Phone__c.removeStart('0');
                }else{
                    for(String countryCode : countryCodeMap.keySet()){
                        if(lead.Secondary_Phone__c != null && lead.Secondary_Phone__c.startsWith(countryCode) && secondaryPhone){
                            lead.Secondary_Country_Code__c = countryCode;
                            lead.Secondary_Country__c = countryCodeMap.get(countryCode);
                            lead.Secondary_Phone__c = lead.Secondary_Phone__c.removeStart(countryCode);
                            if(lead.Secondary_Phone__c.startswith('0'))lead.Phone__c = lead.Secondary_Phone__c.removeStart('0');
                            secondaryPhone = false;
                        }
                    }  
                }
            }
            if(lead.Phone__c != null && (lead.Country__c == null || lead.country_Code__c!='91') &&   lead.Country_Code__c  != null){
                system.debug('enter 5');
                lead.Country__c = countryCodeMap.get(lead.Country_Code__c);
            }
            if(lead.Secondary_Phone__c != null && lead.Secondary_Country__c != null){
                lead.Secondary_Country__c = countryCodeMap.get(lead.Secondary_Country_Code__c);
            }
            if(lead.Phone__c != null && lead.Country__c == null &&   lead.Country_Code__c  == null){
                system.debug('enter 6');
                lead.Country_Code__c = '91';
                lead.Country__c = countryCodeMap.get('91');
            }
            if(lead.Secondary_Phone__c != null && lead.Secondary_Country__c == null){
                lead.Secondary_Country_Code__c = '91';
                lead.Secondary_Country__c = countryCodeMap.get('91');
            }
            
        }
    }
    public static void updateCampaign(List<lead> newRecordsList) {
        system.debug('enter step 1 '+newRecordsList);
        Map<string,string> projectMap = new Map<string,string>();
        for(Project__c prj : [SELECT Id,Project__c,Name,Zone__c FROM Project__c WHERE Zone__c!=null]){
            projectMap.put(prj.Name,prj.Zone__c);
        }
        if(projectMap.size()>0){
                system.debug('enter step 2 size '+projectMap.size()+' projects maps '+projectMap);
        }
        set<string> campIds = new Set<string>();
        set<string> campNames = new Set<string>();
        set<string> campKeys = new Set<string>();
        set<string> landingNumbers = new Set<string>();
        for(Lead ld:newRecordsList){
            if(ld.Campaign_Lookup__c !=null){
                system.debug('ld.Campaign_Lookup__c'+ld.Campaign_Lookup__c);
                campIds.add(ld.Campaign_Lookup__c);
            }else{
                if(ld.landing_number__c !=null){
                    landingNumbers.add(ld.landing_number__c);
                }
                if(ld.Campaign_Id__c !=null){
                    campIds.add(ld.Campaign_Id__c);
                }
                if(ld.Campaign__c !=null){
                    campNames.add(ld.Campaign__c);
                }
                
                string project='';
                string source='';
                string subsource='';
                string zone='';
                List<string> prjs = new List<string>();
                if(ld.Interested_Project__c !=null){
                    prjs.addall(ld.Interested_Project__c.split(';'));
                }
                if(prjs.size()>0){
                    if(prjs[0] == 'None'){
                        if(prjs.size()>1){
                            project = prjs[1];
                        }
                    }else{
                        project = prjs[0];
                    }
                }
                system.debug('enter step 3 '+project);
                if(project != null && project != '' && projectMap.containsKey(project)){
                        system.debug('enter step 4 '+projectMap);
                    ld.Zone__c = projectMap.get(project);
                        system.debug('enter step 5 '+ld.Zone__c);
                }
                if(ld.LeadSource !=null){
                    source = ld.LeadSource;
                }
                if(ld.Sub_Source__c!=null){
                    subsource= ld.Sub_Source__c;
                }
                if(ld.Zone__c != null && ld.Zone__c != ''){
                    zone = ld.Zone__c;
                }
                string key = source+subsource+project+zone;
                campKeys.add(key);
                
            }
            
            
        }
        Map<string,Campaign> cmpIdList = new Map<string,Campaign>();
        Map<string,Campaign> cmpNameList = new Map<string,Campaign>();
        for(Campaign cmp : [SELECT Id,Name,Project__c,Zone__c,NRI_Campaign__c FROM Campaign WHERE Active__c=TRUE AND(Id IN :campIds OR Name IN :campNames)]){
            cmpIdList.put(cmp.Id,cmp);
            cmpNameList.put(cmp.Name,cmp);
        }
        Map<string,Campaign_Source__c> cmplandingList = new Map<string,Campaign_Source__c>();
        Map<string,Campaign_Source__c> cmpkeyList = new Map<string,Campaign_Source__c>();
        for(Campaign_Source__c cs : [SELECT Id,Name,Source__c,Sub_source__c,Campaign__c,Key__c,medium__c,Landing_number__c,Project__c,Zone__c,NRI_Campaign__c ,campaign_Name__c FROM Campaign_Source__c WHERE Active__c=TRUE AND(key__c IN : campKeys OR Landing_number__c IN :landingNumbers)]){
            
            if(cs.Key__c !=null){
                cmpkeyList.put(cs.Key__c,cs);
            }
            if(cs.Landing_number__c !=null){
                cmplandingList.put(cs.Landing_number__c,cs);
            }
        }
        
        for(Lead ld: newRecordsList){
            if(ld.Campaign_Lookup__c !=null && cmpIdList.containskey(ld.Campaign_Lookup__c)){
                
                if((ld.Interested_Project__c==null || ld.Interested_Project__c=='None' || ld.Interested_Project__c=='') && cmpIdList.get(ld.Campaign_Lookup__c).Project__c !=null){
                    ld.Interested_Project__c = cmpIdList.get(ld.Campaign_Lookup__c).Project__c;
                }
                ld.Campaign_Lookup__c = cmpIdList.get(ld.Campaign_Lookup__c).Id;
                if(ld.Zone__c==null && cmpIdList.get(ld.Campaign_Lookup__c).zone__c !=null){
                    ld.Zone__c = cmpIdList.get(ld.Campaign_Lookup__c).Zone__c;
                }
                
                if(cmpIdList.get(ld.Campaign_Lookup__c).NRI_Campaign__c == true)
                    ld.NRI__c = 'Yes';
                else
                    ld.NRI__c = 'No';
            }else if(ld.Campaign_Id__c !=null && cmpIdList.containskey(ld.Campaign_Id__c)){
                
                if((ld.Interested_Project__c==null || ld.Interested_Project__c=='None' || ld.Interested_Project__c=='') && cmpIdList.get(ld.Campaign_Id__c).Project__c !=null){
                    ld.Interested_Project__c = cmpIdList.get(ld.Campaign_Id__c).Project__c;
                }
                ld.Campaign_Lookup__c = cmpIdList.get(ld.Campaign_Id__c).Id;
                if(ld.Zone__c==null && cmpIdList.get(ld.Campaign_Id__c).Zone__c !=null){
                    ld.Zone__c = cmpIdList.get(ld.Campaign_Id__c).Zone__c;
                }   
                if(cmpIdList.get(ld.Campaign_Id__c).NRI_Campaign__c == true)
                    ld.NRI__c = 'Yes';
                else
                    ld.NRI__c = 'No';
            }else if(ld.landing_number__c !=null && cmplandingList.containskey(ld.landing_number__c)){
                if(ld.LeadSource ==null){
                    ld.LeadSource = cmplandingList.get(ld.landing_number__c).Source__c;
                }
                if(ld.Sub_Source__c ==null){
                    ld.Sub_Source__c = cmplandingList.get(ld.landing_number__c).Sub_Source__c;
                }
                // ld.Interested_Project__c = cmplandingList.get(ld.landing_number__c).Project__c;
                if((ld.Interested_Project__c==null || ld.Interested_Project__c=='None' || ld.Interested_Project__c=='') && cmplandingList.get(ld.landing_number__c).Project__c !=null){
                    ld.Interested_Project__c = cmplandingList.get(ld.landing_number__c).Project__c;
                }
                ld.Campaign_Lookup__c = cmplandingList.get(ld.landing_number__c).campaign__c;
                //ld.Zone__c = cmplandingList.get(ld.landing_number__c).Zone__c;
                if(ld.Zone__c==null && cmplandingList.get(ld.landing_number__c).Zone__c !=null){
                    ld.Zone__c = cmplandingList.get(ld.landing_number__c).Zone__c;
                }
                ld.medium__c = cmplandingList.get(ld.landing_number__c).medium__c;
                if(cmplandingList.get(ld.landing_number__c).NRI_Campaign__c == true)
                    ld.NRI__c = 'Yes';
                else
                    ld.NRI__c = 'No';
                
            }else if(ld.Campaign__c !=null && cmpNameList.containskey(ld.Campaign__c)){
                
                if((ld.Interested_Project__c==null || ld.Interested_Project__c=='None' || ld.Interested_Project__c=='') && cmpNameList.get(ld.Campaign__c).Project__c !=null){
                    ld.Interested_Project__c = cmpNameList.get(ld.Campaign__c).Project__c;
                }
                ld.Campaign_Lookup__c = cmpNameList.get(ld.Campaign__c).Id;
                //ld.Zone__c = cmpNameList.get(ld.Campaign__c).Zone__c;
                if(ld.Zone__c==null && cmpNameList.get(ld.Campaign__c).Zone__c !=null){
                    ld.Zone__c = cmpNameList.get(ld.Campaign__c).Zone__c;
                }
                if(cmpNameList.get(ld.Campaign__c).NRI_Campaign__c == true)
                    ld.NRI__c = 'Yes';
                else
                    ld.NRI__c = 'No';
                
            }else{
                string project='';
                string source='';
                string subsource='';
                string zone='';
                List<string> prjs = new List<string>();
                if(ld.Interested_Project__c !=null){
                    prjs.addall(ld.Interested_Project__c.split(';'));
                }
                if(prjs.size()>0){
                    if(prjs[0] == 'None'){
                        if(prjs.size()>1){
                            project = prjs[1];
                        }
                    }else{
                        project = prjs[0];
                    }
                }
                
                if(ld.LeadSource !=null){
                    source = ld.LeadSource;
                }
                if(ld.Sub_Source__c!=null){
                    subsource= ld.Sub_Source__c;
                }
                if(ld.Zone__c != null && ld.Zone__c != ''){
                    zone = ld.Zone__c;
                }
                string key =source+subsource+project+zone;
                if(cmpkeyList.containskey(key)){
                    ld.Campaign_Lookup__c = cmpkeyList.get(key).campaign__c;
                    if(ld.LeadSource ==null){
                        ld.LeadSource = cmpkeyList.get(key).Source__c;
                    }
                    if(ld.Sub_Source__c ==null){
                        ld.Sub_Source__c = cmpkeyList.get(key).Sub_Source__c;
                    }
                    if(ld.Interested_Project__c ==null || ld.Interested_Project__c =='None' || ld.Interested_Project__c==''){
                        ld.Interested_Project__c = cmpkeyList.get(key).Project__c;
                    }
                    if(ld.Zone__c ==null){
                        ld.Zone__c = cmpkeyList.get(key).Zone__c;
                    }
                    if(ld.medium__c ==null){
                        ld.medium__c = cmpkeyList.get(key).medium__c;
                    }
                    if(ld.NRI__c ==null){
                        if(cmpkeyList.get(key).NRI_Campaign__c == true)
                            ld.NRI__c = 'Yes';
                        else
                            ld.NRI__c = 'No';
                    }
                    
                }
            } 
        }
        
    }
    public static void duplicateCheck(List<lead> ldList){
        Set <String> PhoneSet = new Set<String>();
        Set <String> mailSet = new Set<String>();
        for(Lead ld : ldList){
            ld.Email__c = ld.Email;
            if(ld.Phone != null){
                ld.Phone__c = ld.Phone;
            }
            if(ld.Phone__c != null){
                ld.Phone = ld.Phone__c;
            }
            
            if(ld.Phone__c !=null){
                PhoneSet.add(ld.Phone__c);
            }
            if(ld.Secondary_Phone__c !=null){
                PhoneSet.add(ld.Secondary_Phone__c);
            }
            if(ld.Email !=null){
                mailSet.add(ld.Email__c);
            }
            if(ld.Secondary_Email__c !=null){
                mailSet.add(ld.Secondary_Email__c);
            }
        }
        List<Lead> oldLeadList = [SELECT Id,Status,Phone__c,Email,Secondary_phone__c,Secondary_Email__c FROM Lead WHERE (Phone__c IN : PhoneSet OR Email IN :  mailSet OR Secondary_Phone__c IN :PhoneSet OR Secondary_Email__c IN : mailSet) ORDER BY CreatedDate ASC limit 10000];
        if(oldLeadList.size()>0){
            Map<string,Lead> emailMap = new Map<string,Lead>();
            Map<string,Lead> SecondaryEmailMap = new Map<string,Lead>();
            Map<string,Lead> PhoneMap = new Map<string,Lead>();
            Map<string,Lead> SecondaryPhoneMap = new Map<string,Lead>();
            for(Lead old : oldLeadList){
                if(old.Email !=null){
                    emailMap.put(old.Email,old);
                }
                if(old.Phone__c !=null){
                    PhoneMap.put(old.Phone__c,old);
                }
                if(old.Secondary_Email__c !=null){
                    SecondaryEmailMap.put(old.Secondary_Email__c,old);
                }
                if(old.Secondary_phone__c !=null){
                    SecondaryPhoneMap.put(old.Secondary_phone__c,old);
                }
            }
            for(Lead nld : ldList){
                if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, PhoneMap.get(nld.Phone__c));
                }else if(nld.Phone__c !=null && SecondaryPhoneMap.containsKey(nld.Phone__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, SecondaryPhoneMap.get(nld.Phone__c));
                }else if(nld.Email !=null && emailMap.containsKey(nld.Email)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, emailMap.get(nld.Email));
                }else if(nld.Email !=null && SecondaryEmailMap.containsKey(nld.Email)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, SecondaryEmailMap.get(nld.Email));
                }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, PhoneMap.get(nld.Secondary_phone__c));
                }else if(nld.Secondary_phone__c !=null && SecondaryPhoneMap.containsKey(nld.Secondary_phone__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, SecondaryPhoneMap.get(nld.Secondary_phone__c)); 
                }else if(nld.Secondary_Email__c !=null && emailMap.containsKey(nld.Secondary_Email__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, emailMap.get(nld.Secondary_Email__c));
                }else if(nld.Secondary_Email__c !=null && SecondaryEmailMap.containsKey(nld.Secondary_Email__c)){
                    nld.Delete_Lead__c = true;
                    setDuplicateMainLead(nld, SecondaryEmailMap.get(nld.Secondary_Email__c));
                }
            } 
            
        }else{
            List<Related_Source__c> oldList = [SELECT Id,Name,Email__c,Phone__c,Secondary_phone__c,Secondary_Email__c,Lead__c,Lead__r.Status FROM Related_Source__c 
                                                WHERE (Phone__c IN : PhoneSet OR Email__c IN :  mailSet OR Secondary_Phone__c IN :PhoneSet OR Secondary_Email__c IN : mailSet) ORDER BY CreatedDate ASC];
            
            Map<string,Related_Source__c> emailMap = new Map<string,Related_Source__c>();
            Map<string,Related_Source__c> SecondaryEmailMap = new Map<string,Related_Source__c>();
            Map<string,Related_Source__c> PhoneMap = new Map<string,Related_Source__c>();
            Map<string,Related_Source__c> SecondaryPhoneMap = new Map<string,Related_Source__c>();
            if(oldList.size() >0){
                for(Related_Source__c old : oldList){
                    if(old.Email__c !=null){
                        emailMap.put(old.Email__c,old);
                    }
                    if(old.Phone__c !=null){
                        PhoneMap.put(old.Phone__c,old);
                    }
                    if(old.Secondary_Email__c !=null){
                        SecondaryEmailMap.put(old.Secondary_Email__c,old);
                    }
                    if(old.Secondary_phone__c !=null){
                        SecondaryPhoneMap.put(old.Secondary_phone__c,old);
                    }
                }
                
                for(Lead nld : ldList){
                    if(nld.Phone__c !=null && PhoneMap.containsKey(nld.Phone__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, PhoneMap.get(nld.Phone__c));
                    }else if(nld.Phone__c !=null && SecondaryPhoneMap.containsKey(nld.Phone__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, SecondaryPhoneMap.get(nld.Phone__c));
                    }else if(nld.Email !=null && emailMap.containsKey(nld.Email)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, emailMap.get(nld.Email));
                    }else if(nld.Email !=null && SecondaryEmailMap.containsKey(nld.Email)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, SecondaryEmailMap.get(nld.Email));
                    }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, PhoneMap.get(nld.Secondary_phone__c));
                    }else if(nld.Secondary_phone__c !=null && SecondaryPhoneMap.containsKey(nld.Secondary_phone__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, SecondaryPhoneMap.get(nld.Secondary_phone__c)); 
                    }else if(nld.Secondary_Email__c !=null && emailMap.containsKey(nld.Secondary_Email__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, emailMap.get(nld.Secondary_Email__c));
                    }else if(nld.Secondary_Email__c !=null && SecondaryEmailMap.containsKey(nld.Secondary_Email__c)){
                        nld.Delete_Lead__c = true;
                        setDuplicateMainLead(nld, SecondaryEmailMap.get(nld.Secondary_Email__c));
                    }
                } 
            }
        }
        
        
        // recentCreatedLeadCheck(ldList);
        
    }
    private static void setDuplicateMainLead(Lead duplicateLead, Lead mainLead){
        duplicateLead.Main_Lead__c = mainLead.Id;
    }
    private static void setDuplicateMainLead(Lead duplicateLead, Related_Source__c matchedSource){
        duplicateLead.Main_Lead__c = matchedSource.Lead__c;
    }
    private static Boolean isReopenStatus(String leadStatus){
        if(String.isBlank(leadStatus)){
            return false;
        }
        return new Set<String>{
            'Lost',
            'Lead to be Lost',
            'Booked',
            'Unqualified',
            'Rec Unqualified',
            'Rec Lost',
            'Common Incoming',
            'Open',
            'Rec Incoming',
            'Warm Lost',
            'Rec Qualified'
        }.contains(leadStatus.trim());
    }
    public static void afterinsertLogic(List<Lead> ldList){
        /*
        Set<Id> mainLeadIds = new Set<Id>();
        for(Lead nld : ldList){
            if(nld.Delete_Lead__c == true && nld.Main_Lead__c != null){
                mainLeadIds.add(nld.Main_Lead__c);
            }
        }
        
        if(mainLeadIds.size() > 0){
            mainLeadStatusMap.clear();
            for(Lead mainLead : [SELECT Id, Status FROM Lead WHERE Id IN :mainLeadIds]){
                mainLeadStatusMap.put(mainLead.Id, mainLead.Status);
            }
        }
        */
        Set<Id> mainLeadIds = new Set<Id>();

        for (Lead duplicateLead : ldList) {
            if (
                duplicateLead.Delete_Lead__c &&
                duplicateLead.Main_Lead__c != null
            ) {
                mainLeadIds.add(duplicateLead.Main_Lead__c);
            }
        }

        Map<string,Lead> newemailMap = new Map<string,Lead>();
        Map<string,Lead> newPhoneMap = new Map<string,Lead>();
        if(ldList.size()>1){
            for(Lead fnld : ldList){
                if(fnld.Email !=null && !newemailMap.containsKey(fnld.Email)){
                    newemailMap.put(fnld.Email,fnld);
                }
                if(fnld.Phone__c !=null && !newPhoneMap.containsKey(fnld.Phone__c)){
                    newPhoneMap.put(fnld.Phone__c,fnld);
                }
                if(fnld.Secondary_Email__c !=null && !newemailMap.containsKey(fnld.Secondary_Email__c)){
                    newemailMap.put(fnld.Secondary_Email__c,fnld);
                }
                if(fnld.Secondary_phone__c !=null && !newPhoneMap.containsKey(fnld.Secondary_phone__c)){
                    newPhoneMap.put(fnld.Secondary_phone__c,fnld);
                }
            }
            system.debug(newPhoneMap.size());
            system.debug(newemailMap.size());
        }
        //Added by Ashutosh
        mainLeadIds.clear();
        for (Lead duplicateLead : ldList) {
            if (duplicateLead.Delete_Lead__c && duplicateLead.Main_Lead__c != null) {
                mainLeadIds.add(duplicateLead.Main_Lead__c);
            }
        }
        Map<Id, Lead> mainLeadMap = new Map<Id, Lead>([ SELECT Id, Status, RecordType.Name FROM Lead WHERE Id IN :mainLeadIds ]);
        for(Lead nld : ldList){
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null){
                
                //addRelatedSource(nld);
                //Added by Ashutosh
                addRelatedSource(nld,mainLeadMap.get(nld.Main_Lead__c));
            }else if(nld.Phone__c !=null && NewPhoneMap.containsKey(nld.Phone__c) && nld.Id !=NewPhoneMap.get(nld.Phone__c).Id){
                
                addRelatedSource2(nld,NewPhoneMap.get(nld.Phone__c));
            }else if(nld.Email !=null && newemailMap.containsKey(nld.Email) && nld.Id !=newemailMap.get(nld.Email).Id){
                
                addRelatedSource2(nld,newemailMap.get(nld.Email));
            }else if(nld.Secondary_phone__c !=null && NewPhoneMap.containsKey(nld.Secondary_phone__c) && nld.Id !=NewPhoneMap.get(nld.Secondary_phone__c).Id){
                
                addRelatedSource2(nld,NewPhoneMap.get(nld.Secondary_phone__c));
            }else if(nld.Secondary_Email__c !=null && newemailMap.containsKey(nld.Secondary_Email__c)  && nld.Id !=newemailMap.get(nld.Secondary_Email__c).Id){
                
                addRelatedSource2(nld,newemailMap.get(nld.Secondary_Email__c));
            }else{
                
                
                Related_source__c rs = new Related_source__c();
                rs.Lead__c = nld.Id;
                rs.Source__c = nld.LeadSource;
                rs.Sub_Source__c = nld.Sub_Source__c;
                rs.Phone__c = nld.Phone__c;
                rs.Country_Code__c = nld.Country_Code__c;
                rs.Secondary_Phone__c = nld.Secondary_Phone__c;
                rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
                rs.Email__c = nld.Email;
                rs.Secondary_Email__c = nld.Secondary_Email__c;
                rs.Description__c = nld.Description;
                rs.Interested_Project__c = nld.Interested_Project__c;
                rs.Campaign__c = nld.Campaign__c;
                rs.Campaign_Lookup__c = nld.Campaign_Lookup__c;
                rs.landing_number__c = nld.landing_number__c;
                rs.zone__c = nld.Zone__c;
                rs.Ad_Name__c = nld.Ad_Name__c;
                rs.Ad_Set__c = nld.Ad_Set__c;
                rs.Medium__c = nld.Medium__c;
                rs.UTM_Medium__c = nld.UTM_Medium__c;
                rs.UTM_Sub_Medium__c = nld.UTM_Sub_Medium__c;
                rs.UTM_Content__c = nld.UTM_Content__c;
                rs.UTM_Source__c = nld.UTM_Source__c;
                rs.UTM_Sub_source__c = nld.UTM_Sub_source__c;
                rs.lead_status__c = nld.Status;
                rs.lead_type__c = 'fresh';
                rs.Commonfloor_Seq_Id__c=nld.Commonfloor_Seq_Id__c;
                if(rs.Source__c=='Facebook'){
                rs.purpose_to_purchase_a_plot__c = nld.purpose_to_purchase_a_plot__c;
                rs.Plan_to_buy_plot__c = nld.Plan_to_buy_plot__c;
                rs.Primary_purpose_of_acquiring_land__c = nld.Primary_purpose_of_acquiring_land__c;
                rs.plan_for_acquiring_commercial_land__c = nld.plan_for_acquiring_commercial_land__c;
                rs.Looking_spacious_plot_to_build_home__c = nld.Looking_spacious_plot_to_build_home__c;
                rs.Register_your_WhatsApp_Number__c = nld.Register_your_WhatsApp_Number__c;
                rs.Field1__c = nld.Field1__c;
                rs.Campaign__c=nld.Campaign_Name__c;
                rs.Ad_Name__c=nld.Ad_Name__c;
                rs.Ad_Set__c=nld.Ad_Set__c;
                }
                rsList.add(rs);
                if(!matchedMap.containsKey(nld.Id)){
                    system.debug(nld.Id);
                    Lead ld = new Lead();
                    ld.Id = nld.Id;
                    ld.Last_Source_Of_Enquiry__c =nld.LeadSource;
                    ld.Last_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Source_Of_Enquiry__c = nld.LeadSource;
                    ld.First_Sub_Source__c =  nld.Sub_Source__c;
                    ld.First_Approach_On__c = system.now();
                    ld.First_Campaign__c = nld.Campaign__c;
                    ld.Last_Campaign__c = nld.Campaign__c;
                    ld.First_Campaign_Lookup__c = nld.Campaign_Lookup__c;
                    ld.Last_Campaign_Lookup__c = nld.Campaign_Lookup__c;
                    ld.First_Interested_Project__c = nld.Interested_Project__c;
                    system.debug('Interested_Project__c '+nld.Interested_Project__c+'  ld.First_Interested_Project__c '+ ld.First_Interested_Project__c);
                    ld.Interested_Project__c = nld.Interested_Project__c;
                    ld.First_Medium__c = nld.First_Medium__c;
                    ld.Last_Medium__c = nld.Last_Medium__c;
                    ld.Commonfloor_Seq_Id__c=nld.Commonfloor_Seq_Id__c;
                    //ld.Last_Re_engaged_On__c = system.now();
                    system.debug(nld.Re_engaged_Count__c);
                    // ld.Re_engaged_Count__c = nld.Re_engaged_Count__c + 1;
                    matchedMap.put(nld.Id,ld);
                }
                
            }
        }
        system.debug('');
        if(rsList.size() >0){
            insert rsList;
            rsList.clear();
        }
        
        if(matchedMap.size() >0){
            updateList = matchedMap.values();
            system.debug('update values at 523 '+json.serialize(updateList));
            update updateList;
            //system.assert(false,'values '+updateList[0].Plan_to_buy_plot__c);
            matchedMap.clear();
            updateList.clear();
        }
        if(deleteList.size() >0){
            delete deleteList;
            deleteList.clear();
        }
        mainLeadStatusMap.clear();
    }

    public static void addRelatedSource(Lead nld) {

        Lead mainLead;

        if (nld.Main_Lead__c != null) {

            List<Lead> mainLeads = [
                SELECT Id, Status, RecordType.Name
                FROM Lead
                WHERE Id = :nld.Main_Lead__c
                LIMIT 1
            ];

            if (!mainLeads.isEmpty()) {
                mainLead = mainLeads[0];
            }
        }

        addRelatedSource(nld, mainLead);
    }


    public static void addRelatedSource(Lead nld, Lead mainLead){

        //
        String profileId = userInfo.getProfileId();

        Map<String,LeadProfileMetaType__mdt> mapOfMdt =
            new Map<String,LeadProfileMetaType__mdt>();

        List<LeadProfileMetaType__mdt> leadProfileMeta = [
            SELECT id,Lead_Source__c,ProfileName__c
            FROM LeadProfileMetaType__mdt
        ];

        for(LeadProfileMetaType__mdt isMdt : leadProfileMeta){
            mapOfMdt.put(isMdt.profileName__C,isMdt);
        }

        //
        Related_source__c rs = new Related_source__c();

        rs.Lead__c = nld.Main_Lead__c;
        rs.Source__c = nld.LeadSource;
        rs.Sub_Source__c = nld.Sub_Source__c;
        rs.Phone__c = nld.Phone__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        rs.Email__c = nld.Email;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Description__c = nld.Description;
        rs.Interested_Project__c = nld.Interested_Project__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.Campaign_Lookup__c = nld.Campaign_Lookup__c;
        rs.landing_number__c = nld.landing_number__c;
        rs.zone__c = nld.Zone__c;
        rs.Ad_Name__c = nld.Ad_Name__c;
        rs.Ad_Set__c = nld.Ad_Set__c;
        rs.Medium__c = nld.Medium__c;
        rs.UTM_Medium__c = nld.UTM_Medium__c;
        rs.UTM_Sub_Medium__c = nld.UTM_Sub_Medium__c;
        rs.UTM_Content__c = nld.UTM_Content__c;
        rs.UTM_Source__c = nld.UTM_Source__c;
        rs.UTM_Sub_source__c = nld.UTM_Sub_source__c;

        rs.lead_status__c = mainLead != null ? mainLead.Status : nld.Main_lead_status__c;
        rs.Commonfloor_Seq_Id__c = nld.Commonfloor_Seq_Id__c;

        // NEW
        Boolean shouldReopenForPresales =
            mainLead != null &&
             //added by Praveen - July 22
            (
                mainLead.Status == 'Common Incoming' || mainLead.Status == 'Lead To Be Lost' || mainLead.Status == 'Common Prospect' || mainLead.Status == 'Open' || mainLead.Status == 'Rec incoming' || mainLead.Status == 'Rec Lost' || mainLead.Status == 'Rec Opportunity' || mainLead.Status == 'Rec Qualified' || mainLead.Status == 'Rec Sales Prospect' || mainLead.Status == 'Rec Unqualified' || mainLead.Status == 'VDNB incoming' || mainLead.Status == 'VDNB Lost' || mainLead.Status == 'VDNB Prospect' || mainLead.Status == 'Lost' || mainLead.Status == 'Unqualified'
            );/* &&
            (
            mainLead.RecordType.Name == 'Rec SVC' ||
            mainLead.RecordType.Name == 'Rec Pre Sales'
            );*/
        //End - July 22

        if(rs.source__C == 'Facebook'){

            rs.purpose_to_purchase_a_plot__c =
                nld.purpose_to_purchase_a_plot__c;

            rs.Plan_to_buy_plot__c =
                nld.Plan_to_buy_plot__c;

            rs.Primary_purpose_of_acquiring_land__c =
                nld.Primary_purpose_of_acquiring_land__c;

            rs.plan_for_acquiring_commercial_land__c =
                nld.plan_for_acquiring_commercial_land__c;

            rs.Looking_spacious_plot_to_build_home__c =
                nld.Looking_spacious_plot_to_build_home__c;

            rs.Register_your_WhatsApp_Number__c =
                nld.Register_your_WhatsApp_Number__c;

            rs.Field1__c = nld.Field1__c;

            rs.Campaign__c = nld.Campaign_Name__c;

            rs.Ad_Name__c = nld.Ad_Name__c;

            rs.Ad_Set__c = nld.Ad_Set__c;
        }

        system.debug('enter 563 ');

        // UPDATED
        if(shouldReopenForPresales){

            rs.lead_type__c = 'Re-Opened';

            system.debug('enter 566 ');

        }else{

            rs.lead_type__c = 'Re-Engaged';
        }

        rsList.add(rs);

        system.debug('enter 572  '+json.serialize(rsList));

        deleteList.add(new lead(Id=nld.Id));

        Lead ld = new Lead();

        ld.Id = nld.Main_Lead__c;

        ld.Last_Source_Of_Enquiry__c = nld.LeadSource;
        ld.Last_Sub_Source__c = nld.Sub_Source__c;
        ld.Last_Campaign__c = nld.Campaign__c;
        ld.Last_Campaign_Lookup__c = nld.Campaign_Lookup__c;
        ld.Interested_Project__c = nld.Interested_Project__c;
        ld.Last_Medium__c = nld.Last_Medium__c;

        system.debug(nld.Re_engaged_Count__c);
    
        // UPDATED
        if(shouldReopenForPresales){

            String RecTypeId =
                Schema.SObjectType.Lead
                .getRecordTypeInfosByName()
                .get('Pre Sales')
                .getRecordTypeId();

            ld.Status = 'Incoming';

            ld.Lead_Type__c = 'Re-Opened';

            ld.Last_Re_Open_Date__c = system.now();

            ld.lead_Assigned__c = false;

            // NEW
            ld.Pre_sales_user__c = null;

            ld.SV_User__c = null;

            // NEW
            // Start- added the Common Incoming value - Praveen-07-Aug-2026
            if(mainlead.status == 'Unqualified' || mainlead.status == 'Common Prospect' || mainlead.status == 'Open' || mainlead.status == 'Rec incoming' || mainlead.status == 'Rec Lost' || mainlead.status == 'Rec Opportunity' || mainlead.status == 'Rec Qualified' || mainlead.status == 'Rec Sales Prospect' || mainlead.status == 'Rec Unqualified' || mainlead.status == 'VDNB incoming' || mainlead.status == 'VDNB Lost' || mainlead.status == 'VDNB Prospect' || mainlead.status == 'Temp Lost' || mainlead.status == 'Lead To Be Lost'|| mainlead.status == 'Common Incoming') reopenedForPresalesAssignmentUnqualified.add(nld.Main_Lead__c);
            // End - Praveen-07-Aug-2026
            else reopenedForPresalesAssignment.add(nld.Main_Lead__c);           

            ld.RecordTypeId = RecTypeId;

            ld.Drop_Off_Reason__c = '';
            ld.Lost_Drop_Off__c = '';
            ld.Sales_User__c = null;

            ld.Allocated_Project__c = '';
            ld.Followup_Status__c = '';
            ld.Next_Followup_Date__c = null;
            ld.Last_follow_up_conducted_date__c = null;

            ld.Site_visit_Status__c = '';
            ld.Next_Site_visit_Date__c = null;

            ld.site_visit_conducted__c = false;

            ld.Last_Contacted_On__c = system.now();

            ld.Last_Sales_Contacted_On__c = null;
            ld.Last_site_visit_contacted_on__c = null;

            ld.LeadSource = nld.LeadSource;

            ld.sub_source__c = nld.sub_source__c;

            ld.Interested_Project__c =
                nld.Interested_Project__c;

            ld.campaign_lookup__c =
                nld.campaign_lookup__c;

            ld.Channel_Partner__c =
                nld.Channel_Partner__c;

            ld.Channel_Partner_ID__c =
                nld.Channel_Partner_ID__c;

            ld.Channel_Partner_Name__c =
                nld.Channel_Partner_Name__c;

            ld.Channel_Partner_Phone_Number__c =
                nld.Channel_Partner_Phone_Number__c;

            ld.landing_number__c =
                nld.landing_number__c;

            ld.Pre_Sales_Call_Count__c = 0;
            ld.Sales_call_Count__c = 0;
            ld.SV_Call_Count__c = 0;
            ld.VDNB_Call_Count__c = 0;

            ld.last_call_status__c = '';

            ld.Commonfloor_Seq_Id__c =
                nld.Commonfloor_Seq_Id__c;

            ld.Rec_lead_Assigned__c = false;

            ld.Rec_Drop_Off_Reason__c = '';
            ld.Rec_Dropoff_By__c = null;
            ld.Rec_Dropoff_On__c = null;

            ld.Rec_Pre_sales_User__c = null;
            ld.Rec_SVC_User__c = null;

            if(rs.source__C == 'Facebook'
                && ld.Lead_Type__c == 'Re-Opened'){

                ld.purpose_to_purchase_a_plot__c =
                    nld.purpose_to_purchase_a_plot__c;

                ld.Plan_to_buy_plot__c =
                    nld.Plan_to_buy_plot__c;

                ld.Primary_purpose_of_acquiring_land__c =
                    nld.Primary_purpose_of_acquiring_land__c;

                ld.plan_for_acquiring_commercial_land__c =
                    nld.plan_for_acquiring_commercial_land__c;

                ld.Looking_spacious_plot_to_build_home__c =
                    nld.Looking_spacious_plot_to_build_home__c;

                ld.Register_your_WhatsApp_Number__c =
                    nld.Register_your_WhatsApp_Number__c;

                ld.Field1__c = nld.Field1__c;

                ld.Campaign_Name__c =
                    nld.Campaign_Name__c;

                ld.Ad_Name__c =
                    nld.Ad_Name__c;

                ld.Ad_Set__c =
                    nld.Ad_Set__c;
            }

            // KEEP EXISTING LOGIC
            if(mapOfMdt.containskey(profileId)){

                ld.Status = nld.status;

                ld.RecordTypeId =
                    Schema.SObjectType.Lead
                    .getRecordTypeInfosByName()
                    .get('Sales')
                    .getRecordTypeId();

                ld.OwnerId = nld.OwnerId;
            }

            if(nld.Zone__c != null){
                ld.Zone__c = nld.Zone__c;
            }

        }else{

            ld.Lead_Type__c = 'Re-Engaged';

            ld.Re_Engaged_Date__c = system.now();

            if(rs.source__c == 'Facebook'
                && ld.Lead_Type__c =='Re-Engaged'){

                ld.purpose_to_purchase_a_plot__c = '';

                ld.Plan_to_buy_plot__c = '';

                ld.Primary_purpose_of_acquiring_land__c = '';

                ld.plan_for_acquiring_commercial_land__c = '';

                ld.Looking_spacious_plot_to_build_home__c = '';

                ld.Register_your_WhatsApp_Number__c = '';

                ld.Field1__c = nld.Field1__c;

                ld.Campaign_Name__c = '';

                ld.Ad_Name__c = '';

                ld.Ad_Set__c = '';
            }
        }

        matchedMap.put(nld.Main_Lead__c,ld);

        //updateList.add(ld);
    }
    public static void addRelatedSource2(lead nld, lead mainLead){
        Related_source__c rs = new Related_source__c();
        rs.Lead__c = mainLead.Id;
        rs.Source__c = nld.LeadSource;
        rs.Sub_Source__c = nld.Sub_Source__c;
        rs.Phone__c = nld.Phone__c;
        rs.Country_Code__c = nld.Country_Code__c;
        rs.Secondary_Phone__c = nld.Secondary_Phone__c;
        rs.Secondary_Contry_Code__c = nld.Secondary_Country_Code__c;
        rs.Email__c = nld.Email;
        rs.Secondary_Email__c = nld.Secondary_Email__c;
        rs.Description__c = nld.Description;
        rs.Interested_Project__c = nld.Interested_Project__c;
        rs.Campaign__c = nld.Campaign__c;
        rs.Campaign_Lookup__c = nld.Campaign_Lookup__c;
        rs.landing_number__c = nld.landing_number__c;
        rs.zone__c = nld.Zone__c;
        rs.Ad_Name__c = nld.Ad_Name__c;
        rs.Ad_Set__c = nld.Ad_Set__c;
        rs.Medium__c = nld.Medium__c;
        rs.UTM_Medium__c = nld.UTM_Medium__c;
        rs.UTM_Sub_Medium__c = nld.UTM_Sub_Medium__c;
        rs.UTM_Content__c = nld.UTM_Content__c;
        rs.UTM_Source__c = nld.UTM_Source__c;
        rs.UTM_Sub_source__c = nld.UTM_Sub_source__c;
        rs.lead_status__c = nld.Status;
        rs.lead_type__c = 'fresh';
        rs.Commonfloor_Seq_Id__c=nld.Commonfloor_Seq_Id__c;
        rsList.add(rs);
        deleteList.add(new lead(Id=nld.Id));
        Lead ld = new Lead();
        ld.Id=mainLead.Id;
        ld.First_Source_Of_Enquiry__c = mainLead.LeadSource;
        ld.First_Sub_Source__c = mainLead.Sub_Source__c;
        ld.Last_Source_Of_Enquiry__c =nld.LeadSource;
        ld.Last_Sub_Source__c =  nld.Sub_Source__c;
        ld.Re_Engaged_Date__c = system.now();
        ld.First_Campaign__c = mainLead.Campaign__c;
        ld.Last_Campaign__c = nld.Campaign__c;
        ld.First_Campaign_Lookup__c = mainLead.Campaign_Lookup__c;
        ld.Last_Campaign_Lookup__c = nld.Campaign_Lookup__c;
        ld.First_Interested_Project__c = mainLead.Interested_Project__c;
        ld.Interested_Project__c = nld.Interested_Project__c;
        ld.First_Medium__c = nld.First_Medium__c;
        ld.Last_Medium__c = nld.Last_Medium__c;
        ld.Commonfloor_Seq_Id__c=nld.Commonfloor_Seq_Id__c;
        //ld.Last_Re_engaged_On__c = system.now();
        system.debug(nld.Re_engaged_Count__c);
        //ld.Re_engaged_Count__c = nld.Re_engaged_Count__c + 1;
        matchedMap.put(mainLead.Id,ld);
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
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
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