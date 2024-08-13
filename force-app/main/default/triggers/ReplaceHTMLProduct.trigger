Trigger ReplaceHTMLProduct on Product2 (before insert, before update) {
    
    String sobject_type = 'Product2';
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
    
    Map<String,Code_Definitions__c> CDMap = new Map<String,Code_Definitions__c>();
    for(Code_Definitions__c CD: [SELECT code__c,description__c,extRecordId__c,Id,listID__c,Name,Status__c,uniqueid__c FROM Code_Definitions__c]){
        CDMap.put(CD.uniqueid__c,CD);
    } 
    
    for(Product2 P: Trigger.new){
        if(CDMap.ContainsKey('Item Groups.'+P.Item_Class_Code_Write_In__c)) P.Item_Class_Code__c = CDMap.get('Item Groups.'+P.Item_Class_Code_Write_In__c).Id;
    }
}