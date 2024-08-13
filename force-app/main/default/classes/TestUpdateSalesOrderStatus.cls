@isTest(SeeAllData=True)
public class TestUpdateSalesOrderStatus{

    static testMethod void UpdateSalesOrderStatus(){
        
        Account TestAcc = new Account(Name = 'TheTest'); 
        insert TestAcc;
        
        /*InForceEW__salesorder__c TestOrder = new InForceEW__salesorder__c(Name = 'TheTest12356234', InForceEW__Account__c = TestAcc.Id);
        insert TestOrder;
        InForceEW__invoice__c TestInv = new InForceEW__invoice__c(Name = 'TheTest', InForceEW__account__c = TestAcc.Id); 
        insert TestInv;
        String TheOrderId = [Select Id from InForceEW__salesorder__c Where Name = 'TheTest12356234'].Id;
        InForceEW__invoiceline__c TestInvLine = new InForceEW__invoiceline__c(InForceEW__invoice__c = TestInv.Id, Name = '1', InForceEW__ordernumber__c = TheOrderId);
            
            Test.startTest();
            insert TestInvLine;
        
            Test.stopTest(); 
        */
    }
}