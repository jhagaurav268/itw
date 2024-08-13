trigger QuoteLineTrigger on QuoteLineItem (before insert, before update, after insert, after update) {

// -------------------------------------------------------------  START ASSIGN LINE NUM  ------------------------------------------------------------- //
    If(Trigger.IsBefore && Trigger.IsInsert){
        Map<Id,Decimal> MaxLineNum = new Map<Id,Decimal>();
        Set<Id> Quotes = new Set<Id>();
        for(QuoteLineItem QLI: Trigger.new){
            Quotes.Add(QLI.QuoteId);
        }
        for(QuoteLineItem QLI: [Select Id, LineNumber__c, QuoteId from QuoteLineItem Where QuoteId IN: Quotes]){
            If(MaxLineNum.ContainsKey(QLI.QuoteId)){
                If(MaxLineNum.Get(QLI.QuoteId) < QLI.LineNumber__c){
                    MaxLineNum.Put(QLI.QuoteId,QLI.LineNumber__c);
                }
            }
            Else{
                MaxLineNum.Put(QLI.QuoteId,QLI.LineNumber__c);
            }
        }
        Decimal Num = 1;
        for(QuoteLineItem QLI: Trigger.new){
            Decimal sTemp = 0;
            If(MaxLineNum.ContainsKey(QLI.QuoteId)){
                If(MaxLineNum.get(QLI.QuoteId) != Null){
                    sTemp = MaxLineNum.get(QLI.QuoteId);
                }
            }
            System.Debug('sTemp: ' + sTemp);
            System.Debug('Num: ' + Num);
            QLI.LineNumber__c = sTemp + Num;
            
            Num ++;
        }
    }
// -------------------------------------------------------------  STOP ASSIGN LINE NUM  ------------------------------------------------------------- //
// -------------------------------------------------------------  START VARIATION ID CHECK  ------------------------------------------------------------- //
    if(Trigger.IsBefore && Trigger.IsUpdate){
        String MySObject = 'Quote';
        Set<Id> ConfigIds = new Set<Id>();
        
        for(sObject ThisRec : Trigger.new){
            if(string.valueOf( ThisRec.get('configuration__c') ) != null){
                ConfigIds.add(string.valueOf(ThisRec.get('configuration__c')));
            }
        }
        
        Map<Id, DUET__Configuration_Type__c> ConfigTypesMap = new Map<Id, DUET__Configuration_Type__c>();
        if(!ConfigIds.isEmpty()){
            List<DUET__Configuration_Type__c> ConfigTypes = [SELECT DUET__variationbypass__c, DUET__inboundenabled__c, DUET__configuration__r.Id 
                                                       from DUET__Configuration_Type__c WHERE DUET__objecttype__c = :MySObject AND DUET__configuration__c IN :ConfigIds]; 
            if(ConfigTypes != null){
                for(DUET__Configuration_Type__c CT : ConfigTypes){
                    ConfigTypesMap.put(CT.DUET__configuration__r.Id, CT);
                }
            }
        }
        
        for(sObject ThisRec : Trigger.new){
            if(ConfigTypesMap.containsKey(string.valueOf( ThisRec.get('configuration__c')))){
                DUET__Configuration_Type__c theConfig = ConfigTypesMap.get(string.valueOf( ThisRec.get('configuration__c')));
                if(theConfig.DUET__variationbypass__c && theConfig.DUET__inboundenabled__c) continue;
            }
            
            System.debug(string.valueOf( ThisRec.get('variationid__c') ));
            if(string.valueOf( ThisRec.get('variationid__c') ) == null){
                ThisRec.put('variationid__c', 0);
            }
            //Double check if Variation Oldmap is not NULL
            else if(double.valueOf(String.valueOf(Trigger.oldMap.get(String.valueOf( ThisRec.get('Id') )).variationid__c)) != NULL ){
                if( Double.valueof(string.valueOf( ThisRec.get('variationid__c') )) < double.valueOf(String.valueOf(Trigger.oldMap.get(String.valueOf( ThisRec.get('Id') )).variationid__c))){
                   ThisRec.addError('A new version of this BOD has already been processed.'); 
                }
            }
        }
    }
    
// --------------------------------------------------------------  END VARIATION ID CHECK  -------------------------------------------------------------- //
// --------------------------------------------------------------  START PRODUCTLOOKUP  -------------------------------------------------------------- //
    if(Trigger.IsBefore && (Trigger.IsUpdate || Trigger.IsInsert)){   
        map<String,Id> ProductsMap = new map<String,Id>();
        Set<String> ProdSet = new Set<String>();
        
        for(QuoteLineItem QLI: Trigger.new){
            if(QLI.Product_Write_In__c != Null){
                ProdSet.Add(QLI.Product_Write_In__c);
            }
        }
        
        for(Product2 p : [Select Id, Name, ProductCode, DUET__extrecordid__c, DUET__uniqueid__c From Product2 Where DUET__uniqueid__c IN: ProdSet]){
            ProductsMap.put(p.DUET__uniqueid__c, p.id);
        }
        
        for(QuoteLineItem ThisQLI : Trigger.new){
            if(ThisQLI.Product_Write_In__c != Null){
                if(ProductsMap.containsKey(ThisQLI.Product_Write_In__c)){
                    ThisQLI.Product2Id = ProductsMap.get(ThisQLI.Product_Write_In__c);
                }  
            }      
        }  
    }


// --------------------------------------------------------------  END PRODUCTLOOKUP  -------------------------------------------------------------- //
// -------------------------------------------------------------  START OUTBOUNDMESSAGE CREATION AND CONFIG CHECK --------------------------------------- //

    
    if(Trigger.IsAfter){
        if(DUET.checkRecursive.runOnce()){
            String ParentObject;
            String ParentField;
            
            ParentField = 'QuoteId';
            ParentObject = 'Quote';
    
    
            Map<String, Boolean> RemoveFromMap = new Map<String, Boolean>();
            Map<String, Boolean> UpdatedbyIntUser = new Map<String, Boolean>();
            Map<String, String> NewOBMAccAndConfigIds = new Map<String, String>();
            User u = [select Id, DUET__Default_Configuration__c from user where id=:userinfo.getuserid()];
            Id IntUser = [select Id, DUET__integrationuser__c from DUET__Configuration__c where DUET__active__c = true Limit 1].DUET__integrationuser__c;
            for(sObject ThisRec : Trigger.new){
                NewOBMAccAndConfigIds.put(String.valueOf(ThisRec.get(ParentField)), String.valueOf(ThisRec.get('configuration__c')));
                //UpdatedbyIntUser.put(ThisRec.erpquote__c, true);
                if((String.valueOf(ThisRec.get('acknowledgementtimestamp__c')) == null && String.valueOf(ThisRec.get('acknowledgementreceived__c')) == null) || (String.valueOf(ThisRec.get('acknowledgementtimestamp__c')) != null && String.valueOf(ThisRec.get('acknowledgementreceived__c')) != null)){    
                    RemoveFromMap.put(String.valueOf( ThisRec.get(ParentField) ), false);
                }
                else{
                    RemoveFromMap.put(String.valueOf( ThisRec.get(ParentField) ), true);
                }
                 if(Trigger.isUpdate && DateTime.valueOf(Trigger.newMap.get(String.valueOf( ThisRec.get('Id') )).acknowledgementreceived__c) != null && DateTime.valueOf(Trigger.oldMap.get(String.valueOf( ThisRec.get('Id') )).acknowledgementreceived__c) == null && IntUser == u.id){
                    UpdatedbyIntUser.put(String.valueOf( ThisRec.get(ParentField) ), true);
                }
                else if(IntUser == u.id){
                    UpdatedbyIntUser.put(String.valueOf( ThisRec.get(ParentField) ), true);
                }
                else{
                    UpdatedbyIntUser.put(String.valueOf( ThisRec.get(ParentField) ), false);
                }
                
            }
    
            DUET.OutboundMessageCreation.CreateMessage(NewOBMAccAndConfigIds, ParentObject, UpdatedbyIntUser, RemoveFromMap);
            
        }
    }
// --------------------------------------------------------------  END OUTBOUNDMESSAGE CREATION AND CONFIG CHECK --------------------------------------- //
}