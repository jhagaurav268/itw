public with sharing class SearchAccountController {
    @AuraEnabled(cacheable = true)
    public static List<Account> SearchAccounts(String inputPinCode) {
        String objectApiName = 'Account';
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        if(String.isNotBlank(inputPinCode)){
            if (objectDescribe.isQueryable()) {
                Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
                
                String query = 'SELECT ';
                Boolean isFirstField = true;
                
                for (String fieldName : fieldMap.keySet()) {
                    if (!isFirstField) {
                        query += ', ';
                    }
                    query += fieldName;
                    isFirstField = false;
                }
                List<String> inputList = inputPinCode.replace(' ', '').split(',');
                query += ' FROM ' + objectApiName + 
                    ' WHERE Id IN (SELECT AccountId FROM Contact) ' +
                    'AND (BillingPostalCode IN :inputList OR BillingCity IN :inputList OR BillingState IN :inputList)';
                
                List<SObject> records = Database.query(query);
                
                return records;
            } else {
                System.debug('The object ' + objectApiName + ' is not queryable.');
                return null;
            }
        } else {
            return null;
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static List<AggregateResult> searchContacts(List<String> accountId){ 
        System.debug('accountId ' + accountId);
        List<AggregateResult> contactList = [Select AccountId, Name names, Id, Email, Account.Name From Contact WHERE AccountId IN :accountId AND Email != null GROUP BY Id, AccountId, Account.Name, Email, Name Order By Account.Name];
        System.debug('contactList ' + contactList);
        return contactList;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<Emailtemplate> getAllEmailTemplates(){
        List<Emailtemplate> storeEmailTemplates = [SELECT Id, Name, Subject, Body, Folder.Name FROM Emailtemplate WHERE Folder.Name = 'Mass Email'];
        return storeEmailTemplates;
    }
    
    @AuraEnabled
    public static void createCustomEmailTemplate(String subject, String body, String emailTemplateType, String templateName, String letterHead, String templateStyleValue){
        System.debug('body '+ body);
        Emailtemplate et = new Emailtemplate();
        et.Subject = subject;
        et.FolderId = UserInfo.getUserId();
        et.Name = templateName;// String.valueOf(DateTime.now());
        et.DeveloperName = templateName.replace(' ','');
        switch on emailTemplateType{
            when 'Text'{
                et.TemplateType = 'text';
                et.Body = body;
            }
            when 'HTML'{
                et.TemplateType = 'html';
                et.HtmlValue = '<html><body>' +  body + '</body></html>';
                et.BrandTemplateId = letterHead;
                et.TemplateStyle = templateStyleValue;
            }
            when 'Visualforce'{
                et.TemplateType = 'visualforce';
                et.Body = body;
            }
            when 'custom'{
                et.TemplateType = 'text';
                et.Body = body;
            }
        }
        insert et;
    }
    
    @AuraEnabled(cacheable = true)
    public static List<BrandTemplate> getAllEmailLetterheads(){
        List<BrandTemplate> storeEmailLetterheads = [SELECT Id, Name, DeveloperName FROM BrandTemplate];
        return storeEmailLetterheads;
    }
    
    @AuraEnabled(cacheable = true)
    public static Map<String, List<Map<String, String>>> getPicklistValuesByField(String objectApiName) {
        System.debug('objectApiName ' + objectApiName);
        Map<String, List<Map<String, String>>> picklistMap = new Map<String, List<Map<String, String>>>();
        
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).getDescribe();
        
        for (Schema.SObjectField field : objectDescribe.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            
            if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
                List<Map<String, String>> picklistValuesList = new List<Map<String, String>>();
                
                List<Schema.PicklistEntry> picklistValues = fieldDescribe.getPicklistValues();
                
                for (Schema.PicklistEntry entry : picklistValues) {
                    Map<String, String> picklistEntryMap = new Map<String, String>();
                    picklistEntryMap.put('label', entry.getLabel());
                    picklistEntryMap.put('value', entry.getValue());
                    picklistValuesList.add(picklistEntryMap);
                }
                
                picklistMap.put(fieldDescribe.getName(), picklistValuesList);
            }
        }
        return picklistMap;
    }
    
    @AuraEnabled
    public static boolean sendEmailToContacts(Map<String, Object> contactMap, List<Map<String, String>> filesData) {
        System.debug('contactMap ' + contactMap);
        String templateName = (String) contactMap.get('templateName');
        System.debug('templateName ' + templateName);
        String subject = (String) contactMap.get('subject');
        String body = (String) contactMap.get('body');
        System.debug('body ' + body);
        List<Object> contactIdsObjects = (List<Object>) contactMap.get('contactIds');
        List<String> contactIds = new List<String>();
        for (Object conId : contactIdsObjects) {
            contactIds.add((String) conId);
        }
        
        boolean isEmailSent = sendEmailDirectly(subject, body, contactIds, filesData, templateName);
        return isEmailSent;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ContentVersion> getFilesFromSalesforce() {
        return [SELECT Id, Title, ContentSize, FileExtension, CreatedDate, ContentDocumentId
                FROM ContentVersion
                LIMIT 100];
    }
    
    public String Id;
    public String Title;
    public Integer ContentSize;
    public String FileExtension;
    public DateTime CreatedDate;
    public String VersionDataBase64;
    public String ContentDocumentId;
    
    public SearchAccountController(ContentVersion cv, String versionDataBase64) {
        this.Id = cv.Id;
        this.Title = cv.Title;
        this.ContentSize = cv.ContentSize;
        this.FileExtension = cv.FileExtension;
        this.CreatedDate = cv.CreatedDate;
        this.VersionDataBase64 = versionDataBase64;
        this.ContentDocumentId = cv.ContentDocumentId;
    }
    
    @AuraEnabled
    public static Map<String, Object> getSelectedFilesFromSalesforce(List<String> selectedFileIds) {
        Map<String, SearchAccountController> cVMap = new Map<String, SearchAccountController>();
        List<ContentVersion> CVList = [SELECT Id, Title, ContentSize, FileExtension, CreatedDate, VersionData, ContentDocumentId
                                       FROM ContentVersion 
                                       WHERE Id IN :selectedFileIds
                                       LIMIT 100];
        
        for (ContentVersion cv : CVList) {
            String versionDataBase64 = EncodingUtil.base64Encode(cv.VersionData);
            SearchAccountController wrapper = new SearchAccountController(cv, versionDataBase64);
            cVMap.put(cv.Id, wrapper);
        }
        
        System.debug('cVMap===' + cVMap);
        return cVMap;
    }
    
    
    
    private static boolean sendEmailDirectly(String Subject, String body, List<String> contactIds, List<Map<String, String>> filesData, String templateName){
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Contact> contacts = [Select Id, Name, Email, Contact.AccountId From Contact Where Id IN :contactIds];
        
        String currentUserEmail = UserInfo.getUserEmail();
        Emailtemplate storeEmailTemplates = [SELECT Id, Name, Subject, Body FROM Emailtemplate WHERE Name =: templateName];
        //List<String> ccEmails = new List<String>{'gaurav@cloudsciencelabs.com', 'udit@cloudsciencelabs.com', 'mayank@cloudsciencelabs.com', 'prajjwal@cloudsciencelabs.com', 'priya@cloudsciencelabs.com', 'roshni@cloudsciencelabs.com', 'rajat@cloudsciencelabs.com', 'rahul@cloudsciencelabs.com', 'pavitra@cloudsciencelabs.com', 'ashish@cloudsciencelabs.com', 'siddharth@cloudsciencelabs.com'};
        for (Contact con : contacts) {
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setToAddresses(new String[] { con.Email });
            //emailMessage.setCcAddresses(ccEmails);
            emailMessage.setCcAddresses(new String[] { currentUserEmail });
            //emailMessage.setSubject(subject);
            emailMessage.setTemplateId(storeEmailTemplates.Id);
            emailMessage.setTargetObjectId(con.Id);
            emailMessage.setWhatId(con.AccountId);
            
            // Attachments
            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            for (Map<String, String> fileData : filesData) {
                Messaging.EmailFileAttachment emailAttachment = new Messaging.EmailFileAttachment();
                emailAttachment.setFileName(fileData.get('filename'));
                emailAttachment.setBody(EncodingUtil.base64Decode(fileData.get('base64')));
                emailAttachment.setContentType(fileData.get('mimeType'));
                attachments.add(emailAttachment);
            }
            emailMessage.setFileAttachments(attachments);
            emails.add(emailMessage); 
        }	
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
            return true;
        } else {
            return false;
        }
    }
}