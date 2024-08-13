trigger QuoteToSalesOrder on Quote (after update, after insert) {
  /*
    try {
        System.Debug('Enter Quote Trigger');
        List<Id> QuoteIds = new List<Id>();
        Set<Id> OldQuoteIds = new Set<Id>();
        List<IntegrationQuote__c> AllIntegrationQuotes = new List<IntegrationQuote__c>();
        Map<Id, IntegrationQuote__c> QuoteIdTOIntegrationId = new Map<Id, IntegrationQuote__c>();
        
        for(Quote EachQuote: trigger.new){ 
            if(EachQuote.Status == 'Accepted') QuoteIds.add(EachQuote.Id);
        } 
        for(Quote OldQuote: trigger.old){ 
            if(OldQuote.Status == 'Accepted') OldQuoteIds.add(OldQuote.Id);
        } 
        
        List<Quote> AllQuotes = [Select Id, Description, InForceEW__requesteddeliveryby__c, InForceEW__variationid__c, InForceEW__statuscode__c, InForceEW__shiptoaddress__c, 
                                 InForceEW__shiptopostalcode__c, InForceEW__shiptostateorprovince__c, InForceEW__shiptoname__c, 
                                 InForceEW__shiptocountry__c, InForceEW__shiptocity__c, Phone, OpportunityAccountMessageSource__c, 
                                 OpportunityAccountLocationId__c, GrandTotal, ShipTo_External_Id__c, Opportunity_Account_extlogicalid__c, 
                                 OpportunityAccountExtaccountingentityid__c, InForceEW__extaccountingentityid__c, Contact_extRecordId__c, 
                                 Contact_extlogicalid__c, Contact_extaccountingentityid__c, InForceEW__cansendbod__c, InForceEW__billtoaddress__c, 
                                 InForceEW__billtostateorprovince__c, InForceEW__billtopostalcode__c, InForceEW__billtoname__c, 
                                 InForceEW__billtocountry__c, InForceEW__billtocity__c, Opportunity_Account_External_Id__c, QuoteNumber, 
                                 ERPOrderNumber__c, 
                                 RequestedShipDate__c, 
                                 Special_Instructions__c
                                 ,Customer_PO__c
                                 FROM Quote WHERE Id IN : QuoteIds];
                                 
        for(Quote Q : AllQuotes){
            String sAction = 'Add';
            if(OldQuoteIds.contains(Q.Id)){
                sAction = 'Change';
            }
            String sName = (Q.ERPOrderNumber__c != 'NEW') ? Q.ERPOrderNumber__c : '01.1.' + Q.QuoteNumber;
            
            IntegrationQuote__c newQ = new IntegrationQuote__c(
                name = sName ,
                //name = '01.1.' + Q.QuoteNumber, 
                Description__c = Q.Description,
                Account_External_Id__c = Q.Opportunity_Account_External_Id__c, 
                BillingCity__c = Q.InForceEW__billtocity__c, 
                BillingCountry__c = Q.InForceEW__billtocountry__c, 
                BillingName__c = Q.InForceEW__billtoname__c, 
                BillingPostalCode__c = Q.InForceEW__billtopostalcode__c,
                BillingState__c = Q.InForceEW__billtostateorprovince__c,
                BillingStreet__c = Q.InForceEW__billtoaddress__c,
                cansendbod__c = true,
                Contact_extaccountingentityid__c = Q.Contact_extaccountingentityid__c,
                Contact_extlogicalid__c = Q.Contact_extlogicalid__c,
                Contact_extRecordId__c = Q.Contact_extRecordId__c,
                extaccountingentityid__c = Q.InForceEW__extaccountingentityid__c,                
                extId__c = Q.OpportunityAccountExtaccountingentityid__c + ':Default:' + Q.QuoteNumber,
                extlogicalid__c = Q.Opportunity_Account_extlogicalid__c,
                extRecordId__c = Q.ShipTo_External_Id__c,
                GrandTotal__c = Q.GrandTotal,
                locationid__c = Q.OpportunityAccountLocationId__c,
                Message_Source__c = Q.OpportunityAccountMessageSource__c,
                Opportunity_Account_External_Id__c = Q.Opportunity_Account_External_Id__c,
                Opportunity_Account_extlogicalid__c = Q.Opportunity_Account_extlogicalid__c,
                OpportunityAccountLocationId__c = 'Default',
                //OpportunityAccountExtaccountingentityid__c = Q.OpportunityAccountExtaccountingentityid__c,
                OpportunityAccountExtaccountingentityid__c = '01',
                phone__c = Q.Phone,
                //Requesteddeliveryby__c = String.valueOf(Q.InForceEW__requesteddeliveryby__c),
                Requesteddeliveryby__c = String.valueOf(Q.RequestedShipDate__c),
                ShippingCity__c = Q.InForceEW__shiptocity__c,
                ShippingCountry__c = Q.InForceEW__shiptocountry__c,
                ShippingName__c = Q.InForceEW__shiptoname__c,
                ShippingState__c = Q.InForceEW__shiptostateorprovince__c,
                ShippingPostalCode__c = Q.InForceEW__shiptopostalcode__c,
                ShippingStreet__c = Q.InForceEW__shiptoaddress__c,
                statuscode__c = Q.InForceEW__statuscode__c,
                variationId__c = Q.InForceEW__variationid__c,
                Special_Instructions__c = Q.Special_Instructions__c,
                Purchase_Order__c = Q.Customer_PO__c,
                ActionExpression__c = sAction );
                
                
            
            AllIntegrationQuotes.add(newQ);            
            QuoteIdTOIntegrationId.put(Q.Id, newQ);
        }       
        insert AllIntegrationQuotes;
        
        System.Debug('Inserted new integration quote');
        List<IntegrationQuoteItem__c> InsertableQuoteItems = new List<IntegrationQuoteItem__c>(); 
        List<QuoteLineItem> QuoteItemList = [select Id, Quote.Id, LineNumber, Description, ProductExtaccountingentityid__c, Product_extlogicalid__c,
                                            Product_extRecordId__c, Quantity, Product_Description__c, Product_UOM__c, 
                                            UnitPrice, Price_Per_Unit__c from QuoteLineItem where Quote.Id IN : QuoteIds];
        if(QuoteItemList.size() != 0){   
            for(QuoteLineItem QI: QuoteItemList) {
                IntegrationQuoteItem__c newQI = new IntegrationQuoteItem__c( 
                    LineNumber__c = QI.LineNumber, 
                    IntegrationQuote__c = QuoteIdTOIntegrationId.get(QI.QuoteId).Id,                        
                    Description__c = QI.Description,
                    ProductExtaccountingentityid__c = QI.ProductExtaccountingentityid__c ,
                    Product_extlogicalid__c = QI.Product_extlogicalid__c ,
                    Product_extRecordId__c = QI.Product_extRecordId__c ,
                    Quantity__c = QI.Quantity,
                    Product_Description__c = QI.Product_Description__c,
                    Product_UOM__c = QI.Product_UOM__c ,
                    UnitPrice__c = QI.UnitPrice
                    ,Price_Per_Unit__c = QI.Price_Per_Unit__c
                    );
                InsertableQuoteItems.add(newQI);
            }
            insert InsertableQuoteItems;            
        }
    }
    catch (Exception e) {
        System.Debug('Error inserting new integration quote: ' + e.getMessage());
    }
  */
}