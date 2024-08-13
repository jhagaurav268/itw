global class DeleteIntegrationQuotes implements Database.Batchable<sObject>{
    global final String Query;
    public class CustomException extends Exception {}
    
    global DeleteIntegrationQuotes(){       
        query = 'SELECT Id FROM IntegrationQuote__c '; 
    } 
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<IntegrationQuote__c> scope){
        /* Modified by: Abhinav Yaduvanshi
		*  Date: 25/06/2024
		*/
        if(Schema.sObjectType.IntegrationQuote__c.isDeletable()){
            delete scope;
        } else{ 
            throw new CustomException('You do not have access to delete this record, Please ensure you have the necessary permissions to delete this record.');
        }
    }
    
    global void finish(Database.BatchableContext BC){
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        
        // Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Sharing Recalculation ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
    }
}