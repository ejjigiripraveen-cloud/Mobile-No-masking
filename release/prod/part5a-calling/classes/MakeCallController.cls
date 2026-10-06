public class MakeCallController {

    // Mobile number masking (v1.5.0): users who cannot see Lead.Phone__c get masked numbers
    // (e.g. +91 98XXXXXX21); everyone else gets the same list as before.
    @auraEnabled
    public static List<string> readContacts( String  recordId){
        List<string> phones = collectPhones(recordId);
        return PhoneDisplayService.isMaskedUser() ? PhoneDisplayService.maskAllForDisplay(phones) : phones;
    }

    // Mobile number masking (v1.5.0): a masked number selected on screen is resolved to the real number on the
    // server (record access checked, audited); the call is then placed exactly as before by placeMcubeCall.
    @AuraEnabled
    public static string callCustomer(String recordId, string phone) {
        if (!PhoneDisplayService.isMasked(phone)) {
            return placeMcubeCall(recordId, phone);
        }
        // The audit row is written after the MCube callout: no DML is allowed before a callout.
        MaskedDialService.deferAuditWrites();
        String result;
        try {
            String realPhone = PhoneDisplayService.resolve(Id.valueOf(recordId), phone, collectPhones(recordId), 'MCube (MakeCall)');
            result = realPhone == null
                ? 'The selected number could not be identified. Please refresh and try again.'
                : placeMcubeCall(recordId, realPhone);
        } finally {
            MaskedDialService.flushAudits(result == null ? null : 'MakeCall: ' + result);
        }
        return result;
    }

    // Original readContacts body (unchanged): the record's real numbers.
    private static List<string> collectPhones( String  recordId){
        List<string>  phones = new  List<string>();

            Lead targetLead = [select id,Country_Code__c,phone__c,Contact_Data__c,Secondary_Country_Code__c,Secondary_Phone__c from lead where id =: recordId ];
            if(targetLead.phone__c != null ){ 
                phones.add('+'+targetLead.Country_Code__c+' '+targetLead.phone__c);              
            }
            if(targetLead.Secondary_Phone__c != null){
                phones.add('+'+targetLead.Secondary_Country_Code__c+' '+targetLead.Secondary_Phone__c);              
            }
            
            for(Related_Source__c rs: [select id,name,Phone__c,Secondary_Phone__c,Country_Code__c,Secondary_Contry_Code__c  from Related_Source__c where Lead__c=:targetLead.Id order by CreatedDate desc]){
                
                if(!phones.contains('+'+rs.Country_Code__c+' '+rs.Phone__c) && rs.Phone__c!=null){
                    phones.add('+'+rs.Country_Code__c+' '+rs.Phone__c);
                }
                if(!phones.contains('+'+rs.Secondary_Contry_Code__c+' '+rs.Secondary_Phone__c) && rs.Secondary_Phone__c!=null){
                    phones.add('+'+rs.Secondary_Contry_Code__c+' '+rs.Secondary_Phone__c);
                }
            }

        return phones;
     } 
    
    // Original callCustomer body (unchanged).
    private static string placeMcubeCall(String recordId, string phone) {

         User user = [ SELECT Mcube_Phone__c,Phone FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1 ];
        Id myId = Id.valueOf(recordId);
        String sObjName = myId.getSObjectType().getDescribe().getName();
         String phonenum = '';
         String countrycode = '';
        if(user != null){
           
            system.debug('Mcube_Phone__c: ' + user.Mcube_Phone__c);
            if(user.Mcube_Phone__c != null){
                phonenum = user.Mcube_Phone__c;
            }
            else{
                phonenum = user.Phone;
            }
            system.debug('phonenum:' + phonenum );
         /*   user.mobilePhone = user.mobilePhone.replace('+91','')  ; 
        user.mobilePhone = user.mobilePhone.replace('+','')  ;  
        user.mobilePhone=  user.mobilePhone.replaceAll('\\(', '');
        user.mobilePhone=  user.mobilePhone.replaceAll('\\)', '');
        user.mobilePhone=  user.mobilePhone.replaceAll(' ', '');
            user.mobilePhone=  user.mobilePhone.replaceAll('-', '');*/
        }
        
        if(phone != null && phone.contains('+91')){
                phone= phone.replace('+91','')  ; 
                phone=  phone.replaceAll('\\(', '');
                phone=  phone.replaceAll('\\)', ''); 
                phone=  phone.replaceAll(' ', ''); 
             phone=  phone.replaceAll('', ''); 
            countrycode='+91';
        }else if(phone != null && phone.contains('+')){
            list<string> phones=phone.split(' ');
            if(phones.size()>0){
              countrycode=phones[0];
                phone=phones[1];
            }
          phone=  phone.replaceAll('\\(', '');
                phone=  phone.replaceAll('\\)', ''); 
                phone=  phone.replaceAll(' ', ''); 
             phone=  phone.replaceAll('', '');   
        }
        if(sObjName=='Lead'){  
            string qr = 'select id, name,OwnerId from '+sObjName+' where id='+'\'' + recordId + '\'';
            List<lead> oppr = Database.query(qr);  
            Id profileId= userinfo.getProfileId();
            String profileName=[Select Id,Name from Profile where Id=:profileId].Name;  
           system.debug(countrycode+','+phonenum+','+phone+','+recordId);
                //return CallHandlerService.makeCall(user.CTI_Mobile_Number__c,phone,recordId);
                return mCubeController.makeCall(countrycode,phonenum,phone,recordId );   
            
         }
        return null;
    } 
    
       @auraEnabled
    public static boolean readstatus( String  recordId){  
        user u = [select LastRecordCalled__c  from user where id =: userinfo.getUserId()];   
        if(u.LastRecordCalled__c == recordId ){ 
            return true;
        }else{
            return false;
        }
    }
    
     @auraEnabled
    public static string saveCallSummary( String  taskId, string summary ){  
        Task t =  new task();
        t.id = taskId;
        t.Description   = summary;
        update t;
        return 'success'; 
    }   
}