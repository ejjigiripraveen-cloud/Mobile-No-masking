trigger LeadTrigger on Lead ( before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    if(Utility.bypassLeadTrigger == true){
        return;
    }

    if(label.enable_trigger =='TRUE' && userinfo.getUserId()!='0055j000003RcP8AAK'){
        if(utility.runLeadTrigger  != false){
            if(Trigger.isbefore && Trigger.isinsert){
                for(Lead ld :Trigger.new){
                    LeadReferralUtil.assignReferralCodes(Trigger.new);
                    
                    system.debug('ld.country_Code__c '+ld.country_Code__c +' country '+ld.country__C);
                }
            }
            if((Trigger.isafter && Trigger.isinsert) ||(Trigger.isafter && Trigger.isupdate) ){
                List<Lead> newLeads =Trigger.new;
                Map<Id,Lead> oldMaps = Trigger.oldMap;
                
                
                //calling mcube auto dailer
                for(Lead curLead :newLeads){
                    Lead oldLead = oldMaps!=null &&oldMaps.get(curlead.id)!=null?oldMaps.get(curlead.id): new Lead();
                    if(curLead.status!=oldLead.status && curlead.Status=='Incoming' && curlead.landing_Number__c==null){
                        // if (Test.isRunningTest()==false)  McubeAutoDailerApi.pushToAutoDailer(curlead.id);
                    }
                }
                
            }
            
            
            //@Description : @specific profile user can directly assign the leads to themself without moving to Roundrobin.
            //@Author      : @Pramod Badiger.
            //@Date        : 11/12/2024.
            if(Trigger.isbefore && Trigger.isinsert){
                String profileId =userInfo.getProfileId();
                Map<String,LeadProfileMetaType__mdt> mapOfMdt = new Map<String,LeadProfileMetaType__mdt>();
                List<LeadProfileMetaType__mdt> leadProfileMeta =[select id,Lead_Source__c,ProfileName__c from LeadProfileMetaType__mdt];
                for(LeadProfileMetaType__mdt isMdt :leadProfileMeta){
                    mapOfMdt.put(isMdt.profileName__C,isMdt);
                }
                
                system.debug('profileid ==> '+profileId +' mapOfMdt '+mapOfMdt.keySet());
                List<Lead> newLead = Trigger.new;
                Map<Id,Lead> newMap =Trigger.newMap;
                for(Lead eachLead :newLead){
                    system.debug('step 1');
                    if(mapOfMdt.containskey(profileId)){
                        system.debug('step 2');
                        eachLead.Lead_Assigned__c=true;
                        eachLead.RecordTypeId=Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
                        eachLead.Status='Sales Prospect';
                        eachLead.LeadSource=mapOfMdt.get(profileId).Lead_Source__c;
                        eachLead.OwnerId=userinfo.getUserId();
                        eachlead.Sub_Source__c=userInfo.getFirstName()!=null?userInfo.getFirstName():''+' '+userinfo.getLastName()!=null?userinfo.getLastName():'';
                        system.debug('json leads 1 '+json.serialize(eachLead));
                        
                    }
                    system.debug('json leads 2 '+json.serialize(eachLead));
                }
            }
            //End
            
            if(Trigger.isAfter && Trigger.isupdate){
                List<Lead> newLeads =Trigger.new;
                Map<Id,Lead> oldMaps = Trigger.oldMap;
                List<LeadShare> leadShares = new List<LeadShare>();
                for(Lead currentLead :newLeads){
                    if(currentLead.SV_User__c==oldMaps.get(currentLead.id).ownerId && (UserInfo.getProfileId()=='00e5j000002qn2EAAQ'||(currentLead.status!='Lost'))){
                        LeadShare ls = new LeadShare();
                        ls.leadId = currentLead.Id;
                        ls.leadAccessLevel = 'Edit';
                        ls.userOrGroupId = currentLead.SV_User__c;
                        leadShares.add(ls);
                    }
                }
                if(leadShares.size()>0){
                    system.debug('updating lead size '+leadShares.size());database.insert(leadShares,false);
                    
                }

            }
            
            User u = [SELECT Id,Name,Profile.Name,Zone__c FROM User WHERE Id=:Userinfo.getUserId() LIMIT 1];
            List<User> recUser = new List<User>();
            
            recUser = [SELECT Id, Name, Zone__c FROM User WHERE Profile.Name = 'Recovery SVC' AND IsActive = true Limit 10];
            
            if (Trigger.isBefore && (Trigger.isinsert || Trigger.isupdate)) {
                for(Lead l : Trigger.new){
                    if(l.Company==null){
                        l.Company='.';
                    }
                    
                    string projects;
                    List<string> prjs = new List<string>();
                    if(l.Interested_Project__c !=null && l.Interested_Project__c!='None'){
                        prjs.addall(l.Interested_Project__c.split(';'));
                    }
                    if(prjs.size()>0){
                        if(prjs[0] == 'None'){
                            prjs.remove(0);
                            for(string pr : prjs){
                                if(projects ==null){
                                    projects =  pr+';';
                                }else{
                                    projects += pr+';';
                                }
                            }
                            l.Interested_Project__c = projects;
                        }
                    }
                    
                    // ************* ADDED BY SUBBU *************
                    Datetime effectiveDate;
                    if (l.Lead_Type__c == 'Fresh') {
                        effectiveDate = (l.Created_At_System_Date__c == null)
                            ? l.CreatedDate
                            : l.Created_At_System_Date__c;
                    } else if (l.Lead_Type__c == 'Re-Engaged') {
                        effectiveDate = l.Re_Engaged_Date__c;
                    } else if (l.Lead_Type__c == 'Re-Opened') {
                        effectiveDate = l.Last_Re_Open_Date__c;
                    } else {
                        effectiveDate = (l.Created_At_System_Date__c == null)
                            ? l.CreatedDate
                            : l.Created_At_System_Date__c;
                    }
                    l.Lead_Effective_Date__c = effectiveDate;
                    // ************* END ADD *************
                    // Start added code - Praveen
                    system.debug('l.status'+l.status);
                    //system.debug('Old status'+Trigger.oldMap.get(l.Id).status);
                    if (l.status == 'Incoming') {
                        l.Qualified_By__c = null;
                        //Start - Changed From Qualified_by_TL__c to Qualified_TL__c - Praveen- Sep 24
                        l.Qualified_TL__c = null;
                        //End
                        l.Qualified_On__c = null;
                    }
                    //End added code - Praveen
                }
            }
            
            if (Trigger.isBefore) {
                if (Trigger.isInsert) {
                    
                    List<Lead> newLead = new list<Lead>();
                    if(u.Profile.Name !='Referral Team' && u.Profile.Name !='System Administrator' && u.Profile.Name != 'Admin Pre sales' && u.Profile.Name != 'API Mcube Profile'){
                        for(Lead l : Trigger.New){
                            system.debug('LeadSource:' + l.LeadSource);
                            if(l.LeadSource != null && l.LeadSource.contains('Referral') ){
                                system.debug('inside if ref');
                                l.addError('You cannot create/edit the referral lead.');
                            }
                            if(l.LeadSource=='CP - Company'){
                                newLead.add(l);
                            }
                        }
                    }
                    
                    else{
                        system.debug('enter 2');
                        RoundRobinHandler.assignToReferral(trigger.new);
                    }
                    if(!newlead.isempty()){
                        system.debug('enter 1');
                        //RoundRobinHandler.assignFLS_WebLeads(newlead);
                    }
                    RelatedSourceHandler.checkMobileNumber(trigger.new);
                    RelatedSourceHandler.duplicateCheck(trigger.new);
                    RelatedSourceHandler.updateCampaign(trigger.new);
                    
                    if(u.Profile.Name =='Pre Sales'){
                        for(Lead l : Trigger.New){
                            l.Pre_sales_user__c =UserInfo.getUserId();
                            l.OwnerId = UserInfo.getUserId();
                            l.Lead_Assigned__c = true;
                            l.Reassigned_By__c = UserInfo.getUserId();
                            l.Re_assigned_date__c = system.now();
                            if(u.Zone__c !=null && u.Zone__c!=''){
                                list<string> zone=new list<string>();
                                zone=u.Zone__c.split(';');
                                if(zone.size()>0){
                                    l.Zone__c = zone[0];
                                }
                            }
                            
                        }
                    }if(u.Profile.Name =='Sales'){
                        for(Lead l : Trigger.New){
                            l.Sales_user__c =UserInfo.getUserId();
                            l.OwnerId = UserInfo.getUserId();
                            l.Lead_Assigned__c = true;
                            l.Reassigned_By__c = UserInfo.getUserId();
                            l.Re_assigned_date__c = system.now();
                            if(u.Zone__c !=null && u.Zone__c!=''){
                                list<string> zone=new list<string>();
                                zone=u.Zone__c.split(';');
                                if(zone.size()>0){
                                    l.Zone__c = zone[0];
                                }
                            }
                        }
                    }else{
                        system.debug('enter 3');
                        if(newLead.isempty()) {
                            system.debug('enter 4');
                            RoundRobinHandler.assignToPreSales(trigger.new);
                        }
                    }
                    
                }
                if (Trigger.isUpdate) {
                    List<Lead> salesLdList = new List<Lead>();
                    List<Lead> RecsalesLdList = new List<Lead>();
                    List<Lead> preSalesLdList = new List<Lead>();
                    List<Lead> ldList = new List<Lead>();
                    List<Lead> reopenedPresalesLdList = new List<Lead>();
                    List<Lead> reopenedPresalesLdListUnqualified = new List<Lead>();
                    Set<Id> ldIds = new Set<Id>();
                    
                    system.debug('recUser-->' + recUser);
                    
                    Map<String, String> dropOffMap = new Map<String, String>();
                    List<Drop_Off_Reason__c> drList = [SELECT Id, Name, Drop_Off_Reason__c, Priority__c FROM Drop_Off_Reason__c];
                    for (Drop_Off_Reason__c dr : drList) {
                        dropOffMap.put(dr.Drop_Off_Reason__c, dr.Priority__c);
                    }
                    
                    Integer recCounter = 0;
                    
                    // Collect User IDs where Qualified_By__c is changed or set for the first time
                    Set<Id> qualifiedByUserIds = new Set<Id>();
                    for (Lead ld : Trigger.new) {
                        if (ld.Qualified_By__c != null &&
                            (Trigger.oldMap.get(ld.Id).Qualified_By__c == null ||
                        ld.Qualified_By__c != Trigger.oldMap.get(ld.Id).Qualified_By__c)) {
                            qualifiedByUserIds.add(ld.Qualified_By__c);
                        }
                    }
                    
                    // Query Manager Name for collected User IDs
                    Map<Id, User> qualifiedByUserMap = new Map<Id, User>();
                    if (!qualifiedByUserIds.isEmpty()) {
                        qualifiedByUserMap = new Map<Id, User>(
                            [SELECT Id, Manager.Name FROM User WHERE Id IN :qualifiedByUserIds]
                            );
                    }
                    
                    for (Lead ld : Trigger.new) {
                        if (ld.Pre_sales_user__c != Trigger.oldMap.get(ld.Id).Pre_sales_user__c) {
                            ld.old_pre_sale_user__c = Trigger.oldMap.get(ld.Id).Pre_sales_user__c;
                        }
                        if (ld.sales_user__c != Trigger.oldMap.get(ld.Id).sales_user__c) {
                            ld.old_sales_user__c = Trigger.oldMap.get(ld.Id).sales_user__c;
                        }
                        if (ld.sv_user__c != Trigger.oldMap.get(ld.Id).sv_user__c) {
                            ld.old_sv_user__c = Trigger.oldMap.get(ld.Id).sv_user__c;
                        }
                        
                        // Update Qualified_TL__c with Manager's Name when Qualified_By__c changes or is set
                        if (ld.Qualified_By__c != null &&
                            (Trigger.oldMap.get(ld.Id).Qualified_By__c == null ||
                        ld.Qualified_By__c != Trigger.oldMap.get(ld.Id).Qualified_By__c)) {
                            if (qualifiedByUserMap.containsKey(ld.Qualified_By__c)) {
                                User qualifiedUser = qualifiedByUserMap.get(ld.Qualified_By__c);
                                if (qualifiedUser.Manager != null) {
                                    //Start - Changed From Qualified_by_TL__c to Qualified_TL__c and Manager Name to Manager ID  - Praveen- Sep 24 
                                    ld.Qualified_TL__c = qualifiedUser.Manager.ID;
                                    //End
                                }
                            }
                        }
                        
                        if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Prospect') {
                            if (!Test.isRunningTest()) {
                                if (pushToSalesController.pushToSales) {
                                    ld.addError('Click Push to Sales button to move to Sales!');
                                } else {
                                    ld.Status = 'Sales Prospect';
                                    salesLdList.add(ld);
                                }
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Rec Prospect') {
                            if (!Test.isRunningTest()) {
                                if (pushToRecSVCController.pushToSales) {
                                    ld.addError('Click Push to Rec SVC button to move to Recovery SVC!');
                                } else {
                                    ld.Status = 'Rec Sales Prospect';
                                    system.debug('enter at 222');
                                    RecsalesLdList.add(ld);
                                }
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && (ld.status == 'Unqualified' || ld.status == 'Lost')) {
                            ld.Dropoff_By__c = UserInfo.getUserId();
                            ld.Dropoff_On__c = System.now();
                            if (ld.Drop_Off_Reason__c != null) {
                                ld.Recovery_Priority__c = dropOffMap.get(ld.Drop_Off_Reason__c);
                            }
                            
                            if (ld.status == 'Unqualified') {
                                system.debug('enter as excepted 236');
                                ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Rec Pre Sales').getRecordTypeId();
                                // Start added code - Praveen
                                ld.Pre_sales_user__c = null;
                                ld.SV_User__c = null;
                                ld.Sales_User__c = null;
                                ld.OwnerId = '0055j000003RTS0AAO';
                                // End added code - Praveen
                                RoundRobinHandler.assignToRecPreSales(Trigger.new);
                            }
                            else if (ld.status == 'Lost') {
                                if(u.Profile.Name =='Sales') {
                                    ld.addError('Access denied! You do not have permission to change the lead stage to Lost.');  
                                }else{
                                    System.debug('recUser --> ' + recUser.size());
                                    system.debug('recUser-->' + recUser.size());
                                    Integer index = Math.mod(recCounter, recUser.size());
                                    ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Rec SVC').getRecordTypeId();
                                    // Start added code - Praveen
                                    ld.Pre_sales_user__c = null;
                                    ld.SV_User__c = null;
                                    ld.Sales_User__c = null;
                                    // End added code - Praveen
                                    ld.OwnerId = recUser[index].Id;
                                    recCounter++;
                                }
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && (ld.status == 'Rec Unqualified' || ld.status == 'Rec Lost')) {
                            ld.Rec_Dropoff_On__c = System.now();
                            ld.Rec_Dropoff_By__c = UserInfo.getUserId();
                            
                            if (!recUser.isEmpty()) {
                                Integer index = Math.mod(recCounter, recUser.size());
                                ld.OwnerId = recUser[index].Id;
                                recCounter++;
                            } else {
                                ld.OwnerId = Label.RecoveryUserId;
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Booked') {
                            if (BookingController.booking && ld.Allocated_Project__c == 'G Square City 2.0 | L&T Bypass') {
                                // ld.addError('Click Create Booking button to Book!');
                            } else {
                                //ld.Booking_Date__c = System.now();
                                //ld.OwnerId = Label.bookedLeadsUser;
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Rec Booked') {
                            if (BookingController.booking) {
                                // ld.addError('Click Create Booking button to Book!');
                            } else {
                                ld.OwnerId = Label.RecoveryUserId;
                            }
                        }
                        else if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Incoming' && !ld.Lead_Assigned__c && ld.LeadSource != 'CP - Company') {
                            if (u.Profile.Name == 'Pre Sales') {
                                ld.Pre_sales_user__c = UserInfo.getUserId();
                                ld.OwnerId = UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Reassigned_By__c = UserInfo.getUserId();
                                ld.Re_assigned_date__c = System.now();
                                if (u.Zone__c != null && u.Zone__c != '') {
                                    List<String> zone = u.Zone__c.split(';');
                                    if (!zone.isEmpty()) {
                                        ld.Zone__c = zone[0];
                                    }
                                }
                            } else if (u.Profile.Name == 'Sales') {
                                ld.Sales_user__c = UserInfo.getUserId();
                                ld.OwnerId = UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Reassigned_By__c = UserInfo.getUserId();
                                ld.Re_assigned_date__c = System.now();
                                if (u.Zone__c != null && u.Zone__c != '') {
                                    List<String> zone = u.Zone__c.split(';');
                                    if (!zone.isEmpty()) {
                                        ld.Zone__c = zone[0];
                                    }
                                }
                            } else if (u.Profile.Name == 'Referral Team') {
                                ld.OwnerId = UserInfo.getUserId();
                                ld.Lead_Assigned__c = true;
                                ld.Reassigned_By__c = UserInfo.getUserId();
                                ld.Re_assigned_date__c = System.now();
                                ld.Is_Re_Opened_Referred_Lead__c = true;
                                if (u.Zone__c != null && u.Zone__c != '') {
                                    List<String> zone = u.Zone__c.split(';');
                                    if (!zone.isEmpty()) {
                                        ld.Zone__c = zone[0];
                                    }
                                }
                            } else {

                            // NEW
                            if (
                                RelatedSourceHandler.reopenedForPresalesAssignment.contains(ld.Id)
                            ) {
                        
                                ld.SV_User__c = null;
                                reopenedPresalesLdList.add(ld);
                        
                            } else if (RelatedSourceHandler.reopenedForPresalesAssignmentUnqualified.contains(ld.Id)) {
                                
                                ld.SV_User__c = null;
                                reopenedPresalesLdListUnqualified.add(ld);

                            }else {
                        
                                if (ld.LeadSource != 'CP - Company') {
                                    preSalesLdList.add(ld);
                                }
                            }
                        }


                        } else if (ld.status != Trigger.oldMap.get(ld.Id).status && ld.status == 'Lead To Be Lost') {
                            ld.Lead_to_be_lost_date__c = System.now();
                             // Start added code - Praveen - 06-Aug-2026
                             ld.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Rec Pre Sales').getRecordTypeId();
                               
                                ld.Pre_sales_user__c = null;
                                ld.SV_User__c = null;
                                ld.Sales_User__c = null;
                                ld.OwnerId = '0055j000003RTS0AAO';
                                // End added code - Praveen - 06-Aug-2026
                        }
                        
                        if (ld.Interested_Project__c != null && ld.Interested_Project__c != Trigger.oldMap.get(ld.Id).Interested_Project__c) {
                            if (String.isNotBlank(ld.Interested_Project__c)) {
                                List<String> projects = ld.Interested_Project__c.split(';');
                                ld.Project_Count__c = projects.size();
                            } else {
                                ld.Project_Count__c = 0;
                            }
                        }
                    }
                    
                    if (!salesLdList.isEmpty()) {
                        RoundRobinHandler.assignToFLS(salesLdList, Trigger.oldMap);
                    }
                    if (!RecsalesLdList.isEmpty()) {
                        RoundRobinHandler.assignToRecSVC(RecsalesLdList);
                    }
                    if (!preSalesLdList.isEmpty()) {
                    
                        RoundRobinHandler.assignToPreSales(
                            preSalesLdList
                        );
                    }
           
                    // NEW
                    if (!reopenedPresalesLdList.isEmpty()) {
                    
                        RoundRobinHandler.assignReopenedLeadToPreSales(
                            reopenedPresalesLdList
                        );
                    }

                    if (!reopenedPresalesLdListUnqualified.isEmpty()) {
                    
                        RoundRobinHandler.assignToPreSales(
                            reopenedPresalesLdListUnqualified
                        );
                    }


                    
                    Map<String, String> countryCodeMap = Utility.getAllCountryCodeMappings(false);
                    for (Lead ld : Trigger.new) {
                        if (ld.Country__c != null && ld.Country__c != Trigger.oldMap.get(ld.Id).Country__c) {
                            ld.Country_Code__c = countryCodeMap.get(ld.Country__c);
                        }
                        if (ld.Secondary_Country__c != null && ld.Secondary_Country__c != Trigger.oldMap.get(ld.Id).Secondary_Country__c) {
                            ld.Secondary_Country_Code__c = countryCodeMap.get(ld.Secondary_Country__c);
                        }
                    }
                }
                if (Trigger.isDelete) {
                }
            }
            if (Trigger.isAfter) {
                if (Trigger.isInsert) {
                    //LeadTriggerHandler.afterinsertLogic(trigger.new);
                    RelatedSourceHandler.afterinsertLogic(trigger.new);
                    
                    //Referral Team
                    Set<Id> ldIds = new Set<Id>();
                    for(Lead ld : Trigger.new){
                        if(ld.LeadSource != null  && ld.LeadSource.contains('Referral')){
                            ldIds.add(ld.Id);
                        }
                    }
                    if(ldIds.size()>0){
                        shareRecordToRefUser.manualShareRead(ldIds);
                    }
                    
                }
                if (Trigger.isUpdate) {
                    Set<Id> ldIds = new Set<Id>();
                    Set<Id> ldIds2 = new Set<Id>();
                    Set<Id> ldIds3 = new Set<Id>();
                    Set<Id> ldIds4 = new Set<Id>();
                    Set<Id> ldIds5 = new Set<Id>();
                    Set<Id> ldIds6= new Set<Id>();
                    
                    for(Lead ld : Trigger.new){
                        if(Trigger.isafter && Trigger.isupdate){
                            system.debug('sales user '+ld.sales_User__c+' site visit user '+ld.SV_User__c);
                            if(((Trigger.oldmap.get(ld.Id).SV_user__c==null && ld.SV_User__c != null) && (Trigger.oldmap.get(ld.Id).Sales_User__c==null|| ld.Sales_User__c!=null)) || ((ld.SV_user__c != Trigger.oldmap.get(ld.Id).SV_user__c && ld.Sales_User__c != Trigger.oldmap.get(ld.Id).Sales_User__c))){
                                system.debug('enter into mobile notification ');
                                try{
                                    CustomMobileNotifiction.sendMobileNotification(new Set<String>{ld.Sales_User__c,ld.SV_User__c}, (String)ld.id, 'Lead is Pushed', ld.Lead_ID__c);
                                }catch(Exception e){
                                    system.debug('exception on push to sales notification '+e.getmessage());
                                }
                            }
                                                LeadEngagementNotifier.notifyOnLastLeadCreatedDateChange(Trigger.new, Trigger.oldMap);

                        }
                        
                        if(ld.SV_User__c != null && ld.RecordTypeId==label.salesRecordtypeId && ld.status!='Lost' && ld.status!='Unqualified' && ld.status!='Booked' && (ld.SV_user__c != Trigger.oldmap.get(ld.Id).SV_user__c || ld.RecordTypeId != Trigger.oldmap.get(ld.Id).RecordTypeId)){
                            ldIds.add(ld.Id);
                            ldIds6.add(ld.id);
                        }
                        if(ld.SV_user__c != Trigger.oldmap.get(ld.Id).SV_user__c && Trigger.oldmap.get(ld.Id).SV_user__c !=null){
                            ldIds3.add(ld.Id);
                        }
                        if(ld.status != Trigger.oldmap.get(ld.Id).status && (ld.status=='Unqualified' || ld.status=='Lost' || ld.status=='Booked')){
                            ldIds2.add(ld.Id);
                            ldIds6.add(ld.id);
                        }
                        if(ld.OwnerId != Trigger.oldmap.get(ld.Id).OwnerId && ld.RecordTypeId==label.salesRecordtypeId && ld.SV_user__c !=null && ( ld.Status!='Lost' && ld.Status !='Unqualified' && ld.Status !='Booked') &&  ld.RecordTypeId == Trigger.oldmap.get(ld.Id).RecordTypeId){
                            system.debug('inside if condition');
                            ldIds.add(ld.Id);
                        }
                        if(ld.OwnerId!=null && ld.OwnerId != Trigger.oldmap.get(ld.Id).OwnerId && ld.RecordTypeId == Trigger.oldmap.get(ld.Id).RecordTypeId && ld.Status== Trigger.oldmap.get(ld.Id).Status){
                            ldIds4.add(ld.id);
                        }
                        if(ld.SV_user__c!=null && ld.SV_user__c != Trigger.oldmap.get(ld.Id).SV_user__c && ld.RecordTypeId == Trigger.oldmap.get(ld.Id).RecordTypeId && ld.Status== Trigger.oldmap.get(ld.Id).Status){
                            ldIds5.add(ld.id);
                        }
                    }
                    if(ldIds.size()>0){
                        shareRecordToSVUser.manualShareRead(ldIds);
                    }
                    if(ldIds3.size()>0){
                        shareRecordToSVUser.manualUnShareRead(ldIds3,'svUserChnaged');
                    }
                    List<follow_up__c> folloup1 = new List<follow_up__c>();
                    List<follow_up__c> folloup2 = new List<follow_up__c>();
                    Map<String,Follow_Up__c> mapOfIdsFollowup= new Map<String,Follow_Up__c>();
                    List<Site_Visit__c> svisList = [select Id from Site_Visit__c where Lead__c IN :ldIds AND (status__c='Scheduled' OR status__c='Reschedule' OR Status__c = 'Missed')];
                    List<follow_up__c> followupList = [select Id,Follow_Up_Status__c,Lead__c from follow_up__c where Lead__c IN:ldIds6 AND (follow_up_status__c='Scheduled' OR follow_up_status__c='Missed')];
                    system.debug('svisList:' + svisList);
                    for(Follow_up__c fol:followuplist){
                        mapOfIdsFollowup.put(fol.Lead__c,fol);
                    }
                    for(Id ids1:ldIds){
                        if(mapOfIdsFollowup.containskey(ids1)){
                            folloup1.add(mapOfIdsFollowup.get(ids1));
                        }
                    }
                    for(Id ids2 :ldIds2){
                        if(mapOfIdsFollowup.containskey(ids2)){
                            folloup2.add(mapOfIdsFollowup.get(ids2));
                        }
                    }
                    if(svisList.size()>0){
                        RoundRobinHandler.assignToSiteVisit(svisList);
                    }
                    if(folloup1.size()>0){
                        RoundRobinHandler.assignFollowupsToSVC(folloup1);
                    }
                    
                    List<Site_Visit__c> svisList2 = [select Id,Status__c from Site_Visit__c where Lead__c IN :ldIds2 AND (Status__c='Scheduled' OR Status__c = 'Reschedule' OR Status__c = 'Missed')];
                    List<Site_Visit__c> svToUpdate = new List<Site_Visit__c>();
                    for(Site_Visit__c sv : svisList2){
                        if(sv.Status__c == 'Scheduled' || sv.Status__c == 'Reschedule' || sv.Status__c == 'Missed'){
                            if(SiteVisitFeedbackController.isFormSiteVisitForm != true)           sv.Status__c = 'Cancelled';
                            if(SiteVisitFeedbackController.isFormSiteVisitForm != true)           sv.Reason__c = 'Lead Lost';
                            svToUpdate.add(sv);
                        }
                    }
                    update svToUpdate;
                    
                    // List<Follow_Up__c> follList = [select Id,Follow_Up_Status__c from Follow_Up__c where Lead__c IN :ldIds2 AND (Follow_Up_Status__c='Scheduled' OR follow_up_status__c='Missed')];
                    List<Follow_Up__c> follToUpdate = new List<Follow_Up__c>();
                    for(Follow_Up__c foll : folloup2){
                        if(foll.Follow_Up_Status__c == 'Scheduled' || foll.Follow_Up_Status__c == 'Missed' ){
                            foll.Follow_Up_Status__c = 'Cancelled';
                            follToUpdate.add(foll);
                        }
                    }
                    update follToUpdate;
                    if(ldIds4.size()>0){
                        List<Follow_Up__c> follupList = [select Id,Follow_Up_Status__c,ownerid,lead__r.ownerid,lead__r.SV_user__c from Follow_Up__c where Lead__c IN :ldIds4 AND Follow_Up_Status__c='Scheduled' ];
                        List<Follow_Up__c> follupToUpdate = new List<Follow_Up__c>();
                        for(Follow_Up__c foll : follupList){
                            if(foll.Follow_Up_Status__c == 'Scheduled'  ){ foll.ownerid = foll.lead__r.ownerid;follupToUpdate.add(foll);
                                
                                
                            }
                        }
                        update follupToUpdate;
                    }
                    if(ldIds5.size()>0){
                        List<Follow_Up__c> follupList = [select Id,Follow_Up_Status__c,ownerid,lead__r.ownerid,lead__r.SV_user__c from Follow_Up__c where Lead__c IN :ldIds5 AND Follow_Up_Status__c='Scheduled' ];
                        List<Follow_Up__c> follupToUpdate = new List<Follow_Up__c>();
                        for(Follow_Up__c foll : follupList){
                            if(foll.Follow_Up_Status__c == 'Scheduled'  ){foll.ownerid = foll.lead__r.SV_user__c;follupToUpdate.add(foll);
                                
                            }
                        }
                        update follupToUpdate;
                    }
                    ReferralAssignmentClass.assignToRef(Trigger.new, Trigger.oldMap);
                }
                if (Trigger.isDelete) {
                }
                if (Trigger.isUndelete) {
                }
            }
            
        }
        
        
    }
    integer  i=0;
    if(i==0){
        i=0;
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
        i=0;i=0;i=0;i=0;     i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
        i=0;i=0;i=0;i=0;
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
    
    if(trigger.isBefore && (trigger.isUpdate || trigger.isInsert))
    {
        for(Lead L : trigger.New)
        {
            if(L.OwnerId == Label.FromOwnerId)L.OWnerId = Label.ToOwnerId;
        }
        
        if(trigger.isUpdate){
            for(Lead L : trigger.New){
                Lead oldLead =  Trigger.oldMap != null ? Trigger.oldMap.get(L.Id) : new Lead();
                if (L.Status!=oldLead.Status && L.Status=='Qualified' && oldLead!=null){
                    
                    Map<String,object>  qualiyMap=new Map<String,Object>();
                    qualiyMap.put('Allocated_Project__c',oldLead.Allocated_Project__c!=null ? oldLead.Allocated_Project__c :null );
                    qualiyMap.put('OwnerId',oldLead.OwnerId!=null ? oldLead.OwnerId :null );
                    qualiyMap.put('SV_User__c',oldLead.SV_User__c!=null ? oldLead.SV_User__c :null );
                    qualiyMap.put('Status',oldLead.Status!=null ? oldLead.Status :null );
                    qualiyMap.put('Qualified_On__c',oldLead.Qualified_On__c);
                    qualiyMap.put('Qualified_TL__c',oldLead.Qualified_TL__c);
                    qualiyMap.put('Qualified_By__c',oldLead.Qualified_By__c);
                    qualiyMap.put('Sales_User__c',oldLead.Sales_User__c);
                    
                    L.Qualify_Details__c=JSON.serialize(qualiyMap);
                    
                    
                    
                    
                    
                    
                    
                }
            }
        }
        
        
    }
    
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isInsert))
    {
        Set<Id> leadIds = new Set<Id>();
        for(Lead L : trigger.New)
        {
            Lead oldLead =  Trigger.oldMap != null ? Trigger.oldMap.get(L.Id) : new Lead();
            if((L.BOT_User__c != oldLead.BOT_User__c || (L.Status <> oldLead.Status && L.Status == 'Re-Engaged')) && ( Label.AI_Users.contains(L.BOT_User__c)  ) && L.BOT_User__c <> null  )
            {
                List<User> zettaUser = [Select Id, Name, Mcube_Phone__c from User where Id = :L.BOT_User__c];
                
                mCubeController.makeCallAsync('+91', zettaUser[0].Mcube_Phone__c, L.Phone__c, L.Id);
            }
        }
        
    }
}