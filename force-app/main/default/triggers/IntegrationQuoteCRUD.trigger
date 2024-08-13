trigger IntegrationQuoteCRUD on IntegrationQuote__c (after insert, after Update) {
/*    if(trigger.isInsert || trigger.isUpdate){
        List<String> lstIQId = new List<String>();
        for(IntegrationQuote__c IQ : trigger.new){
            lstIQId.add (IQ.id);
        }
        System.debug(LoggingLevel.DEBUG, 'IQ Created' + lstIQId.size());
     if(lstIQId.size()>0){
            System.debug(LoggingLevel.DEBUG, 'IQ Created' + lstIQId.size());
            InforceEW.IonTxnUtility.conditionalInsertIonTxn(lstIQId,'IntegrationQuote__c', trigger.isInsert, trigger.isUpdate, trigger.isDelete);
            System.debug(LoggingLevel.DEBUG, 'Transaction Created');
        }
    }
*/
}