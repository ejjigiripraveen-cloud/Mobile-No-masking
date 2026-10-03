({
	onInit : function (component, event, helper) {
        
        let action = component.get("c.readContacts");
         action.setParams({ 
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                let result=response.getReturnValue();
                if(result !== undefined && result != null  && result.length > 0){
                    component.set("v.phoneList",result); 
                }
            }
            else if(state === "ERROR"){
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                helper.displayMessage(component,"Something went wrong. Message-"+message, "error");
                console.error('Error-'+message);
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
            }
        });
        $A.enqueueAction(action);
    },
    
    callNumber : function (component, event, helper) {
         var action = component.get("c.callCustomer");
        console.log('recordId@@@@@@@@@@@@@@@@'+component.get("v.recordId"));
        console.log('selectedPhone---------------'+component.get("v.selectedPhone"));
         action.setParams({ 
             
             
             recordId : component.get("v.recordId"),
             
             phone : component.get("v.selectedPhone")
        });
        action.setCallback(this, function (response) {
            
            
            var state = response.getState();
            if (state == "SUCCESS") {
                let result=response.getReturnValue();
                
                
                if(result !== undefined && result != null && result == 'Success'){
                    var msg = 'Your call will soon be connected. ';
                    component.set("v.isdisabled",false);
                    helper.displayMessage(component, msg , "success");
                    component.set('v.displayCall', true);
                    component.set("v.selectedPhone", '');
                      //Beep Sound
            var audioElement = component.find("audioPlayer").getElement();
                if(audioElement!=null){
                    audioElement.play().catch(function(error) {
                        console.log("Playback prevented due to user interaction requirements.");
                    });
                    
                    audioElement.onended = function() {
                      /*if(component.get('v.fromQucickAction'))  
                         window.location.reload();*/
                     //    $A.get("e.force:closeQuickAction").fire();
                         var myEvent = component.getEvent("quoteSummaryToQuotationPageEvent");
                         myEvent.fire();
                        console.log('sampleComponentEvent Fired : '+JSON.stringify(myEvent));
                    }
                }
                    
                    
         
                  
                }else{
                    component.set("v.isdisabled",false);
                    helper.displayMessage(component, result , "error");
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
                     //helper.displayMessage(component,"Something went wrong. Lead Owner should be same to make call", "error");  
              
                    //helper.displayMessage(component,"Something went wrong. Message-"+result, "error");  
                }
            }else if(state === "ERROR"){
                
                let errors = response.getError();
                let message = 'Unknown error';
                if (errors && Array.isArray(errors) && errors.length > 0) {
                    message = errors[0].message;
                }
                helper.displayMessage(component,"Something 22  went wrong. Message-"+message, "error");
                console.error('Error-'+message);
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
                    if(component.get('v.fromQucickAction')){
                        $A.get("e.force:closeQuickAction").fire();
}
            }
        });  
        $A.enqueueAction(action);
    },
    
   
    
    displayMessage : function(component,message,type){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type": type,
            "message": message
        });
        toastEvent.fire();
        //Close the Pop up in Home Notification 
       if ( type=='success'  && (component.get("v.fromHome") == true)) {
        var parentComponent = component.get("v.parent");
        parentComponent.closePopUp();
      }    
        
    },  
    getDetails : function(component, event, helper, payload) {
       if(payload.UserId__c  == $A.get( "$SObjectType.CurrentUser.Id" )){ 
            if(payload.RecordId__c  == component.get("v.recordId")  && payload.TaskId__c  != undefined ){ 
                component.set('v.callcomplete',true);
                component.set('v.taskId',payload.TaskId__c );
            } 
        } 
     },
     getCallDetails : function(component, event, helper, payload) {
       if(payload.User_Id__c == $A.get( "$SObjectType.CurrentUser.Id" )){ 
                if(payload.Record_Id__c == component.get('v.recordId')  ){
                     component.set('v.displayCall', true); 
                     component.set('v.callcomplete',false);
                }
          }
    },
    readCallDetails : function(component, event, helper) {
         let action = component.get("c.readstatus");
         action.setParams({ 
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                     component.set('v.displayCall', response.getReturnValue());
            } 
        });
        $A.enqueueAction(action);
     }  
    ,saveCall: function(component, event, helper) {  
        let action = component.get("c.saveCallSummary");
        action.setParams({ 
            taskId: component.get("v.taskId"),
            summary: document.getElementById("textareaid01").value,
        });
        action.setCallback(this, function (response) {
            let state = response.getState();
            if (state == "SUCCESS") {
                    component.set('v.displayCall',false);
                    helper.displayMessage(component, 'Summary Saved Succesfully' , "success");
            }else{
                helper.displayMessage(component,"Something went wrong.", "error");
            } 
        });
        $A.enqueueAction(action);
     }

})