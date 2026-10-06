({
    // Mobile number masking (v1.5.0): a user who cannot see Phone__c does not get it in the form's object info,
    // so the panel shows the masked formula Phone_Masked__c instead of an empty Phone line.
    handlePanelLoad : function(component, event, helper) {
        var recordUi = event.getParam("recordUi");
        var leadInfo = recordUi && ((recordUi.objectInfos && recordUi.objectInfos.Lead) || recordUi.objectInfo);
        if (leadInfo && leadInfo.fields) {
            component.set("v.isMaskedUser", !Object.prototype.hasOwnProperty.call(leadInfo.fields, "Phone__c"));
        }
    },

    doInit : function(component, event, helper) {
       /*Beed sound */
        var audioElement = component.find("audioPlayer").getElement();     
        if (Notification.permission !== "granted") {
            Notification.requestPermission();
        }
        
        /*
         * call details dependent fields changes */
        var action = component.get("c.getDependentPicklist");
        action.setParams({
            ObjectName : component.get("v.objectName"),
            parentField : component.get("v.parentFieldAPI"),
            childField : component.get("v.childFieldAPI")
             });
        
         action.setCallback(this, function(response){
         	var status = response.getState();
            if(status === "SUCCESS"){
                var pickListResponse = response.getReturnValue();
                
                //save response 
                component.set("v.pickListMap",pickListResponse.pickListMap);
                component.set("v.parentFieldLabel",pickListResponse.parentFieldLabel);
                component.set("v.childFieldLabel",pickListResponse.childFieldLabel);
                
                // create a empty array for store parent picklist values 
                var parentkeys = []; // for store all map keys 
                var parentField = []; // for store parent picklist value to set on lightning:select. 
                
                // Iterate over map and store the key
                for (var pickKey in pickListResponse.pickListMap) {
                    parentkeys.push(pickKey);
                }
                
                //set the parent field value for lightning:select
                if (parentkeys != undefined && parentkeys.length > 0) {
                    parentField.push('--- None ---');
                }
                
                for (var i = 0; i < parentkeys.length; i++) {
                    parentField.push(parentkeys[i]);
                }  
                console.log('parent list '+parentField);
                
                // set the parent picklist
                component.set("v.parentList", parentField);
              /*  if (parentField && parentField.length > 0) {
                     console.log('spinner values '+component.get("v.showSpinner"));
                    // If parentList is not null or empty, hide the spinner
                    component.set("v.showSpinner", false);
                    console.log('spinner values '+component.get("v.showSpinner"));
                }*/
                
            }
        });
        
        $A.enqueueAction(action);
        
        
        var action2=component.get("c.userDetail");          
        action2.setCallback(this,function(response){
            if(response.getState() == "SUCCESS"){ 
                var zone  = response.getReturnValue();
                for(var i=0;i<zone.length;i++){ 
                    const empApi = component.find('empApi');
                    empApi.setDebugFlag(true);  
                    const replayId = -1; 
                    empApi.subscribe('/event/CTI'+zone[i]+'__e', replayId, $A.getCallback(eventReceived => {
                          helper.getDetails(component, event, helper, eventReceived.data.payload);        
                    }))
                        .then(subscription => {
                        console.log('Subscribed to channel ', subscription.channel); 
                    });                     
                }  
     
            }else if (response.getState() === "ERROR") {
            }
        });
        $A.enqueueAction(action2); 
        

        component.set('v.todaysDate', new Date().toISOString().split('T')[0]);  
    },
   
   /*  handleInputChange : function(component, event, helper) {
        var disposition=component.get('v.parentValue');
        var subDisposition=component.get('v.childValue');
        
        // Check if the condition is met (firstName is 'singa' and lastName is 'singi')
        if(disposition === 'singa' && subDisposition === 'singi') {
            component.set("v.showAddress", true);
        } else {
            component.set("v.showAddress", false);
        }
    },*/
                        
    parentFieldChange : function(component, event, helper) {
    	var controllerValue = component.find("parentField").get("v.value");// We can also use event.getSource().get("v.value")
        var pickListMap = component.get("v.pickListMap");

        if (controllerValue != '--- None ---') {
             //get child picklist value
            var childValues = pickListMap[controllerValue];
            var childValueList = [];
            childValueList.push('--- None ---');
            for (var i = 0; i < childValues.length; i++) {
                
                childValueList.push(childValues[i]);
            }
            // set the child list
            component.set("v.childList", childValueList);
            
            if(childValues.length > 0){
                component.set("v.disabledChildField" , false);  
            }else{
                component.set("v.disabledChildField" , true); 
            }
            
        } else {
            component.set("v.childList", ['--- None ---']);
            component.set("v.disabledChildField" , true);
        }
    
        var disposition=component.get('v.parentValue');
        var subDisposition=component.get('v.childValue');
        console.log('disposition ',disposition,'subDisposition',subDisposition);
        // Check if the condition is met (firstName is 'singa' and lastName is 'singi')
        if(disposition === 'Contacted' && (subDisposition === 'Scheduled Call Back'||subDisposition === 'Call Back')) {
            component.set("v.showAddress", true);
        }else if(disposition==='Not Contact' && (subDisposition==='No Answer' ||subDisposition==='Switched Off'||subDisposition==='Not Reachable'||subDisposition==='Blank Call' )) {
            component.set("v.showAddress", true);
        }else{
             component.set("v.showAddress", false);
        }


	
            /*end */
            
       
    },
   
   
  navigateToRecord : function(component, event, helper) {
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
          "recordId": component.get('v.recordId'),
          "slideDevName": "detail"
      });
      navEvt.fire();
       component.set('v.isPopup',true);
     // helper.reset(component, event, helper);
  },
            
handleSuccess : function(component, event, helper) {
                component.set('v.isPopup',true);
            },
getcancelled : function(component, event, helper) {
                component.set('v.isPopup',false);
            },       
updateinfo : function(component, event, helper) {
    	//var followupType = 'Follow up call';
    var feedBack=component.get('v.subDispositionType');
    var callType=component.get('v.callType');
    var disposition=component.get('v.parentValue');
    var subDisposition=component.get('v.childValue');
    console.log('disposition values '+disposition);
    console.log('subDisposition values '+subDisposition);
     console.log('subDisposition values '+feedBack+'calltype '+callType);
   
    if((callType=='OUTGOING' || callType=='INCOMING') && ( feedBack=='' || feedBack==null || feedBack.lentgh==0 ||feedBack =='undefined'))
        	helper.showToast('Enter the Feedback','error');
  else{
     	var FollowupDate =component.get('v.followUpTime');
        var istrue =component.get('v.showAddress');
    	var localDate = new Date(FollowupDate);   
    
        console.log('parent value '+component.get('v.parentValue'));
        console.log('chile value '+component.get('v.childValue'));
        FollowupDate=localDate.toLocaleString('en-GB');
      console.log('follow up date '+FollowupDate);
        var action=component.get("c.updateRecord");
          action.setParams({
              'recId' :component.get('v.recordId'),
              'callID' :component.get('v.callId'),
              'followupDate' : FollowupDate,
              'followUpType' :'Follow-up call',
              'feedback' :component.get('v.subDispositionType'),
              'disposition':component.get('v.parentValue'),
              'subDisposition':component.get('v.childValue')
            });
        action.setCallback(this,function(response){
            console.log('response Works',response.getReturnValue());
            if(response.getState() == "SUCCESS"){
                 helper.callDispositionMcubeAPI(component, event, helper);
                let result=response.getReturnValue();
               // console.log('get return valuee 'result);
                if(result=='Updated'){
                   
                    helper.showToast("Record Updated",'Success');
                	component.set('v.isPopup',false);
                    var navEvt = $A.get("e.force:navigateToSObject");
                    navEvt.setParams({
                        "recordId": component.get('v.recordId'),
                        "slideDevName": "detail"
                    });
                    navEvt.fire();  
                    helper.reset(component, event, helper);
                }else if(result='Select future date' && istrue==true){
                    helper.showToast("Please select future date",'Error');
                }
                 
   
     
            }else if (response.getState() === "ERROR") {
               
                var errors = response.getError();
                
                
                
                if (errors) {
                    console.log(JSON.stringify(errors[0])+' '+JSON.stringify(errors[1]));
                    console.log(JSON.stringify(errors[0].pageErrors[0].message));
                    if (errors[0] && errors[0].pageErrors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].pageErrors[0].message);
                        helper.showToast(errors[0].pageErrors[0].message,'error');
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            
        }
                          );
        $A.enqueueAction(action);
      
        }
                 
  },
     navigateToRecordPage : function(component, event, helper) {
       alert(value);
       //alert(component.get('v.recordId'))
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
          "recordId": component.get('v.recordId'),
          "slideDevName": "detail"
      });
      navEvt.fire();  
       component.set('v.isPopup',true);
      helper.reset(component, event, helper);
  },
   
})