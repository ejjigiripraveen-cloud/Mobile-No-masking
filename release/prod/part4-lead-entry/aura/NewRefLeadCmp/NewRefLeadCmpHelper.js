({
    // Mobile number masking (v1.4.0): a user who cannot see Phone__c does not get it in the form's
    // object info, so the form shows the entry fields (Phone_Entry__c / Secondary_Phone_Entry__c) instead.
    detectMaskedUser : function(cmp, event) {
        var recordUi = event.getParam("recordUi");
        var leadInfo = recordUi && ((recordUi.objectInfos && recordUi.objectInfos.Lead) || recordUi.objectInfo);
        if (leadInfo && leadInfo.fields) {
            cmp.set("v.isMaskedUser", !Object.prototype.hasOwnProperty.call(leadInfo.fields, "Phone__c"));
        }
    },

	toastMsg : function (type, title, msg) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type": type,
            "message": msg,
            "mode":'sticky'
        });
        toastEvent.fire();
    }
})