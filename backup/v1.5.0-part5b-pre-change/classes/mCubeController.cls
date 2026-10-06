global without sharing class mCubeController { 
    
    public static string callrouteresponse{get;set;}
     private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
     @AuraEnabled 
    public static PicklistWrapper getDependentPicklist(String ObjectName, string parentField, string childField) {
        Map<String,List<String>> pickListMap = new Map<String,List<String>>();
        PicklistWrapper pw = new PicklistWrapper();
        pw.pickListMap = pickListMap;
        
        if (Schema.getGlobalDescribe().get(ObjectName) ==null || String.isBlank(parentField) || String.isBlank(ChildField)){
            return pw;
        }
 
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(ObjectName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(parentField) || !objFieldMap.containsKey(childField)){
            return pw;     
        }
        
        List<PicklistEntryWrapper> depEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objFieldMap.get(ChildField).getDescribe().getPicklistValues()), List<PicklistEntryWrapper>.class);
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry ple : objFieldMap.get(parentField).getDescribe().getPicklistValues()) {
            pickListMap.put(ple.getLabel(), new List<String>());
            controllingValues.add(ple.getLabel());
        }
        
        for (PicklistEntryWrapper plew : depEntries) {
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    pickListMap.get(controllingValues.get(i)).add(plew.label);
                }
            }
        }
        
        pw.pickListMap = pickListMap;
        pw.parentFieldLabel = objFieldMap.get(parentField).getDescribe().getLabel();
        pw.childFieldLabel = objFieldMap.get(childField).getDescribe().getLabel();
        
        
        system.debug('picklist values wrapper '+json.serialize(pw));
        return pw;
    }
    
    //Refer from here https://salesforce.stackexchange.com/questions/4462/get-lists-of-dependent-picklist-options-in-apex
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
   
    @auraenabled
    webservice static List<string> userDetail() {  
        user u = [select id ,Zone__c from user where id=: userinfo.getUserId()];
        List<string> slist = new List<string>();
        slist = u.Zone__c.split(';');
        return   slist;      
    }
    @auraenabled
    webservice static boolean clickToCall(String recordId) { 
        
        MCUBE_Object_Api__c mcubeObject=[select id,name,Field_to_Compare_Mobile_Incoming_Number__c,LandingNumber__c from MCUBE_Object_Api__c limit 1];
        String condtn='Id='+'\''+recordId+'\'';
        String xQuery='Select id,'+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+ ' from '+mcubeObject.Name+' where '+condtn;
        system.debug(xQuery);        
        List<sObject> l = Database.query(xQuery);
        system.debug(l);        
        
        // Lead l =  [select id, Mobilephone from Lead where id=: leadId ];
        User u = [select mcube_phone__c from user where id=:userinfo.getUserId()];
        String m= String.valueof(l[0].get(mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c));
        
        u.mobilePhone = u.mcube_phone__c.replace('+91','')  ; 
        u.mobilePhone = u.mcube_phone__c.replace('+','')  ;  
        u.mobilePhone=  u.mcube_phone__c.replaceAll('\\(', '');
        u.mobilePhone=  u.mcube_phone__c.replaceAll('\\)', '');
        u.mobilePhone=  u.mcube_phone__c.replaceAll(' ', '');
        if(m != null){
            m= m.replace('+91','')  ; 
            m=  m.replaceAll('\\(', '');
            m=  m.replaceAll('\\)', ''); 
            m=  m.replaceAll(' ', ''); 
        }
        
        Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
        Mcube__mdt api2 =  [select Value__c from Mcube__mdt where DeveloperName ='callbackUrl'];
        
        ////for new Products
            List<Mcube__mdt> verstionList = [select Value__c from Mcube__mdt where DeveloperName ='Version'];

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            string url = '';
        //For New Products 
         if(!(verstionList.isEmpty()) && verstionList[0].Value__c == '2'){
   url  =   'http://api.mcube.com/Restmcube-api/outbound-calls';
     String token = api1.Value__c ;
   request.setHeader('Content-Type', 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
   request.setHeader('Authorization', 'Bearer '+ token );
   String boundary = '------WebKitFormBoundary7MA4YWxkTrZu0gW';
   String requestBody = '';
     
     

   // Add your form data
    requestBody += boundary + '\r\n';
    requestBody += 'Content-Disposition: form-data; name="exenumber"\r\n\r\n';
    //requestBody += '8767316316\r\n';  
     requestBody += u.mobilePhone+'\r\n';
  
     // Add your form data
    requestBody += boundary + '\r\n';
    requestBody += 'Content-Disposition: form-data; name="custnumber"\r\n\r\n';
    requestBody += m+'\r\n';  
      
     // Add your form data
    requestBody += boundary + '\r\n';
    requestBody += 'Content-Disposition: form-data; name="refid"\r\n\r\n';
    requestBody += l[0].get('Id')+'\r\n';  
     
     // Add your form data
    requestBody += boundary + '\r\n';
    requestBody += 'Content-Disposition: form-data; name="refurl"\r\n\r\n';
    requestBody += +'1\r\n';  
    // Add closing boundary
    requestBody += boundary + '--\r\n';
     
    // Set the request body as a Blob
    request.setBody(requestBody); 
    
     System.debug(requestBody);
 }else{
   url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&url='+api2.Value__c +'/calland?refid='+l[0].get('Id');
 }
        
request.setEndpoint(url);
request.setMethod('POST');
system.debug(url);
   if(!test.isRunningTest()){
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            system.debug(var);  
            if(response.getStatusCode() == 200 ){
                return true;
            }
            return false;
        }
        
        return false;  
        
        /*string url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+u.mobilePhone+'&custnumber='+m+'&refid='+l[0].get('Id')+'&url='+api2.Value__c +'/calland?refid='+l[0].get('Id');
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('POST');
        
        if(!test.isRunningTest()){
            HttpResponse response = http.send(request);
            String var= response.getBody() ;
            system.debug(var);  
            if(response.getStatusCode() == 200 ){
                return true;
            }
            return false;
        }
        
        return false;*/
        
    }
    
    @future(callout=true)
    public static void makeCallAsync(string countrycode, String exeNumber, String custNumber,string recordId)
    {
        mCubeController.makeCallZetta(countrycode,exeNumber,custNumber,recordId);
    }
    
    public static String makeCall(string countrycode, String exeNumber, String custNumber,string recordId){
       // countrycode = '+94';
        log__c log=new log__c();
        log.method__c='makeCall';
        try{
            log.LeadId__c=recordId;
            system.debug(countrycode+','+exeNumber+','+custNumber+','+recordId);
            system.debug(custNumber.length());
            Mcube__mdt api1 =  [select Value__c from Mcube__mdt where DeveloperName ='APIKey'];
            Mcube__mdt api2 =  [select Value__c from Mcube__mdt where DeveloperName ='callbackUrl'];
            Mcube__mdt api3 =  [select Value__c from Mcube__mdt where DeveloperName ='NRIAPIKey'];
            //for new Products
            List<Mcube__mdt> verstionList = [select Value__c from Mcube__mdt where DeveloperName ='Version'];
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            string url = '';
            list<Round_Robin_Member__c> nriMember=[select Name,User__c,User__r.Username,NRI__c from  Round_Robin_Member__c where User__r.Mcube_Phone__c = :exeNumber and NRI__c=true];
            if(!(verstionList.isEmpty()) && verstionList[0].Value__c == '2'){
                url  =   'http://api.mcube.com/Restmcube-api/outbound-calls';
                String token = api3.Value__c ;
                request.setHeader('Content-Type', 'multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW');
                request.setHeader('Authorization', 'Bearer '+ token );
                String boundary = '------WebKitFormBoundary7MA4YWxkTrZu0gW';
                String requestBody = '';
                
                // Add your form data
                requestBody += boundary + '\r\n';
                requestBody += 'Content-Disposition: form-data; name="exenumber"\r\n\r\n';
                requestBody += exeNumber+'\r\n';
                
                // Add your form data
                requestBody += boundary + '\r\n';
                requestBody += 'Content-Disposition: form-data; name="custnumber"\r\n\r\n';
                requestBody += custNumber+'\r\n';  
                
                // Add your form data
                requestBody += boundary + '\r\n';
                requestBody += 'Content-Disposition: form-data; name="refid"\r\n\r\n';
                requestBody += recordId+'\r\n';  
                
                
                if(nriMember.size()>0){
                    
                    // Add your form data
                    requestBody += boundary + '\r\n';
                    requestBody += 'Content-Disposition: form-data; name="Countrycode"\r\n\r\n';
                    requestBody += countrycode+'\r\n';             
                    
                } else{
                    // Add your form data
                    requestBody += boundary + '\r\n';
                    requestBody += 'Content-Disposition: form-data; name="Countrycode"\r\n\r\n';
                    requestBody += countrycode+'\r\n';             
                    
                }       
                
                // Add your form data
                requestBody += boundary + '\r\n';
                requestBody += 'Content-Disposition: form-data; name="refurl"\r\n\r\n';
                requestBody += +'1\r\n';  
                // Add closing boundary
                requestBody += boundary + '--\r\n';
                
                // Set the request body as a Blob
                request.setBody(requestBody); 
                System.debug('API Request Log '+ json.serialize(requestBody)); 
                log.Request__c=url+' '+requestBody;
                
            }else{
                
                if(nriMember.size()>0){
                    url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api3.Value__c  +'&exenumber='+exeNumber+'&countrycode='+countrycode+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
                }else if(countrycode=='+91' || countrycode=='' || countrycode==null ){
                    url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+exeNumber+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
                }else{
                    url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api3.Value__c  +'&exenumber='+exeNumber+'&countrycode='+countrycode+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
                }
                
            }
            
            
            /*       
list<Round_Robin_Member__c> nriMember=[select Name,User__c,User__r.Username,NRI__c from  Round_Robin_Member__c where User__r.Mcube_Phone__c = :exeNumber and NRI__c=true];
string url='';
if(nriMember.size()>0){
url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api3.Value__c  +'&exenumber='+exeNumber+'&countrycode='+countrycode+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
}else if(countrycode=='+91' || countrycode=='' || countrycode==null ){
url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api1.Value__c  +'&exenumber='+exeNumber+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
}else{
url  =   'http://mcube.vmc.in/api/outboundcall?apikey='+api3.Value__c  +'&exenumber='+exeNumber+'&countrycode='+countrycode+'&custnumber='+custNumber+'&refid='+recordId+'&url='+api2.Value__c +'?refid='+recordId;
}
log.Request__c=url;
Http http = new Http();
HttpRequest request = new HttpRequest();
*/
            System.debug('API url - '+ url);
            
            
            request.setEndpoint(url);
            request.setMethod('POST');
            
            UserRecordAccess usaccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userinfo.getUserId() AND RecordId =: recordId];
            string returnmsg;
            if(usaccess.HasEditAccess){
                if(!test.isRunningTest()){
                    HttpResponse response = http.send(request);
                    String var= response.getBody() ;
                    system.debug('304 Response '+json.serialize(var));
                    responsewrap rs=(responsewrap) System.JSON.deserialize(var, responsewrap.class);
                    system.debug(var);  
                    log.Response__c=string.valueof(rs);
                    insert log;
                    if(response.getStatusCode() == 200 ){
                        returnmsg = 'Success';  
                       
                    }else{
                        returnmsg='There is some problem while connecting the call. Please try again after sometime.';
                    }
                    
                }
            }else{
                returnmsg='Oops..You do not have the necessary privileges to call for this lead. Contact your administrator for help.';
            }
            
            return returnmsg;  
        }catch(exception e){
            log.LeadId__c  = recordId;
            log.response__c = e.getStackTraceString()  ;
            insert log; 
        }
        return null;
    }

    public static String makeCallZetta(string countrycode, String exeNumber, String custNumber,string recordId){
       // countrycode = '+94';
        log__c log=new log__c();
        log.method__c='makeCall-Zetta';
        String respString = '';
        try{
            log.LeadId__c=recordId;
            system.debug(countrycode+','+exeNumber+','+custNumber+','+recordId);
            system.debug(custNumber.length());
            Mcube__mdt api =  [select Value__c from Mcube__mdt where DeveloperName ='ZETTA'];
              
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            string url = '';

            Map<String,Object> reqMap = new Map<String,Object>();
            reqMap.put('HTTP_AUTHORIZATION',api.Value__c);
            reqMap.put('custnumber',custNumber);
            reqMap.put('exenumber',exeNumber);
            reqMap.put('refurl','1');
            reqMap.put('refid',recordId);
            reqMap.put('is_human','no');

            url = 'https://api.mcube.com/mcube-api/mcube-outboundapi';

            String requestBody = '';
             
            requestBody = JSON.serialize(reqMap);
            log.Request__c=url+' '+requestBody;
            
             
            System.debug('API url - '+ url+ ' Request Body - '+ requestBody);
            
            
            request.setEndpoint(url);
            request.setMethod('POST');
            request.setBody(requestBody);

            
            UserRecordAccess usaccess = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userinfo.getUserId() AND RecordId =: recordId];
            string returnmsg;
            if(usaccess.HasEditAccess){
                if(!test.isRunningTest()){
                    HttpResponse response = http.send(request);
                    String var= response.getBody() ;
                    system.debug('304 Response '+var);
                    Map<String,Object> respMap = (Map<String,Object>) JSON.deserializeUntyped(var); //callType
                    String callId = respMap.containsKey('callid') ?  (String) respMap.get('callid') : 'NODATA';
                    String callType = respMap.containsKey('callType') ?  (String) respMap.get('callType') : 'NODATA';


                  //  responsewrap rs=(responsewrap) System.JSON.deserialize(var, responsewrap.class);
                    system.debug(var);  
                    log.Response__c= var; //string.valueof(rs);
                    respString = var;
                    
                    if(response.getStatusCode() == 200 ){

                        ZettaTechLeadContextService.makeCall(recordId,callId,callType);

                        returnmsg = 'Success';  
                       
                    }else{
                        returnmsg='There is some problem while connecting the call. Please try again after sometime.';
                    }

                    insert log;
                    
                }
            }else{
                returnmsg='Oops..You do not have the necessary privileges to call for this lead. Contact your administrator for help.';
            }
            
            return returnmsg;  
        }catch(exception e){
            log.LeadId__c  = recordId;
            log.response__c = e.getStackTraceString() +' and '+e +' and '+respString;
            insert log; 
        }
        return null;
    }

    public class responsewrap
    {
     string msg;
     string callid;
    }
    public static void readData(){ 
        Log__c log =  new   Log__c();
        string fromnumber = apexpages.currentpage().getparameters().get('fromnumber');
        //string fromnumber = '9502604011';
        string landingnumber = apexpages.currentpage().getparameters().get('landingnumber');
        log.request__c = 'fromnumber '+ fromnumber + 'landingnumber ' + landingnumber;
        log.Method__c = 'readData';
        string leadId;
        
        try{
            
            system.debug('inbound call read data');
            string returnmsg;
            
           
            
            
            if(fromnumber != null){ 
                
                List<Lead> inboundList = new List<Lead>();
                
                List<Lead> ld = [select id,name,Phone__c,status,OwnerId,Owner.Profile.Name,Secondary_Phone__c,Pre_sales_user__c  from Lead where Phone__c = :fromnumber OR Secondary_Phone__c = :fromnumber limit 1 ];
                system.debug('ld:' + ld);
                if(ld.size() == 1){
                    inboundList.add(ld[0]);
                } 
                else{
                    List<Related_Source__c> rs = [select id,Lead__c, Phone__c,OwnerId, Secondary_Phone__c from Related_Source__c where Phone__c = :fromnumber OR Secondary_Phone__c = :fromnumber limit 1];
                    system.debug('rs:' + rs);
                    if(rs.size() == 1){
                        Lead ld2 = [select id,status,OwnerId,Owner.Profile.Name from Lead where id = :rs[0].Lead__c];
                        inboundList.add(ld2);
                    }
                }
                
                //List<Campaign_Number_Mapping__c> campList = [Select id, name, Landing_Number__c, Interested_Project__c, Source__c, Sub_Source__c from Campaign_Number_Mapping__c where name =: landingnumber LIMIT 1];
                List<Campaign_Source__c> campList = [SELECT Id, Name, Source__c,medium__c, Sub_Source__c,Campaign__c, Campaign__r.Project__c, Campaign__r.Active__c, Campaign__r.Zone__c, Campaign__r.NRI_Campaign__c FROM Campaign_Source__c where Landing_Number__c =: landingnumber AND Campaign__r.Active__c =true LIMIT 1];
                Lead l = new Lead();
                if(inboundList.size() == 0){ 
                    
                    l.LastName = 'customer';
                    l.Company = 'McubeLead';
                    if(campList.size() > 0){
                        l.Campaign_Lookup__c = campList[0].Campaign__c;
                        l.Leadsource = campList[0].Source__c;
                        l.sub_source__c = campList[0].Sub_Source__c;
                        l.landing_number__c = landingnumber;
                        l.medium__c = campList[0].medium__c;
                        //l.Interested_Project__c  = campList[0].Interested_Project__c;
                        l.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                        l.Zone__c = campList[0].Campaign__r.Zone__c;
                        if(campList[0].Campaign__r.NRI_Campaign__c == true)
                            l.NRI__c = 'Yes';
                        else
                            l.NRI__c = 'No';
                    }else{
                        l.Leadsource = 'Mcube';
                        l.sub_source__c = 'Inbound call';
                        l.Interested_Project__c  = 'None';
                        l.landing_number__c = landingnumber;
                    }
                    
                    l.phone__c = fromnumber;
                    insert l;
                    List<Lead> ld3 = [select id,name,Phone__c,status,OwnerId,Owner.Profile.Name,Secondary_Phone__c from Lead where Id = :l.Id ];
                    system.debug('ld:' + ld3);
                    if(ld3.size() == 1){
                        inboundList.add(ld3[0]);
                    }/*else{
List<Related_Source__c> rs2 = [select id,Lead__c, Phone__c,OwnerId, Secondary_Phone__c from Related_Source__c where Phone__c = :fromnumber OR Secondary_Phone__c = :fromnumber limit 1];
system.debug('rs:' + rs2);
if(rs2.size() == 1){
Lead ld4 = [select id,status,OwnerId,Owner.Profile.Name from Lead where id = :rs2[0].Lead__c];
inboundList.add(ld4);
}
}*/
                    returnmsg = inboundList[(inboundList.size()-1)].OwnerId;
                    leadId = inboundList[(inboundList.size()-1)].Id;
                }else{ 
                    l = inboundList[0]; 
                    if(l.Owner.Profile.Name =='Sales' || l.Owner.Profile.Name =='Pre Sales' || l.Owner.Profile.Name =='Site visit'){
                        if(campList.size()>0){
                            lead l2 = new lead();
                            l2.LastName = 'customer';
                            l2.Company = 'McubeLead';
                            l2.landing_number__c = landingnumber;
                            l2.Campaign_Lookup__c = campList[0].Campaign__c;
                            l2.Leadsource = campList[0].Source__c;
                            l2.sub_source__c = campList[0].Sub_Source__c;
                            l2.medium__c = campList[0].medium__c;
                            //l2.Interested_Project__c  = campList[0].Interested_Project__c;
                            l2.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                            l2.Zone__c = campList[0].Campaign__r.Zone__c;
                            if(campList[0].Campaign__r.NRI_Campaign__c == true)
                                l2.NRI__c = 'Yes';
                            else
                                l2.NRI__c = 'No';
                            
                            l2.phone__c = fromnumber;
                            insert l2;
                        }
                        
                        system.debug('l.Pre_sales_user__c:' + l.Pre_sales_user__c);
                        if(l.Pre_sales_user__c !=null){
                            returnmsg = l.Pre_sales_user__c;
                        }else{
                            returnmsg = l.ownerId;
                        }
                        leadId = l.Id;
                        
                    }else{
                        lead l2 = new lead();
                        l2.LastName = 'customer';
                        l2.Company = 'McubeLead';
                        if(campList.size() > 0){
                            l2.Campaign_Lookup__c = campList[0].Campaign__c;
                            l2.Leadsource = campList[0].Source__c;
                            l2.sub_source__c = campList[0].Sub_Source__c;
                            l2.landing_number__c = landingnumber;
                            l2.medium__c = campList[0].medium__c;
                            //l2.Interested_Project__c  = campList[0].Interested_Project__c;
                            l2.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                            l2.Zone__c = campList[0].Campaign__r.Zone__c;
                            if(campList[0].Campaign__r.NRI_Campaign__c == true)
                                l2.NRI__c = 'Yes';
                            else
                                l2.NRI__c = 'No';
                        }else{
                            l2.Leadsource = 'Mcube';
                            l2.sub_source__c = 'Inbound call';
                            l2.Interested_Project__c  = 'None';
                            l2.landing_number__c = landingnumber;
                        }
                        l2.phone__c = fromnumber;
                        insert l2;
                        /* List<Lead> ld3 = [select id,name,Phone__c,status,OwnerId,Owner.Profile.Name,Secondary_Phone__c from Lead where Phone__c = :fromnumber OR Secondary_Phone__c = :fromnumber limit 1 ];
system.debug('ld:' + ld3);
if(ld3.size() == 1){
inboundList.add(ld3[0]);
}else{*/
                        List<Related_Source__c> rs2 = [select id,Lead__c, Phone__c,OwnerId, Secondary_Phone__c from Related_Source__c where Phone__c = :fromnumber OR Secondary_Phone__c = :fromnumber limit 1];
                        system.debug('rs:' + rs2);
                        if(rs2.size() == 1){
                            Lead ld4 = [select id,status,OwnerId,Owner.Profile.Name,Pre_sales_user__c from Lead where id = :rs2[0].Lead__c];
                            inboundList.add(ld4);
                        }
                        // }
                        system.debug('inboundList[(inboundList.size()-1)].Pre_sales_user__c:' + inboundList[(inboundList.size()-1)].Pre_sales_user__c);
                        leadId = inboundList[(inboundList.size()-1)].Id;
                        if(inboundList[(inboundList.size()-1)].Pre_sales_user__c !=null){
                            returnmsg = inboundList[(inboundList.size()-1)].Pre_sales_user__c;
                            
                        }else{
                            returnmsg = inboundList[(inboundList.size()-1)].OwnerId;
                        }
                        
                    }
                    
                }
            }
            
            user u = [SELECT Id,Mcube_Phone__c,Phone,Availability__c FROM User WHERE Id=:returnmsg LIMIT 1];
            if(u !=null && u.Availability__c == TRUE){
                if(u.Mcube_Phone__c != null){
                    callrouteresponse = u.Mcube_Phone__c;
                }
                else{
                    callrouteresponse = u.Phone;
                }
            }else{
                callrouteresponse = '';
                Call_Detail__c c = new Call_Detail__c();
                c.Parent_ID__c=leadId;
                String url='/'+leadId+'/view';
                c.Parent_URL__c=url;
                c.Status__c='MISSED'; 
                c.ownerId = u.Id;
                c.Call_From__c = fromnumber;
                c.Start_Time__c =   system.now();
                c.Call_Type__c='Inbound Call'; 
                c.Call_To__c=u.Mcube_Phone__c;
                c.landing_number__c = landingnumber;
                c.lead__c = leadId;
                Insert c;            
                
            }
            
            log.response__c = callrouteresponse;
            log.LeadId__c  = leadId;
            insert log; 
        }catch(exception e){
            log.LeadId__c  = leadId;
            log.response__c = e.getStackTraceString()  ;
            insert log; 
        }
        
    }
    public static void inboundCall(){ 
        
        
        log__c log = new log__c();
        log.method__c = 'inboundCall';
        system.debug('record values ');
        if(apexpages.currentpage().getparameters().get('data')!=null)
       //  system.assert(false,'request '+apexpages.currentpage().getparameters().get('data'));
        
         log.request__c =  EncodingUtil.urlDecode(apexpages.currentpage().getparameters().get('data'), 'UTF-8') ;
        string leadId;
        string callId;
        string method;
        
        try{ 
            system.debug('inbound call');
            
            String data = apexpages.currentpage().getparameters().get('data');
            List<MCUBE_Object_Api__c> mcubeObjectList =[select id,name,field__c,value__c,field1__c,value1__c,field2__c,value2__c, LandingNumber__c,  Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c order by  LandingNumber__c nulls first ];
            
            MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c(); 
            if(mcubeObjectList.size() > 0 ){
                mcubeObject = mcubeObjectList[0]; 
                string mobileNumber ='';
                if(data != null){ 
                    system.debug(data);
                    data = EncodingUtil.urlDecode(data, 'UTF-8');    
                    system.debug(data);
                    callWrapper cw = (callWrapper)JSON.deserialize(data,callWrapper.class); 
                    system.debug('callwrapper:' + cw);
                    List<Call_Detail__c> cList=[select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                    List<Campaign_Source__c> campList = [SELECT Id, Name, Source__c,medium__c, Sub_Source__c,Campaign__c, Campaign__r.Project__c, Campaign__r.Active__c, Campaign__r.Zone__c, Campaign__r.NRI_Campaign__c FROM Campaign_Source__c where Landing_Number__c =: cw.landingNumber AND Campaign__r.Active__c =true LIMIT 1];
                    List<User> u=new List<User>();  
                    for(MCUBE_Object_Api__c m: mcubeObjectList){
                        if( m.LandingNumber__c == cw.landingnumber ){ 
                            mcubeObject = m;
                        } 
                    }
                    system.debug(cw.calltype);
                    if(   cw.executive == null){
                        method = 'inboundCall-'+cw.dialstatus;
                        system.debug(cw.dialstatus);
                        if(cw.dialstatus  == 'CONNECTING' || cw.dialstatus == 'Missed' || cw.dialstatus == 'CANCEL'){   
                            
                            //String xQuery='Select id from '+mcubeObject.Name+' where '+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+'=\''+cw.callfrom+'\'';
                            //List<sObject> inboundList = Database.query(xQuery); 
                            
                            
                            if(cList.size() == 0){
                                List<Lead> inboundList = new List<Lead>();
                                if(mcubeObject.Name == 'Lead' || mcubeObject.Name == null){  
                                    List<Lead> ld = [select id,name,Phone__c, Secondary_Phone__c from Lead where Phone__c = :cw.callfrom OR Secondary_Phone__c = :cw.callfrom limit 1 ];
                                    system.debug('ld:' + ld);
                                    if(ld.size() == 1){
                                        inboundList.add(ld[0]);
                                    } 
                                    else{
                                        List<Related_Source__c> rs = [select id,Lead__c, Phone__c, Secondary_Phone__c from Related_Source__c where Phone__c = :cw.callfrom OR Secondary_Phone__c = :cw.callfrom limit 1];
                                        system.debug('rs:' + rs);
                                        if(rs.size() == 1){
                                            Lead ld2 = [select id from Lead where id = :rs[0].Lead__c];
                                            inboundList.add(ld2);
                                        }
                                    }
                                    
                                }
                                Call_Detail__c c = new Call_Detail__c(); 
                                c.Parent_ID__c=ApexPages.currentPage().getParameters().get('id'); 
                                // u = [select id from user where mobilephone  =: cw.empnumber limit 1]; 
                                u = [select mobilePhone from user where Mcube_Phone__c=:cw.empnumber or Phone =:cw.empnumber];
                                if(u.size()==0){
                                    u = [select mobilePhone from user where id=:label.adminUserRecordId];
                                }
                                
                                lead l = new lead();  
                                if(inboundList.size() == 0){   
                                    l.LastName = 'customer';
                                    l.Company = 'McubeLead';
                                    if(campList.size() > 0){
                                        l.Campaign_Lookup__c = campList[0].Campaign__c;
                                        l.Leadsource = campList[0].Source__c;
                                        l.sub_source__c = campList[0].Sub_Source__c;
                                        l.landing_number__c = cw.landingNumber;
                                        l.medium__c = campList[0].medium__c;
                                        //l.Interested_Project__c  = campList[0].Interested_Project__c;
                                        l.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                                        l.Zone__c = campList[0].Campaign__r.Zone__c;
                                        if(campList[0].Campaign__r.NRI_Campaign__c == true)
                                            l.NRI__c = 'Yes';
                                        else
                                            l.NRI__c = 'No';
                                    }else{
                                        l.Leadsource = 'Mcube';
                                        l.sub_source__c = 'Inbound call';
                                        l.Interested_Project__c  = 'None';
                                        l.landing_number__c = cw.landingNumber;
                                    }
                                    
                                    l.phone__c = cw.callfrom;
                                    if(label.Mcubecheck=='TRUE'){
                                         l.ownerId =u[0].Id;
                                    }
                                    l.lead_assigned__c=true;
                                    insert l;   
                                    c.Parent_ID__c = l.id;  
                                    String url='/'+l.id+'/view';
                                    leadId = l.id;
                                    callId  = cw.CallId;
                                    c.Parent_URL__c=url;
                                    c.Status__c=cw.dialstatus; 
                                    c.ownerId = u[0].Id;
                                }else{ 
                                    l = inboundList[0]; 
                                    //l.put('OwnerId',u.id);
                                    update l;
                                    c.Parent_ID__c  = l.id;
                                    leadId = l.id;
                                    callId  = cw.CallId;
                                    if(label.Mcubecheck=='TRUE'){
                                        c.ownerId = u[0].Id;
                                     }
                                }
                                DateTime start = System.Now();
                                system.debug('cList:' + cList);
                                if(cList.size() == 0){
                                    c.Call_ID__c = cw.CallId;
                                    c.Call_From__c = cw.callfrom;
                                    c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30); 
                                    c.Call_ID__c = cw.callid;
                                    c.Call_Type__c='Inbound Call'; 
                                    c.Call_To__c=cw.empnumber;
                                  /*  if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else */
                                    c.Recording_File__c=cw.filename;
                                    c.landing_number__c = cw.landingNumber;
                                    c.Status__c=cw.dialstatus; 
                                    c.ownerId = u[0].Id;
                                    if(mcubeObject.Name == 'Lead'){
                                        c.lead__c = l.id;
                                    } 
                                    if(mcubeObject.Name == 'Case'){
                                        c.case__c = l.id;
                                    }
                                    
                                    insert c;
                                    system.debug('c:' + c);
                                } 
                                 if(label.Mcubecheck=='TRUE'){
                                sendNotification(cw.callfrom, l.id, u[0].id, mcubeObject.name,c.id,'INCOMING');
                                 }
                                //sendNotification('9502604013','00Q9D000004IlUhUAK', '0055j000001b9zEAAQ', 'Lead','a0P9D000001n2ZIUAY','INCOMING');
                                
                            }
                            else{
                                u = [select mobilePhone from user where Mcube_Phone__c =:cw.empnumber or Phone =:cw.empnumber];
                                if(u.size()==0){
                                    u = [select mobilePhone from user where id=:label.adminUserRecordId];
                                }   
                                /*String X1='\''+cw.callfrom+'\''; 
String xQuery='Select id from '+mcubeObject.Name+' where '+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+' ='+x1; 
List<sObject> inboundList = Database.query(xQuery); */
                                //sObject l = inboundList[0];  
                                if(cList.size() == 1){
                                    Call_Detail__c  c = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                    leadId = c.Lead__c;
                                    callId  = cw.CallId;
                                    c.End_Time__c = Datetime.valueof(cw.endtime).addHours(-5).addMinutes(-30);
                                    Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                    Long seconds = milliseconds / 1000;
                                    Long minutes = seconds / 60;
                                    Long hours = minutes / 60;
                                    Long days = hours / 24;
                                    system.debug(minutes);
                                    system.debug(seconds);
                                    c.Duration__c = seconds;
                                    c.wrap_Up_Time__c = cw.wrapUpTime;
                                    c.Answer_Time__c = cw.answeredtime;
                                    c.Status__c=cw.dialstatus;
                                   /* if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else*/
                                    c.Recording_File__c=cw.filename;
                                     if(label.Mcubecheck=='TRUE'){
                                    c.ownerId = u[0].Id;
                                     }
                                    if(!test.isRunningTest()){
                                        update c;
                                    }
                                }
                            }
                            
                        }else  
                        {
                            
                            // u = [select id from user where mobilephone  =: cw.empnumber limit 1];
                            u = [select mobilePhone from user where Mcube_Phone__c =:cw.empnumber or Phone =:cw.empnumber];
                            if(u.size()==0){
                                u = [select mobilePhone from user where id=:label.adminUserRecordId];
                            }   
                            //String X1='\''+cw.callfrom+'\''; 
                            //String xQuery='Select id from '+mcubeObject.Name+' where '+mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+' ='+x1; 
                            //List<sObject> inboundList = Database.query(xQuery); 
                            //sObject l = inboundList[0];  
                            if(cList.size() == 1){
                                Call_Detail__c  c = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                leadId = c.Lead__c;
                                callId  = cw.CallId;
                                c.End_Time__c = Datetime.valueof(cw.endtime).addHours(-5).addMinutes(-30);
                                Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                Long seconds = milliseconds / 1000;
                                Long minutes = seconds / 60;
                                Long hours = minutes / 60;
                                Long days = hours / 24;
                                // Long timeAvailable = ;
                                // timeAvailable /= 60000;
                                //System.debug(timeAvailable);
                                system.debug(minutes);
                                system.debug(seconds);
                                c.Duration__c = seconds;
                                c.wrap_Up_Time__c = cw.wrapUpTime;
                                 c.Answer_Time__c = cw.answeredtime;
                                c.Status__c=cw.dialstatus;
                              /*  if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else*/
                                c.Recording_File__c=cw.filename;
                                 if(label.Mcubecheck=='TRUE'){
                                c.ownerId = u[0].Id;
                                 }
                                   /*@author: Naveen kumar R
								  @desc: Update the dispotion details from mcube connector
								  @date: 15-09-2026*/
                                c.Disposition__c = cw.dispositionType;
                                c.Sub_Dispoisition__c = cw.subDisposition;
                                c.Comments__c =  cw.dispositionComments;
                                if(!test.isRunningTest()){
                                    update c;   
                                }
                                
                                
                            }
                        } 
                    }
                    if(cw.executive != null){ 
                        method ='outboundCall-'+cw.status;
                        List<task> updatetask = new List<task> ();
                        if (cw.status == 'ORIGINATE')
                        {
                            //List<Call_Detail__c> cs=[select id from Call_Detail__c where Call_ID__c=:cw.CallId limit 1];
                            //String xcondn=mcubeObject.Field_to_Compare_Mobile_Incoming_Number__c+'=\''+cw.customer+'\'';
                            //String xQuery='Select id from '+mcubeObject.Name+' where '+xcondn;
                            //List<sObject> inboundList = Database.query(xQuery);
                            
                            Call_Detail__c c = new Call_Detail__c(); 
                            //u = [select id from user where  mobilePhone =: cw.executive limit 1];  
                            u = [select Id,Last_OutBound_CallID__c,mobilePhone from user where Mcube_Phone__c =:cw.executive or Phone =:cw.executive];
                            if(u.size()==0){
                                u = [select Id,Last_OutBound_CallID__c, mobilePhone from user where id=:label.adminUserRecordId];
                           
                            }else{
                                List<task> taskList = new List<task>();
                                taskList = [select  id,subject,TaskSubtype,Status,Owner.Name,whoid,who.Name from task where subject='Missed Call' AND TaskSubtype='Task' AND Status='Open' AND whoid=:cw.refid AND OwnerId=:u[0].Id];
                                if(taskList.size()>0){
                                    for(task tsk : taskList){
                                        task tk = new task();
                                        tk.Id = tsk.Id;
                                        tk.Status = 'Completed';
                                        updatetask.add(tk);
                                    }
                                }
                                
                            }
                             u[0].Last_OutBound_CallID__c = cw.CallId;
                            update u;
                            if(cw.refid==null  || cw.refid==''){
                                 List<Lead> inboundList = new List<Lead>();
                             
                                inboundList = [select id,name,Phone__c, Secondary_Phone__c,RecordTypeid,RecordType.DeveloperName,OwnerName__c,Status,Lead_Assigned__c,owner.profile.name from Lead where Phone__c = :cw.customer OR Secondary_Phone__c = :cw.customer limit 1 ];
                                system.debug('ld:' + inboundList);
                                
                                if(inboundList.size()>0){
                                    cw.refid = inboundList[0].Id;
                                }else{
                                    List<Related_Source__c> rs = new List<Related_Source__c>();
                                    rs = [select id,Lead__c, Phone__c, Secondary_Phone__c from Related_Source__c where (Phone__c = :cw.customer OR Secondary_Phone__c = :cw.customer) AND Lead__c!=null  limit 1];
                                    system.debug('rs:' + rs);
                                    if(rs.size() >0){
                                         cw.refid = rs[0].Lead__c;
                                    }
                                }
                                    
                            }
                      
                            c.Parent_ID__c = cw.refid;
                            c.Parent_URL__c= '/'+ cw.refid+'/view';
                            leadId = cw.refid;
                            callId  = cw.CallId;
                            c.Status__c=cw.dialstatus; 
                            DateTime start = System.Now();
                            c.Call_ID__c = cw.CallId;
                            c.Call_From__c =cw.executive ;
                            c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30); 
                            c.Recording_File__c= cw.filename;
                            c.Status__c=cw.status;
                            c.Call_ID__c = cw.callid;
                            c.Call_Type__c='Outbound Call';  
                            c.Call_To__c=cw.customer;
                            if(label.Mcubecheck=='TRUE'){
                            c.OwnerId = u[0].Id;
                            }
                            if(mcubeObject.Name == 'Lead'){
                                c.lead__c = cw.refid;
                            } 
                            if(mcubeObject.Name == 'Case'){
                                c.case__c = cw.refid;
                            }
                            insert c;
                            if(updatetask.size()>0){
                                Update updatetask;
                            }
                            //if(!test.isRunningTest())
                            system.debug('call notification');
                            //sendNotification(cw.callfrom,cw.refid, u[0].id, mcubeObject.name,c.id,'OUTGOING');  
                        }else   
                        { 
                            if(cList.size() == 1){  
                                u = [select mobilePhone,email from user where Mcube_Phone__c =:cw.executive or Phone =:cw.executive];
                                if(u.size()==0){
                                    u = [select mobilePhone,email from user where id=:label.adminUserRecordId];
                                } 
                                Call_Detail__c  c1 = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                c1.End_Time__c = Datetime.valueof(cw.endtime).addhours(-5).addMinutes(-30); 
                                leadId = c1.Lead__c; 
                                callId  = cw.CallId;
                                // Long dt1Long = stime.getTime();
                                //Long dt2Long =etime.getTime();
                                Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                Long seconds = milliseconds / 1000;
                                Long minutes = seconds / 60;
                                Long hours = minutes / 60;
                                Long days = hours / 24;
                                system.debug(minutes);
                                system.debug(seconds);
                                c1.Duration__c = seconds;
                                c1.wrap_Up_Time__c = cw.wrapUpTime;
                                 c1.Answer_Time__c = cw.answeredtime;
                                c1.Status__c=cw.status;
                                c1.Recording_File__c= cw.filename;
                                if(label.Mcubecheck=='TRUE'){
                                c1.OwnerId = u[0].Id;
                                }
                                
                                /*@author: Naveen kumar R
								  @desc: Update the dispotion details from mcube connector
								  @date: 15-09-2026*/
                                c1.Disposition__c = cw.dispositionType;
                                c1.Sub_Dispoisition__c = cw.subDisposition;
                                c1.Comments__c =  cw.dispositionComments;
                                update c1;
                                
                                
                            }
                        }
                    }
                }   
            }   
            log.response__c    = 'SUCCESS';
            log.LeadId__c    = leadId;
            log.Call_ID__c    = CallId;
            log.Method__c = method;
            
            insert  log;      
            
        }catch(exception e){
            log.response__c    = e.getStackTraceString()  ;
            log.LeadId__c    = leadId;
            log.Method__c = method;  
            insert  log;  
        }   
    } 
    public static void newInboundCall(){ 
        
        
        log__c log = new log__c();
        log.method__c = 'newInboundCall';
        log.request__c =  EncodingUtil.urlDecode(apexpages.currentpage().getparameters().get('data'), 'UTF-8') ;
        string leadId;
        string callId;
        string method;
        
        try{ 
            system.debug('inbound call');
            
            String data = apexpages.currentpage().getparameters().get('data');
            system.debug(data);
            List<MCUBE_Object_Api__c> mcubeObjectList =[select id,name,field__c,value__c,field1__c,value1__c,field2__c,value2__c, LandingNumber__c,  Field_to_Compare_Mobile_Incoming_Number__c from MCUBE_Object_Api__c order by  LandingNumber__c nulls first ];
            
            MCUBE_Object_Api__c  mcubeObject = new  MCUBE_Object_Api__c(); 
            if(mcubeObjectList.size() > 0 ){
                mcubeObject = mcubeObjectList[0]; 
                string mobileNumber ='';
                if(data != null){ 
                    data = EncodingUtil.urlDecode(data, 'UTF-8');   
                    Map<String,Object> tempObjMap = (Map<String,Object>)JSON.deserializeUntyped(data);
                    for(String keyOfMap : tempObjMap.keyset()) {if(tempObjMap.get(keyOfMap) instanceOf String ) { String valOfKeyOfMap = (String) tempObjMap.get(keyOfMap); valOfKeyOfMap = valOfKeyOfMap.trim()  ; tempObjMap.put(keyOfMap,valOfKeyOfMap);} }  
                    data = JSON.serialize(tempObjMap);       
                    callWrapper cw = (callWrapper)JSON.deserialize(data,callWrapper.class); 
                    system.debug('callwrapper:' + cw);
                    List<Call_Detail__c> cList=[select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                    List<Campaign_Source__c> campList = [SELECT Id, Name, Source__c,medium__c, Sub_Source__c,Campaign__c, Campaign__r.Project__c, Campaign__r.Active__c, Campaign__r.Zone__c, Campaign__r.NRI_Campaign__c FROM Campaign_Source__c where Landing_Number__c =: cw.landingNumber AND Landing_Number__c!=null AND Campaign__r.Active__c =true LIMIT 1];
                    List<User> u=new List<User>();  
                    for(MCUBE_Object_Api__c m: mcubeObjectList){
                        if( m.LandingNumber__c == cw.landingnumber ){ 
                            mcubeObject = m;
                        } 
                    }
                    system.debug(cw.calltype);
                    if(   cw.executive == null){
                        method = 'newInboundCall-'+cw.dialstatus;
                        system.debug(cw.dialstatus);
                        if(cw.dialstatus  == 'CONNECTING' || cw.dialstatus == 'Missed' || cw.dialstatus == 'CANCEL'){   
                            List<Lead> inboundList = new List<Lead>();
                            if(mcubeObject.Name == 'Lead' || mcubeObject.Name == null){  
                                List<Lead> ld = [select id,name,Phone__c, Secondary_Phone__c,RecordTypeid,RecordType.DeveloperName,OwnerName__c,Status,Lead_Assigned__c,owner.profile.name from Lead where Phone__c = :cw.callfrom OR Secondary_Phone__c = :cw.callfrom limit 1 ];
                                system.debug('ld:' + ld);
                                if(ld.size() == 1){
                                    inboundList.add(ld[0]);
                                } 
                                else{
                                    List<Related_Source__c> rs = [select id,Lead__c, Phone__c, Secondary_Phone__c from Related_Source__c where Phone__c = :cw.callfrom OR Secondary_Phone__c = :cw.callfrom limit 1];
                                    system.debug('rs:' + rs);
                                    if(rs.size() == 1){
                                        Lead ld2 = [select id,RecordType.DeveloperName,RecordTypeid,OwnerName__c,Status,Lead_Assigned__c,owner.profile.name from Lead where id = :rs[0].Lead__c];
                                        inboundList.add(ld2);
                                    }
                                }
                                
                            }
                            lead l = new lead();
                            if(cList.size() == 0){
                                
                                Call_Detail__c c = new Call_Detail__c(); 
                                c.Parent_ID__c=ApexPages.currentPage().getParameters().get('id'); 
                                u = [select id,mobilePhone from user where Mcube_Phone__c=:cw.empnumber];
                                if(u.size()==0){
                                    u = [select id,mobilePhone from user where id=:label.adminUserRecordId];
                                }
                                
                                
                                if(inboundList.size() == 0){   
                                    l.LastName = 'customer';
                                    l.Company = 'McubeLead';
                                    if(campList.size() > 0){
                                        l.Campaign_Lookup__c = campList[0].Campaign__c;
                                        l.Leadsource = campList[0].Source__c;
                                        l.sub_source__c = campList[0].Sub_Source__c;
                                        l.landing_number__c = cw.landingNumber;
                                        l.medium__c = campList[0].medium__c;
                                        //l.Interested_Project__c  = campList[0].Interested_Project__c;
                                        l.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                                        l.Zone__c = campList[0].Campaign__r.Zone__c;
                                        if(campList[0].Campaign__r.NRI_Campaign__c == true)
                                            l.NRI__c = 'Yes';
                                        else
                                            l.NRI__c = 'No';
                                    }else{
                                        l.Leadsource = 'Mcube';
                                        l.sub_source__c = 'Inbound call';
                                        l.Interested_Project__c  = 'None';
                                        l.landing_number__c = cw.landingNumber;
                                    }
                                    
                                    l.phone__c = cw.callfrom;
                                    if(label.Mcubecheck=='TRUE'){
                                    l.ownerId =u[0].Id;
                                    l.Pre_sales_user__c=u[0].id;
                                    }
                                    l.lead_assigned__c=true;
                                    insert l;   
                                    c.Parent_ID__c = l.id;  
                                    String url='/'+l.id+'/view';
                                    leadId = l.id;
                                    callId  = cw.CallId;
                                    c.Parent_URL__c=url;
                                    c.Status__c=cw.dialstatus; 
                                    if(label.Mcubecheck=='TRUE'){
                                    c.ownerId = u[0].Id;
                                    }
                                }else{ 
                                    l = inboundList[0]; 
                                    if(campList.size()>0){
                                        lead l2 = new lead();
                                        l2.LastName = 'customer';
                                        l2.Company = 'McubeLead';
                                        l2.landing_number__c = cw.landingnumber;
                                        l2.Campaign_Lookup__c = campList[0].Campaign__c;
                                        l2.Leadsource = campList[0].Source__c;
                                        l2.sub_source__c = campList[0].Sub_Source__c;
                                        l2.medium__c = campList[0].medium__c;
                                        //l2.Interested_Project__c  = campList[0].Interested_Project__c;
                                        l2.Interested_Project__c  = campList[0].Campaign__r.Project__c;
                                        l2.Zone__c = campList[0].Campaign__r.Zone__c;
                                        if(campList[0].Campaign__r.NRI_Campaign__c == true)
                                            l2.NRI__c = 'Yes';
                                        else
                                            l2.NRI__c = 'No';
                                        
                                        l2.phone__c = cw.callfrom;
                                        insert l2;
                                    }
                                    if(l.RecordType.DeveloperName=='Pre_Sales')
                                        
                                    {
                                        if(campList.size()>0){
                                            if(l.Status=='Lost' || l.Status=='Unqualified'){
                                                l.Status='Incoming';
                                                l.Lead_Assigned__c=true;
                                                l.ownerid=u[0].id;
                                                l.Pre_sales_user__c=u[0].id;
                                            }else{
                                                l.Lead_Assigned__c=true;
                                              //  l.ownerid=u[0].id;  
                                            }
                                        }
                                        
                                    }else if(l.RecordType.DeveloperName=='Sales'){
                                        if(l.Status=='Lost' || l.Status=='Unqualified'){
                                            string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                            l.RecordTypeid=RecTypeId;
                                            l.Status='Incoming';
                                            l.Lead_Assigned__c=true;
                                            if(label.Mcubecheck=='TRUE'){
                                            l.ownerid=u[0].id;
                                            l.Pre_sales_user__c=u[0].id;
                                            }
                                        }
                                        
                                    }else if(l.Status=='Lost' || l.Status=='Unqualified'){
                                        string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                        l.RecordTypeid=RecTypeId;
                                        l.Status='Incoming';
                                        l.Lead_Assigned__c=true;
                                        if(label.Mcubecheck=='TRUE'){
                                        l.ownerid=u[0].id;
                                        l.Pre_sales_user__c=u[0].id;
                                        }
                                    }
                                    
                                    try{update l;} catch(Exception e){}
                                    c.Parent_ID__c  = l.id;
                                    leadId = l.id;
                                    callId  = cw.CallId;
                                    if(label.Mcubecheck=='TRUE'){
                                    c.ownerId = u[0].Id;
                                    }
                                }
                                DateTime start = System.Now();
                                system.debug('cList:' + cList);
                                if(cList.size() == 0){
                                    c.Call_ID__c = cw.CallId;
                                    c.Call_From__c = cw.callfrom;
                                    c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30); 
                                    c.Call_ID__c = cw.callid;
                                    c.Call_Type__c='Inbound Call'; 
                                    c.Call_To__c=cw.empnumber;
                                   /* if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else*/
                                    c.Recording_File__c=cw.filename;
                                    c.landing_number__c = cw.landingNumber;
                                    c.Status__c=cw.dialstatus; 
                                    c.ownerId = u[0].Id;
                                    if(mcubeObject.Name == 'Lead'){
                                        c.lead__c = l.id;
                                    } 
                                    if(mcubeObject.Name == 'Case'){
                                        c.case__c = l.id;
                                    }
                                    
                                    insert c;
                                    system.debug('c:' + c);
                                } 
                                if(label.Mcubecheck=='TRUE'){
                                sendNotification(cw.callfrom, l.id, u[0].id, mcubeObject.name,c.id,'INCOMING');
                                }
                                //sendNotification('9502604013','00Q9D000004IlUhUAK', '0055j000001b9zEAAQ', 'Lead','a0P9D000001n2ZIUAY','INCOMING');
                                
                            }
                            else{
                                u = [select mobilePhone from user where Mcube_Phone__c =:cw.empnumber];
                                if(u.size()==0){
                                    u = [select mobilePhone from user where id=:label.adminUserRecordId];
                                } 
                                l = inboundList[0];
                                if(l.RecordType.DeveloperName=='Pre_Sales')
                                    
                                {
                                    if(campList.size()>0){
                                        if(l.Status=='Lost' || l.Status=='Unqualified'){
                                            l.Status='Incoming';
                                            l.Lead_Assigned__c=true;
                                            if(label.Mcubecheck=='TRUE'){
                                            l.ownerid=u[0].id;
                                            l.Pre_sales_user__c=u[0].id;
                                            }
                                        }else{
                                            l.Lead_Assigned__c=true;
                                            if(label.Mcubecheck=='TRUE'){
                                          //  l.ownerid=u[0].id;  
                                            }
                                        }
                                    }
                                    
                                }else if(l.RecordType.DeveloperName=='Sales'){
                                    if(l.Status=='Lost' || l.Status=='Unqualified'){
                                        string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                        l.RecordTypeid=RecTypeId;
                                        l.Status='Incoming';
                                        l.Lead_Assigned__c=true;
                                        if(label.Mcubecheck=='TRUE'){
                                        l.ownerid=u[0].id;
                                        l.Pre_sales_user__c=u[0].id;
                                        }
                                    }
                                    
                                }else if(l.Status=='Lost' || l.Status=='Unqualified'){
                                    string RecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Pre Sales').getRecordTypeId();
                                    l.RecordTypeid=RecTypeId;
                                    l.Status='Incoming';
                                    l.Lead_Assigned__c=true;
                                    if(label.Mcubecheck=='TRUE'){
                                    l.ownerid=u[0].id;
                                    l.Pre_sales_user__c=u[0].id;
                                    }
                                }
                                
                                try{update l;} catch(Exception e){}
                                if(cList.size() == 1){
                                    Call_Detail__c  c = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                    leadId = c.Lead__c;
                                    callId  = cw.CallId;
                                    c.End_Time__c = Datetime.valueof(cw.endtime).addHours(-5).addMinutes(-30);
                                    Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                    Long seconds = milliseconds / 1000;
                                    Long minutes = seconds / 60;
                                    Long hours = minutes / 60;
                                    Long days = hours / 24;
                                    system.debug(minutes);
                                    system.debug(seconds);
                                    c.Duration__c = seconds;
                                    c.wrap_Up_Time__c = cw.wrapUpTime;
                                     c.Answer_Time__c = cw.answeredtime;
                                    c.Status__c=cw.dialstatus;
                                  /*  if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else */
                                    c.Recording_File__c=cw.filename;
                                    c.ownerId = u[0].Id;
                                    if(!test.isRunningTest()){
                                        update c;
                                    }
                                    
                                    
                                }
                            }
                            
                        }
                        else{
                            
                            u = [select mobilePhone from user where Mcube_Phone__c =:cw.empnumber or Phone =:cw.empnumber];
                            if(u.size()==0){
                                u = [select mobilePhone from user where id=:label.adminUserRecordId];
                            }   
                            if(cList.size() == 1){
                                Call_Detail__c  c = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                leadId = c.Lead__c;
                                callId  = cw.CallId;
                                c.End_Time__c = Datetime.valueof(cw.endtime).addHours(-5).addMinutes(-30);
                                Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                Long seconds = milliseconds / 1000;
                                Long minutes = seconds / 60;
                                Long hours = minutes / 60;
                                Long days = hours / 24;
                                system.debug(minutes);
                                system.debug(seconds);
                                c.Duration__c = seconds;
                                c.wrap_Up_Time__c = cw.wrapUpTime;
                                c.Answer_Time__c = cw.answeredtime;
                                c.Status__c=cw.dialstatus;
                              /*  if(cw.filename!=null && !cw.filename.containsIgnorecase('https://mcube.vmctechnologies.com/sounds'))
                                    c.Recording_File__c='https://mcube.vmctechnologies.com/sounds/'+cw.filename;
                                    else*/
                                c.Recording_File__c=cw.filename;
                                if(label.Mcubecheck=='TRUE'){
                                c.ownerId = u[0].Id;
                                }
                                   /*@author: Naveen kumar R
								  @desc: Update the dispotion details from mcube connector
								  @date: 29-09-2026*/
                                c.Disposition__c = cw.dispositionType;
                                c.Sub_Dispoisition__c = cw.subDisposition;
                                c.Comments__c =  cw.dispositionComments;
                                if(!test.isRunningTest()){
                                    update c;
                                }
                            }
                        } 
                    }
                    if(cw.executive != null){ 
                        method ='newoutboundCall-'+cw.status;
                        List<task> updatetask = new List<task> ();
                        if (cw.status == 'ORIGINATE')
                        {
                            
                            Call_Detail__c c = new Call_Detail__c(); 
                            u = [select Id,Last_OutBound_CallID__c,mobilePhone from user where Mcube_Phone__c =:cw.executive or Phone =:cw.executive];
                            if(u.size()==0){
                                u = [select Id,Last_OutBound_CallID__c, mobilePhone from user where id=:label.adminUserRecordId];
                            }else{
                                List<task> taskList = new List<task>();
                                taskList = [select  id,subject,TaskSubtype,Status,Owner.Name,whoid,who.Name from task where subject='Missed Call' AND TaskSubtype='Task' AND Status='Open' AND whoid=:cw.refid AND OwnerId=:u[0].Id];
                                if(taskList.size()>0){
                                    for(task tsk : taskList){
                                        task tk = new task();
                                        tk.Id = tsk.Id;
                                        tk.Status = 'Completed';
                                        updatetask.add(tk);
                                    }
                                }
                                
                            }
                              u[0].Last_OutBound_CallID__c = cw.CallId;
                            update u;
                            if(cw.refid==null  || cw.refid==''){
                                 List<Lead> inboundList = new List<Lead>();
                             
                                inboundList = [select id,name,Phone__c, Secondary_Phone__c,RecordTypeid,RecordType.DeveloperName,OwnerName__c,Status,Lead_Assigned__c,owner.profile.name from Lead where Phone__c = :cw.customer OR Secondary_Phone__c = :cw.customer limit 1 ];
                                system.debug('ld:' + inboundList);
                                
                                if(inboundList.size()>0){
                                    cw.refid = inboundList[0].Id;
                                }else{
                                    List<Related_Source__c> rs = new List<Related_Source__c>();
                                    rs = [select id,Lead__c, Phone__c, Secondary_Phone__c from Related_Source__c where (Phone__c = :cw.customer OR Secondary_Phone__c = :cw.customer) AND Lead__c!=null  limit 1];
                                    system.debug('rs:' + rs);
                                    if(rs.size() >0){
                                         cw.refid = rs[0].Lead__c;
                                    }
                                }
                                    
                                
                                
                            
                            }
                            c.Parent_ID__c = cw.refid;
                            c.Parent_URL__c= '/'+ cw.refid+'/view';
                            leadId = cw.refid;
                            callId  = cw.CallId;
                            c.Status__c=cw.dialstatus; 
                            DateTime start = System.Now();
                            c.Call_ID__c = cw.CallId;
                            c.Call_From__c =cw.executive ;
                            c.Start_Time__c =   Datetime.valueof(cw.starttime).addHours(-5).addMinutes(-30); 
                            c.Recording_File__c= cw.filename;
                            c.Status__c=cw.status;
                            c.Call_ID__c = cw.callid;
                            c.Call_Type__c='Outbound Call';  
                            c.Call_To__c=cw.customer;
                            if(label.Mcubecheck=='TRUE'){
                            c.OwnerId = u[0].Id;
                            }
                            if(mcubeObject.Name == 'Lead'){
                                c.lead__c = cw.refid;
                            } 
                            if(mcubeObject.Name == 'Case'){
                                c.case__c = cw.refid;
                            }
                            insert c;
                            if(updatetask.size()>0){
                                Update updatetask;
                            }
                            //if(!test.isRunningTest())
                           // sendNotification(cw.callfrom,cw.refid, u[0].id, mcubeObject.name,c.id,'OUTGOING');  
                        }else   
                        { 
                            system.debug('clist size '+clist.size());
                            if(cList.size() == 1){  
                                u = [select mobilePhone,email from user where Mcube_Phone__c =:cw.executive or Phone =:cw.executive];
                                if(u.size()==0){
                                    u = [select mobilePhone,email from user where id=:label.adminUserRecordId];
                                } 
                                Call_Detail__c  c1 = [select id,Lead__c from Call_Detail__c where Call_ID__c =: cw.callid limit 1 ];
                                c1.End_Time__c = Datetime.valueof(cw.endtime).addhours(-5).addMinutes(-30); 
                                leadId = c1.Lead__c; 
                                callId  = cw.CallId;
                                // Long dt1Long = stime.getTime();
                                //Long dt2Long =etime.getTime();
                                Long milliseconds = Datetime.valueof(cw.endtime).getTime() - Datetime.valueof(cw.starttime).getTime();
                                Long seconds = milliseconds / 1000;
                                Long minutes = seconds / 60;
                                Long hours = minutes / 60;
                                Long days = hours / 24;
                                system.debug(minutes);
                                system.debug(seconds);
                                c1.Duration__c = seconds;
                                c1.wrap_Up_Time__c = cw.wrapUpTime;
                                 c1.Answer_Time__c = cw.answeredtime;
                                c1.Status__c=cw.status;
                                c1.Recording_File__c= cw.filename;
                                c1.OwnerId = u[0].Id;
                                   /*@author: Naveen kumar R
								  @desc: Update the dispotion details from mcube connector
								  @date: 29-09-2026*/
                                c1.Disposition__c = cw.dispositionType;
                                c1.Sub_Dispoisition__c = cw.subDisposition;
                                c1.Comments__c =  cw.dispositionComments;
                                update c1;
                              // sendNotification(cw.callfrom,cw.refid, u[0].id, mcubeObject.name,c1.id,'OUTGOING');  
                            }
                             
                        }
                    }
                }   
            }   
            log.response__c    = 'SUCCESS';
            log.LeadId__c    = leadId;
            log.Call_ID__c    = CallId;
            log.Method__c = method;
            
            insert  log;      
            
        }catch(exception e){
            log.response__c    = e.getStackTraceString()+',' + e.getMessage() ;
            log.LeadId__c    = leadId;
            log.Method__c = method;  
            insert  log;  
        }   
    } 
    
    //Test Send Notification 
    //mCubeController.sendNotification('9731076175', '00QIk0000018B1KMAU', '0055j000001b9zEAAQ', 'Lead', 'a0PIk000000eyZFMAY', 'INCOMING');
    public static void sendNotification(string mobile, string recordId,String userId, string objectName,string callID, string callType){
        
        
        System.debug('Notifcation');
          System.debug('mobile '+mobile);
          System.debug('recordId' + recordId);
          System.debug('userId' + userId);  
        System.debug('objectName' + objectName);
        System.debug('callID' + callID);
           System.debug('callType' +callType);
        
        
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Mcube_Notification' limit 1]; 
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification(); 
        // Set the contents for the notification
        notification.setTitle('Incoming Call');
        notification.setBody('You Have a call on ' + system.now()); 
        
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(recordId);
        
        // Actually send the notification
        try {
            if(callType == 'INCOMING')
                notification.send(new set<string> {userId});
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }  
        
        System.debug('Custom notification');
        
        call_detail__c cd = [SELECT Id,user_Zone__c FROM call_detail__c WHERE Id =:callID];
        List<string> zoneList =cd.user_Zone__c.split(';');
        string zone = zoneList[0];
        if(zone == 'Chennai'|| test.isRunningTest()){
            List<CtiChennai__e> publishEvents = new List<CtiChennai__e>();
            CtiChennai__e eve = new CtiChennai__e();  
            eve.User_Id__c = userId;
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                list<Database.SaveResult> sr =  EventBus.publish(publishEvents);
                    System.debug('EventPubliushed  Mysore : '+JSON.serialize(sr));
            }
        }
        if(zone== 'Hyderabad'|| test.isRunningTest()){
            List<CtiHyderabad__e> publishEvents = new List<CtiHyderabad__e>();
            CtiHyderabad__e eve = new CtiHyderabad__e();  
            eve.User_Id__c = userId;
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                EventBus.publish(publishEvents);
            }
        }
        if(zone == 'Mysore'|| test.isRunningTest()){
            List<CtiMysore__e> publishEvents = new List<CtiMysore__e>();
            CtiMysore__e eve = new CtiMysore__e();  
            eve.User_Id__c = userId; 
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                 list<Database.SaveResult> sr =  EventBus.publish(publishEvents);
                    System.debug('EventPubliushed  Mysore : '+JSON.serialize(sr));
            }
        }
        if(zone == 'Ballari'|| test.isRunningTest()){
            List<CTIBalleri__e> publishEvents = new List<CTIBalleri__e>();
            CTIBalleri__e eve = new CTIBalleri__e();  
            eve.User_Id__c = userId; 
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                EventBus.publish(publishEvents);
            }
        }
        
        
        if(zone == 'Coimbatore' || test.isRunningTest()){
            List<CtiCoimbatore__e> publishEvents = new List<CtiCoimbatore__e>();
            CtiCoimbatore__e eve = new CtiCoimbatore__e();  
            eve.User_Id__c = userId;
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                EventBus.publish(publishEvents);
            }
        }
        if(zone == 'Trichy'|| test.isRunningTest()){
            List<CtiTrichy__e> publishEvents = new List<CtiTrichy__e>();
            CtiTrichy__e eve = new CtiTrichy__e();  
            eve.User_Id__c = userId;
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                EventBus.publish(publishEvents);
            }
        }
        if(zone == 'Hosur' || test.isRunningTest()){
            List<CtiHosur__e> publishEvents = new List<CtiHosur__e>();
            CtiHosur__e eve = new CtiHosur__e();  
            eve.User_Id__c = userId;
            eve.Record_Id__c = recordId; 
            eve.ObjectName__c = objectName;
            eve.Call_Type__c = callType;
            eve.Call_ID__c = callID;        
            publishEvents.add(eve);  
            System.debug(eve);
            if(!publishEvents.isEmpty()){
                EventBus.publish(publishEvents);
            }
        }
        /* if(l.zone__c == 'Mysore'){
List<CtiMysore__e> publishEvents = new List<CtiMysore__e>();
CtiMysore__e eve = new CtiMysore__e();  
eve.User_Id__c = userId;
eve.Record_Id__c = recordId; 
eve.ObjectName__c = objectName;
eve.Call_Type__c = callType;
eve.Call_ID__c = callID;        
publishEvents.add(eve);  
System.debug(eve);
if(!publishEvents.isEmpty()){
EventBus.publish(publishEvents);
}
}


if(l.zone__c == 'Pune'){
List<CtiPune__e> publishEvents = new List<CtiPune__e>();
CtiPune__e eve = new CtiPune__e();  
eve.User_Id__c = userId;
eve.Record_Id__c = recordId; 
eve.ObjectName__c = objectName;
eve.Call_Type__c = callType;
eve.Call_ID__c = callID;        
publishEvents.add(eve);  
System.debug(eve);
if(!publishEvents.isEmpty()){
EventBus.publish(publishEvents);
}
}

if(l.zone__c == 'Ballari'){
List<CtiBallari__e> publishEvents = new List<CtiBallari__e>();
CtiBallari__e eve = new CtiBallari__e();  
eve.User_Id__c = userId;
eve.Record_Id__c = recordId; 
eve.ObjectName__c = objectName;
eve.Call_Type__c = callType;
eve.Call_ID__c = callID;        
publishEvents.add(eve);  
System.debug(eve);
if(!publishEvents.isEmpty()){
EventBus.publish(publishEvents);
}
}

if(l.zone__c == 'Industrial'){
List<CtiIndustrial__e> publishEvents = new List<CtiIndustrial__e>();
CtiIndustrial__e eve = new CtiIndustrial__e();  
eve.User_Id__c = userId;
eve.Record_Id__c = recordId; 
eve.ObjectName__c = objectName;
eve.Call_Type__c = callType;
eve.Call_ID__c = callID;        
publishEvents.add(eve);  
System.debug(eve);
if(!publishEvents.isEmpty()){
EventBus.publish(publishEvents);
}
} */
         
        
    } 
    
    
    
 
             
             
             
     public class PicklistWrapper{
        @AuraEnabled
        public Map<String, List<String>> pickListMap;
        @AuraEnabled
        public String parentFieldLabel;
        @AuraEnabled
        public String childFieldLabel;      
    }
        
    public class PicklistEntryWrapper{
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
        
    }
   //@date 22/8/2024
   //Call Mcube API  
  @auraEnabled
    public static Boolean callDisposition(String callId){
      //get mcube call id   
       String mcubeCallId = [SELECT id,Call_ID__c  FROM Call_Detail__c  WHERE  id =:callId  ].Call_ID__c;
        
Http http = new Http();
HttpRequest request = new HttpRequest();

string url = '';
 url  =   System.Label.CallDispositionURL;
// Define the JSON payload
//  String payload = '{"HTTP_AUTHORIZATION":"'+ System.Label.DispositionAuthorization+'","callid":"'+mcubeCallId+'","executive":"","customer":"","dispositiontype":""}';
   Map<String, Object> payloadMap = new Map<String, Object>();
payloadMap.put('Authorization', System.Label.DispositionAuthorization); // Using label for Authorization
payloadMap.put('callid', mcubeCallId); // Using variable for callid
payloadMap.put('custom1', '');
payloadMap.put('custom2', '');
payloadMap.put('custom3', '');
payloadMap.put('custom4', '');

// Serialize the map to JSON
String payload = JSON.serialize(payloadMap);
   
request.setEndpoint(url);
request.setMethod('POST');
request.setHeader('Content-Type', 'application/json');
request.setBody(payload);
        
if(!test.isRunningTest()){
    HttpResponse response = http.send(request);
    String var= response.getBody() ;
    system.debug(var);  
    System.debug(payload);
    system.debug('Status Code :: '+response.getStatusCode()); 
    if(response.getStatusCode() == 200 ){
        
        /* if(bodyStatus=='false')
            throw  new AuraHandledException('Some thing went wrong'+response.getStatusCode());
        */
      return true;
    }
  
    return false;
}

return false;
        
   
     
    } 
    
    public class  callWrapper{
        
        String refid;
        String  callid ;
        String callfrom; 
        string starttime ;
        String   filename; 
        String calid;
        string pulse;
        string source;
        String custfeedback;
        String exefeedback;
        String dialstatus;
        String callerbusiness;
        String callername;
        String remark;
        String calleraddress;
        String caller_email;
        String rate;
        string empnumber;
        string   endtime;
        String eid ;
        String empid;
        string gid;
        String empemail;
        String status;
        String executive;
        String customer;
        string LandingNumber;
        string calltype;
        //@date: 22/8/2024
        String wrapUpTime;
        //@date: 29/8/2024
        String answeredtime; 
        
        
        /*@author : Naveen kumar R
		  @desc: additional parameter for the call disposition 
		  @date: 15-09-2026
		*/
        String dispositionType;
        String subDisposition;
		String dispositionComments;
    }
    public   static string status{get;set;} 
    @auraEnabled
    public static  Call_Detail__c readCall(){ 
        try{
            datetime ss =  system.now().addSeconds(-10);
            Call_Detail__c c = [select Call_From__c,Call_ID__c,Call_To__c,Call_Type__c,End_Time__c,Executive_Contact_No__c,Parent_ID__c,Parent_URL__c,Recording_File__c,Start_Time__c,Status__c from Call_Detail__c where createddate >: ss and End_Time__c = null    order by createddate desc limit 1  ];
            return  c;    
        }catch(exception e){
            Call_Detail__c c = new Call_Detail__c();
            return  c;    
        }
        
        
    } 
    public  string recordIds= '';
    @auraEnabled
    public static List<sobject> masdialinit(){
        string userId =  userinfo.getUserId();
        User   u = [select id,massdialerIds__c from User where id=:userId];  
        string recordIdOrPrefix= '';
        if( u.massdialerIds__c != null){
            recordIdOrPrefix = u.massdialerIds__c.split(',')[1]; 
        }
        
        String objectName = '';
        try{
            //Get prefix from record ID
            //This assumes that you have passed at least 3 characters
            String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
            
            //Get schema information
            Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
            
            //Loop through all the sObject types returned by Schema
            for(Schema.SObjectType stype : gd.values()){ 
                
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                
                //Check if the prefix matches with requested prefix
                if(prefix!=null && prefix.equals(myIdPrefix)){
                    objectName = r.getName();
                    System.debug('Object Name! ' + objectName);
                    break;
                }
            }
        }catch(Exception e){
            System.debug(e);
        }
        List<id> idslist = u.massdialerIds__c.split(',');
        List<sobject> llist = database.query('select id, name  from '+objectName +' where id in: idslist  ');
        return  llist; 
        
        
    }
    /*   global static void callrouting(){
RestResponse res = new RestResponse();
RestContext.response.addHeader( 'Content-Type', 'application/json' );
List<string> mobiles = new  List<string>();
List<user> userslist = [select id,mobilephone from user where LastAssignmentTime__c != null order by LastAssignmentTime__c desc];
for(user u: userslist ){
mobiles.add(u.mobilephone ); 

}      
RestContext.response.responseBody = Blob.valueOf( SYSTEM.JSON.serialize( new Response( 'success', mobiles  ) ) );

} 

public class Response {
public String status;
public List<String> agentNumbers;

public Response( String status, List<String> agentNumbers) {
this.status     = status;
this.agentNumbers = agentNumbers;
}

}*/
    @AuraEnabled  
    public static  List<Call_Detail__c> callRecords(string recId){
        List<Call_Detail__c> callIds=[select id,Call_From__c,name, Call_to__c, Call_Type__c, End_Time__c, Start_Time__c, Status__c,Recording_File__c from Call_Detail__c where Parent_id__c=:recId order by createddate desc LIMIT 50000];
        
        return callIds;
    } 
    
    @AuraEnabled  
    public static string  updateRecord(string recId,String callID,String followupDate,String followUpType,String feedback,String disposition,string subDisposition)
    {
        
        string returnmsg ='Updated';
        List<follow_up__c> fuList = [SELECT Id,Name,scheduled_date__c,follow_up_status__c FROM follow_up__c WHERE Lead__c=:recId AND follow_up_status__c='Scheduled'];
        List<follow_up__c> updateFollowupList = new  List<follow_up__c>();
         String formattedFollowUpDate='';
        if((!followupDate.contains('1970')) && followupDate!='Invalid Date' ) {
            system.debug('DateTimee '+followupDate);
            formattedFollowUpDate = followUpController.dateFormat(followupDate);
        }
        if(formattedFollowUpDate !=null && formattedFollowUpDate !=''){
            if(datetime.valueOf(formattedFollowUpDate) >system.now()){
                if(fuList.size()>0){
                    for(follow_up__c fu : fuList){
                        follow_up__c fo = new follow_up__c();
                        fo.Id = fu.Id;
                        fo.Follow_Up_Status__c ='Conducted';
                        updateFollowupList.add(fo);
                        
                    }
                    if(updateFollowupList.size()>0){
                        Update updateFollowupList;
                    }
                }
                
                Follow_Up__c fup = new Follow_Up__c();
                fup.Lead__c = recId;
                fup.Scheduled_Date__c = datetime.valueOf(formattedFollowUpDate);
                fup.Follow_Up_Status__c = 'Scheduled'; 
                insert fup;
            }else{
                returnmsg = 'Select future date';
            }
            
        }
        if(returnmsg == 'Updated'){
            /*if(feedback !=null && feedback!=''){
                Lead ld = new Lead();
                ld.Id = recId;
                ld.last_comment__c = feedback;
                update ld;
            }*/
            list<Call_Detail__c> cdList=[Select id, Disposition__c,Sub_Dispoisition__c,Comments__c from Call_Detail__c where id=:callID];
            if(cdList.size()>0){
                cdList[0].Comments__c=feedback;
                cdList[0].Disposition__c=disposition;
                cdList[0].Sub_Dispoisition__c=subDisposition;
              //  system.debug('values to update '+feedback+'disposition '+disposition+'subDisposition'+subDisposition);
            }
               
            update cdList;
        } 
        
        return returnmsg;
        
    }
    @auraEnabled
    public static outCallWrapper getOutboundCallDetails(){
        
        String userId= userInfo.getUserId();
        list<user> users =[select Id,Name,Last_OutBound_CallID__c from user where Id=:userId];
        if(!users.isEmpty()){
            if(users[0].Last_OutBound_CallID__c !=''&& users[0].Last_OutBound_CallID__c !=null){
                call_detail__c cd = [SELECT Id,Lead__c,user_Zone__c FROM call_detail__c WHERE Call_ID__c =:users[0].Last_OutBound_CallID__c];
                outCallWrapper call = new outCallWrapper();
                call.objectName ='Lead';
                call.callID =cd.Id;
                call.callType ='OUTGOING';
                call.recordId =cd.Lead__c;
                return call;  
            } 
        }
        return null;
    }
     @auraEnabled
    public static void updateUsers(){
        String userId= userInfo.getUserId();
        user user =[select Id,Name,Last_OutBound_CallID__c from user where Id=:userId]; 
        user.Last_OutBound_CallID__c=null;
        update user;
    }
    
   public class outCallWrapper{
        @AuraEnabled
        public string objectName;
        @AuraEnabled
        public String callID;
        @AuraEnabled
        public String callType;   
        @AuraEnabled
        public String recordId;   
    }
    
   
}