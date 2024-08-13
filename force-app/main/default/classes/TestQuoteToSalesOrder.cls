@isTest(SeeAllData=true)
public class TestQuoteToSalesOrder{
    static testMethod void Testingcreation(){
        //query inforce account record type
        Id TheRecordType = [Select Id from RecordType where sObjectType =: 'Account' AND DeveloperName =: 'inforceaccountrectype'].Id;
        
        /*
        //create and insert parenttestaccount
        Account ParentTestAcc = new Account(Name = 'TheParentTest', RecordTypeId = TheRecordType, InForceEW__statuscode__c = 'Open', CustomerStatus__c = 'Active', InForceEW__extRecordId__c = 'Test');
        insert ParentTestAcc;
        
        //create and insert testaccount
        Account TestAcc = new Account(Name = 'TheTest', RecordTypeId = TheRecordType, ParentId = ParentTestAcc.Id, InForceEW__statuscode__c = 'Open', CustomerStatus__c = 'Active', Sales_Rep_Code__c = '68', InForceEW__extRecordId__c = '100');
        insert TestAcc;
        
        //create and insert testopp
        Opportunity TestOpp = new Opportunity(Name = 'TheTestOpp', AccountId = TestAcc.Id, StageName = 'Qualification/Need Analysis', CloseDate = Date.newInstance(2017, 2, 17));
        insert TestOpp;
        
        //create and insert testproduct
        Product2 TestProd = new Product2(Name = 'TestProduct');
        insert TestProd;  
        
        Pricebook2 pb = [select id from Pricebook2 where IsStandard = true limit 1];

        //create and insert Pricebookentry
        PricebookEntry pbe = new PricebookEntry(pricebook2id=pb.id, product2id= TestProd.id, unitprice=1.0, isActive=true);
        insert pbe; 
        
        //create and insert testquote with the fields from the trigger
        Quote TestQuote = new Quote(Name = 'TestQuote', Status = 'Accepted', OpportunityId = TestOpp.Id, Account_External_Id__c = 'TestExtId', pricebook2id=pb.id);
        insert TestQuote; 
        
        //create and insert a salesorder
        InForceEW__salesorder__c TestSO = new InForceEW__salesorder__c(Name = 'TheTestSO', Quote_Number__c = TestQuote.QuoteNumber, InForceEW__Account__c = TestAcc.Id, InForceEW__custordernumber__c = TestQuote.QuoteNumber, InForceEW__statuscode__c = 'Open');
        insert TestSO;
        
        //update salesorder
        TestSO.InForceEW__statuscode__c = 'Shipped';
        update TestSO;
           
        //create and insert quotelineitem
        QuoteLineItem TestQuoteLine = new QuoteLineItem(QuoteId = TestQuote.Id, Product2Id = TestProd.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = 1);
        insert TestQuoteLine;
        
        //update testquotes
        Update TestQuote;  
        */ 
    }
}