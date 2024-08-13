@isTest
public class QuoteTriggerHandlerTest {
    
    @isTest
    static void testTriggerHandler() {
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
            
            TestERPQ.variationid__c = 0;
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
    
}