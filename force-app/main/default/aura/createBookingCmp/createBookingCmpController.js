({
    doInit : function(component, event, helper) {
        
        var recId = component.get("v.recordId");
        
        var opp = component.get("v.opp");
        
        
        var action=component.get("c.getLeadDetails");  
        action.setParams({
            recId:recId
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var lead = response.getReturnValue();
                if(lead.Status != 'Booked'){
                     component.set("v.lead",response.getReturnValue());
                
                var Lsource = lead.LeadSource;
                component.set("v.LeadSource", Lsource);
                
                
                opp.Name = lead.Name;
                opp.Contact_number__c = lead.Phone__c;
                opp.Customer_DOB__c = lead.DOB__c;
                opp.Email_ID__c = lead.Email;
                opp.Address__c = lead.Current_Address__c;
                opp.Project_Name__c = lead.Allocated_Project__c;
                opp.Lead__c = recId;
                opp.Contact_number_1__c = lead.Secondary_Phone__c;
                opp.Email_ID_1__c = lead.Secondary_Email__c;
                opp.FLS_Name__c = lead.OwnerName__c;
                opp.Team_Lead__c = lead.Lead_Owner_TL__c;
                opp.Source__c = lead.LeadSource;
                
                var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
                opp.Date_of_Booking__c = today;
                

                component.set("v.opp",opp);
                
                }
                else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        message: 'Lead is already Booked.',
                        type : 'error'
                    });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                }
               
                
            }
        });
        $A.enqueueAction(action);
        
        var action2=component.get("c.getProjects");  
        
        action2.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var projects = response.getReturnValue();
                component.set("v.projects",projects);
            }
        });
        $A.enqueueAction(action2);
        
        /*var action3=component.get("c.getAccounts");  
     
        action3.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var accounts = response.getReturnValue();
                component.set("v.accounts",accounts);
            }
        });
        $A.enqueueAction(action3);*/
        
        var action4=component.get("c.fetchSources");  
        
        action4.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var sources = response.getReturnValue();
                component.set("v.sources",sources);
            }
        });
        $A.enqueueAction(action4);
        
        var action5=component.get("c.fetchBookingSources");
        
        action5.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var Bsources = response.getReturnValue();
                component.set("v.Bsources",Bsources);
            }
        });
        $A.enqueueAction(action5);
    },
    
    cancel: function (cmp, event) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
    next: function (component, event) {
        //  alert('sdfds')
        var proj = component.get("v.opp").Project__c;
         var projName = component.get("v.opp").Project_Name__c;
            var projects = component.get("v.projects");
            var opp = component.get("v.opp");
       var projFound;
        //alert(proj)
        if(proj == ''){
            
            for(var i=0;i<projects.length;i++){
                //alert(projName + '-----' + projects[i].Name)
                if(projName == projects[i].Name){
                    
                    proj = projects[i].Id;
                    opp.Project__c = proj;
                  //  alert('proj:' + proj)
                    break;
                }
            }
          //  alert(proj)
           // alert(projName)
               
            component.set('v.opp',opp);
        	
            if(proj == ''){
                projFound = false;
                alert('Please select project.')
            }
            else{
                projFound = true;
            }
            
        }
        else{
            projFound = true;
        }
       // alert(component.get("v.opp").Project__c)
       // alert(projFound)
        if(projFound){
              var action4=component.get("c.getPlots");  
       // alert(component.get("v.opp").Project__c)
        action4.setParams({
            project:component.get("v.opp").Project__c
           //project:proj
        });
        action4.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var plots = response.getReturnValue();
                console.log(plots);
                //component.find=("plotsize").set("v.value",23)
                //     var sz= 23;
                // console.log('sizeeeee'+sz);
                component.set("v.plots",plots);
                //   component.set("v.pSize",sz);
                // var d =component.get("v.pSize");
                //console.log('ddddddd'+d);
            }
        });
        $A.enqueueAction(action4);
            
            var oppplot = component.get("v.oppplot");
        
        oppplot.push({
            'sobjectType': 'Opportunity_Plot__c',
            'Plot__c' : '',
            'Rate_per_sqft_Sales__c ' : '',
            'Plot_size__c' : '',
            'All_inclusive_price__c' : ''
            
        });
        component.set("v.oppplot", oppplot);
        
        component.set("v.showPlotPopup",true);
        }
      
        
      /*  var oppplot = component.get("v.oppplot");
        
        oppplot.push({
            'sobjectType': 'Opportunity_Plot__c',
            'Plot__c' : '',
            'Rate_per_sqft_Sales__c ' : '',
            'Plot__r.Minimum_Price__c' : '',
            'Plot__r.Maximum_Price__c' : '',
            'Plot_size__c' : '',
            'All_inclusive_price__c' : ''
            
        });
        component.set("v.oppplot", oppplot);*/
        
    },
    previous: function (component, event) {
        //  alert('sdfds')
        
        component.set("v.showPlotPopup",false);
    },
    validate:  function (component, event) {
        var opp = component.get('v.opp');
        var plotLists = component.get('v.oppplot');
        
        
        for(var i=0;i<plotLists.length;i++){
            if(plotLists[i].Plot_size__c() == ''){
                alert('Enter Size on row ' + (i+1));
            }
            if(plotLists[i].Rate_per_sqft_Sales__c  == ''){
                alert('Enter Rate on row ' + (i+1));
            }
        }
    },
    save: function (component, event) {
        
        var opp = component.get('v.opp');
        //var selectedLookUpRecords = component.get('v.selectedLookUpRecords');
        var plotLists = component.get('v.oppplot');
        var bookingdate = component.get('v.bookingDate');
        //var soldprice = component.get('v.soldPrice');
        var validate = true;
        
        for(var i=0;i<plotLists.length;i++){
            
            if(plotLists[i].Plot__c == ''){
                alert('Select Plot on row ' + (i+1));
                validate = false;
            }
            else if(plotLists[i].Plot_size__c == ''){
                alert('Enter Size on row ' + (i+1));
                validate = false;
            }
                else if(plotLists[i].Rate_per_sqft_Sales__c  == ''){
                    alert('Enter Rate on row ' + (i+1));
                    validate = false;
                }
                    else if(plotLists[i].Rate_per_sqft_Sales__c  != '' && (plotLists[i].Rate_per_sqft_Sales__c  > plotLists[i].Maximum_Price__c || plotLists[i].Rate_per_sqft_Sales__c  < plotLists[i].Minimum_Price__c)){
                         alert('Rate is out of Minimum/Maximum Range on row ' + (i+1));
                    validate = false;
                    }
                    else{
                        validate = true;
                    }
        }
        if(validate == true){
            console.log(opp);
            // console.log(selectedLookUpRecords);
            console.log(bookingdate);
            //console.log(soldprice);
            console.log(plotLists);
            // var action=component.get("c.saveOpp");  
            
            var action=component.get("c.saveOppPlots");
            console.log(action)
            action.setParams({
                opp:opp,
                plotlist: plotLists,
                bookDate: bookingdate
            });
            action.setCallback(this,function(response){
                
                if(response.getState()=="SUCCESS"){ 
                    /* var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Booking are created successfully!',
                    type : 'success'
                });
                toastEvent.fire();*/
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Lead moved to Post sales team',
                    type : 'success'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                var listviews = response.getReturnValue();
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": listviews,
                    "listViewName": null,
                    "scope": "Lead"
                });
                navEvent.fire();
            }
        });
            $A.enqueueAction(action);
        }
        
    },
    save2: function (component, event) {
        
        var opp = component.get('v.opp');
        //var selectedLookUpRecords = component.get('v.selectedLookUpRecords');
       // var plotLists = component.get('v.oppplot');
        var bookingdate = component.get('v.bookingDate');
       
        //var soldprice = component.get('v.soldPrice');
        var validate = true;
       
         if(component.get('v.opp.Contact_number__c') == null){
                alert('Please enter Contact number');
                validate = false;
            }
         else if(component.get('v.opp.Alternate_contact_number__c') == null){
                alert('Please enter Alternate contact number');
                validate = false;
            }
         else if(component.get('v.opp.Customer_DOB__c') == null){
                alert('Please enter Date Of Birth');
                validate = false;
            }
        else if(component.get('v.opp.Email_ID__c') == null){
                alert('Please enter Email id');
                validate = false;
            }
         else if(component.get('v.opp.Aadhar_Number__c') == null){
                alert('Please enter Aadhar number');
                validate = false;
            }
          else if(component.get('v.opp.PAN_Number__c') == null){
                alert('Please enter PAN number');
                validate = false;
            }
        else if(component.get('v.opp.Address__c') == null){
                alert('Please enter Address');
                validate = false;
            }
            else if(component.get('v.opp.Project__c') == null){
                 alert('Please select Project');
                validate = false;
            }
       /* for(var i=0;i<plotLists.length;i++){
            
            if(plotLists[i].Plot__c == ''){
                alert('Select Plot on row ' + (i+1));
                validate = false;
            }
            else if(plotLists[i].Plot_size__c == ''){
                alert('Enter Size on row ' + (i+1));
                validate = false;
            }
                else if(plotLists[i].Rate_per_sqft_Sales__c  == ''){
                    alert('Enter Rate on row ' + (i+1));
                    validate = false;
                }
                    else if(plotLists[i].Rate_per_sqft_Sales__c  != '' && (plotLists[i].Rate_per_sqft_Sales__c  > plotLists[i].Maximum_Price__c || plotLists[i].Rate_per_sqft_Sales__c  < plotLists[i].Minimum_Price__c)){
                         alert('Rate is out of Minimum/Maximum Range on row ' + (i+1));
                    validate = false;
                    }
                    else{
                        validate = true;
                    }
        }*/
        if(validate == true){
            console.log(opp);
            // console.log(selectedLookUpRecords);
            console.log(bookingdate);
            //console.log(soldprice);
            //console.log(plotLists);
            // var action=component.get("c.saveOpp");  
            
            var action=component.get("c.saveOpp");
            console.log(action)
            action.setParams({
                opp:opp,
               // bookDate: bookingdate
            });
            action.setCallback(this,function(response){
                
                if(response.getState()=="SUCCESS"){ 
                    /* var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Booking are created successfully!',
                    type : 'success'
                });
                toastEvent.fire();*/
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Opportunity created successfully.',
                    type : 'success'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                    var oppId = response.getReturnValue();
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": oppId,
                        "slideDevName": "detail"
                    });
                    navEvt.fire();
                }
            });
            $A.enqueueAction(action);
        }
        
    },
    addRow: function(component, event, helper) {
        
        var oppplot = component.get("v.oppplot");
        
        oppplot.push({
            'sobjectType': 'Opportunity_Plot__c',
            'Plot__c' : '',
            'Rate_per_sqft_Sales__c ' : '',
            'Plot_size__c' : '',
            'All_inclusive_price__c' : ''
            
        });
        component.set("v.oppplot", oppplot);
    },     
    removeRow: function(component, event, helper) {
        var oppplot = component.get("v.oppplot");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        oppplot.splice(index, 1);
        component.set("v.oppplot", oppplot);
    },     
    calculateTotal: function(component, event, helper) {
        
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        var plots= component.get('v.oppplot');
        
        if( plots[index].Plot_size__c != '' && plots[index].Rate_per_sqft_Sales__c  != ''){
            plots[index].All_inclusive_price__c  = plots[index].Plot_size__c * plots[index].Rate_per_sqft_Sales__c ;
        }else{
            plots[index].All_inclusive_price__c = '';
        }
        component.set('v.oppplot',plots);
    },
     searchText1 : function(component, event, helper) {
        
        var proj= component.get('v.projects');
        //console.log(proj)
        var searchText1= component.get('v.searchText1');
         console.log(searchText1.length)
         var open = component.find("open");
         if(searchText1.length < 1){
             console.log(searchText1)
             
             //$A.util.toggleClass(open, 'slds-is-open');
         
         }
        
     
        var matchproj=[];
        if(searchText1 !=''){
            for(var i=0;i<proj.length; i++){ 
               // console.log(proj[i].Name)
                if(proj[i].Name.toLowerCase().indexOf(searchText1.toLowerCase())  != -1  ){
                    
                    if(matchproj.length <50){
                        matchproj.push( proj[i] );
                    }else{
                        break;
                    }
                    
                } 
            } 
            //alert(matchproj)
            if(matchproj.length >0){
                component.set('v.matchproj',matchproj);
            }
        }else{
            component.set('v.matchproj',[]);
        }
    },
    update1: function(component, event, helper) {
       // component.set('v.prjId', event.currentTarget.dataset.id);
        var edi =  event.currentTarget.dataset.id;
        // alert(edi);
        var prj= component.get('v.matchproj');
        //   alert(prj);
        for(var i=0;i<prj.length; i++){ 
            
            if(prj[i].Id ===  edi ){
                component.set('v.searchText1', prj[i].Name);
                
                component.set('v.opp.Project__c', prj[i].Id);
                break;
            } 
        } 
        
        component.set('v.matchproj',[]);
        
    },
    
})