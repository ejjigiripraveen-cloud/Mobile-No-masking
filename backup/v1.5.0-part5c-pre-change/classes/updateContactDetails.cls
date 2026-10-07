public class updateContactDetails {
    @AuraEnabled
    public static Lead getcontactdetails(string recId){
        Lead ld = [SELECT Id,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email,Country__c,Country_Code__c,Secondary_Country_Code__c,Secondary_Country__c FROM Lead WHERE Id=:recId];
        return ld;
    }
     @AuraEnabled
    public static string savecontactdetails(string recId,string phone, string email, string secondaryPhone, string secondaryEmail){
       system.debug(phone+' '+email+' '+secondaryPhone+' '+secondaryEmail);
       UserRecordAccess usaccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userinfo.getUserId() AND RecordId =: recId];
        string returnmsg;
        if(usaccess.HasEditAccess){
            Lead old = [SELECT Id,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email FROM Lead WHERE Id=:recId];
        if(phone != old.Phone__c || email != old.Email || secondaryPhone !=old.Secondary_Phone__c || secondaryEmail != old.Secondary_Email__c){
            Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(true); 
         if(phone != null){
                phone =   contactFormatter.getformated(phone);
            }
             if(secondaryPhone != null){
                secondaryPhone =   contactFormatter.getformated(secondaryPhone);
            }
        boolean phonematched=true;
        boolean secondaryPhoneMatched=true;
         if(phone != null && phone.startsWith('+')){
                phone = phone.removeStart('+');
                if(phone != null && phone.startsWith('91')){
                    phone = phone.removeStart('91');
                }else{
                    
                    for(String countryCode : countryCodeMap.keySet()){
                        if(phone != null && phone.startsWith(countryCode) && phonematched){
                            phone = phone.removeStart(countryCode);
                            phonematched = false;
                        }
                    }
                }
            }
        if(secondaryPhone != null && secondaryPhone.startsWith('+')){
                secondaryPhone = secondaryPhone.removeStart('+');
                if(secondaryPhone  != null && secondaryPhone.startsWith('91')){
                    secondaryPhone= secondaryPhone.removeStart('91');
                }else{
                    for(String countryCode : countryCodeMap.keySet()){
                        if(secondaryPhone != null && secondaryPhone.startsWith(countryCode) && secondaryPhoneMatched){
                          
                            secondaryPhone = secondaryPhone.removeStart(countryCode);
                            secondaryPhoneMatched = false;
                        }
                    }  
                }
        }
            if(phone != old.Phone__c || email != old.Email || secondaryPhone !=old.Secondary_Phone__c || secondaryEmail != old.Secondary_Email__c){
                set<string> PhoneSet = new set<string>();
                set<string> mailSet = new set<string>();
                List<Lead> matchLead;
                if(phone !=null &&phone !=''){
                    PhoneSet.add(phone);
                }
                if(secondaryPhone !=null &&secondaryPhone !=''){
                    PhoneSet.add(secondaryPhone);
                }
                if(email !=null && email !=''){
                    mailSet.add(email);
                }
                if(secondaryEmail  !=null && secondaryEmail !=''){
                    mailSet.add(secondaryEmail);
                }
                system.debug(PhoneSet.size()+' '+PhoneSet);
                system.debug(mailSet.size()+' '+mailSet);
                if(PhoneSet.size()>0 && mailSet.size()>0){
                    matchLead = [SELECT Id,Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email,Country__c,Country_Code__c,Secondary_Country_Code__c,Secondary_Country__c FROM Lead 
                                      WHERE (Phone__c IN : PhoneSet OR Email IN :  mailSet OR Secondary_Phone__c IN :PhoneSet OR Secondary_Email__c IN : mailSet) AND Id!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }else if(PhoneSet.size()>0 && mailSet.size()==0){
                     matchLead = [SELECT Id,Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email,Country__c,Country_Code__c,Secondary_Country_Code__c,Secondary_Country__c FROM Lead 
                                      WHERE (Phone__c IN : PhoneSet OR Secondary_Phone__c IN :PhoneSet) AND Id!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }else if(PhoneSet.size()==0 && mailSet.size()>0){
                     matchLead = [SELECT Id,Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email,Country__c,Country_Code__c,Secondary_Country_Code__c,Secondary_Country__c FROM Lead 
                                      WHERE (Email IN :  mailSet OR Secondary_Email__c IN : mailSet) AND Id!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }
               
                if(matchLead.size()>0){
                    
                   returnmsg = 'Lead aleady existed with this contact details. Lead Id:'+matchLead[0].Lead_Id__c;
                }else{
                    List<Related_source__c> matchRs;
                    if(PhoneSet.size()>0 && mailSet.size()>0){
                    matchRs = [SELECT Id,Lead__r.Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email__c FROM Related_source__c 
                                      WHERE (Phone__c IN : PhoneSet OR Email__c IN :  mailSet OR Secondary_Phone__c IN :PhoneSet OR Secondary_Email__c IN : mailSet) AND Lead__c!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }else if(PhoneSet.size()>0 && mailSet.size()==0){
                     matchRs = [SELECT Id,Lead__r.Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email__c FROM Related_source__c 
                                      WHERE (Phone__c IN : PhoneSet OR Secondary_Phone__c IN :PhoneSet) AND Lead__c!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }else if(PhoneSet.size()==0 && mailSet.size()>0){
                     matchRs = [SELECT Id,Lead__r.Lead_Id__c,Phone__c,Secondary_Phone__c,Secondary_Email__c,Email__c FROM Related_source__c 
                                      WHERE (Email__c IN :  mailSet OR Secondary_Email__c IN : mailSet) AND Lead__c!=:recId ORDER BY CreatedDate ASC LIMIT 1];
                }   
                    if(matchRs.size()>0){
                        returnmsg = 'Lead aleady existed with this contact details. Lead Id:'+matchRs[0].Lead__r.Lead_Id__c;
                    }else{
                        Lead nld = new Lead();
                        nld.Id = recId;
                        nld.Phone__c = phone;
                        nld.Email = email;
                        nld.Secondary_Phone__c = secondaryPhone;
                        nld.Secondary_Email__c = secondaryEmail;
                        Update nld;
                        returnmsg = 'Success';
                    }
                }
            }
        }else{
             Lead nld = new Lead();
                        nld.Id = recId;
                        nld.Phone__c = phone;
                        nld.Email = email;
                        nld.Secondary_Phone__c = secondaryPhone;
                        nld.Secondary_Email__c = secondaryEmail;
            Update nld;
            returnmsg = 'Success';
        }
        }else{
            returnmsg = 'Oops...you do not have the necessary privileges to edit this record. See your administrator for help.';
        }
        return returnmsg;
       
    }
   
}