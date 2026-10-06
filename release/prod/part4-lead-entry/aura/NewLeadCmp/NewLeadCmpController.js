({
    handleCreateLoad: function (cmp, event, helper) {
        helper.detectMaskedUser(cmp, event); // Mobile number masking (v1.4.0)
        // var recId = cmp.get('v.recordId');
        
    },
    
    onSelect: function(component, event, helper) {
        var selValue = '';
        if(component.find("ldsource") != undefined){
            selValue = component.find("ldsource").get("v.value");
        }
        else if(component.find("ldsource2") != undefined){
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
        }
        else if(selValue == 'Existing Customer Referral'){
            component.set("v.isExCustRef",true);
            component.set("v.isCustRef",false);
            component.set("v.isVDNBRef",false);
            component.set("v.isEmpRef",false);
            component.set("v.isVendRef",false);
            component.set("v.isMgtRef",false);
            component.set("v.isOtherSrc",false);
        }
            else if(selValue == 'VDNB Referral'){
                component.set("v.isVDNBRef",true);
                component.set("v.isCustRef",false);
                component.set("v.isExCustRef",false);
                component.set("v.isEmpRef",false);
                component.set("v.isVendRef",false);
                component.set("v.isMgtRef",false);
                component.set("v.isOtherSrc",false);
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
        //alert(record)
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
        console.log('start');
        event.preventDefault(); // stop form submission
        var eventFields = event.getParam("fields");
        console.log('start 2');  
        
        if(component.find("ldsource2") != undefined){
            eventFields["LeadSource"] = component.find("ldsource2").get("v.value");
        }
        component.find('recordCreateForm').submit(eventFields); // continue form submission
        component.set("v.isbutton", false);
        console.log('end');
        
    },
    handleError: function (cmp, event, helper) {
        cmp.set("v.isbutton", true);
        //var error = event.getParams();
        const profile = cmp.get('v.CurrentUser')['Profile'].Name;
        var selValue = '';
        if(cmp.find("ldsource") != undefined)
            selValue = cmp.find("ldsource").get("v.value");
        else
            selValue = cmp.find("ldsource2").get("v.value");
        
        // Get the error message
        var errorMessage = event.getParam("message"); 
        //alert(errorMessage); 
        if(errorMessage=='The requested resource does not exist'){
            helper.toastMsg('error','Duplicate','Lead already exist in the system');
        }
        else if(profile != 'Referral Team' && profile != 'System Administrator' && profile != 'Admin Pre sales' && selValue.includes('Referral')){
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
        history.back();   
    },
})