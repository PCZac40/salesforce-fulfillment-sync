@isTest
private class FulfillmentSyncQueueableTest {
    
    @isTest
    static void testEnqueueSync_Success() {
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockResponse());
        
        Opportunity testOpp = new Opportunity(
        	Name = 'Test Deal - Success',
            Amount = 5000,
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            Shipping_Priority__c = 'Expedited'
        );
        insert testOpp;
        
        Test.startTest();
        FulfillmentSyncQueueable.enqueueSync(new Set<Id>{ testOpp.Id });
        Test.stopTest();

        System.assert(FulfillmentMockResponse.lastRequestBody.contains('Expedited'),
        'Expected the payload sent to the external system to include the shipping priority.');
        
        Opportunity updatedOpp = [
            SELECT Fulfillment_Order_Id__c, Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id = :testOpp.Id
        ];
        
        System.assertEquals('101', updatedOpp.Fulfillment_Order_Id__c);
        System.assertEquals('Success', updatedOpp.Fulfillment_Sync_Status__c);
        
        //Verify the log record was created correctly
        List<Fulfillment_Sync_Log__c> logs = [
            SELECT Status__c, External_Order_ID__c
            FROM Fulfillment_Sync_Log__c
            WHERE Opportunity__c = :testOpp.Id
        ];
        System.assertEquals(1, logs.size());
        System.assertEquals('Success', logs[0].Status__c);
        System.assertEquals('101', logs[0].External_Order_ID__c);
    }
    
    @isTest
    static void testEnqueueSync_Failure(){
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockFailureResponse());
        
        Opportunity testOpp = new Opportunity (
        	Name = 'Test Deal - Failure',
            Amount = 5000,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Test.startTest();
           FulfillmentSyncQueueable.enqueueSync(new Set<Id>{ testOpp.Id });
        Test.stopTest();
        
        Opportunity updatedOpp = [
            SELECT Fulfillment_Order_ID__c, Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id = :testOpp.Id
        ];
        
        System.assertEquals(null, updatedOpp.Fulfillment_Order_ID__c);
        System.assertEquals('Failed', updatedOpp.Fulfillment_Sync_Status__c);
        
        //Verify the log record failed
        List<Fulfillment_Sync_Log__c> logs = [
            SELECT Status__c, Error_Message__c
            FROM Fulfillment_Sync_Log__c
            WHERE Opportunity__c = :testOpp.Id
        ];
        System.assertEquals(1, logs.size());
        System.assertEquals('Failed', logs[0].Status__c);
        System.assertNotEquals(null, logs[0].Error_Message__c);
    }

}