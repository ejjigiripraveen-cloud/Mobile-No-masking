({
	doInit: function(component, event, helper)
	{
		component.set('v.columns', [
            {label: 'Name', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'name' }, target: '_blank'}},
            {label: 'Status', fieldName: 'status', type: 'text'},
            {label: 'Email', fieldName: 'email', type: 'email'},
			{label: 'Phone', fieldName: 'mobile', type: 'phone'},
			{label: 'Type', fieldName: 'type', type: 'text'},
			{label: 'Remarks', fieldName: 'comments', type: 'text'},
            
        ]);
        // for comparative quote 
        component.set('v.columnsForOpportunityTable', [
            {label: 'Name', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
            {label: 'Email', fieldName: 'Email__c', type: 'text'},
            {label: 'Phone', fieldName: 'Mobile__c', type: 'email'}
            
        ]);
        
       
        var oppId = component.get("v.opportunityId")
        var quoteType = component.get("v.typeOfSummary");
        // check its opportunity id or not
        if(oppId.startsWith("006"))
        {
            if(quoteType =='quoteSummary')
            {
                helper.getData(component, event, helper,true);
            }else{
                helper.applyFiltersOnOpp(component, event, helper,true);
            }
        }
        else if(oppId.startsWith("00Q"))
        {
            component.set("v.setOfSelectedLeadId", component.get("v.setOfSelectedLeadId").push(oppId));
            if(quoteType =='quoteSummary')
            {
                helper.getData(component, event, helper,true);
            }else{
                helper.applyFiltersOnOpp(component, event, helper,true);
            }
        }
        
        component.set("v.showLeadOppPage",true); 
        
	},
	getData : function(component, event, helper, fromDoInit)
    {
		component.set("v.showSpinner",true);
        var filterStr = component.get("v.filterString");
        
        
        if ((filterStr == null ||  filterStr == undefined || filterStr.length == 0) && fromDoInit ==false)
        {
			
			component.set("v.showSpinner",false);
            helper.showToast(component, event, helper,'Please fill the search string!','error','error');
			return;
		}else{
            
            
            var obj = component.get("c.getOppLeadTableData");
            obj.setParams({"searchString": filterStr,
                            "projectId": component.get("v.projectId"),
                            "oppRecId" : component.get("v.opportunityId"),
                            "setOfOppIds": component.get("v.setOfSelectedOppId"),
                            "setOfLeadIds" : component.get("v.setOfSelectedLeadId")
                          });
            
            obj.setCallback(this, function(response) {
                //store state of response
                var state = response.getState();
                if (state === "SUCCESS") 
				{  
                    var rows = response.getReturnValue();
                    
                    rows.forEach(function(record){
                        record.linkName = '/'+record.id; 
                    });
                    
                    //alert(JSON.stringify(rows));

					component.set("v.data",rows);
					component.set("v.showSpinner",false);
                    //alert(response.getReturnValue().length);
					if(response.getReturnValue().length <=0)
					{
						component.set("v.resMessage",'No Data Found!');
                        
                        if(fromDoInit == true)
                        {
                            //alert('This opportunity stage have not permission to share quotes');
                            helper.showToast(component, event, helper,'This opportunity stage have not permission to share quotes','error','error');
                        }
					}

                    //alert(JSON.stringify(response.getReturnValue()));
                }
                else if (state === "ERROR") {
					
                    var errors = response.getError();                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //alert(errors[0].message);
							component.set("v.showSpinner",false);
							helper.showToast(component, event, helper,errors[0].message,'error','error');
                            
                        }
                    } else {
						component.set("v.showSpinner",false);
						helper.showToast(component, event, helper,'Something went wrong!','error','error');
                    }
                }
                
            });
            $A.enqueueAction(obj);
		}
        
    },
    applyFiltersOnOpp: function(component, event, helper , fromDoInit)
    {
        component.set("v.showSpinner",true);
        var filterStr = component.get("v.filterString");
        
        if ( (filterStr == null ||  filterStr == undefined || filterStr.length == 0) && fromDoInit ==false )
        {
			component.set("v.showSpinner",false);
            helper.showToast(component, event, helper,'Please fill the search string!','error','error');
			return;
		}

        var obj = component.get("c.getOppForComparativeQuote");
            obj.setParams({"searchString": filterStr,
                            "oppRecId": component.get("v.opportunityId"),
                            "setOfOppIds": component.get("v.setOfSelectedOppId"),
                            "projectId": component.get("v.projectId")
                          });
            
            obj.setCallback(this, function(response) {
                //store state of response
                var state = response.getState();
                if (state === "SUCCESS") 
				{  
                    var rows = response.getReturnValue();
                    
                    rows.forEach(function(record){
                        record.linkName = '/'+record.Id; 
                    });

					component.set("v.opportunityList",rows);
					component.set("v.showSpinner",false);
					if(response.getReturnValue().length <=0)
					{
						component.set("v.resMessage",'No Data Found!');
					}
                    //alert('nnnnnnn = '+JSON.stringify(response.getReturnValue()));
                    
                }
                else if (state === "ERROR") {
					
                    var errors = response.getError();                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            //alert(errors[0].message);
							component.set("v.showSpinner",false);
							helper.showToast(component, event, helper,errors[0].message,'error','error');
                            
                        }
                    } else {
						component.set("v.showSpinner",false);
						helper.showToast(component, event, helper,'Something went wrong!','error','error');
                    }
                }
                
            });
            $A.enqueueAction(obj);


    },

    generateQuoteSummary: function(component, event, helper)
    {
        component.set("v.showSpinner",true);
        
        var data = component.get("v.selectedApartment");
        //alert(JSON.stringify(data[0].apartmentRec));
        var apartmentList = [];
        for (var i = 0; i < data.length; i++)
        {
            apartmentList.push(data[i].apartmentRec);
        }
        //alert(JSON.stringify(component.get("v.selectedApartment")));
            var obj = component.get("c.createQuoteSummary");
            obj.setParams({"leadList": component.get("v.selectedLead"),
                            //"oppList": component.get("v.selectedOpportunity"),
                            "oppId": component.get("v.opportunityId"),
                            "apartmentList": apartmentList,//component.get("v.selectedApartment"),
                            "leadOppData": JSON.stringify(component.get("v.selectedLeadOppData"))
                          });
            
            obj.setCallback(this, function(response) {
                //store state of response
                var state = response.getState();
                if (state === "SUCCESS") 
				{  
                    //var rows = response.getReturnValue();
                    
					helper.showToast(component, event, helper,'Summary Quote has been send successfully!','Success','Success');
					component.set("v.showSpinner",false);
                    helper.navigatetoOpp(component, event, helper);
					
					
                    //alert(JSON.stringify(response.getReturnValue()));
                }
                else if (state === "ERROR") {
					
                    var errors = response.getError();                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            
							component.set("v.showSpinner",false);
							helper.showToast(component, event, helper,errors[0].message,'error','error');
                            
                        }
                    } else {
						component.set("v.showSpinner",false);
						helper.showToast(component, event, helper,'Something went wrong!','error','error');
                    }
                }
                
            });
            $A.enqueueAction(obj);
    },

    setSelectedOpportunities: function(component,event,helper,isContinue)
    {
        var wrapRecord = component.get('v.currentWrapperOfQuoteWithInstallments')[0];
        var selectedOpportunity = component.get('v.selectedOpportunity');
        var wrapperList =[];
        for(var element of selectedOpportunity){
            wrapRecord.quotation.Opportunity__c = element.Id;
            for(var data of wrapRecord.installmentsList){
                data.Opportunity__c =element.Id;
            }
            var wrapRecordWithOpp ={
                oppDetail :element,
                quotationRecord : wrapRecord.quotation, 
                installments : wrapRecord.installmentsList, 
                apartment : wrapRecord.apartment 
            };
            wrapperList.push(wrapRecordWithOpp);
        }
         
        var event = component.getEvent("cmpEvent"); 
        
        event.setParams({
            "isOppLeadPage" : false,
            "isContinue":isContinue,
            "wrapperOfQuoteWithInstallments": wrapperList
        }); 
            
       	//fire the event    
       	event.fire();
           //helper.showToast(component, event, helper,'Comparative Quote has been send successfully!','Success','Success');
       /* component.set("v.showSpinner",true);
        
        var data = component.get("v.selectedApartment");
        var apartmentList = [];
        for (var i = 0; i < data.length; i++)
        {
            apartmentList.push(data[i].apartmentRec);
        }
        
            var obj = component.get("c.calculateDetails");
            obj.setParams({"oppRecId": component.get("v.selectedOpportunity")[0].Id,
                            "listOfApartment": apartmentList
                          });
            
            obj.setCallback(this, function(response) {
                //store state of response
                var state = response.getState();
                if (state === "SUCCESS") 
				{  
                    //alert(JSON.stringify(response.getReturnValue()));
                    component.set("v.quotationRec",response.getReturnValue());
                    component.set("v.showQuotationDetalLWCPage",true);
                    component.set("v.showLeadOppPage",false);
                    
					component.set("v.showSpinner",false);
                    
                }
                else if (state === "ERROR") {
					
                    var errors = response.getError();                    
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            
							component.set("v.showSpinner",false);
							helper.showToast(component, event, helper,errors[0].message,'error','error');
                            
                        }
                    } else {
						component.set("v.showSpinner",false);
						helper.showToast(component, event, helper,'Something went wrong!','error','error');
                    }
                }
                
            });
            $A.enqueueAction(obj);*/
    },
	goBack: function(component,event,helper)
    {
        component.set("v.showLeadOppPage",false); 
        //Call Parent aura method
        var parentComponent = component.get("v.parent");  
		parentComponent.showHidePage();
        
        var event = component.getEvent("cmpEvent"); 
        
        event.setParams({
            "isOppLeadPage" : false,
             "isContinue":true,
            "wrapperOfQuoteWithInstallments": []
        }); 
        //fire the event    
        event.fire();
        
    },
    goBackForSummaryQuote: function(component,event,helper)
    {
        component.set("v.showLeadOppPage",false); 
        //Call Parent aura method
        var parentComponent = component.get("v.parent");  
		parentComponent.showHidePage();
        
    },
    
    /*handleLWCEvent : function(component, event, helper) 
    {
        alert('LWC event handled');
		console.log('LWC event handled');
        
        var quoteRecord = event.getParam('quotationRecord');
        var listOfInstallment = [];
        listOfInstallment = event.getParam('installments');
        var isContinue = event.getParam('continueToInventory');
        var oppName = event.getParam('oppName');
		var apartmentName = event.getParam('apartmentName')
        
        console.log('quoteRecord');
        console.log(quoteRecord);
        console.log(listOfInstallment);
        console.log(isContinue);
        console.log(oppName);
        console.log(apartmentName);
        
        if(isContinue == true)
        {
            component.set("v.showQuotationDetalLWCPage",false);
            helper.goBack(component,event,helper);
           	console.log('Hey!!');
        }     
		if(isContinue == false)
        {
            component.set("v.showQuotationDetalLWCPage",false);
            component.set("v.showLeadOppPage",false);
        }
        
        var event = component.getEvent("cmpEvent"); 
        
        event.setParams({
            "quotation" : quoteRecord,
            "installmentsList": listOfInstallment,
            "isContinue" : isContinue,
            "oppName" : oppName,
            "apartmentName":apartmentName
        }); */
            
       	//fire the event    
       //	event.fire();

    //},

	showToast : function(component, event, helper,msg,type,title) {
        /*var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "type" : type,
            "duration" :50000,
            "message": msg
        });
        toastEvent.fire();
        */
        sforce.one.showToast({
            "title":title,
            "type":type,
            "message": msg
        });
    },
    navigatetoOpp:function(component, event, helper){
        //var oppId = cmp.get("v.oppRec.Id");
        
        var oppId = component.get("v.opportunityId"); //?  component.get("v.recordId"):component.get('v.pageReference.state.c__oppId') ;
        console.log('oppId');
		$A.get('e.force:refreshView').fire();

        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": oppId,
          "slideDevName": "detail"
        });
        navEvt.fire();
        //sforce.one.navigateToSObject(oppId,"detail");
    },
})