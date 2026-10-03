@isTest
public class BookingControllerTest {

    public static testmethod void testBooking(){
        Round_Robin__c rr = new Round_Robin__c();
       rr.Project_Assigned__c='G square Ambrosia | Padur';
        rr.RR_Type__c = 'Project-Wise';
       insert rr;
         Round_Robin_Member__c rrm = new Round_Robin_Member__c();
       rrm.User_Type__c='Pre Sales';
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
        Lead ld = new Lead();
        ld.LastName = 'Test';
        ld.Phone__c = '9847383567';
        ld.Email__c = 'test@gmail.com';
        ld.Company = 'XYZ ';
        insert ld;
        
        Project__c prj = new Project__c();
        prj.Name = 'G square Ambrosia | Padur';
        prj.Project__c = 'G square Ambrosia | Padur';
        prj.Phase__c = 'Phase 1';
        insert prj;
        
        List<Plot__c> plotlist = new List<Plot__c>();
        Plot__c plot = new Plot__c();
        plot.Project__c = prj.Id;
        plot.Name = prj.Name;
        insert plot;
        plotlist.add(plot);
        
        Opportunity__c opp = new Opportunity__c();
        opp.Lead__c = ld.Id;
        opp.Email_ID__c = 'opp@gmail.com';
        opp.Contact_number__c = '9738234323';
        opp.Project__c = prj.Id;
        
        List<Opportunity_Plot__c> oppPlots = new List<Opportunity_Plot__c>();
        Opportunity_Plot__c oppPlot = new Opportunity_Plot__c();
        oppPlot.Plot__c = plot.Id;
        oppPlot.Plot_size__c = 20.0;
        oppPlot.Rate_per_sqft_Sales__c = 2000.0;
        oppPlot.All_inclusive_price__c = oppPlot.Plot_size__c * oppPlot.Rate_per_sqft_Sales__c;
        oppPlots.add(oppPlot);
        
        BookingController.getLeadDetails(ld.Id);
        BookingController.fetchSources();
         BookingController.fetchBookingSources();
        //BookingController.getAccounts();
        BookingController.getProjects();
        BookingController.getPlots(prj.Id);
       
        BookingController.saveOpp(opp);
           BookingController.saveOppPlots(opp, oppPlots, system.today());
      
    }
}