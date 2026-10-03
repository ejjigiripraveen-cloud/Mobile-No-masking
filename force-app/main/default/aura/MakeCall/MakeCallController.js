({
  doInit: function(component, event, helper) {

      /*Beed sound */
        var audioElement = component.find("audioPlayer").getElement();      
        if (Notification.permission !== "granted") {
            Notification.requestPermission();
        }
     
          
    helper.onInit(component, event, helper);
    helper.readCallDetails(component, event, helper);

   const empApi = component.find("empApi");
    empApi.setDebugFlag(true);
    const replayId = -1;
   empApi
      .subscribe(
        "/event/CtitaskCreated__e",
        replayId,
        $A.getCallback(eventReceived => {
          helper.getDetails(
            component,
            event,
            helper,
            eventReceived.data.payload
          );
        })
      )
      .then(subscription => {});
 empApi
      .subscribe(
        "/event/CtiNotification__e",
        replayId,
        $A.getCallback(eventReceived => {
          helper.getCallDetails(
            component,
            event,
            helper,
            eventReceived.data.payload
          );
        })
      )
      .then(subscription => {});
  },

  handleClear: function(component, event, helper) {
    component.set("v.selectedPhone", "");
  },

  handleCall: function(component, event, helper) {
      component.set("v.isdisabled",true);
    var phone = component.get("v.selectedPhone");
    var subject = component.get("v.subject");
    component.set("v.callcomplete", false);
    console.log("phone!!!!!!!!!" + phone);
    if (phone != undefined && phone.trim() != "") {
      helper.callNumber(component, event, helper); 
    } else {
      helper.displayMessage(
        component,
        "Please select Phone number to make a call.",
        "error"
      );
    }
  },

  refresh: function(component, event, helper) {
    helper.onInit(component, event, helper);
  },
  saveCall: function(component, event, helper) {
    helper.saveCall(component, event, helper);
  }
});