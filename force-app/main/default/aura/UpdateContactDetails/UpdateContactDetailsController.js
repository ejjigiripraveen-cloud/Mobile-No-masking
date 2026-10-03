({
	doInit : function(component, event, helper) {
		component.set('v.Spinner', true); 
        helper.getcontactdata(component, event, helper);
	},
    updateDetails : function(component,event,helper){
        
        let isAllValid = component.find('field1').reduce(function(isValidSoFar, inputCmp){
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        },true);
        
        if(isAllValid == true){
            component.set('v.Spinner', true);
            helper.saveContactData(component,event,helper);
        }
    },
    closeModel: function(component, event, helper) {
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
    },
})