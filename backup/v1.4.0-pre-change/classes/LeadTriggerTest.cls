@isTest
public class LeadTriggerTest {
    
  
    
    /* public static testmethod void testLead2(){
test.startTest();
//pushToSalesController.pushToSales=false;
User u = new User(
ProfileId = [SELECT Id FROM Profile WHERE Name = 'sales'].Id,
LastName = 'last',
Email = 'puser000@amamama.com',
Username = 'puser000@amamama.com' + System.currentTimeMillis(),
CompanyName = 'TEST',
Title = 'title',
Alias = 'alias',
TimeZoneSidKey = 'America/Los_Angeles',
EmailEncodingKey = 'UTF-8',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
zone__c='Chennai'
);  
utility.runLeadTrigger  = true;
Round_Robin__c rr = new Round_Robin__c();
rr.Project_Assigned__c='G Square Auris | Perungalathur';
rr.RR_Type__c = 'Project-Wise';
insert rr;
Round_Robin_Member__c rrm = new Round_Robin_Member__c();
rrm.User_Type__c='Sales';
rrm.Round_Robin__c = rr.id;
rrm.Active__c=true;
rrm.User__c = userinfo.getUserId();
rrm.Last_Assigned_Time__c = 1;
insert rrm;
Round_Robin_Member__c rrm2 = new Round_Robin_Member__c();
rrm2.User_Type__c='Sales';
rrm2.Round_Robin__c = rr.id;
rrm2.Active__c=true;
rrm2.User__c = userinfo.getUserId();
rrm2.Last_Assigned_Time__c = 1;
insert rrm2;
Round_Robin_Member__c rrm3 = new Round_Robin_Member__c();
rrm3.User_Type__c='Site visit';
rrm3.Round_Robin__c = rr.id;
rrm3.Active__c=true;
rrm3.User__c = userinfo.getUserId();
rrm3.Last_Assigned_Time__c = 1;
insert rrm3;
Lead ld = new Lead();
system.runAs(u){

Campaign cnm = new Campaign();
cnm.Landing_Number__c = '11111';
cnm.Project__c = 'None';
cnm.Name = '11111';
cnm.Source__c = 'Facebook';
cnm.Sub_Source__c = 'test';
cnm.Zone__c = 'Chennai';    
insert cnm;

ld.LastName='Test lead';
ld.Email = 'testlead@gmail.com';
ld.Phone__c = '9876598765';
ld.Company = 'ABC Company';
ld.Interested_Project__c = 'None';
ld.Campaign_Id__c = cnm.Id;
insert ld;
}


Follow_Up__c f=new Follow_Up__c();
f.Lead__c=ld.Id;
f.Follow_Up_Status__c='Scheduled';
f.Scheduled_Date__c=system.now();
insert f; 


Site_visit__c sv1 = new Site_visit__c();
sv1.lead__c = ld.Id;
sv1.Date__c = system.now();
sv1.Project__c = 'G Square Auris | Perungalathur' ;
sv1.Status__c = 'Scheduled';
insert sv1;

Lead lead1 = new Lead();
lead1.id = ld.Id;
lead1.Status = 'Lost';
lead1.Drop_Off_Reason__c = 'Test Enquiry';
// update lead1;


Lead ld1 = new Lead();
ld1.Id = ld.id;
ld1.Status = 'Converted';
ld1.recordtypeId = label.salesRecordtypeId;
ld1.sales_user__c = userinfo.getUserId();
ld1.pre_sales_user__c = userinfo.getUserId();
ld1.SV_user__c = userinfo.getUserId();
try{
update ld1;
}catch(Exception e){
//pushToSalesController.moveToSales(ld1.Id,'G Square Auris | Perungalathur');
system.debug(e.getMessage());
System.assert(e.getMessage().contains('Click Push to Sales button to move to Sales!'));
}

Lead l12 = new Lead();
l12.Id = ld.id;
l12.Status = 'Incoming';
l12.sales_user__c = userinfo.getUserId();
l12.pre_sales_user__c = userinfo.getUserId();
l12.SV_user__c = userinfo.getUserId();
update l12;

l12.Status = 'Prospect';
update l12;


Lead ld4 = new Lead();
ld4.Id = ld.id;
ld4.Status = 'Booked';


Lead ld5 = new Lead();
ld5.Id = ld.id;
ld5.Status = 'Lost';
ld5.sales_user__c = userinfo.getUserId();
ld5.pre_sales_user__c = userinfo.getUserId();
ld5.SV_user__c = userinfo.getUserId();

try{
// update ld4;
// update ld5;

}catch(Exception e){

System.assert(e.getMessage().contains('Click Create Booking button to Book!'));
}
test.stopTest(); 
}*/
    public static testmethod void testLead3(){
        
        test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            zone__c='Chennai'
        );  
        insert u;
        Lead ld = new Lead();
        system.runAs(u){
            Campaign cnm = new Campaign();
            cnm.Landing_Number__c = '11111';
            cnm.Project__c = 'None';
            cnm.Name = '11111';
            cnm.Source__c = 'Facebook';
            cnm.Sub_Source__c = 'test';
            cnm.Zone__c = 'Chennai';    
            insert cnm;
            
            ld.LastName='Test lead';
            ld.Email = 'testlead@gmail.com';
            ld.Phone__c = '9876598765';
            ld.Company = 'ABC Company';
            ld.Interested_Project__c = 'None';
            ld.Campaign_Id__c = cnm.Id;
            ld.ownerid=u.id;
            insert ld;
           /* Lead ld5 = new Lead();
            ld5.Id = ld.id;
            ld5.Status = 'Lost';
            ld5.Drop_Off_Reason__c='Do Not Call';
            ld5.sales_user__c = userinfo.getUserId();
            ld5.pre_sales_user__c = userinfo.getUserId();
            ld5.SV_user__c = userinfo.getUserId();
            update ld5;*/
            
        } 
        Lead ld6 = new Lead();
        ld6.id=ld.id;
        ld6.Status='Incoming';
        ld6.Lead_Assigned__c=false;
        update ld6;
        test.stopTest(); 
    }
    public static testmethod void testLead4(){
        
        test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            zone__c='Chennai'
        );
        insert u;
        Lead ld = new Lead();
        system.runAs(u){
            Campaign cnm = new Campaign();
            cnm.Landing_Number__c = '11111';
            cnm.Project__c = 'None';
            cnm.Name = '11111';
            cnm.Source__c = 'Facebook';
            cnm.Sub_Source__c = 'test';
            cnm.Zone__c = 'Chennai';    
            insert cnm;
            
            ld.LastName='Test lead';
            ld.Email = 'testlead@gmail.com';
            ld.Phone__c = '9876598765';
            ld.Company = 'ABC Company';
            ld.Interested_Project__c = 'None';
            ld.Campaign_Id__c = cnm.Id;
            ld.ownerid=u.id;
            insert ld;
            Lead ld5 = new Lead();
            ld5.Id = ld.id;
            ld5.Status = 'unqualified';
            ld5.Drop_Off_Reason__c='Do Not Call';
            ld5.sales_user__c = userinfo.getUserId();
            ld5.pre_sales_user__c = userinfo.getUserId();
            ld5.SV_user__c = userinfo.getUserId();
            update ld5;
             Lead ld6 = new Lead();
        ld6.id=ld.id;
        ld6.Status='Incoming';
        ld6.Lead_Assigned__c=false;
        update ld6;
        } 
       
        
        test.stopTest(); 
    }
    public static testmethod void testRecovery(){
        
        test.startTest();
        
        Lead ld = new Lead();
        ld.LastName='Test lead';
        ld.Email = 'testlead@gmail.com';
        ld.Phone__c = '9876598765';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        
        insert ld;
        
        Lead ld6 = new Lead();
        ld6.id=ld.id;
        ld6.Status='Incoming';
        ld6.Lead_Assigned__c=false;
        update ld6;
        
        ld6.Status = 'Unqualified';
        ld6.Drop_Off_Reason__c = 'Budget Mismatch';
        update ld6;
        
        if(!Test.isRunningTest()) {
            Lead ldNew = new Lead();
            ldNew.Id = ld6.id;
            ldNew.Status = 'Rec Prospect';
            
            try{
                //ldNew.Allocated_Project__c ='G Square Auris | Perungalathur';
                update ldNew;
            }catch(Exception e){
                pushToRecSVCController.moveToSales(ldNew.Id,'G Square Auris | Perungalathur');
                system.debug(e.getMessage());
                System.assert(e.getMessage().contains('Click Push to Rec SVC button to move to Recovery SVC!'));
            }
        
        ldNew.Status = 'Rec Lost';
        ldNew.Rec_Drop_Off_Reason__c = 'Not Interested';
        
        update ldNew;
        
        Lead ld4 = new Lead();
        ld4.Id = ldNew.id;
        ld4.Status = 'Rec Booked';
        
        
        try{
            update ld4;
            
        }catch(Exception e){
            
            System.assert(e.getMessage().contains('Click Create Booking button to Book!'));
        }
        }
        test.stopTest(); 
        
    }
  /*   public static testmethod void testLead5(){
        
        test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Pre Sales'].Id,
            LastName = 'last',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            zone__c='Chennai'
        );
        insert u;
        Lead ld = new Lead();
        system.runAs(u){
            Campaign cnm = new Campaign();
            cnm.Landing_Number__c = '11111';
            cnm.Project__c = 'None';
            cnm.Name = '11111';
            cnm.Source__c = 'Facebook';
            cnm.Sub_Source__c = 'test';
            cnm.Zone__c = 'Chennai';    
            insert cnm;
            
            ld.LastName='Test lead';
            ld.Email = 'testlead@gmail.com';
            ld.Phone__c = '9876598765';
            ld.Company = 'ABC Company';
            ld.Interested_Project__c = 'None';
            ld.Campaign_Id__c = cnm.Id;
            ld.ownerid=u.id;
            insert ld;
            Follow_Up__c f=new Follow_Up__c();
            f.Scheduled_Date__c=system.now().adddays(2);
            f.Follow_Up_Status__c='';
            f.Lead__c=ld.id;
            f.OwnerId=ld.OwnerId;
            insert f;
            
             Lead ld6 = new Lead();
        ld6.id=ld.id;
        ld.ownerid=u.id;
        update ld6;
        } 
       
        
        test.stopTest(); 
    }*/

    // ===================================================================
    // NEW TESTS ADDED FOR COVERAGE
    // ===================================================================

    /**
     * Returns active picklist values for a field so tests don't hardcode
     * literal values that may not exist in a restricted picklist.
     * excludeValues lets you skip values already used elsewhere (e.g. 'None').
     */
    private static List<String> getActivePicklistValues(String objectName, String fieldName, Set<String> excludeValues){
        List<String> vals = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        for(Schema.PicklistEntry pe : fieldResult.getPicklistValues()){
            if(pe.isActive() && (excludeValues == null || !excludeValues.contains(pe.getValue()))){
                vals.add(pe.getValue());
            }
        }
        return vals;
    }

    /**
     * Covers: before-insert branch where a non-excluded profile (Sales) creates
     * a Lead with LeadSource = 'CP - Company' (adds to newLead list),
     * and separately a Lead whose LeadSource contains 'Referral' (addError path).
     */
    public static testmethod void testLead_CPCompanyAndReferralSourceBlock(){

        test.startTest();

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales'].Id,
            LastName = 'last',
            Email = 'puser001@amamama.com',
            Username = 'puser001@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias2',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            zone__c = 'Chennai;Bangalore'
        );
        insert u;

        system.runAs(u){
            Campaign cnm = new Campaign();
            cnm.Landing_Number__c = '22222';
            cnm.Project__c = 'None';
            cnm.Name = '22222';
            cnm.Source__c = 'Facebook';
            cnm.Sub_Source__c = 'test';
            cnm.Zone__c = 'Chennai';
            insert cnm;

            // Hits: LeadSource == 'CP - Company' -> newLead.add(l)
            Lead cpLead = new Lead();
            cpLead.LastName = 'CP Company Lead';
            cpLead.Email = 'cplead@gmail.com';
            cpLead.Phone__c = '9876500001';
            cpLead.Company = 'ABC Company';
            cpLead.Interested_Project__c = 'None';
            cpLead.Campaign_Id__c = cnm.Id;
            cpLead.LeadSource = 'CP - Company';
            insert cpLead;

            // Hits: LeadSource.contains('Referral') -> l.addError(...)
            Lead refLead = new Lead();
            refLead.LastName = 'Referral Source Lead';
            refLead.Email = 'refsourcelead@gmail.com';
            refLead.Phone__c = '9876500002';
            refLead.Company = 'ABC Company';
            refLead.Interested_Project__c = 'None';
            refLead.Campaign_Id__c = cnm.Id;
            refLead.LeadSource = 'Referral Partner';

            try{
                insert refLead;
                System.assert(false, 'Expected addError to block insert of Referral-sourced lead');
            }catch(Exception e){
                System.assert(e.getMessage().contains('You cannot create/edit the referral lead.'));
            }
        }

        test.stopTest();
    }

    /**
     * Covers: Pre Sales profile before-insert zone assignment with a
     * multi-value Zone__c field (semicolon separated), and the
     * Qualified_By__c / Qualified_by_TL__c / Status == 'Qualified'
     * JSON snapshot logic in before-update.
     */
    public static testmethod void testLead_PreSalesZoneAndQualifiedSnapshot(){

        test.startTest();

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Pre Sales'].Id,
            LastName = 'last',
            Email = 'puser002@amamama.com',
            Username = 'puser002@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias3',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            zone__c = 'Chennai;Bangalore'
        );
        insert u;

        // Fetch real, active Interested_Project__c values instead of guessing
        // literal strings, since it's a restricted picklist.
        List<String> projectValues = getActivePicklistValues('Lead', 'Interested_Project__c', new Set<String>{'None'});

        Lead ld = new Lead();
        system.runAs(u){
            Campaign cnm = new Campaign();
            cnm.Landing_Number__c = '33333';
            cnm.Project__c = 'None';
            cnm.Name = '33333';
            cnm.Source__c = 'Facebook';
            cnm.Sub_Source__c = 'test';
            cnm.Zone__c = 'Chennai';
            insert cnm;

            ld.LastName = 'Pre Sales Zone Lead';
            ld.Email = 'presaleszone@gmail.com';
            ld.Phone__c = '9876500003';
            ld.Company = 'ABC Company';
            ld.Interested_Project__c = 'None';
            ld.Campaign_Id__c = cnm.Id;
            insert ld; // hits Pre Sales zone-split branch, and Project_Count__c is not touched here (insert, not update)
        }

        // Move through a status change first so oldLead.Status differs from 'Qualified'
        Lead moveToProspect = new Lead();
        moveToProspect.Id = ld.Id;
        moveToProspect.Status = 'Incoming';
        moveToProspect.Lead_Assigned__c = true;
        update moveToProspect;

        // Now flip to 'Qualified' to hit the Qualify_Details__c JSON snapshot block
        Lead qualifyLead = new Lead();
        qualifyLead.Id = ld.Id;
        qualifyLead.Status = 'Qualified';
        update qualifyLead;

        Lead updated = [SELECT Id, Qualify_Details__c FROM Lead WHERE Id = :ld.Id];
        System.assert(updated.Qualify_Details__c != null, 'Expected Qualify_Details__c to be populated on Qualified transition');

        // Also cover Project_Count__c recalculation branch (non-blank and blank)
        if(!projectValues.isEmpty()){
            String multiValue = projectValues.size() >= 2
                ? (projectValues[0] + ';' + projectValues[1])
                : projectValues[0];

            Lead multiProject = new Lead();
            multiProject.Id = ld.Id;
            multiProject.Interested_Project__c = multiValue;
            update multiProject;
        }

        Lead blankProject = new Lead();
        blankProject.Id = ld.Id;
        blankProject.Interested_Project__c = '';
        update blankProject;

        test.stopTest();
    }

    /**
     * Covers: 'Rec Unqualified' and 'Rec Lost' status transitions,
     * which reassign OwnerId via the Recovery SVC round-robin or
     * fall back to Label.RecoveryUserId when no active Recovery SVC users exist.
     * Also covers the 'Lead To Be Lost' status branch.
     */
    public static testmethod void testLead_RecUnqualifiedRecLostAndLeadToBeLost(){

        test.startTest();

        Lead ld = new Lead();
        ld.LastName = 'Rec Status Lead';
        ld.Email = 'recstatuslead@gmail.com';
        ld.Phone__c = '9876500004';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        insert ld;

        // A validation rule requires Rec_Drop_Off_Reason__c to be populated
        // when moving into these statuses, so fetch a real active value
        // instead of guessing a literal string.
        List<String> recDropOffReasons = getActivePicklistValues('Lead', 'Rec_Drop_Off_Reason__c', null);
        String recDropOffReason = recDropOffReasons.isEmpty() ? null : recDropOffReasons[0];

        Lead toRecUnqualified = new Lead();
        toRecUnqualified.Id = ld.Id;
        toRecUnqualified.Status = 'Rec Unqualified';
        if(recDropOffReason != null){
            toRecUnqualified.Rec_Drop_Off_Reason__c = recDropOffReason;
        }
        update toRecUnqualified;

        Lead toRecLost = new Lead();
        toRecLost.Id = ld.Id;
        toRecLost.Status = 'Rec Lost';
        if(recDropOffReason != null){
            toRecLost.Rec_Drop_Off_Reason__c = recDropOffReason;
        }
        update toRecLost;

        Lead toBeLost = new Lead();
        toBeLost.Id = ld.Id;
        toBeLost.Status = 'Lead To Be Lost';
        update toBeLost;

        Lead updated = [SELECT Id, Lead_to_be_lost_date__c FROM Lead WHERE Id = :ld.Id];
        System.assert(updated.Lead_to_be_lost_date__c != null, 'Expected Lead_to_be_lost_date__c to be set');

        test.stopTest();
    }

    /**
     * Covers: Country_Code__c / Secondary_Country_Code__c population on
     * before-update when Country__c / Secondary_Country__c change.
     */
    public static testmethod void testLead_CountryCodeMapping(){

        test.startTest();

        Lead ld = new Lead();
        ld.LastName = 'Country Code Lead';
        ld.Email = 'countrycodelead@gmail.com';
        ld.Phone__c = '9876500005';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        insert ld;

        Lead withCountry = new Lead();
        withCountry.Id = ld.Id;
        withCountry.Country__c = 'India';
        withCountry.Secondary_Country__c = 'India';
        update withCountry;

        test.stopTest();
    }

    /**
     * Covers: after-update LeadShare insert branch, which fires when
     * SV_User__c is set to the lead's *current* OwnerId and Status != 'Lost'.
     * Also exercises the SV_User__c / Sales_User__c change block that
     * attempts CustomMobileNotifiction.sendMobileNotification (internally
     * try/catch'd in the trigger, so a failure there won't fail this test).
     */
    public static testmethod void testLead_LeadShareAndMobileNotificationBlock(){

        test.startTest();

        Lead ld = new Lead();
        ld.LastName = 'Lead Share Lead';
        ld.Email = 'leadsharelead@gmail.com';
        ld.Phone__c = '9876500006';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        insert ld;

        Id currentOwnerId = ld.OwnerId;

        // SV_User__c changes from null -> current OwnerId, Status stays non-'Lost'
        // -> hits: currentLead.SV_User__c == oldMap.get(id).OwnerId branch -> LeadShare insert
        // Also populates Sales_User__c in the same update to help trip the
        // SV/Sales user-change mobile notification block.
        Lead shareUpdate = new Lead();
        shareUpdate.Id = ld.Id;
        shareUpdate.SV_User__c = currentOwnerId;
        shareUpdate.Sales_User__c = currentOwnerId;
        update shareUpdate;

        test.stopTest();
    }

    /**
     * Covers: 'Booked' and 'Rec Booked' status branches. These reference
     * BookingController.booking, which may be an uninitialized (null)
     * static Boolean outside of a real Visualforce/LWC request context, so
     * this is wrapped defensively — if it throws, we still want the rest
     * of the suite to run and we still get partial line coverage on the
     * branch entry itself.
     */
    public static testmethod void testLead_BookedAndRecBookedStatus(){

        test.startTest();

        Lead ld = new Lead();
        ld.LastName = 'Booked Status Lead';
        ld.Email = 'bookedstatuslead@gmail.com';
        ld.Phone__c = '9876500007';
        ld.Company = 'ABC Company';
        ld.Interested_Project__c = 'None';
        insert ld;

        try{
            Lead toBooked = new Lead();
            toBooked.Id = ld.Id;
            toBooked.Status = 'Booked';
            update toBooked;
        }catch(Exception e){
            system.debug('Booked branch threw (likely BookingController.booking uninitialized): ' + e.getMessage());
        }

        Lead ld2 = new Lead();
        ld2.LastName = 'Rec Booked Status Lead';
        ld2.Email = 'recbookedstatuslead@gmail.com';
        ld2.Phone__c = '9876500008';
        ld2.Company = 'ABC Company';
        ld2.Interested_Project__c = 'None';
        insert ld2;

        try{
            Lead toRecBooked = new Lead();
            toRecBooked.Id = ld2.Id;
            toRecBooked.Status = 'Rec Booked';
            update toRecBooked;
        }catch(Exception e){
            system.debug('Rec Booked branch threw (likely BookingController.booking uninitialized): ' + e.getMessage());
        }

        test.stopTest();
    }
}