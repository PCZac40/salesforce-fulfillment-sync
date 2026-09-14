@RestResource(urlMapping='/accountERPSync/*')
global class AccountERPSyncAPI {
    
    @HttpPost
    global static void syncCustomer() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
        
        String erpProspectId = (String) body.get('erpProspectId');
        String customerNumber = (String) body.get('customerNumber');
        String creditTerms = (String) body.get('creditTerms');
        
        if (erpProspectId == null || customerNumber == null) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error": "erpProspectId and customerNumber are required"}');
            return;
        }
        
        // Only sync against an Account that already exists as a known prospect.
        // A customer should never be able to appear in Salesforce fo the
        // first time via this endpoint
        List<Account> matches = [
          SELECT Id, ERP_Prospect_Id__c
          FROM Account
          WHERE ERP_Prospect_ID__c = :erpProspectId
          LIMIT 1
        ];
        
        if (matches.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"error": "No matching prospect found for erpProspectId: ' + erpProspectId + '"}');
            return;
        }
        
        try {
            Account acc = matches[0];
            acc.ERP_Customer_Number__c = customerNumber;
            acc.Account_Status__c = 'Customer';
            acc.Customer_Since_Date__c = Date.today();
            if (creditTerms != null) { 
                acc.Credit_Terms__c = creditTerms;
            }
            update acc;
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"status": "success", "erpProspectId": "' + erpProspectId + '"}');
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
        
        }
    }

}