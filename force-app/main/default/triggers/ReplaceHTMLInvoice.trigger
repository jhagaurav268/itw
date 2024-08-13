trigger ReplaceHTMLInvoice on DUET__Invoice__c (before insert, before update) {
    
    String sobject_type = 'DUET__Invoice__c';
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
    
    for(DUET__Invoice__c CO: Trigger.new){
        if(CDMap.ContainsKey('PaymentTerm.'+CO.DUET__paymenttermid__c)) CO.Payment_Terms__c = CDMap.get('PaymentTerm.'+CO.DUET__paymenttermid__c).Id;
    }
}