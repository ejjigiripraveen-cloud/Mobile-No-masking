({
    handleCreateLoad: function (cmp, event, helper) {
        helper.detectMaskedUser(cmp, event); // Mobile number masking (v1.4.0)
        //alert('in onload')
        var recId = cmp.get('v.recordId');
       // alert(JSON.stringify(cmp.get('v.CurrentLead')))
        //const ldData = cmp.get('v.CurrentLead').Name;
        //var selectSrc = cmp.find("ldsource2").set("v.value","Customer Referral" );
        //alert('selectSrc:' + cmp.find("ldsource2").get("v.value"))
        var selValue = '';
        if(cmp.find("ldsource2") != undefined){
           	selValue = cmp.find("ldsource2").get("v.value");
        }
        if(selValue == 'Customer Referral'){
          //  alert('hey')
                cmp.set("v.isCustRef",true);
                cmp.set("v.isExCustRef",false);
                cmp.set("v.isVDNBRef",false);
                cmp.set("v.isEmpRef",false);
                cmp.set("v.isVendRef",false);
                cmp.set("v.isMgtRef",false);
                cmp.set("v.isOtherSrc",false);
             //alert('refledcmp:' +cmp.find("refLead"))
             
             	cmp.find("refLead").set("v.value",recId );
            //cmp.find("refProject1").set("v.value",ldData );
            }
      
        
        
    },
   
    onSelect: function(component, event, helper) {
        //alert(JSON.stringify(component.get('v.CurrentLead')))
         var recId = component.get('v.recordId');
       var selValue = '';
       if(component.find("ldsource2") != undefined){
           	selValue = component.find("ldsource2").get("v.value");
        }
       
       
        //alert(component.find("ldsource").get("v.value"))
        if(selValue == 'Customer Referral'){
            component.set("v.isCustRef",true);
            component.set("v.isExCustRef",false);
            component.set("v.isVDNBRef",false);
            component.set("v.isEmpRef",false);
            component.set("v.isVendRef",false);
            component.set("v.isMgtRef",false);
            component.set("v.isOtherSrc",false);
            component.find("refLead").set("v.value",recId );
             component.find("refProject1").set("v.value",recId );
        }
        else if(selValue == 'Existing Customer Referral'){
            component.set("v.isExCustRef",true);
            component.set("v.isCustRef",false);
            component.set("v.isVDNBRef",false);
            component.set("v.isEmpRef",false);
            component.set("v.isVendRef",false);
            component.set("v.isMgtRef",false);
            component.set("v.isOtherSrc",false);
            component.find("refLead2").set("v.value",recId );
        }
            else if(selValue == 'VDNB Referral'){
                component.set("v.isVDNBRef",true);
                component.set("v.isCustRef",false);
                component.set("v.isExCustRef",false);
                component.set("v.isEmpRef",false);
                component.set("v.isVendRef",false);
                component.set("v.isMgtRef",false);
                component.set("v.isOtherSrc",false);
                component.find("refLead3").set("v.value",recId );
            }
                else if(selValue == 'Employee Referral'){
                    component.set("v.isEmpRef",true);
                    component.set("v.isCustRef",false);
                    component.set("v.isExCustRef",false);
                    component.set("v.isVDNBRef",false);
                    component.set("v.isVendRef",false);
                    component.set("v.isMgtRef",false);
                    component.set("v.isOtherSrc",true);
                }
                    else if(selValue == 'Vendor Referral'){
                        component.set("v.isVendRef",true);
                        component.set("v.isCustRef",false);
                        component.set("v.isExCustRef",false);
                        component.set("v.isVDNBRef",false);
                        component.set("v.isEmpRef",false);
                        component.set("v.isMgtRef",false);
                        component.set("v.isOtherSrc",true);
                    }
                        else if(selValue == 'Management Referral'){
                            component.set("v.isMgtRef",true);
                            component.set("v.isCustRef",false);
                            component.set("v.isExCustRef",false);
                            component.set("v.isVDNBRef",false);
                            component.set("v.isEmpRef",false);
                            component.set("v.isVendRef",false);
                            component.set("v.isOtherSrc",true);
                        }
                            else{
                                component.set("v.isCustRef",false);
                                component.set("v.isExCustRef",false);
                                component.set("v.isVDNBRef",false);
                                component.set("v.isEmpRef",false);
                                component.set("v.isVendRef",false);
                                component.set("v.isMgtRef",false);
                                component.set("v.isOtherSrc",true);
                            }
    },
    handleSuccess : function(component, event, helper) {
        
        var record = event.getParam("response");
        var apiName = record.apiName;
        var myRecordId = record.id; // ID of updated or created record
        
        // alert(myRecordId);
        helper.toastMsg('Success','Success','Lead created successfully');
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": myRecordId,
            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    handleSubmit: function(component, event, helper) {
        event.preventDefault(); // stop form submission
        var eventFields = event.getParam("fields");
        //alert(JSON.stringify(eventFields))
        
        if(component.find("ldsource2") != undefined){
           // alert(component.find("ldsource2").get("v.value"))
            eventFields["LeadSource"] = component.find("ldsource2").get("v.value");
        }
       // alert(JSON.stringify(eventFields))
       // alert(component.find("ldsource").get("v.value"))
        component.find('recordCreateForm').submit(eventFields); // continue form submission
        component.set("v.isbutton", false);
        
    },
     handleError: function (cmp, event, helper) {
        // alert('error');
        cmp.set("v.isbutton", true);
        var error = event.getParams();
        const profile = cmp.get('v.CurrentUser')['Profile'].Name;
            var selValue = cmp.find("ldsource2").get("v.value");
		//alert(selValue)
        // Get the error message
        var errorMessage = event.getParam("message"); 
        // alert(errorMessage);
        if(errorMessage=='The requested resource does not exist'){
            helper.toastMsg('error','Duplicate','Lead already exist in the system');
        }
        else if(profile != 'Referral Team' && selValue.includes('Referral')){
            helper.toastMsg('error','Error','You cannot create Referral Leads. Please contact Referral Team.');
        }
        else{
            helper.toastMsg('error','Error',errorMessage);
        }
        history.back();    
        
    },
    openModel: function(component, event, helper) {
        // Set isModalOpen attribute to true
        component.set("v.isModalOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
        $A.get("e.force:closeQuickAction").fire();
        //history.back();   
    },
})