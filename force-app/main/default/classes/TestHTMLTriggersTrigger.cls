@isTest(SeeAllData=true)
public class TestHTMLTriggersTrigger{
   
    Public static testMethod void HTMLTests(){
        RecordType ShipTo = [Select Id from RecordType where SObjectType = 'Account' AND DeveloperName = 'Ship_To_Account_Record_Type' Limit 1];
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='testingusertestclasses@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testingusertestclasses@duet.com', Sales_Rep_Code__c = 'ABC;DEF');
        DUET__Configuration__c TestConfig = new DUET__Configuration__c (Name = 'Class Test Configuration', DUET__active__c = True, DUET__integrationuser__c =u.id, DUET__fromlogicalid__c = 'LogicalIdTest');
        insert TestConfig;
        Account TestAcc = new Account(Name = 'TheTest', FamilyCode__c = 'F', Sales_Rep_Code__c = 'ABC', RecordTypeId = ShipTo.Id, DUET__extrecordid__c = 'TheTest'); 
        insert TestAcc;
        DUET__Customer_Order__c TestCO = new DUET__Customer_Order__c(Name = 'TheTest', DUET__account__c = TestAcc.id, DUET__variationid__c = 4);
        DUET.checkRecursive.run = true;
        insert TestCO;
        
        DUET__Customer_Order_Line__c TestCOLine = new DUET__Customer_Order_Line__c (Name = 'TheTest', DUET__customerorder__c = TestCO.id, DUET__quantityordered__c = '5');
        DUET.checkRecursive.run = true;
        insert TestCOLine;        
        TestCOLine.DUET__quantityordered__c = '0';
        DUET.checkRecursive.run = true;
        Update TestCOLine;
        
        DUET__Invoice__c TestInvoice = new DUET__Invoice__c (Name = 'TheTest', DUET__account__c = TestAcc.id, DUET__variationid__c = 4);
        DUET.checkRecursive.run = true;
        insert TestInvoice;
        
        DUET__Invoice_Line__c TestInvLine = new DUET__Invoice_Line__c (Name = 'TheTest', DUET__invoice__c = TestInvoice.id, DUET__variationid__c = 5, DUET__writeinsalesordernumber__c = 'TheTest', DUET__writeinsalesorderlinenumber__c = '100');
        DUET.checkRecursive.run = true;
        insert TestInvLine;
        
        Product2 TestProduct = new Product2(Name = 'ProductTesting', DUET__variationid__c = 4);
        insert TestProduct;
    }
    
    Public static testMethod void InvoiceLineTests(){
        RecordType ShipTo = [Select Id from RecordType where SObjectType = 'Account' AND DeveloperName = 'Ship_To_Account_Record_Type' Limit 1];
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='testingusertestclasses@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testingusertestclasses@duet.com', Sales_Rep_Code__c = 'ABC;DEF');
        DUET__Configuration__c TestConfig = new DUET__Configuration__c (Name = 'Class Test Configuration', DUET__active__c = True, DUET__integrationuser__c =u.id, DUET__fromlogicalid__c = 'LogicalIdTest');
        insert TestConfig;
        Account TestAcc = new Account(Name = 'TheTest', FamilyCode__c = 'F', Sales_Rep_Code__c = 'ABC', RecordTypeId = ShipTo.Id, DUET__extrecordid__c = 'TheTest'); 
        insert TestAcc;
        DUET__Customer_Order__c TestCO = new DUET__Customer_Order__c(Name = 'TheTest', DUET__account__c = TestAcc.id, DUET__variationid__c = 4);
        DUET.checkRecursive.run = true;
        insert TestCO;
        
        DUET__Customer_Order_Line__c TestCOLine = new DUET__Customer_Order_Line__c (Name = 'TheTest', DUET__customerorder__c = TestCO.id, DUET__quantityordered__c = '5');
        DUET.checkRecursive.run = true;
        insert TestCOLine;        
        TestCOLine.DUET__quantityordered__c = '0';
        TestCOLine.DUET__uniqueid__c = 'TheTest_100';
        DUET.checkRecursive.run = true;
        Update TestCOLine;
        
        Test.startTest();
            DUET__Invoice__c TestInvoice = new DUET__Invoice__c (Name = 'TheTest', DUET__account__c = TestAcc.id, DUET__variationid__c = 4);
            DUET.checkRecursive.run = true;
            insert TestInvoice;
            
            DUET__Invoice_Line__c TestInvLine = new DUET__Invoice_Line__c (Name = 'TheTest', DUET__invoice__c = TestInvoice.id, DUET__variationid__c = 5, DUET__writeinsalesordernumber__c = 'TheTest', DUET__writeinsalesorderlinenumber__c = '100');
            DUET.checkRecursive.run = true;
            insert TestInvLine;
            
            Product2 TestProduct = new Product2(Name = 'ProductTesting', DUET__variationid__c = 4);
            insert TestProduct;
        Test.stopTest();
    }
        
    //insert an ERP Quote and update with an older var Id
    static testMethod void QuoteVarIdCheckTest(){
        DUET__Configuration__c TestConfig = new DUET__Configuration__c (Name = 'Class Test Configuration', DUET__active__c = True, DUET__integrationuser__c =userinfo.getuserid(), DUET__fromlogicalid__c = 'LogicalIdTest');
        insert TestConfig;        
        Account TestAcc = new Account(Name = 'TheTest', DUET__extlogicalid__c = 'LogicalIdTest'); 
        insert TestAcc;
        Opportunity O = new Opportunity(Name = 'TestOpp',AccountId = TestAcc.Id, StageName = 'Qualification/Need Analysis', CloseDate = System.Today());
        Insert O;
        Quote TestERPQ = new Quote(Name = 'TestQuote', OpportunityId = O.Id, variationid__c = 5, extlogicalid__c = 'LogicalIdTest');
        
        Test.startTest();
        try{     
            insert TestERPQ;
            
            TestERPQ.variationid__c = 3;
            update TestERPQ;
        }
        catch(exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('A new version of this BOD has already been processed.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        TestERPQ.variationid__c = null;
            DUET.checkRecursive.run = true;
            update TestERPQ;
        
        Test.stopTest(); 
    }
    
    Public static testMethod void ERPQuoteLineTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='testingusertestclasses@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='testingusertestclasses@duet.com');
        DUET__Configuration__c TestConfig = new DUET__Configuration__c (Name = 'Class Test Configuration', DUET__active__c = True, DUET__integrationuser__c =u.id, DUET__fromlogicalid__c = 'LogicalIdTest');
        insert TestConfig;
        Account TestAcc = new Account(Name = 'TheTest'); 
        insert TestAcc;
        Product2 TestProduct = new Product2(Name = 'ProductTesting', DUET__variationid__c = 4);
        insert TestProduct;
        Opportunity O = new Opportunity(Name = 'TestOpp',AccountId = TestAcc.Id, StageName = 'Qualification/Need Analysis', CloseDate = System.Today());
        Insert O;
        Id pricebookId = Test.getStandardPricebookId();
        Quote TestERPQ = new Quote(Name = 'TestQuote', OpportunityId = O.Id, variationid__c = 5, extlogicalid__c = 'LogicalIdTest', Pricebook2Id = pricebookId);      

        DUET.checkRecursive.run = true;
        insert TestERPQ;
        
        Id PBEId = [Select Id from PricebookEntry where Product2.Name = 'ProductTesting'].Id;
            
        QuoteLineItem TestERPGLine = new QuoteLineItem (QuoteId = TestERPQ.id, variationid__c = 5, Product2Id = TestProduct.Id, PricebookEntryId = PBEId, UnitPrice = 100, Quantity = 1);
        
        Test.startTest();
        insert TestERPGLine;
        try{     


            TestERPGLine.variationid__c = 3;
            update TestERPGLine;
        }
        catch(exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('A new version of this BOD has already been processed.') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        TestERPGLine.variationid__c = null;
        DUET.checkRecursive.run = true;
        update TestERPGLine;
        
        Test.stopTest();         
  
    }
}