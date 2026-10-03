/* @Description : Once the lead status is changed to incoming push the 
 *                data to auto dailer.
 * @Author      : Pramod Badiger
 * @Date        : 27/11/2024
 * 
 */ 
public class McubeAutoDailerApi {            
     private static final String AUTH_TOKEN = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJUSEVfQ0xBSU0iLCJhdWQiOiJUSEVfQVVESUVOQ0UiLCJpYXQiOjE3NTQwNjE2MTksImV4cF9kYXRhIjoxNzg1NTk3NjE5LCJkYXRhIjp7ImJpZCI6IjYxOTAifX0.h4DKO0fk9sNwMlbOCei5oxwWWbtbSuRgaSDD05OTfgw';

    @future(callout=true)
    public static void pushToAutoDailer(string leadID){
        
        List<Object> loadBody = new List<object>();
        Map<String,object> mapOfObject = new Map<String,Object>();
        Map<String,object> reqMap = new Map<String,object>();
       
        List<Lead> leadList =[select id,Phone__c, owner.phone from Lead where id =: leadId];
        Lead curLead =leadlist.size()>0?leadList[0]:new Lead();
        if(curLead.Phone__c!=null) mapOfObject.put('number',long.valueOf(curLead.Phone__c));
        if(curlead.owner.phone!=null) mapOfObject.put('eid',    long.valueOf(curLead.owner.phone));
        loadBody.add(mapOfObject);
        reqMap.put('campaign_id',815);
        reqMap.put('listData',loadBody);
        string  body = JSON.serialize(reqMap);
        
        system.debug('request body '+body);
        String url='https://config.mcube.com/Restmcube-api/campaign';
        // Instantiate a new Http object
        Http h = new Http();
        
        
        // Instantiate a new HTTP request
        // Specify request properties such as the endpoint, the POST method, etc. 
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', AUTH_TOKEN);
        
        req.setBody(body);
        
        HttpResponse res = h.send(req);
        system.debug('response '+res.getbody());
     
    }

}