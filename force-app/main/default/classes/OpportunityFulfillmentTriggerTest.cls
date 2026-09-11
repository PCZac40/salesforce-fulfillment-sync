@isTest
private class OpportunityFulfillmentTriggerTest {
    
    @isTest
    static void testTriggerFiresOnClosedWon(){
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockResponse());
        
        Opportunity testOpp = new Opportunity(
        	Name = 'Trigger Test Deal',
            Amount = 7500,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Test.startTest();
        testOpp.StageName = 'Closed Won';
        update testOpp;
        Test.stopTest();
        
        Opportunity updatedOpp = [
            SELECT Fulfillment_Order_ID__c, Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id = :testOpp.Id
        ];
        
        System.assertEquals('Success', updatedOpp.Fulfillment_Sync_Status__c);
    }
    
    @isTest
    static void testTriggerDoesNotFireOnOtherChanges() {
        Opportunity testOpp = new Opportunity(
        	Name = 'New Trigger Deal',
            Amount = 3000,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;
        
        Test.startTest();
        testOpp.Amount = 4000;
        update testOpp;
        Test.stopTest();
        
        Opportunity updatedOpp = [
            SELECT Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id = :testOpp.Id
        ];
        
        System.assertEquals(null, updatedOpp.Fulfillment_Sync_Status__c);
    }

}