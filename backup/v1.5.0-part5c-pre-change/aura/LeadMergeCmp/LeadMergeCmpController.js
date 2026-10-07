({
    doInit : function(component, event, helper) {
        /*var action=component.get("c.getLeads");  
        action.setParams({
            recordId:component.get("v.recordId")
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var leads = response.getReturnValue();
                console.log(leads);
                component.set("v.leads",leads);
            }
        });
        $A.enqueueAction(action);*/
    },
    searchText : function(component, event, helper) {
        
      /*  var searchText= component.get('v.searchText');
        
        if(searchText !='' && searchText.length >= 3){
            var action=component.get("c.getSearchLeads");  
            action.setParams({
                recordId:component.get("v.recordId"),
                searchText: searchText
            });
            action.setCallback(this,function(response){
                if(response.getState()=="SUCCESS"){ 
                    var leads = response.getReturnValue();
                    console.log(leads);
                    component.set("v.leads",leads);
                    component.set("v.matchleads",leads);
                }
            });
            $A.enqueueAction(action);
        }
        else{
             component.set('v.matchleads',[]);
        }*/
    
       /* var leads= component.get('v.leads');
        console.log('leads:' + JSON.stringify(leads))
        //var searchText= component.get('v.searchText');
        var matchleads=[];
        if(searchText !=''){
           
             console.log(leads.length);
            for(var i=0;i<leads.length; i++){ 
                 console.log(leads[i]);
               if( leads[i].Lead_ID__c!=undefined   && leads[i].Lead_ID__c.toLowerCase().indexOf(searchText.toLowerCase())  != -1 ){
                    
                    matchleads.push( leads[i] );
                }
                else if( leads[i].Name!=undefined  && leads[i].Name.toLowerCase().indexOf(searchText.toLowerCase())  != -1){
                    matchleads.push( leads[i] );
                }
                else if( leads[i].Phone__c!=undefined  && leads[i].Phone__c.toLowerCase().indexOf(searchText.toLowerCase())  != -1)
            		matchleads.push( leads[i] );
                else if( leads[i].Secondary_Phone__c!=undefined  && leads[i].Secondary_Phone__c.toLowerCase().indexOf(searchText.toLowerCase())  != -1)
                    matchleads.push( leads[i] );
                    
                    }  		 
           
            if(matchleads.length >0){
                component.set('v.matchleads',matchleads);
            }
            else{
                component.set('v.matchleads',[]);
            }
        }
        else{
            component.set('v.matchleads',[]);
        }*/
    },
    onSearch : function(component, event, helper) {
        //alert('324')
        var searchText= component.get('v.searchText');
         //  alert('search text ',component.get('v.searchText'))
       // system.debug('search text '+component.get('v.searchText'));
        if(searchText !='' && searchText.length >= 3){
            var action=component.get("c.getSearchLeads");  
            action.setParams({
                recordId:component.get("v.recordId"),
                searchText: searchText
            });
            action.setCallback(this,function(response){
                if(response.getState()=="SUCCESS"){ 
                    var leads = response.getReturnValue();
                    console.log(leads);
                    component.set("v.leads",leads);
                    component.set("v.matchleads",leads);
                }
            });
            $A.enqueueAction(action);
        }
        else{
             component.set('v.matchleads',[]);
        }
        
    },
    update: function(component, event, helper) {
        
        //alert(event.currentTarget.dataset.id)
        component.set('v.value', event.currentTarget.dataset.id);
        var lid = component.get('v.value');
        var leads= component.get('v.matchleads');
        
        for(var i=0;i<leads.length; i++){ 
            // alert(leads[i].Id + ' == ' + lid)
            if(leads[i].Id ===  lid ){
                
                component.set('v.searchText', leads[i].Lead_ID__c + ' - ' + leads[i].Name);
                component.set('v.leadName', leads[i].Name);
                break;
            } 
        } 
        
        component.set('v.matchleads',[]);
        
        var getSelectlead = component.get("v.value");
        // call the event   
        var compEvent = component.getEvent("oSelectedleadEvent");
        // set the Selected lead to the event attribute.  
        compEvent.setParams({"leadByEvent" : getSelectlead });  
        // fire the event  
        compEvent.fire();
        //alert(component.get('v.value'));
    },
    merge: function(component, event, helper) {
        var ldId = component.get('v.value');
        console.log('new lead id '+ldId);
        alert(ldId);
        var action=component.get("c.mergeLead");
        action.setParams({
            oldLeadId:component.get("v.recordId"),
            newLeadId : ldId
        });
        action.setCallback(this,function(response){
            var resVal=response.getReturnValue();
            if(resVal=="Success"){ 
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message: 'Lead merged successfully!',
                    type : 'success'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                
                /*var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": ldId
                });
                navEvt.fire();*/
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    message:resVal ,
                    type : 'error'
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
            }
        });
        $A.enqueueAction(action);
        
    },
    cancel: function (cmp, event) {
        $A.get("e.force:closeQuickAction").fire();
    },
    
})