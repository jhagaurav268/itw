@isTest
private class DeleteIntegrationQuotesTest {
    @testSetup
    static void setup() {
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Application Engineers'];
        User u = new User(Alias = 'standtst', Email='standarduser@test.com', 
                          EmailEncodingKey='UTF-8', LastName='Test', LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', 
                          UserName='standardusercsl@test.com');
        
        insert u;
        
        List<IntegrationQuote__c> quotes = new List<IntegrationQuote__c>();
        for(Integer i = 0; i < 10; i++) {
            quotes.add(new IntegrationQuote__c(Name = 'Test Quote ' + i));
        }
        insert quotes;
    }
    
    @isTest
    static void testBatchWithInsufficientPermissions() {
        
        User u = [SELECT Id FROM User WHERE UserName='standardusercsl@test.com'];
        
        System.runAs(u) {
            Test.startTest();
            DeleteIntegrationQuotes batch = new DeleteIntegrationQuotes();
            Id batchJobId = Database.executeBatch(batch);
            Test.stopTest();
            
            AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :batchJobId];
            System.assertEquals('Completed', job.Status);
            
            Boolean exceptionThrown = false;
            try {
                Database.executeBatch(batch);
            } catch (DeleteIntegrationQuotes.CustomException e) {
                exceptionThrown = true;
            }
        }
    }
}