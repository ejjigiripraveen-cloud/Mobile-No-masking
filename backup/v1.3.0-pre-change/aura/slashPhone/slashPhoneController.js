({
  // This function runs automatically when the component is initialized
  // It performs 3 things:
  // 1. Clears any existing search results
  // 2. Handles call logic if there's an outgoing call
  // 3. Logs in the user to the CTI system
  // 4. Also does some component-specific initialization
  init: function(cmp, event, helper) {
    // Set searchResults attribute to an empty list initially
    cmp.set('v.searchResults', []);
   
    // Handle any logic needed when an outgoing call is triggered
    helper.handleOutgoingCalls(cmp);

    // Handle login to the SlashRTC dialer or CTI system
    helper.handleLogin(cmp);

    // Do additional initialization (e.g., setting iframe URL)
    helper.doInit(cmp);
  },

  // This function is triggered manually when login is performed by user action
  // It calls the helper function to manage the login process
  handleLogin: function(cmp, event, helper) {
    helper.handleLogin(cmp);
  },

  // This function listens for messages sent between the iframe and Salesforce
  // For example: when the dialer sends call info back to Salesforce
  // The helper handles the message logic (eventKiranApex is a custom handler)
  eventOnMessage: function(cmp, event, helper) {
    var params = event.getParams(); // Extract message parameters
    helper.eventKiranApex(cmp, params); // Handle them in helper
  },
 
  // This is another init method, probably tied to a specific component event
  // It extracts the event parameters and passes them to helper.doInit
  doInit: function(cmp, event, helper) {
    var params = event.getParams();
    helper.doInit(cmp, params);
  },
})