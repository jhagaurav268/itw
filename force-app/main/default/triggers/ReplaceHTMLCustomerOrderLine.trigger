trigger ReplaceHTMLCustomerOrderLine on DUET__Customer_Order_Line__c (before insert, before update) {
    
    String sobject_type = 'DUET__Customer_Order_Line__c';
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
    
    If(Trigger.IsUpdate){
        Map<Id,decimal> InvoicesMap = new Map<Id,Decimal>();
        for(DUET__Customer_Order_Line__c COL: [Select Id, (Select Id, DUET__quantity__c from DUET__Invoice_Lines__r) From DUET__Customer_Order_Line__c Where Id IN: Trigger.new]){
            Decimal QTY = 0;
            for(DUET__Invoice_Line__c IVL: COL.DUET__Invoice_Lines__r){
                if(IVL.DUET__quantity__c != Null){
                    QTY = QTY + IVL.DUET__quantity__c;
                }
            }
            InvoicesMap.Put(COL.Id,QTY);
        }
        
        for(DUET__Customer_Order_Line__c COL: Trigger.new){
            if(InvoicesMap.ContainsKey(COL.Id)){
                COL.Invoiced_Quantity__c = InvoicesMap.Get(COL.Id);
                if(COL.DUET__quantityordered__c != NULL && COL.DUET__status__c != 'Paid'){
                    System.Debug('InvoicesMap.Get(COL.Id): ' + InvoicesMap.Get(COL.Id));
                    System.Debug('Decimal.ValueOf(COL.DUET__quantityordered__c): ' + Decimal.ValueOf(COL.DUET__quantityordered__c));
                    if(InvoicesMap.Get(COL.Id) >= Decimal.ValueOf(COL.DUET__quantityordered__c)){
                        COL.DUET__status__c = 'Invoiced';
                    }
                    else if(COL.DUET__status__c != 'PartiallyShipped'){
                        COL.DUET__status__c = 'PartiallyShipped';
                    }
                }
            }
        }
    }
}