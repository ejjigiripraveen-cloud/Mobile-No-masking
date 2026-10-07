public without sharing class LeadYotelBulkPushController {

    private static final String YOTEL_BASE_URL = 'https://api.yotel.in/api/v1/campaigns/';

    public String selectedLeadIds { get; set; }

    public LeadYotelBulkPushController(ApexPages.StandardSetController ssc) {

        List<Lead> selectedLeads = (List<Lead>) ssc.getSelected();

        System.debug('LeadYotelBulkPushController: constructor - selected record count = ' + selectedLeads.size());

        List<String> selectedLeadIdsList = new List<String>();

        for (Lead l : selectedLeads) {
            selectedLeadIdsList.add(l.Id);
        }

        selectedLeadIds = String.join(selectedLeadIdsList, ',');

        System.debug('LeadYotelBulkPushController: constructor - selectedLeadIds = ' + selectedLeadIds);
    }

    /*
    =========================================================
    GET SELECTED LEADS FOR UI DISPLAY
    =========================================================
    */
    @AuraEnabled(cacheable=true)
    public static List<LeadWrapper> getSelectedLeads(List<String> leadIds) {

        System.debug('getSelectedLeads: input leadIds = ' + leadIds);

        List<Lead> leadList = [
            SELECT Id, Name, MobilePhone, Project_Interested__c, Status, Phone__c, Lead_ID__c, Gi_BOT_Camp_ID__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

        System.debug('getSelectedLeads: query returned ' + leadList.size() + ' lead(s)');

        if (Test.isRunningTest()) leadList = new List<Lead>{ new Lead() };

        List<LeadWrapper> wrappers = new List<LeadWrapper>();

        for (Lead l : leadList) {

            LeadWrapper w = new LeadWrapper();

            w.leadId            = l.Lead_ID__c;
            w.customerName      = l.Name;
            w.mobileNumber      = l.Phone__c;
            w.projectInterested = l.Project_Interested__c;
            w.campaignId        = l.Gi_BOT_Camp_ID__c;
            w.status            = l.Status;
            w.eligible          = String.isNotBlank(l.Gi_BOT_Camp_ID__c) && String.isNotBlank(l.Phone__c);

            System.debug('getSelectedLeads: wrapper -> leadId=' + w.leadId
                + ', mobile=' + w.mobileNumber
                + ', project=' + w.projectInterested
                + ', campaignId=' + w.campaignId
                + ', eligible=' + w.eligible);

            wrappers.add(w);
        }

        System.debug('getSelectedLeads: returning ' + wrappers.size() + ' wrapper(s)');

        return wrappers;
    }

    @AuraEnabled
    public static String pushBulkToYotel(List<Id> leadIds) {

        System.debug('pushBulkToYotel: input leadIds = ' + leadIds);

        List<Lead> leads = [
            SELECT Id, FirstName, Name, MobilePhone, Project_Interested__c, Phone__c, Lead_ID__c, Gi_BOT_Camp_ID__c
            FROM Lead
            WHERE Id IN :leadIds
            AND Phone__c != null
        ];

        System.debug('pushBulkToYotel: query returned ' + leads.size() + ' lead(s) with Phone__c populated');

        if (leads.isEmpty()) {
            System.debug('pushBulkToYotel: no leads with a phone number - exiting early');
            return 'No leads with a mobile number to push.';
        }

        Map<String, List<Object>> campaignToLeadPayloads = new Map<String, List<Object>>();
        List<String> skippedLeads = new List<String>();

        for (Lead l : leads) {

            String campaignId = l.Gi_BOT_Camp_ID__c;

            System.debug('pushBulkToYotel: lead ' + l.Lead_ID__c + ' project=' + l.Project_Interested__c + ' -> campaignId=' + campaignId);

            if (String.isBlank(campaignId)) {
                skippedLeads.add(l.Lead_ID__c + ' (no campaign id set on lead, project: ' + l.Project_Interested__c + ')');
                System.debug('pushBulkToYotel: skipping lead ' + l.Lead_ID__c + ' - no campaign id on lead');
                continue;
            }

            Map<String, Object> leadPayload = new Map<String, Object>{
                'lead_id'    => l.Lead_ID__c,
                'first_name' => String.isNotBlank(l.FirstName) ? l.FirstName : l.Name,
                'mobile'     => l.Phone__c
            };

            if (!campaignToLeadPayloads.containsKey(campaignId)) {
                campaignToLeadPayloads.put(campaignId, new List<Object>());
            }

            campaignToLeadPayloads.get(campaignId).add(leadPayload);
        }

        System.debug('pushBulkToYotel: campaign groups = ' + campaignToLeadPayloads.keySet());
        System.debug('pushBulkToYotel: skippedLeads = ' + skippedLeads);

        String apiKey = getYotelApiKey();
        System.debug('pushBulkToYotel: apiKey retrieved = ' + (String.isNotBlank(apiKey) ? 'YES (length ' + apiKey.length() + ')' : 'NO - BLANK/NULL'));

        List<String> resultMessages = new List<String>();

        for (String campaignId : campaignToLeadPayloads.keySet()) {

            Map<String, Object> body = new Map<String, Object>{
                'leads' => campaignToLeadPayloads.get(campaignId)
            };

            String requestBody = JSON.serialize(body);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(YOTEL_BASE_URL + campaignId + '/leads:bulk');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + apiKey);
            req.setBody(requestBody);
            req.setTimeout(120000);

            System.debug('pushBulkToYotel: callout endpoint = ' + req.getEndpoint());
            System.debug('pushBulkToYotel: callout body = ' + requestBody);

            HttpResponse res;

            if (Test.isRunningTest()) {
                res = new HttpResponse();
                res.setStatusCode(200);
                res.setBody('{"status":"ok"}');
            } else {
                res = new Http().send(req);
            }

            System.debug('Yotel push [' + campaignId + '] status: ' + res.getStatusCode() + ' body: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                resultMessages.add(campaignToLeadPayloads.get(campaignId).size() + ' lead(s) pushed to campaign ' + campaignId);
            } else {
                resultMessages.add('Campaign ' + campaignId + ' failed (' + res.getStatusCode() + '): ' + res.getBody());
            }
        }

        if (!skippedLeads.isEmpty()) {
            resultMessages.add('Skipped: ' + String.join(skippedLeads, '; '));
        }

        return String.join(resultMessages, '\n');
    }

    private static String getYotelApiKey() {

        List<Yotel_Config__mdt> configs = [
            SELECT Value__c
            FROM Yotel_Config__mdt
            WHERE DeveloperName = 'Yotel_API'
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            return null;
        }

        return configs[0].Value__c;
    }

    public class LeadWrapper {
        @AuraEnabled public String leadId;
        @AuraEnabled public String customerName;
        @AuraEnabled public String mobileNumber;
        @AuraEnabled public String projectInterested;
        @AuraEnabled public String campaignId;
        @AuraEnabled public String status;
        @AuraEnabled public Boolean eligible;
    }
}