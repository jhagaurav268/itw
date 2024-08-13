trigger ReplaceHTMLInvoiceLine on DUET__Invoice_Line__c (before insert, before update, after insert, after update) {

    If(Trigger.IsBefore){
        String sobject_type = 'DUET__Invoice_Line__c';
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
        
        Set<String> COLSet = new Set<String>();
        Map<String,DUET__Customer_Order_Line__c> COLMap = new Map<String,DUET__Customer_Order_Line__c>();
        for(DUET__Invoice_Line__c IVL: Trigger.New){
            if(IVL.DUET__customerorderline__c == NULL && IVL.DUET__writeinsalesordernumber__c != NULL && IVL.DUET__writeinsalesorderlinenumber__c != NULL){
                COLSet.Add(IVL.DUET__writeinsalesordernumber__c + '_' + IVL.DUET__writeinsalesorderlinenumber__c);
            }
        }
        if(!COLSet.IsEmpty()){
            for(DUET__Customer_Order_Line__c COL: [Select Id, DUET__uniqueid__c from DUET__Customer_Order_Line__c Where DUET__uniqueid__c IN: COLSet]){
                COLMap.Put(COL.DUET__uniqueid__c, COL);
            }
            
            If(!COLMap.IsEmpty()){
                for(DUET__Invoice_Line__c IVL: Trigger.New){
                    if(IVL.DUET__customerorderline__c == NULL && IVL.DUET__writeinsalesordernumber__c != NULL && IVL.DUET__writeinsalesorderlinenumber__c != NULL){
                        if(COLMap.ContainsKey(IVL.DUET__writeinsalesordernumber__c + '_' +IVL.DUET__writeinsalesorderlinenumber__c)){
                            IVL.DUET__customerorderline__c = COLMap.get(IVL.DUET__writeinsalesordernumber__c + '_' +IVL.DUET__writeinsalesorderlinenumber__c).Id;
                        }
                    }
                }
            }
        }
    }
    
    else if(Trigger.IsAfter){
        List<DUET__Customer_Order_Line__c> COLUpdate = new List<DUET__Customer_Order_Line__c>();
        for(DUET__Invoice_Line__c IVL: Trigger.new){
            if(IVL.DUET__customerorderline__c != Null){
                DUET__Customer_Order_Line__c COL = new DUET__Customer_Order_Line__c();
                COL.Id = IVL.DUET__customerorderline__c;
                COLUpdate.Add(COL);
            }
        }
        if(!COLUpdate.IsEmpty()) Update COLUpdate;
    }
}