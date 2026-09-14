@isTest
private class AccountERPSyncAPITest {
    
    @isTest
    static void testSyncCustomer_Success() {
        Account prospect = new Account(Name = 'Prospect Test Co');
        insert prospect;
        
        Account insertedProspect = [
            SELECT Id, ERP_Prospect_ID__c
            FROM Account
            WHERE Id = :prospect.Id
        ];
        
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accountERPSync';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'erpProspectId' => insertedProspect.ERP_Prospect_ID__c,
            'customerNumber' => 'CUST-9001',
            'creditTerms' => 'Net 30'
        }));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        AccountERPSyncAPI.syncCustomer();
        Test.stopTest();
        System.debug('RESPONSE BODY: ' + RestContext.response.responseBody.toString());
        
        System.assertEquals(200, RestContext.response.statusCode, 'Response was: ' + RestContext.response.responseBody.toString());
        
        Account updatedAcc = [
            SELECT ERP_Customer_Number__c, Account_Status__c, Customer_Since_Date__c, Credit_Terms__c
            FROM Account
            WHERE Id = :prospect.Id
        ];
        
        System.assertEquals('CUST-9001', updatedAcc.ERP_Customer_Number__c);
        System.assertEquals('Customer', updatedAcc.Account_Status__c);
        System.assertEquals(Date.today(), updatedAcc.Customer_Since_Date__c);
        System.assertEquals('Net 30', updatedAcc.Credit_Terms__c);
    }
    
    @isTest
    static void testSyncCustomer_NoMatchingProspect() {
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accountERPSync/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'erpProspectId' => 'PROSPECT-DOESNOTEXIST',
            'customerNumber' => 'CUST-9002'
        }));
            
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        AccountERPSyncAPI.syncCustomer();
        Test.stopTest();
        
        System.assertEquals(404, RestContext.response.statusCode);
        
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('No matching prospect found'));
    }
    
    @isTest
    static void testSyncCustomer_MissingParameteres(){
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/accountERPSync/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'erpProspectId' => 'PROSPECT-12345'
            // customerNumber intentionally omitted
        }));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        Test.startTest();
        AccountERPSyncAPI.syncCustomer();
        Test.stopTest();
        
        System.assertEquals(400, RestContext.response.statusCode);
    }

}