({
  // -------------------------------
  // Handles Outgoing Click-to-Call
  // -------------------------------
  // This function listens for the "Click-to-Dial" event triggered from Salesforce UI.
  // When triggered, it:
  // 1. Opens the softphone panel
  // 2. Sends call data to the dialer iframe (inside Salesforce UI)
  handleOutgoingCalls : function(cmp) {
    console.log("handleOutgoingCalls");

    // Mobile number masking (v1.3.0): returns { fieldKey, maskedNumber } when the click came from the
    // masked phone panel (params contain fieldKey=..., or the number is masked with X), otherwise null.
    var getMaskedClick = function(payload) {
      var fieldKey = '';
      var params = payload && payload.params;
      if (params && typeof params === 'object' && params.fieldKey) {
        fieldKey = String(params.fieldKey);
      } else if (typeof params === 'string') {
        params.split(',').forEach(function(pair) {
          var parts = pair.split('=');
          if (parts.length === 2 && parts[0].trim() === 'fieldKey') {
            fieldKey = parts[1].trim();
          }
        });
      }
      var number = (payload && payload.number) ? String(payload.number) : '';
      if (!fieldKey && !/[xX]/.test(number)) {
        return null;
      }
      return { fieldKey: fieldKey, maskedNumber: number };
    };

    // This function will run when Click-to-Call is triggered
    var listener = function(payload) {
      var maskedClick = getMaskedClick(payload);
      if (!maskedClick) {
        continueClickToDial(payload);
        return;
      }
      // Masked click: ask Salesforce for the real number (access check + audit), then dial as usual.
      sforce.opencti.runApex({
        apexClass: 'MaskedDialServiceCTI',
        methodName: 'resolveMaskedClick',
        methodParams: 'recordId=' + (payload.recordId || '')
          + '&fieldKey=' + maskedClick.fieldKey
          + '&maskedNumber=' + maskedClick.maskedNumber,
        callback: function(response) {
          var body = null;
          try {
            body = JSON.parse(response && response.returnValue ? response.returnValue.runApex : '');
          } catch (e) {
            body = null;
          }
          if (!response || !response.success || !body || body.success !== true) {
            console.log('Slash ::', 'masked click-to-dial refused', body ? body.message : response);
            return;
          }
          payload.number = body.phoneNumber;
          continueClickToDial(payload);
        }
      });
    };

    // Original click-to-dial flow (unchanged): leadOp lookup, then send the call to the SlashRTC dialer.
    var continueClickToDial = function(payload) {
         sforce.opencti.runApex({
              apexClass: 'leadOp',
              methodName: 'getValues',
              methodParams: 'phone=' + payload.number,
              callback: function (response) {
                if (!response || !response.success || !response.returnValue || !response.returnValue.runApex) {
                  //saveLog(taskValue)
                  console.log('Slash ::', 'leadOp failure ', response);
                } else {
                  let responseString = response.returnValue.runApex || '';
                  let responseJson = {}
                  try {
                    responseJson = JSON.parse(responseString);
                    payload.lead_id = responseJson.customLeadId || "";
                  } catch (e) {
                    console.log('Got Error in while parins responseString CATCH block', e);
            
                    if (responseJson && typeof responseJson == 'string') {
                      responseJson = {}
                    } else {
                      responseJson = responseString
                    }
            
                  }
            
            
                }
                  
                 // Open the softphone panel inside Salesforce
                  sforce.opencti.setSoftphonePanelVisibility({
                    visible : true,
                    callback : function() {
            
                      // Check if the component is valid and user is available
                      if (cmp.isValid() && cmp.get('v.presence') != 'Unavailable') {
                        console.log("payload", payload);
            
                        // Build call attributes (for internal use or softphone pop logic)
                        var attributes = {
                          'state'     : 'Dialing',
                          'recordName': payload.recordName,
                          'phone'     : payload.number,
                          'title'     : '',
                          'account'   : '',
                          'presence'  : cmp.get('v.presence')
                        };
            
                        // Prepare the message object to send to the SlashRTC dialer iframe
                        var response = {};
                        response.isSalesapi      = true;
                        response.directProcess   = true; // If true, no campaign/process selection needed
                        response.requestType     = 'clickToCall';
                        response.clickToCallData = {
                          number      : payload.number,
                          objectType  : payload.objectType,
                          recordId    : payload.recordId,
                          recordName  : payload.recordName,
                          customerName: payload.recordName,
                          lead_id     : payload.lead_id
                        };
            
                        // Define iframe ID (same as used in your Lightning component markup)
                        var IframeIdName = "slashCallingScreen";
            
                        // Send the message to the iframe to trigger a call in the dialer
                        console.log("response IframeIdName", IframeIdName, response);
                        document.getElementById(IframeIdName)
                          .contentWindow
                          .postMessage(response,
                            document.getElementById(IframeIdName).src);
                      }
                    }
                  });
              }
            })
         
      console.log("listener =========>",payload);
  
    };

    // Register the listener for click-to-dial
    sforce.opencti.onClickToDial({
      listener : listener
    });
  },

  // -------------------------
  // Enables Click-to-Dial
  // -------------------------
  // This tells Salesforce to activate the click-to-dial functionality on phone fields
  handleLogin : function(cmp) {
    sforce.opencti.enableClickToDial({
      callback: function() {
        console.log("enableClickToDial");
      }
    });
  },

  // -------------------------
  // Initializes the IFrame URL
  // -------------------------
  // This function generates the dialer iframe URL based on the current user ID/email
  // It then sets the iframe `src` attribute to launch the SlashRTC dialer
  doInit : function(component, event, helper) {
    // Get the current user's email as unique ID
    var userId = $A.get("$SObjectType.CurrentUser.Email");

    // Construct the SlashRTC dialer login URL with this user ID
    var url = `https://gsquarehousing.slashrtc.in/index.php/directLogin?tptUniqueId=${userId}&requestOrigin=https://gsquaregroup--c.vf.force.com`;
    // Set the iframe source (binds to v.userUrl in the component)
    console.log("url------------------------->",url);
    component.set("v.userUrl", url);
  }
})