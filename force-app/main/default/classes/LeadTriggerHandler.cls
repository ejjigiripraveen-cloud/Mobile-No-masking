public without sharing class LeadTriggerHandler {
    /*public static List<Related_Source__c> sourceList = new List<Related_Source__c>(); 
    public static List<Related_Source__c> updateSourceList = new List<Related_Source__c>(); 
    public static List<Lead> leadUpdateList = new List<Lead>(); 
    public static List<Lead> leadReopenUpdateList = new List<Lead>(); 
    public static List<Lead> leadDeleteList = new List<Lead>(); 
    public static List<Lead> leadAssignList = new List<Lead>();
    public static Map<Id,Opportunity> opportunityMap  = new  Map<Id,Opportunity> ();  */
    
    public static void checkMobileNumber(List<lead> newRecordsList) {
        Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(true); 
        List<Lead> leadItems = newRecordsList;
        for( Lead lead : leadItems ) { 
             boolean phone=true;
            boolean secondaryPhone=true;
            if(lead.Phone__c != null){
                lead.Phone__c =   contactFormatter.getformated(lead.Phone__c);
            }
            
            if(lead.Phone__c != null && lead.Phone__c.startsWith('+')){
                lead.Phone__c = lead.Phone__c.removeStart('+');
                if(lead.Phone__c != null && lead.Phone__c.startsWith('91')){
                    lead.Country_Code__c = '91';
                    lead.Country__c = countryCodeMap.get('91');
                    lead.Phone__c = lead.Phone__c.removeStart('91');
                }else{
                    
                    for(String countryCode : countryCodeMap.keySet()){
                        if(lead.Phone__c != null && lead.Phone__c.startsWith(countryCode) && phone){
                            lead.Country_Code__c = countryCode;
                            lead.Country__c = countryCodeMap.get(countryCode);
                            lead.Phone__c = lead.Phone__c.removeStart(countryCode);
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
                }else{
                    for(String countryCode : countryCodeMap.keySet()){
                        if(lead.Secondary_Phone__c != null && lead.Secondary_Phone__c.startsWith(countryCode) && secondaryPhone){
                            lead.Secondary_Country_Code__c = countryCode;
                            lead.Secondary_Country__c = countryCodeMap.get(countryCode);
                            lead.Secondary_Phone__c = lead.Secondary_Phone__c.removeStart(countryCode);
                            secondaryPhone = false;
                        }
                    }  
                }
            }
            if(lead.Phone__c != null && lead.Country__c == null &&   lead.Country_Code__c  == null){
                lead.Country_Code__c = '91';
                lead.Country__c = countryCodeMap.get('91');
            }
            if(lead.Secondary_Phone__c != null && lead.Secondary_Country__c == null){
                lead.Secondary_Country_Code__c = '91';
                lead.Secondary_Country__c = countryCodeMap.get('91');
            }
        }
    }
     public static void duplicateCheck(List<lead> ldList){
        Set <String> PhoneSet = new Set<String>();
        Set <String> mailSet = new Set<String>();
        
        
        for(Lead ld : ldList){
            ld.Email__c = ld.Email;
            ld.Phone = ld.Phone__c;
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
        
        List<Lead> oldList = [SELECT Id,Name,Email,Email__c,Phone,Phone__c,Secondary_phone__c,Secondary_Email__c FROM Lead 
                              WHERE (Phone__c IN : PhoneSet OR Email IN :  mailSet OR Secondary_Phone__c IN :PhoneSet OR Secondary_Email__c IN : mailSet)];
        
        Map<string,Lead> emailMap = new Map<string,Lead>();
        Map<string,Lead> SecondaryEmailMap = new Map<string,Lead>();
        Map<string,Lead> PhoneMap = new Map<string,Lead>();
        Map<string,Lead> SecondaryPhoneMap = new Map<string,Lead>();
        if(oldList.size() >0){
            for(Lead old : oldList){
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
                    nld.Main_Lead__c = PhoneMap.get(nld.Phone__c).Id;
                }else if(nld.Phone__c !=null && SecondaryPhoneMap.containsKey(nld.Phone__c)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Phone__c).Id;
                }else if(nld.Secondary_phone__c !=null && PhoneMap.containsKey(nld.Secondary_phone__c)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c).Id;
                }else if(nld.Secondary_phone__c !=null && SecondaryPhoneMap.containsKey(nld.Secondary_phone__c)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = PhoneMap.get(nld.Secondary_phone__c).Id;
                }else if(nld.Email !=null && emailMap.containsKey(nld.Email)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = emailMap.get(nld.Email).Id;
                }else if(nld.Email !=null && SecondaryEmailMap.containsKey(nld.Email)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = SecondaryEmailMap.get(nld.Email).Id;
                }else if(nld.Secondary_Email__c !=null && emailMap.containsKey(nld.Secondary_Email__c)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = emailMap.get(nld.Secondary_Email__c).Id;
                }else if(nld.Secondary_Email__c !=null && SecondaryEmailMap.containsKey(nld.Secondary_Email__c)){
                    nld.Delete_Lead__c = true;
                    nld.Main_Lead__c = SecondaryEmailMap.get(nld.Secondary_Email__c).Id;
                }
            } 
        }
        
       /*  for ( integer i=0;i<ldList.size();i++){ 
          Lead l1 = ldList[i];
           for ( integer  j=i+1;j<ldList.size();j++){ 
                 
                   Lead l2 = ldList[j];
                    
                   if(l1.email  != null  && (  l1.email == l2.email  ||  l1.email == l2.Secondary_Email__c ) ){
                       l2.delete_lead__c = true;

                   }
                     
                   if(l1.email__c  != null  && (  l1.email__c  == l2.email__c  ||  l1.email__c   == l2.Secondary_Email__c ) ){
                       l2.delete_lead__c = true;
                   }
                   if(l1.Secondary_Email__c  != null  && (  l1.Secondary_Email__c  == l2.email  ||  l1.Secondary_Email__c  == l2.Secondary_Email__c ) ){
                       l2.delete_lead__c = true;
                   } 
                   if(l1.Phone__c != null  && (  l1.Phone__c == l2.Phone__c ||  l1.Phone__c == l2.Secondary_Phone__c) ){
                       l2.delete_lead__c = true;
                   }
                   if(l1.Secondary_Phone__c != null  && (  l1.Secondary_Phone__c  == l2.Phone__c  ||  l1.Secondary_Phone__c  == l2.Secondary_Phone__c  ) ){
                       l2.delete_lead__c = true;
                   } 
           }
           system.debug(l1 .delete_lead__c );
        
        }*/
       for(Lead fnld : ldList){
         if(!fnld.Delete_Lead__c){
            for(Lead snld : ldList){
				if(snld.Id != fnld.Id && fnld.email !=null && (fnld.email == snld.email || fnld.email == snld.Secondary_Email__c)){
					fnld.Delete_Lead__c = true;
                    fnld.Main_Lead__c = snld.Id;
				}else if(snld.Id != fnld.Id && fnld.Secondary_Email__c !=null && (fnld.Secondary_Email__c == snld.email || fnld.Secondary_Email__c == snld.Secondary_Email__c)){
					fnld.Delete_Lead__c = true;
                    fnld.Main_Lead__c = snld.Id;
				}else if(snld.Id != fnld.Id && fnld.Phone__c !=null && (fnld.Phone__c == snld.Phone__c || fnld.Phone__c == snld.Secondary_Phone__c)){
					fnld.Delete_Lead__c = true;
                    fnld.Main_Lead__c = snld.Id;
				}else if(snld.Id != fnld.Id && fnld.Secondary_Phone__c !=null && (fnld.Secondary_Phone__c == snld.Phone__c || fnld.Secondary_Phone__c == snld.Secondary_Phone__c)){
					fnld.Delete_Lead__c = true;
                    fnld.Main_Lead__c = snld.Id;
				}
            }   
           }
            
        }
    }
    public static void afterinsertLogic(List<Lead> ldList){
        List<Lead> deleteList = new List<Lead>();
        List<Lead> updateList = new List<Lead>();
         List<Related_source__c> rsList = new List<Related_source__c>();
        for(Lead nld : ldList){
            if(nld.Delete_Lead__c && nld.Main_Lead__c !=null){
                Related_source__c rs = new Related_source__c();
                rs.Lead__c = nld.Main_Lead__c;
                rs.Source__c = nld.LeadSource;
                rs.Sub_Source__c = nld.Sub_Source__c;
                rsList.add(rs);
                deleteList.add(new lead(Id=nld.Id));
                Lead ld = new Lead();
                ld.Id=nld.Main_Lead__c;
                ld.Last_Source_Of_Enquiry__c =nld.LeadSource;
                ld.Last_Sub_Source__c =  nld.Sub_Source__c;
                ld.Re_Engaged_Date__c = system.now();
                if(nld.Main_lead_status__c == 'Lost' || nld.Main_lead_status__c=='Booked' || nld.Main_lead_status__c=='Unqualified'){
                    string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                   ld.status ='Incoming';
                    ld.lead_Assigned__c=false;
                    ld.RecordTypeId=RecTypeId;
                }
                updateList.add(ld);
            }else{
                 Related_source__c rs = new Related_source__c();
                rs.Lead__c = nld.Id;
                rs.Source__c = nld.LeadSource;
                rs.Sub_Source__c = nld.Sub_Source__c;
                rsList.add(rs);
                 Lead ld = new Lead();
                //ld.Id=nld.Main_Lead__c;
                ld.Id = nld.Id;
                ld.Last_Source_Of_Enquiry__c =nld.LeadSource;
                ld.Last_Sub_Source__c =  nld.Sub_Source__c;
                ld.First_Source_Of_Enquiry__c = nld.LeadSource;
                 ld.First_Sub_Source__c =  nld.Sub_Source__c;
                ld.First_Approach_On__c = system.now();
                updateList.add(ld);
            }
        }
        if(rsList.size() >0){
            insert rsList;
        }
        if(updateList.size() >0){
            update updateList;
        }
        if(deleteList.size() >0){
           delete deleteList; 
        }
    }
    /*public static void leadAssignmentLogic(List<lead> newRecordsList) {  
        sourceList = new List<Related_Source__c>();
        updateSourceList = new List<Related_Source__c>();
        leadUpdateList = new List<Lead>();
        leadAssignList = new List<Lead>(); 
        
        Map<string,String> emailMobiletoLeadIdMap = new  Map<string,String>();
        List<sobject> matchingRecords =  DuplicateContactManager.matchAllRecords(newRecordsList);
        system.debug(matchingRecords);
        List<string> oldEmailMobiles = new List<string>();
        
        for(sobject so : matchingRecords ){
            
            lead oldlead   ;
            Opportunity  oldOpportunity  ;
            if(so.getSObjectType().getDescribe().getName() ==   'Lead'   ){ 
                oldlead  = (lead)so;  
            }
            
            if( oldlead != null){ 
                if(  oldlead.Phone__c != null){ 
                    oldEmailMobiles.add(oldlead.Phone__c); 
                    emailMobiletoLeadIdMap.put(oldlead.Phone__c,oldlead.Id);
                }
                if(  oldlead.Email__c != null){ 
                    oldEmailMobiles.add(oldlead.Email__c);
                    emailMobiletoLeadIdMap.put(oldlead.Email__c,oldlead.Id);
                }
                if(  oldlead.secondary_email__c != null){ 
                    oldEmailMobiles.add(oldlead.secondary_email__c);
                    emailMobiletoLeadIdMap.put(oldlead.secondary_email__c,oldlead.Id);
                }
                if(  oldlead.secondary_phone__c != null){ 
                    oldEmailMobiles.addAll(  contactFormatter.geAllPhoneNumbers(oldlead.secondary_phone__c) );
                    for(string s:  contactFormatter.geAllPhoneNumbers(oldlead.secondary_phone__c)){
                        emailMobiletoLeadIdMap.put(s,oldlead.Id);
                    }
                }
                leadUpdateList.add(oldlead);
            }
            
        } 
        Decimal Timestamp = system.now().getTime(); 
        Integer i=0;
        boolean leadExisit = false;
        for(Lead l :   newRecordsList){  
            l.Timestamp__c =   Timestamp+i;
            i++;            
            if( l.phone__c != null && oldEmailMobiles.contains(l.phone__c) ){
                leadDeleteList.add(l);  
                leadExisit = true;
                sourceList.add( addSource( emailMobiletoLeadIdMap.get(l.phone__c), l.Leadsource,l.First_Sub_Source__c, false, l.Interested_Project__c) ) ;
            }else
                if( l.email__c != null &&  oldEmailMobiles.contains(l.email__c) ){
                    leadDeleteList.add(l);
                    leadExisit = true;
                    sourceList.add( addSource( emailMobiletoLeadIdMap.get(l.phone__c), l.Leadsource,l.First_Sub_Source__c, false, l.Interested_Project__c)  );
                }else
                    if(  l.secondary_email__c  != null &&  oldEmailMobiles.contains(l.secondary_email__c) ){
                        leadDeleteList.add(l);
                        leadExisit = true;
                        sourceList.add( addSource(  emailMobiletoLeadIdMap.get(l.phone__c), l.Leadsource,l.First_Sub_Source__c, false, l.Interested_Project__c) );
                    }else
                        if(  l.secondary_phone__c != null){
                            for(string s: contactFormatter.geAllPhoneNumbers(l.secondary_phone__c)){
                                if( oldEmailMobiles.contains( s) ){
                                    leadDeleteList.add(l);
                                    leadExisit = true;
                                    sourceList.add( addSource(emailMobiletoLeadIdMap.get(l.phone__c), l.Leadsource,l.First_Sub_Source__c, false, l.Interested_Project__c) );
                                }
                            }  
                        }
            if(!leadExisit){ 
                leadAssignList.add(l);
            } 
            
        } 
       // RoundRobinHandler.setRROwner(leadAssignList,'Pre Sales'); 
    } */    
   /* public static Related_Source__c addSource(String recordId,String sourceName, string subSource, boolean isFirstSource,string Interested_Project){
        Related_Source__c newSource = new Related_Source__c(); 
        User u = [ select contactId, contact.Accountid from user where id=: userinfo.getuserId()];
        if(u.contactId != null && u.contact.Accountid != null){
            newSource.Account__c = [ select contact.Accountid from user where id=: userinfo.getuserId()].contact.Accountid;
        }
        newSource.status__c =  isFirstSource ? 'Active' : 'Duplicate';
        newSource.Source__c = sourceName;
        newSource.Sub_Source__c = subSource;            
        newSource.Submission_Date__c = Datetime.now();
        newSource.Interested_Project__c = Interested_Project;
        newSource.Lead__c = recordId;        
        return newSource;
    }*/
    
    
    //After Insert delete duplicate leads, add new source, add campaign member
   /* public static void leadAfterInsertLogic(List<lead> newRecordsList) {   
        List<lead> leadinsertedList = [select id,Status ,timestamp__c from lead where id in: newRecordsList];
        for(Lead L: leadAssignList){
            for(lead ld : leadinsertedList){
                if( l.timestamp__c == ld.timestamp__c){
                    sourceList.add( addSource( ld.Id  , l.Leadsource,l.First_Sub_Source__c, true, l.Interested_Project__c) );
                }  
            }
        }
        for(Lead L: leadUpdateList){
            if(l.status == 'Closed - Not Converted' ){
                l.status = 'Re - Opened'; 
            }
            if(l.status == 'Closed Converted' && opportunityMap.get(l.ConvertedOpportunityId).stagename == 'Closed Lost' ){
                l.status = 'Re - Opened';
            }
        } 
        insert sourcelist;
        update leadUpdateList;
        delete leadDeleteList;
        
        
    } */
   
    
}