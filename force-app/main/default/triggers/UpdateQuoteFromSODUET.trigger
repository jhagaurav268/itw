trigger UpdateQuoteFromSODUET on DUET__Customer_Order__c (before insert, before update, after insert, after update) {
    
    If(Trigger.IsBefore){
        String sobject_type = 'DUET__Customer_Order__c';
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
        Set<String> QuoteIds = new Set<String>();
        Map<String,Id> QuoteMap = new Map<String,Id>();
        for(DUET__Customer_Order__c CO: Trigger.new){
            If(CO.DUET__custordernumber__c != Null){
                QuoteIds.Add(CO.DUET__custordernumber__c);
            }
        }
        
        for(Quote q : [Select Id, QuoteNumber from Quote where QuoteNumber in: QuoteIds]){
            QuoteMap.Put(q.QuoteNumber,q.Id);
        }  
        
        Map<String,Code_Definitions__c> CDMap = new Map<String,Code_Definitions__c>();
        for(Code_Definitions__c CD: [SELECT code__c,description__c,extRecordId__c,Id,listID__c,Name,Status__c,uniqueid__c FROM Code_Definitions__c]){
            CDMap.put(CD.uniqueid__c,CD);
        } 
        
        for(DUET__Customer_Order__c CO: Trigger.new){
            if(CDMap.ContainsKey('PaymentTerm.'+CO.DUET__paymenttermid__c)) CO.Payment_Terms__c = CDMap.get('PaymentTerm.'+CO.DUET__paymenttermid__c).Id;
            if(QuoteMap.ContainsKey(CO.DUET__custordernumber__c)){
                CO.Quote__c = QuoteMap.get(CO.DUET__custordernumber__c);
            }
        }
    }
    
    If(Trigger.IsAfter){
        Map<String,DUET__Customer_Order__c> OrderMap = new Map<String,DUET__Customer_Order__c>();
        List<Id> SOtoDelete = new List<Id>();
        for(DUET__Customer_Order__c so : trigger.new){
            OrderMap.put(so.DUET__custordernumber__c,so);
            //if(so.DUET__status__c == 'Shipped'){
            //    SOtoDelete.add(so.Id);
            //}        
        } 
        
        List<Quote> QuoteList =  [Select QuoteNumber from Quote where QuoteNumber in: OrderMap.keyset()];
        for(Quote q : QuoteList){
            q.ERPOrderNumber__c = OrderMap.get(q.QuoteNumber).DUET__exRecordId__c;        
        }   
        If(!QuoteList.IsEmpty()) update QuoteList;
        //List<DUET__Customer_Order__c> SODelCopy = [Select Id from DUET__Customer_Order__c where Id IN :SOtoDelete];
        //If(!SODelCopy.IsEmpty()) delete SODelCopy;
    }
}