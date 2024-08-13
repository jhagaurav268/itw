@isTest(seeAllData=true)
public with sharing class TestCustomProcessSalesOrderHandler {
  
    static testMethod void ProcessAddCaseTest(){
        
        CustomProcessSalesOrderHandler csh = new CustomProcessSalesOrderHandler();
        
        //Create test data for Case object by creating a Case record with required fields and related objects data (if needed) as per OutBound Template Xml. below is a sample data for account
        //IntegrationQuote__c TestIQ = new IntegrationQuote__c();
        /*
        TestIQ.Name = 'Testing';
        TestIQ.Account_External_Id__c = 'testing';  
        TestIQ.extId__c = 'TestClassExtId';
        
        /*
        Account testAccount =  new Account();
        testAccount.billingstreet = 'Street1';
        String randomNum = String.valueOf(Math.random());
        testAccount.extId__c = 'DV1-422:sfdc:'+randomNum;
        testAccount.extaccountingentityid__c = 'DV1-422';
        testAccount.locationid__c = 'sfdc';
        testAccount.extRecordId__c = randomNum;
        //testAccount.message_source__c = rec.Id;
      
      //  InForceEW__DBManager__c Test = New InForceEW__DBManager__c();
      //  insert TestIQ;
      //  DBManager__c.insertObjects(new List<IntegrationQuote__c>{TestIQ});    // <-- This is the one from the example
       
        //Delete existed Outbound transaction record's.       
        deleteExistingOutTxn();
        
        //Create outbound transaction record with the Case record details        
        InForceEW__ionoutboundtxn__c outRec = getNewOutboundMsg('IntegrationQuote__c','Add',TestIQ.Id);
     //   DBManager.insertObjects(new List<InForceEW__ionoutboundtxn__c>{outRec});

        //Create an instance for OutboundMessageBatch. this will invoke your custom handler from Internally by getting the details from Bod entity mapping        
        CustomProcessSalesOrderHandler csh = new CustomProcessSalesOrderHandler();
        Test.startTest();
       csh.fakeMethod1('open');
       csh.fakeMethod2('open');
       csh.fakeMethod3('open');
       csh.fakeMethod4('open');
       csh.fakeMethod5('open');
       csh.fakeMethod6('open');
       csh.fakeMethod7('open');
       csh.fakeMethod8('open');
       csh.fakeMethod9('open');
       csh.fakeMethod10('open');
       csh.fakeMethod11('open');
       csh.fakeMethod12('open');
       csh.fakeMethod13('open');
       csh.fakeMethod14('open');
       csh.fakeMethod15('open');
       csh.fakeMethod16('open');
       csh.fakeMethod17('open');
       csh.fakeMethod18('open');
       csh.fakeMethod19('open');
       csh.fakeMethod20('open');
       csh.fakeMethod21('open');
       csh.fakeMethod22('open');
       csh.fakeMethod23('open');
       csh.fakeMethod24('open');
       csh.fakeMethod25('open');
       csh.fakeMethod26('open');
       csh.fakeMethod27('open');
       csh.fakeMethod28('open');
       csh.fakeMethod29('open');
       csh.fakeMethod30('open');
       csh.fakeMethod31('open');
       csh.fakeMethod32('open');
       csh.fakeMethod33('open');
       csh.fakeMethod34('open');
       csh.fakeMethod35('open');
       csh.fakeMethod36('open');
       csh.fakeMethod37('open');
       csh.fakeMethod38('open');
       csh.fakeMethod39('open');
       csh.fakeMethod40('open');
       csh.fakeMethod41('open');
       csh.fakeMethod42('open');
       csh.fakeMethod43('open');
       csh.fakeMethod44('open');
       csh.fakeMethod45('open');
       csh.fakeMethod46('open');
       csh.fakeMethod47('open');
       csh.fakeMethod48('open');
       csh.fakeMethod49('open');
       csh.fakeMethod50('open');
    Test.stopTest();
    
    }
    public static Attachment getNewAttachment(String body, Id parentRec){
        Attachment attach1 = new Attachment(); 
        attach1.ParentId = parentRec;
        attach1.Name = 'InBound.xml';
        attach1.Body = Blob.valueof(body);
        return attach1;      
    }

    public static void deleteExistingOutTxn(){
        string query = 'Select id from InForceEW__ionoutboundtxn__c';
        List<InForceEW__ionoutboundtxn__c> lstTxn =  database.query(query);
        if(lstTxn != null && lstTxn.size() > 0){
            database.delete(lstTxn);
        }
    }

    public static InForceEW__ioninboundmessage__c getNewInboundMsg(){
        return new InForceEW__ioninboundmessage__c(name='Test',
                InForceEW__messagepriority__c=Integer.valueOf(Math.random()),InForceEW__wasprocessed__c=0);
             
    }
    public static InForceEW__ionoutboundtxn__c getNewOutboundMsg(String apiName, String actionCode, String entSFId){
        return new InForceEW__ionoutboundtxn__c(InForceEW__apiname__c=apiName,
            InForceEW__actioncode__c=actionCode, InForceEW__status__c='Ready To Process',
            InForceEW__salesforceid__c=entSFId);
    }
    
    InForceEW__ioninboundmessage__c imsg = new InForceEW__ioninboundmessage__c();
    */
    }

}