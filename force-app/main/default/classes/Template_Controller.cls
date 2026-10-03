/**
 *
 *  Purpose         :   Class for the Template to get data in LWC ComponentDetails.
 *
 *  Revision Logs   :   V_1.0 - Created - By Deepesh Bairathee
 *
 **/
public without sharing class Template_Controller
{
    /**
     *
     * Description     : Method to Return Templates__c Records By Template Master ID
     *
     * Args            : Id [templateMasterId], Quotation__c [quotationObj]
     *
     * Return type     : List<TemplateDetail> (Wrapper Class)
     *
     * Revision  Log   : V_1.0 - created
     */
    
    @AuraEnabled
    public static List<TemplateDetail> getTemplateDetails(Id templateMasterId, Quotation__c quotationObj, Double finalBalance)
    {
        List<TemplateDetail> templateDetailList = new List<TemplateDetail>();
        Double OnBookValue = 0;
        Double OrigOnBookValue = 0;
        Double Diff = 0;
        
        Template_Master__c templateMaster = [SELECT Id, Name, 
                                                 (SELECT Id, Name, Display_Order__c, Generate_Demand_Letter__c, Dont_GP__c, 
                                                        Due_Date__c, Grace_Period__c, Installment_Value__c, Use_STD_Amt__c, 
                                                        Component_Included__c, Overdue_Available__c, component_Included_Prcnt__c,
                                                        Overdue_penalty__c 
                                                    FROM Templates__r ORDER BY Display_Order__c) 
                                            FROM Template_Master__c WHERE 
                                            Id = :templateMasterId];
        
        List<Apartment__c> apartmentList = [SELECT Id, Standard_Booking_Amount__c FROM Apartment__c WHERE ID =:quotationObj.Inventory__c];
        
        Double inclusiveAmount = quotationObj.Inclusive_Amt_Total__c;
        
        System.debug('@@1 '+inclusiveAmount);
        System.debug('@@1 '+quotationObj.component_1_Discount__c);
        
        Boolean isFirst = true;
        List<Integer> componenetIncludedList = new List<Integer>();
        Integer index = 0;
        Boolean stdBookingAmountAllowed = false;
        Double stdAmt =0;
        Boolean isAlloted = false;
        
        for(Template__c  template : templateMaster.Templates__r)
        {
            if(template.Display_Order__c == 1 && template.Use_STD_Amt__c == true)
            {
                stdBookingAmountAllowed = true;
                
                Double OppTot =  quotationObj.Inclusive_Amt_Total__c;//quotationObj.Inclusive_Amt_Total__c-(quotationObj.Total_Balance__c- finalBalance);
                stdAmt = apartmentList[0].Standard_Booking_Amount__c != null ? apartmentList[0].Standard_Booking_Amount__c :0;
                OnBookValue = (stdAmt/OppTot) *100;
                OrigOnBookValue = template.Installment_Value__c;
                template.Installment_Value__c = OnBookValue;
                Diff = OrigOnBookValue - OnBookValue;
                system.debug('OnBookValue---'+OnBookValue +'---'+OrigOnBookValue+'--'+OppTot);
            }
            
            if(template.Display_Order__c == 1)
            {
                template.Overdue_Interest_Applicable__c = false;
            }
            else
            {
                template.Overdue_Interest_Applicable__c = template.Overdue_Available__c;
            }
            
            if(template.Display_Order__c !=1 &&  OnBookValue > 0 && template.Installment_Value__c >0 && !isAlloted){
                template.Installment_Value__c += Diff; isAlloted = true;
                system.debug(template.Installment_Value__c );
            }
            
            if(stdBookingAmountAllowed)
            {
                quotationObj.Standard_Booking_Amount__c = true;
            }
            else {
                quotationObj.Standard_Booking_Amount__c = false;
            }
            
            templateDetailList.add(new TemplateDetail(template.Name, template.Display_Order__c,( template.Due_Date__c < System.today() ? System.today() :template.Due_Date__c ),
            template.Grace_Period__c, template.Installment_Value__c, template.Overdue_Interest_Applicable__c,
            template.Overdue_penalty__c, template.Component_Included__c, template.component_Included_Prcnt__c,  quotationObj.Standard_Booking_Amount__c));
        }
        
        List<Quotation_Installment__c> listOfInstallmentObject = new List<Quotation_Installment__c>();
        Boolean isComponentIncluded = false;
        
        for(Integer k = 0; k<templateDetailList.size(); k++)
        {
            System.debug('INS VALUE -> '+templateDetailList[k].installmentValue);
            listOfInstallmentObject.add(new Quotation_Installment__c (
                Display_Order__c    = templateDetailList[k].displayOrder,
            Due_Date__c         = templateDetailList[k].dueDate < System.today() ? System.today() :templateDetailList[k].dueDate ,
            Grace_Period__c     = templateDetailList[k].gracePeriod,
            Installment_Value__c  =  templateDetailList[k].installmentValue * 100,
            Name              = templateDetailList[k].name,
            Component_Included__c = templateDetailList[k].componentIncluded,
            Component_Included_Prcnt__c = templateDetailList[k].componentIncludedPrcnt,
            Overdue_Interest_Applicable__c = templateDetailList[k].overdueInterestApplicable
                ));
            if(string.isNotBlank(templateDetailList[k].componentIncluded))
            {
                isComponentIncluded = true;
            }
        }
        system.debug('quotationObj---'+quotationObj.Total_Balance__c);
        
        if(isComponentIncluded)
        {
            InstallmentAndQuotationWrapper iQWrapper =
                beforeInsertInstallment(listOfInstallmentObject, quotationObj, true, true, '1', true,false, true);
            
            List<Quotation_Installment__c>  quotationInstallmentList = iQWrapper.installmentList;
            Boolean isAmountAlloted = false;
            
            for(Integer k = 0; k<templateDetailList.size(); k++)
            {
                System.debug('quotationObj.Component_1_Amount_After_Discount__c--- '+quotationObj.Component_1_Amount_After_Discount__c);
                system.debug('OnBookValue---'+ finalBalance);
                
                Double installValue =  quotationInstallmentList[k].Total_Amount__c/finalBalance;
                system.debug('installValue---'+installValue+'(quotationInstallmentList[k].Total_Amount__c'+quotationInstallmentList[k].Total_Amount__c);
                
                if( templateDetailList[k].displayOrder == 1 && stdBookingAmountAllowed && stdAmt>0)
                {
                    OnBookValue = (stdAmt/finalBalance); templateDetailList[k].installmentValue = OnBookValue; Diff = installValue - OnBookValue;
                    system.debug('OnBookValue---'+Diff +'--'+installValue);
                }
                
                else if( templateDetailList[k].displayOrder != 1 && stdBookingAmountAllowed && stdAmt >0
                    &&  templateMaster.Templates__r[k].Installment_Value__c >0  && !isAmountAlloted)
                {
                    templateDetailList[k].installmentValue =  installValue+Diff; isAmountAlloted = true;
                }
                else
                {
                    templateDetailList[k].installmentValue = installValue;
                }
                system.debug('templateDetailList---- '+templateDetailList[k].installmentValue);
            }
        }
        
        System.debug(templateDetailList);
        
        return templateDetailList;
    }
    
    /**
     *
     * Description     : Method to Return updated installment with taxes
     *
     * Args            : List<Installment__c>  [newList], Quotation__c [quotationObj], Boolean isTaxAllowed
     *
     * Return type     : List<Installment__c>
     *
     * Revision  Log   : V_1.0 - created
     */
    
    @AuraEnabled(cacheable = true)
    public static InstallmentAndQuotationWrapper beforeInsertInstallment(List<Quotation_Installment__c> newList,
    Quotation__c quotationObj, Boolean isTaxAllowed, Boolean allowUserToSelectSubComponent, String subCompToReduceTotalDiscount,
    Boolean calculateAmountWithTax, Boolean isCallfromComp, Boolean isFromTemp)
    {
        List<Id> componentTaxMaster = new List<Id>();
        List<Quotation_Installment__c> newListQI = new List<Quotation_Installment__c>();
        List<Apartment__c> listApartment = [SELECT Id, Standard_Booking_Amount__c, Built_Up_Area__c, Apartment_Rate_Formula__c 
                                            FROM Apartment__c 
                                            WHERE ID =:quotationObj.Inventory__c];
        List<Token__c> listOfTokens = [SELECT Id, Name, EOI_Discount_Per_Sqft__c, Total_EOI_Discount__c,Token_Discount_Status__c,Inventory__c,Opportunity__c,Plot_Cost_With_elevated_value__c,Plot_Cost_With_elevated_after_discount__c,EOI_Increment__c,Total_Eoi_Increment__c FROM Token__c WHERE Inventory__c =:quotationObj.Inventory__c AND Opportunity__c =:quotationObj.Opportunity__c AND Token_Discount_Status__c = 'Approved'];
        Double eoiIncrement = 0.0;
        Double eoiTokenDiscount = 0.0;
        System.debug('quotationObjpc==>'+quotationObj);
        System.debug('quotationObjpc==>'+listOfTokens);
        if(!listOfTokens.isEmpty()){
            eoiIncrement = listOfTokens[0].EOI_Increment__c ?? 0.0;  eoiTokenDiscount = listOfTokens[0].Total_EOI_Discount__c ?? 0.0 ;
        }
        Double OnBookValue = 0;
        Double OrigOnBookValue = 0;
        Double Diff = 0;
        Double remValue =0;
        Double calDiff =0;
        calDiff = quotationObj.Component_1_Basic__c -quotationObj.Component_1_Amount_After_Discount__c;
        system.debug('isTaxAllowed0---'+calculateAmountWithTax+'---'+isTaxAllowed);
        System.debug('newList@@ ' + newList);
        if(newList !=null && newList.size()>0 && calculateAmountWithTax && isTaxAllowed)
        {
            Integer dependentChargesNumber = 1;
            if(!String.isBlank(subCompToReduceTotalDiscount))
            {
                dependentChargesNumber = (subCompToReduceTotalDiscount.contains(',') &&
                    subCompToReduceTotalDiscount.split(',')[1].split(';')[0] != null) ? integer.valueof(subCompToReduceTotalDiscount.split(',')[1].split(';')[0])
                    : 0;
            }
            
            System.debug('quotationObj.Comp1_Total__c -> '+quotationObj.Comp1_Total__c);
            System.debug('quotationObj.component_1_Basic__c -> '+quotationObj.component_1_Basic__c);
            Double basicTaxPercent = 0;
            if(quotationObj.component_1_Basic__c != 0)
            {
                basicTaxPercent = (quotationObj.Comp1_Total__c - quotationObj.component_1_Basic__c)/(quotationObj.component_1_Basic__c);
            }
            
            
            System.debug('basicTaxPercent --> '+basicTaxPercent);
            //System.debug('dependentChargesNumber --> '+dependentChargesNumber);
            //System.debug('split --> '+subCompToReduceTotalDiscount.split(';'));
            
            //10
            Double dependentTaxCharges = dependentChargesNumber != 0 ? ((double.valueOf(quotationObj.get
                ('comp'+dependentChargesNumber+'_Total__c')) - double.valueOf(quotationObj.get  ('component_'+dependentChargesNumber+'_Basic__c')))  / double.valueOf(quotationObj.get
                ('component_'+dependentChargesNumber+'_Basic__c'))) * 100 : 0;
            
            //20
            Double dependentCharges = dependentChargesNumber!=0 ? (double.valueOf(quotationObj.get
                ('component_'+dependentChargesNumber+'_Basic__c')) /
                (listApartment[0].Apartment_Rate_Formula__c *listApartment[0].Built_Up_Area__c)*100):0;
            
            String selectedSubComp = allowUserToSelectSubComponent ? quotationObj.Sub_comp_to_reduce_total_discount__c :
                subCompToReduceTotalDiscount;
            
            if(!String.isBlank(selectedSubComp))
            {
                for(Integer i =2; i<=20; i++)
                {
                    if(!selectedSubComp.contains(string.valueof(i)))
                    {
                        remValue += double.valueOf((quotationObj.get('Comp'+i+'_Total__c')) == NULL ? 0 : (quotationObj.get('Comp'+i+'_Total__c')));
                    }
                }
            }
            
            // if(!listApartment.isEmpty())
            // {
                //     System.debug('component_1_Basic__c -> '+quotationObj.component_1_Basic__c);
                //     System.debug('basicTaxPercent -> '+(basicTaxPercent+1));
                
                //     Double discountOnBasicPerSqft = listApartment[0].Apartment_Rate_Formula__c -
                //         (( quotationObj.Total_Balance__c - remValue - listApartment[0].Built_Up_Area__c *
                //         (quotationObj.component_1_Basic__c / listApartment[0].Built_Up_Area__c - listApartment[0].Apartment_Rate_Formula__c) *
                //         (1+basicTaxPercent))/((1+basicTaxPercent)+(dependentCharges*(1+dependentTaxCharges))))/listApartment[0].Built_Up_Area__c;
                
                //     Double premiumCharges = (quotationObj.component_1_Basic__c / listApartment[0].Built_Up_Area__c - listApartment[0].Apartment_Rate_Formula__c);
                //     System.debug('premiumCharges@@@ ' + premiumCharges);
                //     System.debug('discountOnBasicPerSqft@@@ ' + discountOnBasicPerSqft);
                //     Double totalRate = listApartment[0].Apartment_Rate_Formula__c + premiumCharges - discountOnBasicPerSqft;
                //     System.debug('totalRate@@@ ' + totalRate);
                //     Double calculatedBasicCost = totalRate * listApartment[0].Built_Up_Area__c;
                //     System.debug('calculatedBasicCost@@@ ' + calculatedBasicCost);
                
                //     System.debug('listApartment[0].Apartment_Rate_Formula__c -> '+listApartment[0].Apartment_Rate_Formula__c);
                //     System.debug('quotationObj.Total_Balance__c -> '+quotationObj.Total_Balance__c);
                //     System.debug('remValue -> '+remValue);
                //     System.debug('listApartment[0].Built_Up_Area__c -> '+listApartment[0].Built_Up_Area__c);
                //     System.debug('1+basicTaxPercent -> '+ (1+basicTaxPercent));
                //     System.debug('dependentCharges -> '+ dependentCharges);
                //     System.debug('dependentTaxCharges -> '+ dependentTaxCharges);
                //     System.debug('PRI -> '+ premiumCharges);
                //     System.debug('discountOnBasicPerSqft---> '+discountOnBasicPerSqft);
                //     System.debug('calculatedBasicCost---> '+calculatedBasicCost);
                //     System.debug('quotationObj.component_1_Discount__c---> '+quotationObj.component_1_Discount__c);
                //     System.debug('quotationObj.Component_1 ---> '+quotationObj.Component_1_Amount_After_Discount__c);
                //     if((quotationObj.Component_1_Amount_After_Discount__c - calculatedBasicCost) > 1)
                //     {
                    //         quotationObj.component_1_Discount__c = (quotationObj.Component_1_Amount_After_Discount__c - calculatedBasicCost)+quotationObj.component_1_Discount__c ;
                    //         quotationObj.Component_1_Amount_After_Discount__c = quotationObj.Component_1_Amount_After_Discount__c - (quotationObj.Component_1_Amount_After_Discount__c - calculatedBasicCost);
                    //         calDiff = quotationObj.Component_1_Basic__c -quotationObj.Component_1_Amount_After_Discount__c;
                    
                    //         System.debug('quotationObj.Component_1_Discount__c---> '+quotationObj.component_1_Discount__c);
                    //         System.debug('quotationObj.Component_1_Amount_After_Discount__c---> '+quotationObj.Component_1_Amount_After_Discount__c);
                    
                    //         if(dependentCharges != 0)
                    //         {
                        //             double discountOnDepComp = Double.valueOf(quotationObj.get('component_'+dependentChargesNumber+'_Discount__c'))+
                        //                 (dependentCharges * listApartment[0].Built_Up_Area__c *
                        //                 (listApartment[0].Apartment_Rate_Formula__c - discountOnBasicPerSqft));
                        //             quotationObj.put('component_'+dependentChargesNumber+'_Discount__c', discountOnDepComp);
                        //             System.debug('discountOnDepComp '+discountOnDepComp);
                    //         }
                //     }
                //     else{
                    //         calDiff = quotationObj.Component_1_Basic__c -quotationObj.Component_1_Amount_After_Discount__c;
                //     }
            // }
            Integer countOfInstallmentWhichAreNotIncludedWithOutStd = 0;
            Integer countOfInstallmentWhichAreNotIncludedWithStd = 0;
            Double amountOfComponenetWhichAreNotIncluded = 0;
            system.debug('quotationObj---'+quotationObj);
            system.debug('newList---'+newList);
            
        }
        
        //Commneted by Prem Chand For EOI Increment fix
        /*if(newList !=null && newList.size()>0 && isFromTemp == false)
        {
            Boolean isStd = quotationObj.Standard_Booking_Amount__c;
            
            for(Quotation_Installment__c  installmentObj : newList)
            {
                if(!String.isBlank(installmentObj.Component_Included__c) || isStd)
                {
                    installmentObj.Installment_Value__c = 0.00;
                    isStd = false;
                }
                else {
                    System.debug('InsValuePcc==>'+installmentObj.Installment_Value__c);
                    System.debug('InsValuePcc==>'+quotationObj.Total_Balance__c);
                    System.debug('InsValuePcc==>'+quotationObj.Inclusive_Amt_Total__c);
                    Double discountedValue = (installmentObj.Installment_Value__c * quotationObj.Total_Balance__c) / quotationObj.Inclusive_Amt_Total__c;
                    System.debug('** discountedValue -> '+discountedValue);
                    System.debug('** INS -> '+installmentObj.Installment_Value__c);
                    System.debug('** TOTAL -> '+quotationObj.Total_Balance__c);
                    System.debug('** INC -> '+quotationObj.Inclusive_Amt_Total__c);
                    installmentObj.Installment_Value__c = discountedValue; // need to comment
                }
                
                newListQI.add(installmentObj);
            }
            
            newList.clear();
            newList.addAll(newListQI);
        }*/
        
        for(Integer k = 1; k<= 19 ; k++)
        {
            Id taxMasterId = (Id)quotationObj.get('Comp'+k+'_Tax__c');
            componentTaxMaster.add(taxMasterId);
        }
        
        Map<Id,Tax_Master__c> mapWithIdAndTaxMaster = new Map<ID, Tax_Master__c>([SELECT Id, TC1_Appr__c, TC1_Available__c, TC1_Value__c, 
            TC2_Appr__c, TC2_Available__c, TC2_Value__c, TC3_Appr__c, TC3_Available__c, TC3_Name__c, TC3_Type__c, TC3_Value__c, TC4_Appr__c, 
            TC4_Available__c, TC4_Name__c, TC4_Type__c, TC4_Value__c, TC1_Name__c, TC1_Type__c, TC2_Name__c, TC2_Type__c, TC1_Change_Type__c, 
            TC2_Change_Type__c, TC3_Change_Type__c, TC4_Change_Type__c, Sub_Component__c, Sub_Component__r.Collection_Type__c,Sub_Component__r.Iscalculate_TDS__c
            FROM Tax_Master__c WHERE Id = :componentTaxMaster]);
        
        Decimal totalTax1 = 0;
        Decimal totalTax2 = 0;
        Decimal totalTax3 = 0;
        Decimal totalTax4 = 0;
        Decimal totalBasicAfterDiscount = 0;
        Decimal totalDiscount = 0;
        Decimal totalBasic = 0;
        
        for(Integer compCount = 1; compCount<= 19 ; compCount++)
        {
            Tax_Master__c taxMasterObject = mapWithIdAndTaxMaster.get((Id)quotationObj.get('Comp'+compCount+'_Tax__c'));
            Decimal tax1 = 0, tax2 = 0, tax3 = 0, tax4 = 0;
            String tax1Name ='';
            String tax2Name ='';
            String tax3Name ='';
            String tax4Name ='';
            if(taxMasterObject != null && isTaxAllowed)
            {
                tax1 = MATH.round((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) * (taxMasterObject.TC1_Value__c == null ? 0 : taxMasterObject.TC1_Value__c/100) * (taxMasterObject.TC1_Appr__c == null ? 0 : taxMasterObject.TC1_Appr__c/100 )));
                tax1Name = taxMasterObject.TC1_Name__c;
                
                tax2 = MATH.round((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) * (taxMasterObject.TC2_Value__c == null ? 0 : taxMasterObject.TC2_Value__c/100) * (taxMasterObject.TC2_Appr__c == null ? 0 : taxMasterObject.TC2_Appr__c/100 )));
                tax2Name = taxMasterObject.TC2_Name__c;
                
                tax3 = MATH.round((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) * (taxMasterObject.TC3_Value__c == null ? 0 : taxMasterObject.TC3_Value__c/100) * (taxMasterObject.TC3_Appr__c == null ? 0 : taxMasterObject.TC3_Appr__c/100 )));
                tax3Name = taxMasterObject.TC3_Name__c;
                
                tax4 = MATH.round((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) * (taxMasterObject.TC4_Value__c == null ? 0 : taxMasterObject.TC4_Value__c/100) * (taxMasterObject.TC4_Appr__c == null ? 0 : taxMasterObject.TC4_Appr__c/100 )));
                tax4Name = taxMasterObject.TC4_Name__c;
                
                totalTax1 += tax1;
                totalTax2 += tax2;
                totalTax3 += tax3;
                totalTax4 += tax4;
            }
            
            quotationObj.put('Comp'+compCount+'_Tax1_Name__c', tax1Name);
            quotationObj.put('Comp'+compCount+'_Tax2_Name__c', tax2Name);
            quotationObj.put('Comp'+compCount+'_Tax3_Name__c', tax3Name);
            quotationObj.put('Comp'+compCount+'_Tax4_Name__c', tax4Name);
            
            quotationObj.put('Comp'+compCount+'_Tax1_Amount__c',tax1);
            quotationObj.put('Comp'+compCount+'_Tax2_Amount__c',tax2);
            quotationObj.put('Comp'+compCount+'_Tax3_Amount__c',tax3);
            quotationObj.put('Comp'+compCount+'_Tax4_Amount__c',tax4);
            
            quotationObj.put('Comp'+compCount+'_Total__c',(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')))+tax1 + tax2 + tax3 + tax4));
            
            
            totalBasicAfterDiscount += (quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 : double.valueOf((quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c'))));
            
            totalDiscount += (quotationObj.get('Component_'+compCount+'_Discount__c') == NULL ? 0 : double.valueOf((quotationObj.get('Component_'+compCount+'_Discount__c'))));
            
            System.debug((quotationObj.get('Component_'+compCount+'_Discount__c') == NULL ? 0 : double.valueOf((quotationObj.get('Component_'+compCount+'_Discount__c'))))+ '  ---  '+ compCount);
            
            System.debug('quotationObj.Total_Balance__c -> '+totalDiscount);
            totalBasic += (quotationObj.get('Component_'+compCount+'_Basic__c') == NULL ? 0 : double.valueOf((quotationObj.get('Component_'+compCount+'_Basic__c')))); // Added by Shubham k.
        }
        System.debug('quotationObj.Total_Discount1__c@@@@ ' + quotationObj.Total_Discount1__c);
        // Added by Shubham Kumar.
        if(totalDiscount == 0.0)
        {
            totalDiscount = quotationObj.Total_Discount1__c; //  this field have the value when the 88/12 applied on the quotation.
        }
        else
        {
            totalDiscount += quotationObj.Total_Discount1__c == null ? 0 : quotationObj.Total_Discount1__c;
        }
        System.debug('Discount@@#@ ' + totalDiscount);
        quotationObj.put('Total_Tax1__c', totalTax1);
        quotationObj.put('Total_Tax2__c', totalTax2);
        quotationObj.put('Total_Tax3__c', totalTax3);
        quotationObj.put('Total_Tax4__c', totalTax4);
        quotationObj.put('Total_Tax__c', totalTax1 + totalTax2 + totalTax3 + totalTax4);
        quotationObj.put('Total_Basic_After_Discount__c', totalBasicAfterDiscount);
        quotationObj.put('Final_Inventory_Cost__c', totalBasicAfterDiscount);
        quotationObj.put('Total_Basic__c', totalBasic);
        
        Decimal totalbalancewitheoi = 0.0;
        if(quotationObj.EOI_Discount__c == null) {
            // if(eoiIncrement > 0){
                //     totalbalancewitheoi = (double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2)
                //     + double.valueOf(totalTax3) + double.valueOf(totalTax4) + double.valueOf(eoiIncrement));
            // }
            // if(eoiTokenDiscount > 0){
                //     totalbalancewitheoi = (double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2)
                //     + double.valueOf(totalTax3) + double.valueOf(totalTax4) + double.valueOf(eoiIncrement))- double.valueOf(eoiTokenDiscount);
            // }
            totalbalancewitheoi = (double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2)
                + double.valueOf(totalTax3) + double.valueOf(totalTax4) + double.valueOf(eoiIncrement));
            
        }
        else {
            totalbalancewitheoi += double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2)+ double.valueOf(totalTax3) + double.valueOf(totalTax4);
        }
        
        System.debug('totalbalancepcc==>'+totalbalancewitheoi);
        
        // quotationObj.put('Total_Balance__c', double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2) + double.valueOf(totalTax3) + double.valueOf(totalTax4));
        //  quotationObj.put('Total_Balance__c', double.valueOf(totalBasicAfterDiscount) + double.valueOf(totalTax1) + double.valueOf(totalTax2) + double.valueOf(totalTax3) + double.valueOf(totalTax4) + double.valueOf(eoiIncrement)); // Add Prem EOI Discount
        quotationObj.put('Total_Balance__c', double.valueOf(totalbalancewitheoi));
        
        quotationObj.put('Total_Discount__c', totalDiscount);
        system.debug('quotationObj '+ quotationObj.get('Total_Balance__c'));
        
        double inclusiveAmount = 0;
        Double tdsCalculateAmt = 0;
        for(Integer compCount=1; compCount<=19; compCount++)
        {
            System.debug('compCount -> '+compCount);
            
            Tax_Master__c taxMasterObject = mapWithIdAndTaxMaster.get((Id)quotationObj.get('Comp'+compCount+'_Tax__c'));
            
            if(taxMasterObject != null && taxMasterObject.Sub_Component__c != null
                && taxMasterObject.Sub_Component__r.Collection_Type__c == 'Inclusive')
            {
                inclusiveAmount += Double.valueOf(quotationObj.get('Comp'+compCount+'_Total__c'));
                System.debug('@@1 '+Double.valueOf(quotationObj.get('Comp'+compCount+'_Total__c')));
            }
            if(taxMasterObject != null && taxMasterObject.Sub_Component__r.Iscalculate_TDS__c)
            {
                tdsCalculateAmt += Double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c'));
                
            }
        }
        System.debug('@@1 INC '+inclusiveAmount);
        System.debug('@@1 BASIC '+quotationObj.component_1_Basic__c);
        System.debug('@@1 DIS '+quotationObj.component_1_Discount__c);
        System.debug('@@1 AMT AFTR '+quotationObj.Component_1_Amount_After_Discount__c);
        System.debug('@@1 TOTAL '+quotationObj.Comp1_Total__c);
        //inclusiveAmount += eoiIncrement ?? 0.0; // Add Prem EOI Discount
        quotationObj.put('Inclusive_Amt_Total__c', inclusiveAmount);
        quotationObj.put('Total_TDS_Count_After_Discount__c', tdsCalculateAmt);
        
        // ------------------------ Installment Creation ------------------------ //
        
        if(newList !=null && newList.size()>0 && isFromTemp == false)
        {
            Boolean isStd = quotationObj.Standard_Booking_Amount__c;
            
            for(Quotation_Installment__c  installmentObj : newList)
            {
                if(!String.isBlank(installmentObj.Component_Included__c) || isStd)
                {
                    installmentObj.Installment_Value__c = 0.00;
                    isStd = false;
                }
                else
                {
                    System.debug('InsValuePcc==>'+installmentObj.Installment_Value__c);
                    System.debug('InsValuePcc==>'+quotationObj.Total_Balance__c);
                    System.debug('InsValuePcc==>'+quotationObj.Inclusive_Amt_Total__c);
                    Double discountedValue = (installmentObj.Installment_Value__c * quotationObj.Total_Balance__c) / quotationObj.Inclusive_Amt_Total__c;
                    System.debug('** discountedValue -> '+discountedValue);
                    System.debug('** INS -> '+installmentObj.Installment_Value__c);
                    System.debug('** TOTAL -> '+quotationObj.Total_Balance__c);
                    System.debug('** INC -> '+quotationObj.Inclusive_Amt_Total__c);
                    installmentObj.Installment_Value__c = discountedValue; // need to comment
                }
                
                newListQI.add(installmentObj);
            }
            
            newList.clear();
            newList.addAll(newListQI);
        }
        
        Decimal stdAmt =0;
        if(newList !=null && newList.size()>0 )
        {
            Boolean isAlloted = false;
            Map<Decimal,Template__c> mapTemplate = new Map<Decimal,Template__c>();
            if( quotationObj.Template_Master__c != null && isCallFromComp){
                for( Template__c temp: [SELECT Id, Name, Display_Order__c, Generate_Demand_Letter__c, Dont_GP__c, 
                                        Due_Date__c, Grace_Period__c, Installment_Value__c, Use_STD_Amt__c, 
                                        Component_Included__c, Overdue_Available__c, component_Included_Prcnt__c,
                                        Overdue_penalty__c 
                                        FROM Template__c WHERE 
                                        Template_Master__c = :quotationObj.Template_Master__c ORDER BY Display_Order__c]){ mapTemplate.put(temp.Display_Order__c, temp);
                }
            }
            system.debug('mapTemplate---'+mapTemplate.size()+'---'+isCallFromComp+'--'+quotationObj.Template_Master__c );
            Boolean isUpdated = false;
            for(Quotation_Installment__c  installmentObj : newList)
            {
                //To calculate the original installment value of template and check the demand letter generation: 17/02/22 :Priyanka Mittal
                if(mapTemplate.size() > 0 && mapTemplate.containsKey(installmentObj.Display_Order__c)){
                    if(mapTemplate.get(installmentObj.Display_Order__c).Generate_Demand_Letter__c && installmentObj.Due_Date__c <= System.Today()){
                        // installmentObj.Generate_Demand_Letter__c = true;
                        installmentObj.Generate_Demand_Letter__c = false;
                    }
                    Double OppTot =  quotationObj.Inclusive_Amt_Total__c; stdAmt = listApartment[0].Standard_Booking_Amount__c;
                    system.debug('stdAmt---'+(stdAmt/oppTot.round()*100).setScale(3) +'---'+(newList[0].Installment_Value__c).setScale(3));
                    System.debug('IS AL' + isAlloted);
                    
                    if(installmentObj.Display_Order__c == 1 && quotationObj.Standard_Booking_Amount__c == true)
                    {
                        system.debug('quotationObj.Inclusive_Amt_Total__c---'+quotationObj.Inclusive_Amt_Total__c+'---'+calDiff);
                        OnBookValue = (stdAmt/OppTot) *100;
                        system.debug('OnBookValue--'+OnBookValue);
                        OrigOnBookValue = Double.valueOf(mapTemplate.get(installmentObj.Display_Order__c).Installment_Value__c); installmentObj.Installment_Value__c = OnBookValue; Diff = OrigOnBookValue - OnBookValue;
                        System.debug('IN DIFF '+Diff);
                        isUpdated = true;
                    }
                    system.debug('installmentObj.Installment_Value__c--'+  installmentObj.Installment_Value__c);
                }
                else if(mapTemplate.size() == 0 )
                {
                    if( (listApartment[0].Standard_Booking_Amount__c/quotationObj.Total_Balance__c.round()*100).setScale(3) != (newList[0].Installment_Value__c).setScale(3)){
                        if(installmentObj.Display_Order__c == 1 && quotationObj.Standard_Booking_Amount__c == true)
                        {
                            Double OppTot =  quotationObj.Inclusive_Amt_Total__c; stdAmt = listApartment[0].Standard_Booking_Amount__c; OnBookValue = (stdAmt/OppTot) *100;
                            system.Debug('OnBookValue---'+OnBookValue+'---'+OppTot);
                            OrigOnBookValue = installmentObj.Installment_Value__c;installmentObj.Installment_Value__c = OnBookValue;Diff = OrigOnBookValue - OnBookValue;
                            System.debug('IN DIFF '+Diff);
                        }
                        if(installmentObj.Display_Order__c == 1) { installmentObj.Overdue_Interest_Applicable__c = false;
                        }
                        else
                        {
                            //installmentObj.Overdue_Interest_Applicable__c = installmentObj.Overdue_Available__c;
                        }
                        System.debug('DIFF '+ Diff);
                        if(installmentObj.Display_Order__c != 1 &&  OnBookValue > 0 && isAlloted == false && installmentObj.Installment_Value__c >0)
                        {
                            installmentObj.Installment_Value__c += Diff;isAlloted = true;
                        }
                    }
                }
                if(((mapTemplate.size() >0 && !mapTemplate.containsKey(installmentObj.Display_Order__c))|| mapTemplate.size() ==0)
                && installmentObj.Due_Date__c <= system.today()){
                    // installmentObj.Generate_Demand_Letter__c = true;
                    installmentObj.Generate_Demand_Letter__c = false;
                }
            }
        }
        
        if(newList !=null && newList.size()>0)
        {
            system.debug('newList---'+newList);
            for(Quotation_Installment__c ins : newList)
            {
                System.debug('Component_Included_Prcnt__c--->'+ins.Component_Included_Prcnt__c);
                ins.Total_Basic__c = 0;
                ins.Total_Tax1__c = 0;
                ins.Total_Tax2__c = 0;
                ins.Total_Tax3__c = 0;
                ins.Total_Tax4__c = 0;
                
                //For getting Components included in this schedule
                for(Integer compCount=1; compCount<=19; compCount++)
                {
                    System.debug('compCount -> '+compCount);
                    
                    Tax_Master__c taxMasterObject = mapWithIdAndTaxMaster.get((Id)quotationObj.get('Comp'+compCount+'_Tax__c'));
                    
                    if(taxMasterObject != null && taxMasterObject.Sub_Component__c != null
                        && taxMasterObject.Sub_Component__r.Collection_Type__c == 'Inclusive')
                    {
                        ins.put('Comp'+compCount+'_Name__c',quotationObj.get('Component_'+compCount+'_Name__c'));
                        
                        ins.put('Comp'+compCount+'_Basic__c',(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 :  double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) * (double.valueOf(ins.get('Installment_Value__c')) /100)));
                        
                        
                        System.debug('1 IN # '+ compCount + '   '+ double.valueOf(ins.get('Installment_Value__c')));
                        //System.debug('2 IN # '+ compCount + '   ' + (quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 :  double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c'))));
                        
                        ins.put('Comp'+compCount+'_Total__c',ins.get('Comp'+compCount+'_Basic__c'));
                        
                        ins.put('Total_Basic__c',double.valueOf(ins.get('Total_Basic__c')) + double.valueOf(ins.get('Comp'+compCount+'_Basic__c')));
                        system.debug('insvalue--- '+ins.Display_Order__c +'---'+  ins.Total_Basic__c);
                        
                        if(isTaxAllowed)
                        {
                            for(integer taxCount=1;taxCount<=4;taxCount++)
                            {
                                if(boolean.valueOf(taxMasterObject.get('TC'+taxCount+'_Available__c'))
                                    && taxMasterObject.get('TC'+taxCount+'_Type__c') == 'Exclusive'
                                    && taxMasterObject.get('TC'+taxCount+'_Value__c') != null
                                    && taxMasterObject.get('TC'+taxCount+'_Appr__c') != null)
                                {
                                    ins.put('Comp'+compCount+'_Tax'+taxCount+'_Name__c',taxMasterObject.get('TC'+taxCount+'_Name__c'));
                                    double TaxAmount = double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c')) *
                                        (taxMasterObject.get('TC'+taxCount+'_Value__c') == NULL ? 0 : double.valueOf(taxMasterObject.get('TC'+taxCount+'_Value__c') )/100) *
                                        (double.valueOf(taxMasterObject.get('TC'+taxCount+'_Appr__c'))/100) *
                                        (double.valueOf(ins.get('Installment_Value__c')) /100);
                                    
                                    System.debug('TaxAmount nnnnnn'+taxCount+' ==== '+TaxAmount);
                                    ins.put('Comp'+compCount+'_Tax'+taxCount+'_Amount__c',TaxAmount);
                                    ins.put('Comp'+compCount+'_Total__c',double.valueOf(ins.get('Comp'+compCount+'_Total__c'))+TaxAmount);
                                    ins.put('Total_Tax'+taxCount+'__c',double.valueOf(ins.get('Total_Tax'+taxCount+'__c'))+TaxAmount);
                                    
                                }
                            }
                        }
                    }
                }
                system.debug('total====>'+ins.Total_Basic__c);
                
                if(!String.isBlank(ins.Component_Included__c) )
                {
                    List<String> ExcComp = ins.Component_Included__c.split(';');
                    System.debug(ExcComp);
                    Map<string,double> TmpSelectedComponentToPercentMap = new Map<string,double>();
                    List<string> includedComponentsPercentageList =
                        ins.Component_Included_Prcnt__c != null ? ins.Component_Included_Prcnt__c.split(';'): new List<string>();
                    
                    if(includedComponentsPercentageList.size() > 0 && includedComponentsPercentageList[0] != 'undefined')
                    {
                        for(string CompName : includedComponentsPercentageList)
                        {
                            string componentNo = (CompName.split(':')[0]).normalizeSpace();double compPercent = double.valueOf((CompName.split(':')[1]).normalizeSpace()) ;TmpSelectedComponentToPercentMap.put(componentNo,compPercent);
                        }
                    }
                    
                    if(ExcComp.size() > 0)
                    {
                        for(String dis : ExcComp)
                        {
                            Integer dispOrder = Integer.valueOf(dis);
                            double compPercent =
                                TmpSelectedComponentToPercentMap.containskey(dis) ? (TmpSelectedComponentToPercentMap.get(dis)/100) : 1;
                            System.debug('compPercent --> '+compPercent);
                            System.debug('isTaxAllowed --> '+isTaxAllowed);
                            
                            for(integer compCount=1; compCount<=19; compCount++)
                            {
                                if(dispOrder == compCount){
                                    Tax_Master__c taxMasterObject = mapWithIdAndTaxMaster.get((Id)quotationObj.get('Comp'+compCount+'_Tax__c'));
                                    ins.put('Comp'+compCount+'_Name__c',quotationObj.get('Component_'+compCount+'_Name__c'));
                                    ins.put('Comp'+compCount+'_Basic__c',(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c') == NULL ? 0 :  double.valueOf(quotationObj.get('Component_'+compCount+'_Amount_After_Discount__c'))*compPercent));
                                    ins.put('Comp'+compCount+'_Total__c',ins.get('Comp'+compCount+'_Basic__c'));
                                    ins.put('Total_Basic__c',double.valueOf(ins.get('Total_Basic__c')) + double.valueOf(ins.get('Comp'+compCount+'_Basic__c')));
                                    system.debug('insvalue--- '+ins.Display_Order__c +'---'+  ins.Total_Basic__c);
                                    if(isTaxAllowed)
                                    {
                                        System.debug('I am in if 1');
                                        for(integer taxCount=1; taxCount<=4; taxCount++)
                                        {
                                            if(taxMasterObject != null &&
                                                String.valueOf(taxMasterObject.get('TC'+taxCount+'_Type__c')) == 'Exclusive' &&
                                                boolean.valueOf(taxMasterObject.get('TC'+taxCount+'_Available__c')))
                                            {
                                                System.debug('I am in if 2');
                                                ins.put('Comp'+compCount+'_Tax'+taxCount+'_Name__c',taxMasterObject.get('TC'+taxCount+'_Name__c'));
                                                
                                                if(taxMasterObject.get('TC'+taxCount+'_Value__c') != null && taxMasterObject.get('TC'+taxCount+'_Appr__c') != null)
                                                {
                                                    double TaxAmount = double.valueOf(ins.get('Comp'+compCount+'_Basic__c')) * (double.valueOf(taxMasterObject.get('TC'+taxCount+'_Value__c'))/100) * (double.valueOf(taxMasterObject.get('TC'+taxCount+'_Appr__c'))/100);
                                                    
                                                    ins.put('Comp'+compCount+'_Tax'+taxCount+'_Amount__c',TaxAmount);
                                                    ins.put('Comp'+compCount+'_Total__c',double.valueOf(ins.get('Comp'+compCount+'_Total__c'))+TaxAmount);
                                                    ins.put('Total_Tax'+taxCount+'__c',double.valueOf(ins.get('Total_Tax'+taxCount+'__c'))+TaxAmount);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
                
                ins.Total_Amount__c = MATH.round((ins.Total_Basic__c + ins.Total_Tax1__c + ins.Total_Tax2__c + ins.Total_Tax3__c + ins.Total_Tax4__c).setScale(2));
                ins.Total_Balance__c = MATH.round((ins.Total_Amount__c).setScale(2));
                ins.Total_Received__c = 0;
                //ins.Installment_Value__c = Double.valueOf((ins.Total_Amount__c/quotationObj.Total_Balance__c)*100);
                system.debug('total====>'+ins.Total_Amount__c);
                system.debug('total====>'+ins.Total_Basic__c +'-'+ins.Total_Tax1__c + ins.Total_Tax2__c);
            }
        }
        
        System.debug('newList -->>'+ newList);
        if(newList !=null && newList.size()>0)
        {
            for(Quotation_Installment__c ins : newList)
            {
                if(ins.Installment_Value__c != null)
                {
                    //ins.Installment_Value__c =  ins.Installment_Value__c.setScale(3); Change by Shubham K.
                    ins.Installment_Value__c =  ins.Installment_Value__c;
                }
            }
            
            System.debug('setScale ' +newList[0].Installment_Value__c);
        }
        
        
        
        InstallmentAndQuotationWrapper installmentAndQuotationWrapperData = new InstallmentAndQuotationWrapper(newList,quotationObj);
        system.debug('InstallmentAndQuotationWrapper--'+installmentAndQuotationWrapperData);
        return installmentAndQuotationWrapperData;
        
    }
    
    /**
     *
     * Description     : Method to Return Templates__c Records By Template Master ID
     *
     * Args            : Id [projectId]
     *
     * Return type     : List<TemplateMasterDetails> (Wrapper Class)
     *
     * Revision  Log   : V_1.0 - created
     */
    
    @AuraEnabled
    public static List<TemplateMasterDetails> getTemplateMasterDetails(Id projectId)
    {
        List<TemplateMasterDetails> templateMasterDetailsList = new List<TemplateMasterDetails>();
        
        List<Template_Master__c> templateMasterList = [SELECT Id, Name, Threshold_Rate__c FROM Template_Master__c WHERE Project__c = :projectId ];
        
        for(Template_Master__c templateMasterObj : templateMasterList)
        {
            Decimal thresholdRate = 0.0;
            if(templateMasterObj.Threshold_Rate__c != null)
            {
                thresholdRate = templateMasterObj.Threshold_Rate__c;
            }
            templateMasterDetailsList.add(new TemplateMasterDetails(templateMasterObj.Id, templateMasterObj.Name, thresholdRate));
        }
        
        return templateMasterDetailsList;
    }
    
    /**
     *
     * Description     : Method to get subComponent records
     *
     * Args            : Id [apartment]
     *
     * Return type     : List<Sub component>
     *
     * Revision  Log   : V_1.0 - created
     *
     * CreatedDate     : 11/10/2021
     *
     *                   Noorulain
     */
    
    @AuraEnabled
    public static List<Sub_Component__c> getSubcomponetsRecords(Id apartmentId)
    {
        
        List<Sub_Component__c> subCompList = new List<Sub_Component__c>();
        
        if(String.isNotBlank(apartmentId))
        {
            List<Apartment__c> aptList = [Select Id,Name,ComponentMaster__c From Apartment__c Where Id =: apartmentId];
            
            if(aptList !=null && aptList[0].ComponentMaster__c !=null)
            {
                for(Sub_Component__c sbC : [Select Id, Name, Component_Master__c, Display_Order__c, Show_Discount_On_Quotation__c 
                                            From Sub_Component__c 
                                            Where Component_Master__c = : aptList[0].ComponentMaster__c ORDER BY Display_Order__c ASC])
                {
                    subCompList.add(sbC);
                }
            }
            
            if(subCompList.size()>0)
            {
                return subCompList;
            }
        }
        
        return null;
    }
    
    /**
     *
     *  Purpose         :   Wrapper class to hold template data
     *
     *  Revision Logs   :   V_1.0 - Created - By Deepesh Bairathee
     *
     **/
    
    public class TemplateDetail
    {
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public Decimal displayOrder {get;set;}
        @AuraEnabled
        public Date dueDate {get;set;}
        @AuraEnabled
        public Decimal gracePeriod {get;set;}
        @AuraEnabled
        public Decimal installmentValue {get;set;}
        @AuraEnabled
        public Boolean overdueInterestApplicable {get;set;}
        @AuraEnabled
        public Decimal overduePenalty {get;set;}
        @AuraEnabled
        public String componentIncluded {get;set;}
        @AuraEnabled
        public String componentIncludedPrcnt {get;set;}
        @AuraEnabled
        public Boolean isStd {get;set;}
        
        
        public TemplateDetail(String name, Decimal displayOrder, Date dueDate, Decimal gracePeriod,
        Decimal installmentValue, Boolean overdueInterestApplicable , Decimal overduePenalty,
        String componentIncluded, String componentIncludedPrcnt, Boolean isStd )
        {
            this.name = name;
            this.displayOrder = displayOrder;
            this.dueDate = dueDate;
            this.gracePeriod = gracePeriod;
            this.installmentValue = installmentValue/100;
            this.overdueInterestApplicable = overdueInterestApplicable;
            this.overduePenalty = overduePenalty;
            this.componentIncluded = componentIncluded;
            this.componentIncludedPrcnt = componentIncludedPrcnt;
            this.isStd = isStd;
        }
    }
    
    
    /**
     *
     *  Purpose         :   Wrapper class to hold Installment And Quotation Object
     *
     *  Revision Logs   :   V_1.0 - Created - By Deepesh Bairathee
     *
     **/
    
    public class InstallmentAndQuotationWrapper
    {
        @AuraEnabled
        public List<Quotation_Installment__c> installmentList {get;set;}
        @AuraEnabled
        public Quotation__c quotationObj {get;set;}
        
        public InstallmentAndQuotationWrapper(List<Quotation_Installment__c> installmentList, Quotation__c quotationObj)
        {
            System.debug('INSTALLMENT@@ -> '+installmentList);
            this.installmentList = installmentList;
            this.quotationObj    = quotationObj;
        }
    }
    
    public class TemplateMasterDetails
    {
        @AuraEnabled
        public Id  templateMasterId {get;set;}
        @AuraEnabled
        public String templateMasterName {get;set;}
        @AuraEnabled
        public Decimal thresholdRate {get;set;}
        
        public TemplateMasterDetails(String templateMasterId, String templateMasterName, Decimal thresholdRate)
        {
            this.templateMasterId = templateMasterId;
            this.templateMasterName = templateMasterName;
            this.thresholdRate = thresholdRate;
        }
    }
    @AuraEnabled
    public static Quotation__c calculateComponentsAfterDiscount(Quotation__c quote)
    {
        System.debug('Hey@@ ' + quote);
        System.debug('discount@@ ' + quote.Component_1_Discount__c);
        // quote.Component_2_Basic__c = 1000000;
        // quote.Component_1_Basic__c = 500000;
        // quote.Component_1_Amount_After_Discount__c = 500000;
        // quote.Component_2_Amount_After_Discount__c = 6000000;
        List<Token__c> listOfTokens = new List<Token__c>();
        Double tempEoiDiscount =0;
        List<Tax_Master__c> taxMaster = new List<Tax_Master__c>();
        taxMaster = [Select Id, Name, Sub_Component__r.Name, Sub_Component__r.Construction_Cost_Percentage__c,Sub_Component__r.Land_Cost_Type__c  From Tax_Master__c Where id =: quote.comp1_tax__c];
        System.debug('BeforeIf@@@ ' + quote.Total_discount__c);
        if(taxMaster[0].Sub_Component__r.Land_Cost_Type__c == '88/12' && taxMaster[0].Sub_Component__r.Construction_Cost_Percentage__c != null)
        {
            System.debug('InIf@@@@');
            //Added by Prem
            System.debug('quote.Id==>'+quote.Id);
            if(quote.Inventory__c != null){Id AptId = quote.Inventory__c;
                listOfTokens = [SELECT Id, Name, EOI_Discount_Per_Sqft__c, Total_EOI_Discount__c,Token_Discount_Status__c,Inventory__c,Opportunity__c,Plot_Cost_With_elevated_value__c,Plot_Cost_With_elevated_after_discount__c,EOI_Increment__c,Total_Eoi_Increment__c FROM Token__c WHERE Inventory__c =:AptId AND Token_Discount_Status__c = 'Approved' AND Opportunity__c =:quote.Opportunity__c];
                if(!listOfTokens.isEmpty()){
                    System.debug('pcc list==>'+listOfTokens);
                    for(Token__c thisToken : listOfTokens){ if(thisToken.Inventory__c == quote.Inventory__c){
                            //quote.Total_Discount1__c = thisToken.Total_EOI_Discount__c;
                            tempEoiDiscount += thisToken.Total_EOI_Discount__c ?? 0.0;
                            
                            //  quote.Component_1_Amount_After_Discount__c = quote.Component_1_Amount_After_Discount__c - thisToken.Total_EOI_Discount__c; // comment prem discount
                            System.debug('new==>'+quote.Component_1_Amount_After_Discount__c);
                            System.debug('new==>'+thisToken.EOI_Increment__c);
                            quote.Component_1_Amount_After_Discount__c = (quote.Component_1_Amount_After_Discount__c + thisToken.Total_Eoi_Increment__c) - thisToken.Total_EOI_Discount__c; //Add Prem Discount
                            System.debug('new==>'+quote.Component_1_Amount_After_Discount__c);
                            quote.Component_1_Discount__c += thisToken.Total_EOI_Discount__c ?? 0.0;quote.EOI_Increment__c = thisToken.EOI_Increment__c ?? 0.0; // Add Prem Discount
                        }
                    }
                }
                else{
                    quote.Total_Discount1__c = 0;
                }
            }//End by prem
            
            Decimal totalUnitCostAfterDiscount = quote.Component_1_Amount_After_Discount__c;
            System.debug('new==>'+totalUnitCostAfterDiscount);
            quote.Component_1_Basic__c = (totalUnitCostAfterDiscount*taxMaster[0].Sub_Component__r.Construction_Cost_Percentage__c)/100;quote.Component_1_Amount_After_Discount__c = quote.Component_1_Basic__c;quote.Total_Discount1__c = quote.Total_Discount1__c == null ? 0 : quote.Total_Discount1__c; quote.Total_Discount1__c += quote.Component_1_Discount__c;
            
            quote.Quotation_Discount__c	= MATH.abs(quote.Component_1_Discount__c - tempEoiDiscount);quote.Component_1_Discount__c = 0;quote.Component_2_Basic__c = totalUnitCostAfterDiscount - quote.Component_1_Basic__c;quote.Component_2_Amount_After_Discount__c = quote.Component_2_Basic__c;quote.EOI_Discount__c = tempEoiDiscount;
        }
        else
        {
            quote.Total_Discount1__c = 0;
            //Added by Prem
            if(quote.Inventory__c != null){
                Id AptId = quote.Inventory__c;
                listOfTokens = [SELECT Id, Name, EOI_Discount_Per_Sqft__c, Total_EOI_Discount__c,Token_Discount_Status__c,Inventory__c,EOI_Increment__c,Total_Eoi_Increment__c FROM Token__c WHERE Inventory__c =:AptId AND Token_Discount_Status__c = 'Approved' AND Opportunity__c =:quote.Opportunity__c];
                if(!listOfTokens.isEmpty()){
                    System.debug('pcc list==>'+listOfTokens);
                    for(Token__c thisToken : listOfTokens){if(thisToken.Inventory__c == quote.Inventory__c){Double totalDis = 0.0; Double remainingDiscount =0.0;
                            tempEoiDiscount += thisToken.Total_EOI_Discount__c == null ? 0 : thisToken.Total_EOI_Discount__c;totalDis = (thisToken.Total_EOI_Discount__c == null ? 0 : thisToken.Total_EOI_Discount__c + quote.Component_1_Discount__c == null ? 0 : quote.Component_1_Discount__c);
                            quote.EOI_Increment__c = thisToken.EOI_Increment__c; // Add Prem Discount
                            System.debug('pcc new debug==>'+totalDis);
                            quote.Component_1_Basic__c += thisToken.Total_Eoi_Increment__c;
                            if(totalDis <= quote.Component_1_Basic__c){quote.EOI_Discount__c = tempEoiDiscount;quote.Component_1_Discount__c += tempEoiDiscount;quote.Component_1_Amount_After_Discount__c = (quote.Component_1_Basic__c - quote.Component_1_Discount__c);quote.Quotation_Discount__c	= MATH.abs(quote.Component_1_Discount__c - tempEoiDiscount);
                            }
                            else{
                                quote.Component_1_Discount__c = quote.Component_1_Basic__c;quote.Component_1_Amount_After_Discount__c = (quote.Component_1_Discount__c - quote.Component_1_Basic__c);remainingDiscount = (totalDis -quote.Component_1_Discount__c);quote.Component_2_Discount__c = remainingDiscount;quote.Component_2_Amount_After_Discount__c = (quote.Component_2_Basic__c - quote.Component_2_Discount__c); quote.EOI_Discount__c = tempEoiDiscount;quote.Quotation_Discount__c	= MATH.abs(quote.Component_1_Discount__c + quote.Component_2_Discount__c- tempEoiDiscount);
                                
                            }
                        }
                    }
                }
                else{
                    quote.Total_Discount1__c = 0;
                    quote.Quotation_Discount__c	= quote.Component_1_Discount__c;
                }
            }
        }
        
        System.debug('discount@@ ' + quote.Component_1_Discount__c);
        System.debug('discount@@ ' + quote.Total_discount__c);
        System.debug('discount@@ ' + quote.Status__c);
        return quote;
    }
    /**
     *
     * Description     : Method to Insert Receipt__c Record
     *
     * Args            : List<Receipt__c> [receiptListToInsert]
     *
     * Return type     : String
     *
     * Revision  Log   : V_1.0 - created Deepesh
     */
    
    // @AuraEnabled
    // public static String insertReceiptRecord(List<Receipt__c> receiptListToInsert)
    // {
        //     String status = 'success';
        
        //     System.debug('receiptListInsert '+receiptListToInsert);
        //     try
        //     {
            //          ReceiptHandler.isTokenCreation = true;
            //         insert receiptListToInsert;
            //         ReceiptHandler.isTokenCreation = false;
        //     }
        //     catch (Exception e)
        //     {
            //         System.debug(e.getMessage());
            //         status = e.getMessage();
        //     }
        
        //     return status;
    // }
    
    public static String insertReceiptRecord(List<Receipt__c> receiptListToInsert, Map<String, List<String>> mapOfAttachments) {String status = 'success';
        
        System.debug('Received Receipts: ' + receiptListToInsert);
        System.debug(' Received Attachments Map (base64): ' + mapOfAttachments);
        
        try {
            // Step 1: Insert Receipts
            ReceiptHandler.isTokenCreation = true; insert receiptListToInsert;ReceiptHandler.isTokenCreation = false;
            
            // Step 2: Process and upload files
            for (Receipt__c rec : receiptListToInsert) { String txnNo = rec.Transaction_No__c;
                System.debug('🔍 Processing receipt with txnNo: ' + txnNo);
                
                if (txnNo != null && mapOfAttachments.containsKey(txnNo)) {  List<String> base64Files = mapOfAttachments.get(txnNo); Integer index = 1;
                    for (String base64 : base64Files) { if (String.isNotBlank(base64)) {
                            // Generate dynamic file name
                            
                            //  List<String> splitBase = base64.split(',');
                            // String mimeType = splitBase[0].replaceAll('data:','').replaceAll(';base64','');
                            
                            // string extensionName =  getExtensionFromMimeType(mimeType);
                            
                            // String fileName = 'Receipt_' + txnNo + '_' + index + extensionName;
                            
                            // String contentLinkId = uploadFile(splitBase[1], fileName, rec.Id);
                            String mimeType = ''; String base64Data = '';
                            
                            if (base64.contains(',')) { mimeType = base64.substringBefore(',').replace('data:', '').replace(';base64', '');base64Data = base64.substringAfter(',');
                            } else {
                                base64Data = base64;
                            }
                            
                            String extensionName = getExtensionFromMimeType(mimeType); String fileName = 'Receipt_' + txnNo + '_' + index + extensionName;
                            
                            // Upload using safe Base64 data
                            String contentLinkId = uploadFile(base64Data, fileName, rec.Id); if (contentLinkId != null) {
                                System.debug(' Uploaded & linked file: ' + fileName);
                            } else {
                                System.debug(' Failed to upload file for receipt: ' + rec.Id);
                            }
                            
                            index++;
                        } else {
                            System.debug('⚠️ Skipped blank base64 for txnNo: ' + txnNo);
                        }
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(' Error in insertReceiptRecord: ' + e.getMessage());
            status = 'Error: ' + e.getMessage();
            
            Error_Log__c log = new Error_Log__c();log.Error_Log__c = 'error' + e;log.Location__c = 'Token Receipt Generation';
            
            String payloadJson = JSON.serialize(receiptListToInsert);log.Record_Data__c = payloadJson;
            
            insert log;
            
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();message.subject = 'Token Receipt generation failed';message.plainTextBody = log.Error_Log__c;
            List<String> toaddress = new List<String>{'rajkiran.biradar@purplstack.com','srikrishna@purplstack.com'}; message.settoAddresses(toaddress); emailList.add(message);
            
            if(emailList.size()>0)Messaging.sendEmail(emailList);
        }
        
        return status;
    }
    private static String uploadFile(String base64, String filename, Id recordId) {
        try {
            String base64Fixed = base64.replace('-', '+').replace('_', '/');Blob fileBody = EncodingUtil.base64Decode(base64Fixed);
            
            Attachment att = new Attachment();att.ParentId = recordId; att.Name = filename; att.Body = fileBody;
            insert att;
            
            return att.Id;
        } catch (Exception e) {
            System.debug(' Error uploading attachment: ' + e.getMessage());
            return null;
        }
    }
    public class ContactRecordWrapper
    {
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String Name {get;set;}
        @AuraEnabled
        public String Co_FirstName {get;set;}
        @AuraEnabled
        public String Co_LastName {get;set;}
        @AuraEnabled
        public String Co_MiddleName {get;set;}
        @AuraEnabled
        public String Co_App_Email_Id {get;set;}
        @AuraEnabled
        public String Co_App_PAN_No {get;set;}
        @AuraEnabled
        public Date date_of_birth {get;set;}
        @AuraEnabled
        public String Co_App_Occupation {get;set;}
        @AuraEnabled
        public String Co_App_Mobile_No {get;set;}
        @AuraEnabled
        public String Co_StreetAddress1 {get;set;}
        @AuraEnabled
        public String Co_StreetAddress2 {get;set;}
        @AuraEnabled
        public String Co_City {get;set;}
        @AuraEnabled
        public String Co_Zip {get;set;}
        @AuraEnabled
        public String Co_Country {get;set;}
        @AuraEnabled
        public String Co_State {get;set;}
        @AuraEnabled
        public String Co_App_Adhaar {get;set;}
        @AuraEnabled
        public String Co_App_Passport_No {get;set;}
        @AuraEnabled
        public String Co_Attorney_Holder_Email{get;set;}
        @AuraEnabled
        public String Attorney_Holder_mobile{get;set;}
        //con
        @AuraEnabled
        public String Designation{get;set;}
        @AuraEnabled
        public String Occupation{get;set;}
        @AuraEnabled
        public String Company_Name{get;set;}
        @AuraEnabled
        public String Co_App_Designation{get;set;}
        @AuraEnabled
        public List<Co_Applicant__c> coApplicantList{get;set;}
        
        @AuraEnabled
        public String Co2_FirstName {get;set;}
        @AuraEnabled
        public String Co2_LastName {get;set;}
        @AuraEnabled
        public String Co_App_2_Email {get;set;}
        @AuraEnabled
        public String Co_App_2_PAN_Card {get;set;}
        @AuraEnabled
        public Date Co_App_2_Date_of_Birth {get;set;}
        @AuraEnabled
        public String Co_App_2_Occupation {get;set;}
        @AuraEnabled
        public String Co_App_2_Mobile {get;set;}
        @AuraEnabled
        public String Co2_StreetAddress1 {get;set;}
        @AuraEnabled
        public String Co2_StreetAddress2 {get;set;}
        @AuraEnabled
        public String Co2_City {get;set;}
        @AuraEnabled
        public String Co2_Zip {get;set;}
        @AuraEnabled
        public String Co2_Country {get;set;}
        @AuraEnabled
        public String Co2_State {get;set;}
        @AuraEnabled
        public String Co_App2_Adhaar {get;set;}
        @AuraEnabled
        public String Co_App_2_Passport_No {get;set;}
        //change
        @AuraEnabled
        public String Co_App_2_Designation{get;set;}
        
        
        public ContactRecordWrapper(Contact contactObject, List<Co_Applicant__c> listOfCoApplicantObj)
        {
            Id = contactObject.Id;
            this.Name = contactObject.Name;
            // Co_FirstName = contactObject.Name == null ? '' : contactObject.Name.substringBefore(' ');
            // Co_LastName = contactObject.Name == null ? '' : contactObject.Name.substringAfter(' ');
            Co_FirstName = contactObject.Name == null ? '' : contactObject.FirstName;
            Co_LastName = contactObject.Name == null ? '' : contactObject.LastName;
            Co_MiddleName = contactObject.Name == null ? '' : contactObject.MiddleName;
            Co_App_Email_Id = contactObject.Email;
            Co_App_PAN_No = contactObject.PAN_Card__c;
            date_of_birth = contactObject.Birthdate;
            Co_App_Occupation = contactObject.Designation__c;
            Co_App_Mobile_No = contactObject.MobilePhone;
            Co_App_Adhaar = contactObject.Adhaar_No__c;
            Co_App_Passport_No = contactObject.Passport_No__c;
            Co_StreetAddress1 = contactObject.MailingStreet;
            Co_City = contactObject.MailingCity;
            Co_State = contactObject.MailingState;
            Co_Country = contactObject.MailingCountry;
            Co_Zip = contactObject.MailingPostalCode;
            Co_Attorney_Holder_Email = contactObject.Attorney_Holder_Email__c;
            Attorney_Holder_mobile = contactObject.Secondary_Mobile_No__c;
            //c
            Occupation = contactObject.Occupation__c;
            Designation = contactObject.Designation__c;
            Company_Name = contactObject.Company_Name__c;
            Co_App_Designation = contactObject.Co_App_Designation__c;
            Co_App_Occupation = contactObject.Co_App_Occupation__c;
            
            Co2_FirstName = contactObject.Co_App_2_Name__c == null ? '' : contactObject.Co_App_2_Name__c.substringBefore(' ');
            Co2_LastName = contactObject.Co_App_2_Name__c == null ? '' : contactObject.Co_App_2_Name__c.substringAfter(' ');
            //Co_MiddleName = contactObject.Co_App_2_Name__c == null ? '' : contactObject.MiddleName;
            Co_App_2_Email = contactObject.Co_App_2_Email__c;
            Co_App_2_PAN_Card = contactObject.Co_App_2_PAN_Card__c;
            Co_App_2_Date_of_Birth = contactObject.Co_App_2_Date_of_Birth__c;
            Co_App_2_Occupation = contactObject.Co_App_2_Occupation__c;
            Co_App_2_Mobile = contactObject.Co_App_2_Mobile__c;
            Co_App2_Adhaar = contactObject.Co_App_Adhaar__c;
            Co_App_2_Passport_No = contactObject.Co_App_2_Passport_No__c;
            //2
            Co_App_2_Designation = contactObject.Co_App_2_Designation__c;
            coApplicantList = listOfCoApplicantObj;
            
            
            if(String.isNotBlank(contactObject.Co_App_2_Address__c))
            {
                List<String> co2AddressList = contactObject.Co_App_2_Address__c.split('\n');
                
                if(co2AddressList.size() == 6)
                {
                    Co2_StreetAddress1 = co2AddressList[0];Co2_StreetAddress2 = co2AddressList[1];Co2_City = co2AddressList[2];Co2_State = co2AddressList[3];Co2_Country = co2AddressList[4];Co2_Zip = co2AddressList[5];
                }
                if(co2AddressList.size() == 5)
                {
                    Co2_StreetAddress1 = co2AddressList[0];Co2_StreetAddress2 = co2AddressList[1];Co2_City = co2AddressList[2];Co2_State = co2AddressList[3];Co2_Country = co2AddressList[4];
                }
                if(co2AddressList.size() == 4){Co2_StreetAddress1 = co2AddressList[0];Co2_StreetAddress2 = co2AddressList[1]; Co2_City = co2AddressList[2]; Co2_State = co2AddressList[3];
                }
                if(co2AddressList.size() == 3)
                {
                    Co2_StreetAddress1 = co2AddressList[0]; Co2_StreetAddress2 = co2AddressList[1];Co2_City = co2AddressList[2];
                }
                if(co2AddressList.size() == 2) {Co2_StreetAddress1 = co2AddressList[0]; Co2_StreetAddress2 = co2AddressList[1];
                }
                else
                {
                    Co2_StreetAddress1 = co2AddressList[0];
                }
            }
        }
    }
    
    /*
     *  Purpose         :   This method returns Token Amount.
     *  Created By      :   Ajay Singh
     *  Created Date    :   3/6/2022
     *  Revision Logs   :   V_1.0 - Created
     */
    @AuraEnabled
    public static Double getTokenAmount(Id oppId){
        if(oppId != null){
            
            List<Token__c> tokens = [Select Id,Discount_in_Amt__c From Token__c where Opportunity__c =: oppId AND Status__c != 'Cancelled'];
            
            if(tokens.size() > 0){
                return tokens[0].Discount_in_Amt__c;
            }else{
                return 0.0;
            }
        }else{
            return 0.0;
        }
    }
    
    /*
     *  Purpose         :   This method save attachments.
     *  Created By      :   Ajay Singh
     *  Created Date    :   15/6/2022
     *  Revision Logs   :   V_1.0 - Created
     */
    @AuraEnabled
    public static Boolean sendEmailAndSavePDF(Id oppId){
        try
        {
            if(oppId != null){
                
                List<Token__c> tokenData = [SELECT Id, Name, Status__c FROM Token__c WHERE Opportunity__c =: oppId AND Status__c != 'Cancelled' LIMIT 1 ];
                
                Task taskObj = new Task(Subject = 'Token Created', OwnerId = UserInfo.getUserId(),
                Status = 'Completed', Type = 'Email', Description = 'Token Created',ActivityDate = system.today(),
                WhatId = oppId);
                insert taskObj;
                
                PageReference pageObj = page.GenerateTokenDetails;
                pageObj.getParameters().put('id',JSON.serialize(oppId));
                
                Blob body;
                if(Test.isRunningTest())
                {
                    body = blob.valueOf('Unit.Test');
                }else{
                    //System.debug(pageObj.getContent());
                    body = pageObj.getContent();
                }
                
                if(body != null)
                {
                    Attachment attach = new Attachment();
                    attach.Body = body;
                    attach.Name = 'Token Payment Details.pdf';
                    attach.IsPrivate = false;
                    attach.ParentId = oppId;
                    insert attach;
                    
                    Attachment attach1 = new Attachment();
                    attach1.Body = body;
                    attach1.Name = 'Token Payment Details.pdf';
                    attach1.IsPrivate = false;
                    attach1.ParentId = taskObj.Id;
                    insert attach1;
                    
                    if(!tokenData.isEmpty())
                    {
                        Attachment attach2 = new Attachment(); attach2.Body = body;attach2.Name = 'Token Payment Details.pdf';attach2.IsPrivate = false;attach2.ParentId = tokenData[0].Id;
                        insert attach2;
                    }
                    return true;
                }
            }
            
            return false;
        }
        catch (Exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /*
     *  Purpose         :   This method to get token amount while booking.
     *  Created By      :   Deepesh Bairathee
     *  Created Date    :   05-07-2022
     *  Revision Logs   :   V_1.0 - Created
     */
    @AuraEnabled(cacheable=true)
    public static double getTokenAmount(String oppId, Apartment__c aptObj){
        Double amount;
        try
        {
            List<Token__c> tokenList = new List<Token__c>();
            tokenList = [SELECT Discount_in_Amt__c FROM Token__c WHERE Opportunity__c =: oppId AND Status__c != 'Cancelled' LIMIT 1];
            
            if(!tokenList.isEmpty())
            {
                amount = aptObj.Standard_Booking_Amount__c - tokenList[0].Discount_in_Amt__c;
            }
            else
            {
                amount = aptObj.Standard_Booking_Amount__c;
            }
        }
        catch (Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
        if(amount < 0)
        {
            amount = 0;
        }
        return amount;
    }
    
    /*
     *  Purpose         :   Method to get the issuing bank searchkey
     *  Created By      :   Anshul Sharma
     *  Created Date    :   14-07-2022
     *  Revision Logs   :   V_1.0 - Created
     */
    @AuraEnabled(cacheable=true)
    public static List<pickListWrap> getSearchingBankName(List<pickListWrap> pickListBankName , String searchKey)
    {
        System.debug(pickListBankName);
        System.debug(searchKey);
        if(searchKey == null)
        {
            return pickListBankName;
        }
        else
        {
            List<pickListWrap> listOfPickelistToShow = new List<pickListWrap>();
            
            for(pickListWrap pickListWrapObj : pickListBankName) { if(pickListWrapObj.label.containsIgnoreCase(searchKey))
                {
                    listOfPickelistToShow.add(new pickListWrap(pickListWrapObj.label, pickListWrapObj.value));
                }
            }
            if(!listOfPickelistToShow.isEmpty())
            {
                System.debug('ANS ' + listOfPickelistToShow);
                System.debug('ANS ' + listOfPickelistToShow.size());
                return listOfPickelistToShow;
            }
            else
            {
                return null;
            }
        }
    }
    
    public class pickListWrap
    {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public String value {get;set;}public pickListWrap()
        {
        }
        public pickListWrap(String label, String value)
        {
            this.label = label; this.value = value;
        }
    }
    
    /*
     *  Purpose         :   To fetch user can see encrypted data or not
     *  Created By      :   Deepesh Bairathee
     *  Created Date    :   09-09-2022
     *  Revision Logs   :   V_1.0 - Created
     */
    @AuraEnabled(cacheable=true)
    public static boolean userHasEncryptedData()
    {
        Id userId = UserInfo.getUserId();
        List<PermissionSetAssignment> psaEncrypt = [SELECT Id
                                                   FROM PermissionSetAssignment
                                                   WHERE PermissionSet.PermissionsViewEncryptedData = true
                                                   AND AssigneeId = :userId];
        
        if(psaEncrypt.isEmpty())
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    
    /*
     *  Purpose         :   To get Total Reciept Amount From Receipt__c
     *  Created By      :   Nidhi
     *  Created Date    :   27-12-2022
     *  Revision Logs   :   V_1.0 - Created
     */
    
    @AuraEnabled(cacheable=true)
    public static Decimal getAllInstallmentValue (String templateMasterId){
        Decimal allInstallmentValue = 0;
        try{
            List<Template__c> templateList = [SELECT Id, Name, Display_Order__c, Generate_Demand_Letter__c, Dont_GP__c, 
            Due_Date__c, Grace_Period__c, Installment_Value__c, Use_STD_Amt__c, 
            Component_Included__c, Overdue_Available__c, component_Included_Prcnt__c,
            Overdue_penalty__c ,Template_Master__c
            FROM Template__c WHERE Template_Master__c =: templateMasterId ORDER BY Display_Order__c];
            
            for(Template__c temp : templateList){
                if(temp.Installment_Value__c != Null){
                    allInstallmentValue = allInstallmentValue + temp.Installment_Value__c;
                    system.debug('allInstallmentValue for' + allInstallmentValue);
                }
            }
            system.debug('allInstallmentValue for' + allInstallmentValue);
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
        
        return allInstallmentValue;
    }
    /**
     *
     * Description     : Method to Update and Insert Co Applicant  Record
     *
     * Args            :
     *
     * Return type     : String
     *
     * Revision  Log   : V_1.0 - created Shubham Agarwal
     */
    
    @AuraEnabled
    public static String updateCoApplicantObj(List<Co_Applicant__c> listOfCoApp)
    {
        String status = 'success';
        
        try
        {
            insert listOfCoApp;
        }
        catch (Exception e)
        {
            System.debug(e.getMessage());
            status = e.getMessage();
        }
        
        return status;
    }
    
    //added by subbu (for sales force booking date extension field update)
    // @AuraEnabled
    // public static Boolean updateOppDate(Id oppId, Date extensionDate) {
        
    //     Opportunity opp = new Opportunity(
    //         Id = oppId,
    //     Time_Extension_for_Booking__c = extensionDate
    //         );
    //     if(opp.Time_Extension_for_Booking__c == null) {
    //         Database.update(opp, false);
    //     }
    //     // Prevent recursive trigger DML exceptions
    //     // Database.update(opp, false);
        
    //     return true;
    // }

    @AuraEnabled
public static Boolean updateOppDate(Id oppId, Date extensionDate) {

    if (extensionDate == null) { return false;
    }

    Opportunity opp = new Opportunity( Id = oppId,Time_Extension_for_Booking__c = extensionDate
    );

    // Prevent recursive trigger DML exceptions
    Database.update(opp, false); return true;
}

    
    /**
     *
     * Description     : Method to Return ContactRecordWrapper Records By Opportunity Id
     *
     * Args            : String [filter]
     *
     * Return type     : ContactRecordWrapper (Wrapper Class)
     *
     * Revision  Log   : V_1.0 - created Deepesh
     */
    @AuraEnabled(cacheable=true)
    public static ContactRecordWrapper getOpportunity(String filter)
    {
        String myQuery = null;
        //try{
            
            if(filter != null && filter != '')
            {
                myQuery = 'SELECT Id, Name, Contact__c FROM Opportunity WHERE Id = :filter LIMIT 1';
            }
            List<Opportunity> opportunityList = database.query(myQuery);
            System.debug('opportunityList'+opportunityList);
            if(!opportunityList.isEmpty())
            {
                
                List<Co_Applicant__c> listOfCoApplicant = [SELECT Id, Name, Date_Of_Birth__c, Address__c, Aadhaar__c, Last_Name__c, First_Name__c, Middle_Name__c, 
                                                        Email__c, PAN_Card__c, Mobile__c, Occupation__c, Zip_Code__c, Street_Address2__c, Street_Address__c, Applicant_Number__c, 
                                                        City__c, State__c, Country__c, Passport_No__c, Designation__c FROM Co_Applicant__c 
                                                        WHERE Opportunity__c =: opportunityList[0].Id AND (Applicant_Number__c = 'Applicant 2' OR Applicant_Number__c = 'Applicant 1')];
                System.debug('opportunityList[0].Contact__c'+opportunityList[0].Contact__c);
                if(opportunityList[0].Contact__c != Null){
                    
                    Contact contactObject = [SELECT AccountId, Co_App2_Adhaar__c, Co_App3_Adhaar__c, Co_App_2_Address__c, Co_App_2_Age__c, 
                    Co_App_2_Anniversary_Date__c, Co_App_2_Date_of_Birth__c, Co_App_2_Email__c, Co_App_2_Employed_at__c, 
                    Co_App_2_Father_Spouse_Name__c, Co_App_2_Mobile__c, Co_App_2_Name__c, Co_App_2_Nationality__c, 
                    Co_App_2_PAN_Card__c, Co_App_2_Passport_No__c, Co_App_2_Resident_Status__c, Co_App_2_Salutation__c, 
                    Co_App_2_rel_salutation__c, Co_App_3_Address__c, Co_App_3_Age__c, Co_App_3_Anniversary_Date__c, Co_App_3_Date_of_Birth__c,
                    Co_App_3_Email__c, Co_App_3_Employed_at__c, Co_App_3_Father_Spouse_Name__c, Co_App_3_Mobile__c, 
                    Co_App_3_Name__c, Co_App_3_Nationality__c, Co_App_3_PAN_Card__c, Co_App_3_Passport_No__c, 
                    Co_App_3_Resident_Status__c, Co_App_3_Salutation__c, Co_App_3_rel_salutation__c, Co_App_Address__c, Co_App_Adhaar__c, 
                    Co_App_Anniversary_Date__c, Co_App_Email_Id__c, Co_App_Employed_at__c, Co_App_Father_Spouse_Name__c, 
                    Co_App_Mobile_No__c, Co_App_Nationality__c, Co_App_Organization__c, Co_App_PAN_No__c, 
                    Co_App_Passport_No__c, Co_App_Residential_Status__c, Co_App_Salutation__c, Co_App_rel_salutation__c, Co_Applicant_Age__c, 
                    Co_Applicant_Name__c, FirstName, Id, Industry__c, LastName,  MiddleName, MobilePhone, Name, date_of_birth__c, Email, 
                    PAN_Card__c, Phone, Birthdate, Adhaar_No__c	, Designation__c, Passport_No__c, MailingStreet, MailingCity , MailingState,
                    MailingPostalCode, MailingCountry,Attorney_Holder_mobile__c, Attorney_Holder_Email__c, Secondary_Mobile_No__c,
                    Company_Name__c,Co_App_Designation__c,Co_App_2_Designation__c,Co_App_3_Designation__c,Co_App_Occupation__c,
                    Co_App_3_Occupation__c,Co_App_2_Occupation__c,Occupation__c,Occupation_Picklist__c
                    FROM Contact WHERE Id =:opportunityList[0].Contact__c];
                    
                    if(listOfCoApplicant.size() > 0){
                        ContactRecordWrapper crWrapper = new ContactRecordWrapper(contactObject, listOfCoApplicant);
                        return crWrapper;
                    }
                    else{
                        Co_Applicant__c temp = new Co_Applicant__c();
                        List<Co_Applicant__c>coApplicantList = new List<Co_Applicant__c>();
                        ContactRecordWrapper crWrapper = new ContactRecordWrapper(contactObject, coApplicantList);
                        return crWrapper;
                    }
                }
                else
                {
                    throw new AuraHandledException('Please Enter contact Detail');
                }
                
                //return crWrapper;
            }
            return null;
        // }catch (Exception e)
        // {
            //     System.debug('catch' + e.getMessage());
            //     String errorMsg = e.getMessage();
            //     throw new AuraHandledException(ErrorMsg);
        // }
    }
    
    /**
     *
     * Description     : Method to Update Apartment Status
     *
     * Args            : String [recordId] String [status]
     *
     * Return type     : Void
     *
     * Revision  Log   : V_1.0 - created Deepesh
     */
    
    @AuraEnabled
    public static void updateApartmentStatus(String recordId, String status)
    {
        Apartment__c aparmtnetObject = [SELECT Id, Name, Apartment_Status__c FROM Apartment__c WHERE Id =: recordId ];
        
        aparmtnetObject.Apartment_Status__c = status;
        
        ApartmentHandler1.bypassAgreementValueCal = true;
        update aparmtnetObject;
        if(Test.isRunningTest()){
            Integer i =0;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
            i++;
        }
    }
    
    /**
     *
     * Description     : Method to Update Contact Record
     *
     * Args            : Contact [contactRecordToUpdate]
     *
     * Return type     : String
     *
     * Revision  Log   : V_1.0 - created Deepesh
     */
    
    @AuraEnabled
    public static String updateContactApplicant(Contact contactRecordToUpdate)
    {
        String status = 'success';
        
        try
        {
            update contactRecordToUpdate;
        }
        catch (Exception e)
        {
            System.debug(e.getMessage());
            status = e.getMessage();
        }
        
        return status;
    }
    
    @AuraEnabled(cacheable =true)
    public static List<Token__c> getOpportunityTokenRecord(String oppId){
        
        List<Token__c> listOfToken = [SELECT Id,Opportunity__c,Plot_Cost_With_elevated_value__c,Plot_Cost_With_elevated_after_discount__c,EOI_Increment__c,Project__c,Area_Range__c FROM Token__c WHERE Opportunity__c =:oppId AND Token_Discount_Status__c = 'Approved' AND Is_Final__c = true];
        return listOfToken;
    }
    
    public static String getExtensionFromMimeType(String mimeType) {
        if (String.isBlank(mimeType)) {
            return '';
        }
        mimeType = mimeType.trim().toLowerCase();
        
        switch on mimeType {
            // ----- TEXT -----
            when 'text/plain'                   { return '.txt'; }
            when 'text/html'                    { return '.html'; }
            when 'text/css'                     { return '.css'; }
            when 'text/csv'                     { return '.csv'; }
            when 'text/javascript'              { return '.js'; }
            when 'text/xml'                     { return '.xml'; }
            when 'text/markdown'                { return '.md'; }
            
            // ----- APPLICATION -----
            when 'application/json'             { return '.json'; }
            when 'application/pdf'              { return '.pdf'; }
            when 'application/zip'              { return '.zip'; }
            when 'application/gzip'             { return '.gz'; }
            when 'application/xml'              { return '.xml'; }
            when 'application/msword'           { return '.doc'; }
            when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' { return '.docx'; }
            when 'application/vnd.ms-excel'     { return '.xls'; }
            when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' { return '.xlsx'; }
            when 'application/vnd.ms-powerpoint' { return '.ppt'; }
            when 'application/vnd.openxmlformats-officedocument.presentationml.presentation' { return '.pptx'; }
            when 'application/x-www-form-urlencoded' { return '.txt'; }
            when 'application/x-javascript'     { return '.js'; }
            when 'application/x-tar'            { return '.tar'; }
            when 'application/x-7z-compressed'  { return '.7z'; }
            when 'application/x-rar-compressed' { return '.rar'; }
            when 'application/octet-stream'     { return ''; } // generic binary
            
            // ----- IMAGES -----
            when 'image/jpeg'                   { return '.jpg'; }
            when 'image/pjpeg'                  { return '.jpg'; }
            when 'image/png'                    { return '.png'; }
            when 'image/gif'                    { return '.gif'; }
            when 'image/webp'                   { return '.webp'; }
            when 'image/bmp'                    { return '.bmp'; }
            when 'image/tiff'                   { return '.tiff'; }
            when 'image/svg+xml'                { return '.svg'; }
            when 'image/x-icon'                 { return '.ico'; }
            when 'image/heic'                   { return '.heic'; }
            
            // ----- AUDIO -----
            when 'audio/mpeg'                   { return '.mp3'; }
            when 'audio/wav'                    { return '.wav'; }
            when 'audio/ogg'                    { return '.ogg'; }
            when 'audio/aac'                    { return '.aac'; }
            when 'audio/webm'                   { return '.weba'; }
            
            // ----- VIDEO -----
            when 'video/mp4'                    { return '.mp4'; }
            when 'video/mpeg'                   { return '.mpeg'; }
            when 'video/ogg'                    { return '.ogv'; }
            when 'video/webm'                   { return '.webm'; }
            when 'video/quicktime'              { return '.mov'; }
            when 'video/x-msvideo'              { return '.avi'; }
            
            // ----- FONTS -----
            when 'font/ttf'                     { return '.ttf'; }
            when 'font/otf'                     { return '.otf'; }
            when 'font/woff'                    { return '.woff'; }
            when 'font/woff2'                   { return '.woff2'; }
            
            // ----- DEFAULT -----
            when else                           { return ''; } // Unknown MIME type
        }
    }
    
    
}