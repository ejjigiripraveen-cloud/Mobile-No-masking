({
    getPickValues : function(component, event, helper,fieldName) {
        var action=component.get("c.getPicklistValues");  
        action.setParams({
            'fieldName' :fieldName
        });
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var result = response.getReturnValue();
                
                if(fieldName == 'Project__c'){
                    component.set("v.projects",result);
                }
                if(fieldName == 'Purpose_of_purchase__c'){
                    component.set("v.purpose",result);
                }
                 if(fieldName == 'Looking_For__c'){
                    component.set("v.lookingfor",result);
                }
                if(fieldName == 'Status'){
                    component.set("v.leadStage",result);
                }
                if(fieldName == 'Aspect_of_our_brand__c'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    component.set("v.aspect", plValues);
                }
                if(fieldName == 'How_did_you_find_out_about_us__c'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    component.set("v.infosource", plValues);
                }
                if(fieldName == 'Price_range__c'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    
                    component.set("v.pricerange", plValues);
                }
                if(fieldName == 'What_is_your_preferred_location__c'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    component.set("v.location", plValues);
                }
                if(fieldName == 'Country__c'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    component.set('v.Country', plValues);
                }
                if(fieldName == 'LeadSource'){
                    var plValues = [];
                    for (var i = 0; i < result.length; i++) {
                        plValues.push({
                            label: result[i],
                            value: result[i]
                        });
                    }
                    component.set('v.leadSources', plValues);
                }
                
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "type":type,
            "message":  message
        });
        toastEvent.fire();
    },
})