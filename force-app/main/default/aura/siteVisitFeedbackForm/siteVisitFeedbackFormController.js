({
    doInit: function (component, event, helper) {
        helper.getPickValues(component, event, helper, 'Project__c');
        helper.getPickValues(component, event, helper, 'Purpose_of_purchase__c');
        helper.getPickValues(component, event, helper, 'Looking_For__c');
        helper.getPickValues(component, event, helper, 'Status');
        helper.getPickValues(component, event, helper, 'Aspect_of_our_brand__c');
        helper.getPickValues(component, event, helper, 'How_did_you_find_out_about_us__c');
        helper.getPickValues(component, event, helper, 'Price_range__c');
        helper.getPickValues(component, event, helper, 'What_is_your_preferred_location__c');
        helper.getPickValues(component, event, helper, 'Country__c');
        helper.getPickValues(component, event, helper, 'LeadSource');


        var action7 = component.get("c.getuserdetails");
        action7.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.users', result);


            }
        });
        $A.enqueueAction(action7);


        /* var action=component.get("c.getProjects");  
        action.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var projects = response.getReturnValue();
                component.set("v.projects",projects);
            }
        });
        $A.enqueueAction(action);
        
        var action2=component.get("c.getPurpose");  
        action2.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                var purpose = response.getReturnValue();
                component.set("v.purpose",purpose);
               
            }
        });
        $A.enqueueAction(action2);
        
        var action3=component.get("c.getAspect");  
        action3.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                //var aspect = response.getReturnValue();
                //component.set("v.aspect",aspect);
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set("v.aspect", plValues);
                //alert(component.get('v.aspect'))
            }
        });
        $A.enqueueAction(action3);
        
        var action4=component.get("c.getInfoSource");  
        action4.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                // var infosource = response.getReturnValue();
                //  component.set("v.infosource",infosource);
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set("v.infosource", plValues);
            }
        });
        $A.enqueueAction(action4);
        
        var action5=component.get("c.getPriceRange");  
        action5.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                //var pricerange = response.getReturnValue();
                //component.set("v.pricerange",pricerange);
                var result = response.getReturnValue();
                
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                
                component.set("v.pricerange", plValues);
            }
        });
        $A.enqueueAction(action5);
        
        var action6=component.get("c.getPrefLocation");  
        action6.setCallback(this,function(response){
            if(response.getState()=="SUCCESS"){ 
                //var location = response.getReturnValue();
                //component.set("v.location",location);
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set("v.location", plValues);
            }
        });
        $A.enqueueAction(action6);
        
        
        
        var action8 = component.get("c.getCountry");
        action8.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var plValues = [];
                for (var i = 0; i < result.length; i++) {
                    plValues.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set('v.Country', plValues);
                //alert(JSON.stringify(result))
                //alert(plValues1);
            }
        });
        $A.enqueueAction(action8);
        
        var action9 = component.get("c.getleadSource1");
        action9.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                var plValues1 = [];
                for (var i = 0; i < result.length; i++) {
                    plValues1.push({
                        label: result[i],
                        value: result[i]
                    });
                }
                component.set('v.leadSources', plValues1);
                // alert(JSON.stringify(result))
                
            }
        });
        $A.enqueueAction(action9);*/
    },
    searchText: function (component, event, helper) {
        var users = component.get('v.users');
        var searchText = component.get('v.searchText');

        var matchusers = [];
        if (searchText != '') {
            for (var i = 0; i < users.length; i++) {

                if (users[i].Name.toLowerCase().indexOf(searchText.toLowerCase()) != -1) {
                    matchusers.push(users[i])
                }
            }
            if (matchusers.length > 0) {
                component.set('v.matchUsers', matchusers);
            }
        } else {
            component.set('v.matchUsers', []);
        }
    },
    handleMobileChange: function (component, event, helper) {
        var mobile = component.get("v.newSiteVisit.Mobile__c");

        if (mobile) {
            component.set("v.spinner", true);
            var action = component.get("c.getDetailsByMobile");
            action.setParams({ mobileNumber: mobile });

            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if (result) {
                        var feedback = component.get("v.newSiteVisit");

                        // Always prefill these fields
                        feedback.Name__c = result.Name;
                        feedback.Email__c = result.Email;
                        feedback.Secondary_Email__c = result.Secondary_Email__c;
                        feedback.Secondary_Phone__c = result.Secondary_Phone__c;
                        feedback.Status = result.Status;

                        // Define valid lead stages for prefill
                        var prefillStages = [
                            'Incoming',
                            'Sales Prospect',
                            'Prospect',
                            'Opportunity',
                            'VDNB Prospect',
                            'VDNB incoming',
                            'Temp Lost',
                            'Qualified'
                        ];

                        // Conditionally prefill Source and Sub Source
                        if (result.Status && prefillStages.indexOf(result.Status) !== -1) {
                            feedback.Source__c = result.LeadSource;
                            feedback.Sub_Source__c = result.Sub_Source__c;
                        } else {
                            feedback.Source__c = null;
                            feedback.Sub_Source__c = null;
                        }

                        component.set("v.newSiteVisit", feedback);
                    } else {
                        console.log("No matching record found.");
                    }
                } else {
                    console.error("Failed to fetch details by mobile.");
                }
                component.set("v.spinner", false);
            });

            $A.enqueueAction(action);
        }
    },
    handleGenreChange1: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");

        //Update the Selected Values  
        component.set("v.newSiteVisit.Aspect_of_our_brand__c", selectedValues);
    },
    handleGenreChange2: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");

        //Update the Selected Values  
        component.set("v.newSiteVisit.How_did_you_find_out_about_us__c", selectedValues);
    },
    handleGenreChange3: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");

        //Update the Selected Values  
        component.set("v.newSiteVisit.What_is_your_preferred_location__c", selectedValues);
    },
    update: function (component, event, helper) {
        component.set('v.userId', event.currentTarget.dataset.id);
        component.set('v.showUsers', true);
        var rdi = component.get('v.userId');
        var users = component.get('v.matchUsers');
        for (var i = 0; i < users.length; i++) {
            if (users[i].Id === rdi) {
                component.set('v.searchText', users[i].Name);
                break;
            }
        }
        component.set('v.matchUsers', []);
        var st = component.get('v.newSiteVisit');
        st.FLS_Name__c = rdi;

    },

    save: function (component, event, helper) {
        // Prevent double-click / double-submit
        if (component.get("v.spinner") === true) {
            return;
        }

        var st = component.get("v.newSiteVisit");
        let isAllValid = component.find('field1').reduce(function (isValidSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return isValidSoFar && inputCmp.checkValidity();
        }, true);
        if (isAllValid == true) {
            component.set("v.spinner", true);
            var st = component.get("v.newSiteVisit");
            console.log('SIT : ' + JSON.stringify(st));
            var rdi = component.get('v.userId');
            var action = component.get("c.InsertSitevisit");
            action.setParams({
                'sit': st
            });
            action.setCallback(this, function (response) {
                if (response.getState() == "SUCCESS") {
                    var ex = response.getReturnValue();
                    var parts = ex ? ex.split('|||') : [];
                    var recordId = parts[0];
                    var stringMsg = parts[1];
                    console.log('return response ' + recordId);
                    console.log('return response ' + stringMsg);
                    console.log('return response ' + ex);

                    if (ex != null) {
                        if (stringMsg == 'Inserted' || stringMsg == 'updated') {
                            helper.showToast(
                                stringMsg == 'Inserted' ? "Site Visit Created Successfully" : "Site Visit Updated Successfully",
                                "Success"
                            );
                            console.log('Record Id : ' + recordId);

                            window.setTimeout(
                                $A.getCallback(function () {
                                    var navService = component.find("navService");
                                    var pageReference = {
                                        type: "standard__recordPage",
                                        attributes: {
                                            recordId: recordId,
                                            objectApiName: "Site_Visit__c",
                                            actionName: "view"
                                        }
                                    };
                                    navService.navigate(pageReference);
                                }),
                                1000
                            );
                        } else if (stringMsg == 'Invalid') {
                            console.log('else part');
                            var homeEvent = $A.get("e.force:navigateToObjectHome");
                            homeEvent.setParams({
                                "scope": "Site_Visit__c"
                            });
                            homeEvent.fire();
                            helper.showToast("GRE Is Not Available In Project", "Error");
                        } else if (stringMsg && stringMsg.indexOf('Error:') === 0) {
                            helper.showToast(stringMsg.substring(6), "Error");
                        } else {
                            helper.showToast("Some Error Occurred. Please try after sometime.", "Error");
                        }
                    } else {
                        helper.showToast("Some Error Occurred. Please try after sometime.", "Error");
                    }
                } else {
                    helper.showToast("Some Error Occurred. Please try after sometime.", "Error");
                }
                component.set("v.spinner", false);
            });
            $A.enqueueAction(action);
        }
    },
    searchText1: function (component, event, helper) {
        var proj = component.get('v.projects');

        var searchText1 = component.get('v.searchText1');
        var matchproj = [];
        if (searchText1 != '') {
            for (var i = 0; i < proj.length; i++) {
                if (proj[i].toLowerCase().indexOf(searchText1.toLowerCase()) != -1) {

                    if (matchproj.length < 50) {
                        matchproj.push(proj[i]);
                    } else {
                        break;
                    }

                }
            }
            if (matchproj.length > 0) {
                component.set('v.matchproj', matchproj);
            }
        } else {
            component.set('v.matchproj', []);
        }
    },
    update1: function (component, event, helper) {
        component.set('v.prjId', event.currentTarget.dataset.id);
        var edi = component.get('v.prjId');
        // alert(edi);
        var prj = component.get('v.matchproj');
        //   alert(prj);
        for (var i = 0; i < prj.length; i++) {

            if (prj[i] === edi) {
                component.set('v.searchText1', prj[i]);

                component.set('v.newSiteVisit.Project__c', prj[i]);
                break;
            }
        }

        component.set('v.matchproj', []);

    },
})