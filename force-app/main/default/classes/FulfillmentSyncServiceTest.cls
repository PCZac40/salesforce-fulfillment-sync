@isTest
private class FulfillmentSyncServiceTest {
    
    @isTest
    static void testSendFulfillmentOrder_Success() {
        // Tell Apex to use our fake response instead of a real callout
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockResponse());
        
        Opportunity testOpp = new Opportunity(
        	Name = 'Test Deal',
            Amount = 5000,
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Test.startTest();
        FulfillmentSyncService.sendFulfillmentOrder(testOpp);
        Test.stopTest();
        
        // If we got here without an exception, the callout logic ran successfully
        // (In a more advanced version, we'd assert against a field the method updates)
    }

}