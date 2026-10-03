({
	doInit: function(component, event, helper)
    {
		helper.doInit(component, event, helper);
	},
	
	applyFilters: function(component, event, helper) 
    {
        helper.getData(component, event, helper,false);
    },
    applyFiltersOnOpp: function(component, event, helper) 
    {
        helper.applyFiltersOnOpp(component, event, helper,false);
    },
    generateQuoteSummary: function(component, event, helper)
    {
        helper.generateQuoteSummary(component, event, helper);
    },
    previewSummaryQuote: function(component, event, helper)
    {
        var data = component.get("v.selectedApartment");
        var oppData = component.get("v.setOfSelectedOppId");
        var leadData = component.get("v.setOfSelectedLeadId");

        var apartmentIds = [];
        for (var i = 0; i < data.length; i++)
        {
            apartmentIds.push(data[i].apartmentRec.Id);
        }

        var windowOpenStr = '/apex/GenerateQuoteSummary?aptIds='+ JSON.stringify(apartmentIds);

        if(oppData.length > 0)
        {
            windowOpenStr += '&oppIds='+oppData;
        }
        if(leadData.length > 0)
        {
            windowOpenStr += '&leadIds='+leadData;
        }

        window.open(windowOpenStr, '_blank');
       // window.location.href='/apex/GenerateQuoteSummary?aptIds='+ JSON.stringify(apartmentIds);
    },
    getSelectedRow: function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        var type = component.get("v.typeOfSummary")
        
        if(type == 'quoteSummary')
        {
            component.set("v.selectedLeadOppData",selectedRows);
        
        }else{
            component.set("v.selectedOpportunity",selectedRows);
        }
        
       
        var temp =[];
        var temp2 = [];
        var setOfOppId = [];
        var setOfLeadId = [];

        if(type == 'quoteSummary')
        {
            for (var i = 0; i < selectedRows.length; i++)
            {
                if(selectedRows[i].type == 'Lead')
                {
                    temp.push(selectedRows[i]);
                    setOfLeadId.push(selectedRows[i].id);

                }
                if(selectedRows[i].type == 'Opportunity')
                {
                    temp2.push(selectedRows[i]);
                    var str = '\''+selectedRows[i].id +'\'';
                    setOfOppId.push(str);
                }   
            }
        }else{

            for (var i = 0; i < selectedRows.length; i++)
            {
                
                temp2.push(selectedRows[i]);
                var str = '\''+selectedRows[i].Id +'\'';
                setOfOppId.push(str); 
            }
        }
        
        component.set("v.selectedLead",temp);
        component.set("v.setOfSelectedOppId",setOfOppId);
        component.set("v.setOfSelectedLeadId",setOfLeadId);
        //component.set("v.selectedOpportunity",temp2);
        //alert('dddddd  = '+JSON.stringify( component.get("v.setOfSelectedOppId")));
    },

    

    goBack: function(component,event,helper)
    {
       helper.goBack(component,event,helper);
        
    },
    goBackForSummaryQuote: function(component,event,helper)
    {
       helper.goBackForSummaryQuote(component,event,helper);
        
    },
    nextQuotation: function(component,event,helper)
    {

       helper.setSelectedOpportunities(component,event,helper, true);  
    },
    finishQuotation: function(component,event,helper)
    {

       helper.setSelectedOpportunities(component,event,helper, false);  
    },

    handleLWCEvent : function(component, event, helper) 
    {
        helper.handleLWCEvent(component, event, helper);
    },


})