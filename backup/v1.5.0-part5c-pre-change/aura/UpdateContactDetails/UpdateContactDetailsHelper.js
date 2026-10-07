({
	getcontactdata : function(component, event, helper) {
		 var action = component.get("c.getcontactdetails");
        action.setParams({ 
            recId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue());            
            if(state==='SUCCESS'){
                var lead = response.getReturnValue();
                if(lead !=null && lead !='' && lead !=undefined){
                    component.set('v.leaddata',lead);
                    
                   if(lead.Phone__c !=null && lead.Phone__c !='' && lead.Phone__c != undefined){
                        
                        component.set('v.phone',lead.Phone__c.toString());
                    }
                    if(lead.Secondary_Phone__c !=null && lead.Secondary_Phone__c !=''){
                         component.set('v.secondaryPhone',lead.Secondary_Phone__c);
                    }
                    if(lead.Email !=null && lead.Email !='' && lead.Email!=undefined){
                         component.set('v.email',lead.Email);
                    }
                    if(lead.Secondary_Email__c !=null && lead.Secondary_Email__c !='' && lead.Secondary_Email__c!=undefined){
                        component.set('v.secondaryEmail',lead.Secondary_Email__c);
                    }
                     //alert(JSON.stringify(component.get("v.leaddata")));
                }
                component.set("v.isModalOpen", true);
                 component.set('v.Spinner', false);
            }else{
                console.log('else block');
                component.set('v.Spinner', false);
                helper.toastMsg(component, event, helper, "error", "Error!", "Something went Wrong! Please contact System Admin");
            }
        });
        $A.enqueueAction(action);
	},
     toastMsg : function (component, event, helper, type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg
        });
        toastEvent.fire();
    },
    saveContactData: function(component,event,helper){
       
        //alert(JSON.stringify(component.get("v.leaddata")));
         var action = component.get("c.savecontactdetails");
        action.setParams({ 
            recId: component.get("v.recordId"),
            phone : component.get("v.phone"),
            email : component.get("v.email"),
            secondaryPhone : component.get("v.secondaryPhone"),
            secondaryEmail : component.get("v.secondaryEmail")
        });
        action.setCallback(this, function(response) {
            var state=response.getState();
            console.log('Response : '+response.getReturnValue());            
            if(state==='SUCCESS'){
                if( response.getReturnValue()=='Success'){
                    helper.toastMsg(component, event, helper, "success", "Success", "Contact details updated");
                component.set("v.isModalOpen", true);
                 component.set('v.Spinner', false);
                 $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                }else{
                    helper.toastMsg(component, event, helper, "error", "Error!", response.getReturnValue());
               component.set("v.isModalOpen", true);
                 component.set('v.Spinner', false);
                }
                 
            }else{ 
                component.set('v.Spinner', false);
                helper.toastMsg(component, event, helper, "error", "Error!", "Something went wrong. please contact admin");
            }
        });
        $A.enqueueAction(action);
    }
})