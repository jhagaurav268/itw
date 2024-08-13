Trigger AssignOwner on Account (before insert, before update) { 

    String sobject_type = 'Account';
    Map<String, Schema.SObjectType> global_describe = Schema.getGlobalDescribe();
    Map<String, Schema.SObjectField> fields = global_describe.get(sobject_type).getDescribe().fields.getMap();
    
    for(sObject ThisRec : Trigger.new){
        for(String fieldName : fields.keySet()) {
            Schema.SObjectField field = fields.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            If(String.ValueOf(fieldDescribe.getSoapType()) == 'STRING' && fieldDescribe.isUpdateable()){
                if(string.valueOf( ThisRec.get(field) ) != null){
                    ThisRec.put(field, string.valueOf(ThisRec.get(field)).unescapeHtml4());
                }
            }
        }
    }
    
    Set<String> ParentIds = new Set<String>();
    for(Account A: Trigger.new){
        If(A.Parent_Write_In__c != Null){
            ParentIds.Add(A.Parent_Write_In__c);
        }
    }
    
    Map<String,Code_Definitions__c> CDMap = new Map<String,Code_Definitions__c>();
    for(Code_Definitions__c CD: [SELECT code__c,description__c,extRecordId__c,Id,listID__c,Name,Status__c,uniqueid__c FROM Code_Definitions__c]){
        CDMap.put(CD.uniqueid__c,CD);
    } 
    
    Map<String,Id> ParentMap = new Map<String,Id>();
    for(Account A: [Select Id, DUET__uniqueid__c from Account Where DUET__uniqueid__c IN: ParentIds]){
        ParentMap.Put(A.DUET__uniqueid__c, A.Id);
    }

  
 // put all sales users in a map so we can pick the correct one later
  Map<String, Id> salesUser = new Map<String,Id>();
  User[] usrs = [Select Id, Sales_Rep_Code__c From User Where Sales_Rep_Code__c != NULL and IsActive = true];
  
  List<string> RepSplit = new List<string>();
  
  for (User u : usrs) {
  
    If(u.Sales_Rep_Code__c.contains(';')){   
       RepSplit = u.Sales_Rep_Code__c.Split(';');
       for(integer i=0; i<RepSplit.size(); i++){
         salesUser.put(RepSplit[i].toUpperCase(), u.Id);
       }  
    }   
    Else{
      salesUser.put(u.Sales_Rep_Code__c.toUpperCase(), u.Id);
    }
      
  }
   
  // Select the default record owner
  Id dro = [SELECT Id FROM User WHERE UserName LIKE 'ionadmin@simco-ion.com%' LIMIT 1].Id;
  
  //select Bill to and Ship to record Type
  RecordType BillTo = [Select Id from RecordType where SObjectType = 'Account' AND DeveloperName = 'Bill_To_Account_Record_Type' Limit 1];
  RecordType ShipTo = [Select Id from RecordType where SObjectType = 'Account' AND DeveloperName = 'Ship_To_Account_Record_Type' Limit 1];
  
  //F = Industrial & L = Technical
  for (Account a : Trigger.New) {   
              System.debug('Entering Trigger.new');
      if (a.DUET__extrecordid__c != NULL && a.FamilyCode__c != 'L' && a.RecordTypeId != BillTo.Id) {  
              System.debug('Entering Parent check');
          
          if (a.Sales_Rep_Code__c != NULL) {
              String salesRepCd;      
              salesRepCd = a.Sales_Rep_Code__c.toUpperCase();   
              System.debug('SalesRepCD' + ' : ' + salesRepCd);
              if (salesUser.containsKey(salesRepCd)){
                  a.OwnerId = salesUser.get(salesRepCd);  
              } else {
                a.OwnerId = dro; 
              }
          } else {
          
              a.OwnerId = dro; 
          }
       }
       if(CDMap.ContainsKey('Customer Types.'+a.DUET__customertypeid__c)) a.Customer_Type__c = CDMap.get('Customer Types.'+a.DUET__customertypeid__c).Id;
       if(CDMap.ContainsKey('Industries.'+a.DUET__industryid__c)) a.Industry__c = CDMap.get('Industries.'+a.DUET__industryid__c).Id;
       if(CDMap.ContainsKey('PaymentTerm.'+a.DUET__paymenttermid__c)) a.Payment_Term__c = CDMap.get('PaymentTerm.'+a.DUET__paymenttermid__c).Id;
       If(A.Parent_Write_In__c != Null){
           if(ParentMap.ContainsKey(A.Parent_Write_In__c)){
               A.ParentId = ParentMap.get(A.Parent_Write_In__c);
           }
       }
   }
    
}