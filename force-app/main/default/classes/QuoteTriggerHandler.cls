public class QuoteTriggerHandler {
    
    public static void handleTrigger(List<Quote> newList, Map<Id, Quote> oldMap, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate) {
        if (isBefore) {
            if (isUpdate) {
                handleBeforeUpdate(newList, oldMap);
            }
            if (isInsert || isUpdate) {
                handleBeforeInsertOrUpdate(newList);
            }
        }
        
        if (isAfter) {
            if (isInsert || isUpdate) {
                handleAfterInsertOrUpdate(newList, oldMap, isInsert, isUpdate);
            }
        }
    }
    
    private static void handleBeforeUpdate(List<Quote> newList, Map<Id, Quote> oldMap) {
        for (Quote ThisRec : newList) {
            System.debug(String.valueOf(ThisRec.get('variationid__c')));
            if (String.valueOf(ThisRec.get('variationid__c')) == null) {
                ThisRec.put('variationid__c', 0);
            } else if (Double.valueOf(String.valueOf(oldMap.get(ThisRec.Id).get('variationid__c'))) != null) {
                if (Double.valueOf(String.valueOf(ThisRec.get('variationid__c'))) < Double.valueOf(String.valueOf(oldMap.get(ThisRec.Id).get('variationid__c')))) {
                    ThisRec.addError('A new version of this BOD has already been processed.');
                }
            }
        }	
        
        for (Quote Q : newList) {
            if (Q.Status == 'Accepted' && oldMap.get(Q.Id).Status != 'Accepted') {
                Q.sendtoerp__c = true;
            }
            if (Q.ERP_Status__c == null) {
                Q.ERP_Status__c = 'Open';
            }
        }
    }
    
    private static void handleBeforeInsertOrUpdate(List<Quote> newList) {
        Id IntegrationUser;
        User usr = [SELECT Id, DUET__Default_Configuration__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<DUET__Configuration__c> DefaultConfig = [SELECT Id, Name, DUET__integrationuser__c, DUET__fromlogicalid__c, DUET__extaccountingentityid__c FROM DUET__Configuration__c WHERE DUET__active__c = true ORDER BY CreatedDate ASC];
        Map<String, DUET__Configuration__c> Configs = new Map<String, DUET__Configuration__c>();
        Map<String, DUET__Configuration__c> ConfigsLogicalId = new Map<String, DUET__Configuration__c>();
        Map<Id, DUET__Configuration__c> ConfigsId = new Map<Id, DUET__Configuration__c>();
        IntegrationUser = DefaultConfig[0].DUET__integrationuser__c;
        
        for (DUET__Configuration__c c : DefaultConfig) {
            Configs.put(c.Name, c);
            ConfigsLogicalId.put(c.DUET__fromlogicalid__c, c);
            ConfigsId.put(c.Id, c);
        }
        
        for (Quote ThisRec : newList) {
            if (String.valueOf(ThisRec.get('Configuration__c')) != null) {
                ThisRec.put('extaccountingentityid__c', ConfigsId.get(String.valueOf(ThisRec.get('Configuration__c'))).DUET__extaccountingentityid__c);
                ThisRec.put('extlogicalid__c', ConfigsId.get(String.valueOf(ThisRec.get('Configuration__c'))).DUET__fromlogicalid__c);
            }
            if (IntegrationUser == usr.Id) {
                if (String.valueOf(ThisRec.get('Configuration__c')) == null) {
                    if (ConfigsLogicalId.containsKey(String.valueOf(ThisRec.get('extlogicalid__c')))) {
                        ThisRec.put('Configuration__c', ConfigsLogicalId.get(String.valueOf(ThisRec.get('extlogicalid__c'))).Id);
                        ThisRec.put('extaccountingentityid__c', ConfigsLogicalId.get(String.valueOf(ThisRec.get('extlogicalid__c'))).DUET__extaccountingentityid__c);
                        ThisRec.put('extlogicalid__c', ConfigsLogicalId.get(String.valueOf(ThisRec.get('extlogicalid__c'))).DUET__fromlogicalid__c);
                    } else {
                        ThisRec.addError('There is no Matching Configuration for the Logical Id');
                    }
                }
            } else if (String.valueOf(ThisRec.get('Configuration__c')) == null && String.valueOf(ThisRec.get('sendtoerp__c')) == 'true') {
                ThisRec.addError('Please select a Configuration before you send this Record to ERP');
            }
            
            if (String.valueOf(ThisRec.get('acknowledgementreceived__c')) != null) {
                ThisRec.put('acknowledgementtimestamp__c', System.now());
            }
        }
        
        Map<String, String> NewOBMAccAndConfigIds = new Map<String, String>();
        for (Quote ThisRec : newList) {
            NewOBMAccAndConfigIds.put(String.valueOf(ThisRec.get('Id')), String.valueOf(ThisRec.get('Configuration__c')));
        }
        
        String MySObject = newList[0].getSObjectType().getDescribe().getName();
        System.debug('MySObject' + MySObject);
        DUET.UpdateRecordwithRecordType.UpdateRecord(NewOBMAccAndConfigIds, MySObject, MySObject);
    }
    
    private static void handleAfterInsertOrUpdate(List<Quote> newList, Map<Id, Quote> oldMap, Boolean isInsert, Boolean isUpdate) {
        if (DUET.checkRecursive.runOnce()) {
            String type = newList[0].getSObjectType().getDescribe().getName();
            Map<String, Boolean> RemoveFromMap = new Map<String, Boolean>();
            Map<String, Boolean> UpdatedbyIntUser = new Map<String, Boolean>();
            Map<String, String> NewOBMAccAndConfigIds = new Map<String, String>();
            User u = [SELECT Id, DUET__Default_Configuration__c FROM User WHERE Id = :UserInfo.getUserId()];
            Id IntUser = [SELECT DUET__integrationuser__c FROM DUET__Configuration__c WHERE DUET__active__c = true LIMIT 1].DUET__integrationuser__c;
            
            for (Quote ThisRec : newList) {
                NewOBMAccAndConfigIds.put(String.valueOf(ThisRec.get('Id')), String.valueOf(ThisRec.get('Configuration__c')));
                System.debug('Configuration Integration User: ' + IntUser);
                
                if ((ThisRec.acknowledgementtimestamp__c == null && ThisRec.acknowledgementreceived__c == null) ||
                    (ThisRec.acknowledgementtimestamp__c != null && ThisRec.acknowledgementreceived__c != null)) {
                        RemoveFromMap.put(String.valueOf(ThisRec.get('Id')), false);
                    } else {
                        RemoveFromMap.put(String.valueOf(ThisRec.get('Id')), true);
                    }
                
                if (ThisRec.acknowledgementreceived__c != null && oldMap.get(ThisRec.Id).acknowledgementreceived__c == null && IntUser == u.Id) {
                    UpdatedbyIntUser.put(String.valueOf(ThisRec.get('Id')), true);
                } else if (IntUser == u.Id) {
                    UpdatedbyIntUser.put(String.valueOf(ThisRec.get('Id')), true);
                } else {
                    UpdatedbyIntUser.put(String.valueOf(ThisRec.get('Id')), false);
                }
            }
            
            if (isInsert || isUpdate) {
                DUET.UpdateRecordwithConfig.UpdateRecord(NewOBMAccAndConfigIds, u, type);
                DUET.UpdateRecordwithUniqueId.UpdateRecord(NewOBMAccAndConfigIds, type);
            }
            
            DUET.OutboundMessageCreation.CreateMessage(NewOBMAccAndConfigIds, type, UpdatedbyIntUser, RemoveFromMap);
        }
    }
}