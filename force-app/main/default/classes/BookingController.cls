public class BookingController {
    
     public static Boolean booking = true;
    
    @AuraEnabled
    public static Lead getLeadDetails(string recId){
        
        system.debug('recId:' + recId);
        
        List<Lead> leadList = [select Id,Name,Phone__c,DOB__c,Email__c,Email,LeadSource,Current_Address__c,Allocated_Project__c,Secondary_Phone__c,Secondary_Email__c,OwnerName__c,  Lead_Owner_TL__c from Lead where Id = :recId];
        
        if(leadList.size() > 0){
            return leadList[0];
        }
        return null;
    }

      @AuraEnabled
    public static List<String> fetchSources(){
           List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Opportunity_Plot__c.Source__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
		return pickListValuesList;
    }
          @AuraEnabled
    public static List<String> fetchBookingSources(){
           List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Opportunity_Plot__c.Booking_Source__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
		return pickListValuesList;
    }
     @AuraEnabled
    public static List<Project__c> getProjects(){
        /*List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = Opportunity__c.Project_Name__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}     
		return pickListValuesList;*/
       // List<Project__c> projList = new List<Project__c>();
        List<Project__c> projects = [SELECT Id, Name, Project_Id__c, Project__c FROM Project__c];
       /* for(Project__c p : projects){
            projNames.add(p.Project__c);
        }
        return projNames;*/
        
        return projects;
    }
   
    
         @AuraEnabled
    public static List<Plot__c> getPlots(string project){
        system.debug('project:' + project);
        List<Plot__c> plotList = [select Id,Name,Status__c,Project__r.Project__c,Size_as_per_site__c,Rate_Per_Sqft__c,Minimum_Price__c,Maximum_Price__c from Plot__c where Project__c = :project and Status__c = 'Available'];
        return plotList;
    }
    
         @AuraEnabled
    public static string saveOpp(Opportunity__c opp){
        
        if(opp != null){
            insert opp;
        }
       
        booking = false;
        Lead l = [select id,name from Lead where Id = :opp.Lead__c];
         l.Status = 'Booked';
        update l;
        
        return opp.Id;
        //ListView lw= [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType='Lead' AND DeveloperName='RecentlyViewedLeads'];
        //return lw.Id;
    }
    
       @AuraEnabled
    public static string saveOppPlots(Opportunity__c opp, List<Opportunity_Plot__c> plotlist, Date bookDate){
         
        system.debug(opp);
        system.debug(plotlist);
       //system.debug('opp.Project__c:' + opp.Project__c);
        String prjName = '', prjPhase = '';
        List<Opportunity__c> opOld = new List<Opportunity__c>();
        Lead ld = new Lead();
        if(opp != null){
            
             ld = [select id,name from Lead where Id = :opp.Lead__c];
           
            if(opp.Project__c != null ){
                Project__c prj = [select id,name,Project__c,Phase__c from Project__c where id = :opp.Project__c limit 1];
				prjName = prj.Project__c;
                prjPhase = prj.Phase__c;
            }
            
            
            
            opOld = [select id,name,Project_Name__c,Project__c,Project__r.Project__c,Phase__c,Date_of_Booking__c,Team_Lead__c,Source__c,Booking_Source__c,FLS_Name__c,Lead__c from Opportunity__c where Contact_number__c = :opp.Contact_number__c limit 1  ];
            if(opOld.size() > 0){
                opp = opOld[0];
            }
              opp.Project_Name__c = prjName;
			opp.Phase__c = prjPhase;          
            upsert opp;
        }
       
        List<User> userList = [Select id,name from user where profile.Name = 'CIT'];
        string managerId=  [Select Id, ManagerId FROM User WHERE Id = :UserInfo.getUserId()].ManagerId;
        
        List<Opportunity_Plot__c> oppPlots = new List<Opportunity_Plot__c>();
        for(Opportunity_Plot__c plot : plotList){
            Opportunity_Plot__c op = new Opportunity_Plot__c();
            op.Opportunity__c = opp.Id;
            
            op.Project_Name__c = prjName;
            op.Phase__c= prjPhase;
            system.debug('op.Project_Name__c:' + op.Project_Name__c + '-----opp.Project_Name__c: ' + opp.Project_Name__c);
            system.debug('op.Phase__c:' + op.Phase__c + '-----opp.Phase__c: ' + opp.Phase__c);
            op.Plot__c = plot.Plot__c;
            //op.Booking_date__c = (Date)opp.Date_of_Booking__c;
            if(opp.Date_of_Booking__c != null)   op.Booking_date__c = date.newinstance(opp.Date_of_Booking__c.year(), opp.Date_of_Booking__c.month(), opp.Date_of_Booking__c.day());
            op.Team_Lead_Name__c = opp.Team_Lead__c;
            op.FLS_Name__c = opp.FLS_Name__c;
            op.FLS__c = UserInfo.getUserId();
            if(managerId != null){
                op.FLS_TL__c = managerId;
            }
            op.Source__c = opp.Source__c;
            op.Booking_Source__c= opp.Booking_Source__c;
            op.Rate_per_sqft_Sales__c =plot.Rate_per_sqft_Sales__c;
            op.Plot_size__c = plot.Plot_size__c;
            op.All_inclusive_price__c = plot.All_inclusive_price__c;
            //op.Stage__c = 'Booked';
            if(userList.size () > 0){
                op.OwnerId = userList[0].id;
            }
            
            //op.Sold_Price__c = price;
            
            oppPlots.add(op);
        }
        insert oppPlots; 
        
        booking = false;
       
         ld.Status = 'Booked';
        update ld;
        ListView lw= [SELECT Id, Name, DeveloperName, SobjectType FROM ListView WHERE SobjectType='Lead' AND DeveloperName='RecentlyViewedLeads'];
        return lw.Id;
    }
  }