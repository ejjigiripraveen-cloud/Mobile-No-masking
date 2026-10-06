({
    getDetails : function(component, event, helper) {
         var action2 =component.get("c.getOutboundCallDetails");          
        action2.setCallback(this,function(response){
           
            if(response.getState() == "SUCCESS"){ 
                var result  = response.getReturnValue();
                if(result){
               // alert(JSON.stringify(result));
                    component.set('v.recordId', result.recordId); 
                    component.set('v.objectName', result.objectName); 
                    component.set('v.callType', result.callType);
                    component.set('v.callId', result.callID);
                    component.set('v.displayCall', true); 
                    //Beep Sound
                    if (Notification.permission === "granted") {
                        new Notification("New Event Notification", {
                            body: 'you got a new call,please navigate for salesforce'
                        });
                    }
                   /* var audioElement = component.find("audioPlayer").getElement();
                    if(audioElement!=null){
                        audioElement.play().catch(function(error) {
                            console.log("Playback prevented due to user interaction requirements.");
                        });
                    }*/
                }else{
                    component.set('v.recordId', ''); 
                    component.set('v.objectName', ''); 
                    component.set('v.callType','');
                    component.set('v.callId', '');
                    component.set('v.displayCall', false); 
                }
                helper.openUtility(component, event, helper);
            }else if (response.getState() === "ERROR") {
                helper.openUtility(component, event, helper);
            }
        });
        $A.enqueueAction(action2); 
       
    },
    
    openUtility : function(component, event, helper) {
        var utilityAPI = component.find("utilitybar");
        var utilityId = utilityAPI.getEnclosingUtilityId();
        utilityAPI.openUtility(utilityId);
        if(component.get('v.callType') =='OUTGOING' ||component.get('v.callType') =='INCOMING' ){
           component.set('v.isPopup',true);          
       }
        if(component.get('v.parentList')!=null){
            console.log('spinner values 1 '+component.get("v.showSpinner"));
            component.set("v.showSpinner", false);
            console.log('spinner values 1'+component.get("v.showSpinner"));
        }
    },
    
    closeUtility : function(component, event, helper) {
    var utilityAPI = component.find("utilitybar");
    var utilityId = utilityAPI.getEnclosingUtilityId();
    utilityAPI.minimizeUtility();

    // force:refreshView is NOT available in Utility Bar
    var refreshEvent = $A.get("e.force:refreshView");
    if (refreshEvent) {
        refreshEvent.fire();
    }
},
    
    reset : function(component, event, helper) {
        helper.closeUtility(component, event, helper);
         component.set('v.displayCall', false);
        // $A. get('e. force:refreshView'). fire();
         component.set('v.recordId','');
         component.set('v.dispositionType', '');
         component.set('v.subDispositionType', '');
         component.set('v.dispositionNotes', '');
         component.set('v.Rating', '');
         component.set('v.followUpTime', '');
         component.set('v.callType','');
         component.set('v.parentValue', 'None');
         component.set('v.childValue', 'None');
        
    },
    
     
    openOverlay : function(component, event, helper, objectName, header) {
        $A.createComponent("c:LeadGeneration", {
            objectName: objectName,
            header: header,
            isModalOpen: true,
            recordId: "anything",
            isSales: component.get("v.isSales"),
            isIncomingCall : true,
            mobileNumber: component.get("v.mobileNumber"),
            source: component.get("v.source"),
            subSource : component.get("v.subSource"),
            project: component.get("v.project")
        },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Application Confirmation",
                                       body: modalBody,
                                       showCloseButton: true,
                                       closeCallback: function() {
                                           
                                       }
                                   })
                               }
                           });
    },
     showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
    callDispositionMcubeAPI :function(component,event,helper){
          console.log('call Mcube Disposition API');
        var action = component.get("c.callDisposition");
        action.setParams({ callId : component.get("v.callId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
           // alert('Mcube API Call status ::'+state);
            if (state === "SUCCESS") {
                console.log("API Result From Mcube : "+ response.getReturnValue());
               //alert("API Result From Mcube : " + response.getReturnValue());
            }
            else if (state === "ERROR") {
                 var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
               //alert("Error While calling API : " + response.getReturnValue()); 
            } 
        });
     $A.enqueueAction(action);  
    },
      UpdateUser :function(component,event,helper){
        var action = component.get("c.updateUsers");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
             helper.reset(component, event, helper); 
            helper.getDetails(component, event, helper);
            }
            else if (state === "ERROR") {
            } 
        });
     $A.enqueueAction(action);  
    }
})