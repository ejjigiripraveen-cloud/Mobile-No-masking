/** 
  *    Description     :      Class to get opportunity name when lead is converted
  *
  *    Created By      :      Anshul Sharma
  *
  *    Created Date    :      04/07/2022
  * 
  *    Revision Logs   :      V_1.0 - Created
  *                      
  **/
  public class ConvertedLeadInformation {

	@auraEnabled(cacheable=true)
    //Method to get the opportunity name from lead
    public static ConvertedDetail getConvertedDetails(Id recordId)
    {
        //getting ConvertedAccountId , ConvertedContactId , ConvertedOpportunityId ids
        try{
              List<Lead> leadList = [SELECT Id, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId FROM Lead Where Id =:recordId];
              if(!leadList.isEmpty())
              {
                  //fetching opportunity
                  List<Contact> conDetail = [SELECT Id , FirstName , LastName , Title , Account.Name , Phone , Email , MobilePhone
                  FROM Contact WHERE Id =: leadList[0].ConvertedContactId];
                  List<Account> accDetail = [SELECT Id , Name , Email__c , Mobile__c , Owner.Name From Account WHERE Id =: leadList[0].ConvertedAccountId];
                  List<opportunity> oppDetail=[SELECT Id , Name , CloseDate , Owner_Name__c , StageName FROM Opportunity
                  WHERE Id =: leadList[0].ConvertedOpportunityId];
                  //creating object of wrapper class
                  ConvertedDetail convertedObj = new ConvertedDetail(oppDetail,accDetail,conDetail); 
                  return convertedObj;
              }
              else
              {
                  return null;
            }   
          }
        catch(Exception e)
        {
            throw new AuraHandledException('You have an error : '+e.getMessage());
        } 
    }
    //Wrapper class to hold list of account , contact and opportunity
    public class ConvertedDetail
    {
        @AuraEnabled
        public list<opportunity> oppDetails {get;set;}
        @AuraEnabled
        public list<Account> accDetails {get;set;}
        @AuraEnabled
        public list<Contact> conDetails {get;set;} 
        //Constructor method to alot data
        public ConvertedDetail(list<opportunity> oppDetails, list<Account> accDetails, list<Contact> conDetails) 
          {
              this.oppDetails = oppDetails;
              this.accDetails = accDetails;
              this.conDetails = conDetails;
          }
  
    }
}