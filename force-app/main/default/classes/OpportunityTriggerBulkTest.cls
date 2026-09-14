@isTest
private class OpportunityTriggerBulkTest {

    private static List<Opportunity> buildOpportunities(Integer count, String namePrefix) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opps.add(new Opportunity(
                Name = namePrefix + i,
                Amount = 1000 + i,
                StageName = 'Prospecting',
                CloseDate = Date.today()
            ));
        }
        return opps;
    }

        @isTest
    static void testBulkClosedWonAtSingleBatchBoundary() {
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockResponse());

        List<Opportunity> opps = buildOpportunities(100, 'Bulk ClosedWon Deal ');
        insert opps;

        for (Opportunity opp : opps) {
            opp.StageName = 'Closed Won';
        }

        Test.startTest();
        update opps;
        Test.stopTest();

        List<Opportunity> updated = [
            SELECT Id, Fulfillment_Sync_Status__c, Fulfillment_Order_ID__c
            FROM Opportunity
            WHERE Id IN :opps
        ];
        System.assertEquals(100, updated.size());
        for (Opportunity opp : updated) {
            System.assertEquals('Success', opp.Fulfillment_Sync_Status__c,
                'Expected every Closed Won transition at the single-batch limit to sync successfully.');
            System.assert(String.isNotBlank(opp.Fulfillment_Order_ID__c));
        }
    }

    @isTest
    static void testQueueableChainsAcrossMultipleBatches() {
        Test.setMock(HttpCalloutMock.class, new FulfillmentMockResponse());

        List<Opportunity> opps = buildOpportunities(200, 'Bulk Chain Deal ');
        insert opps;

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : opps) {
            oppIds.add(opp.Id);
        }

        Test.startTest();
        // Execute the first batch directly (not via System.enqueueJob) so our
        // one allowed test-context enqueueJob call is reserved for the chain
        // this method makes internally to process the remaining 100 records.
        new FulfillmentSyncQueueable(oppIds).execute(null);
        Test.stopTest();

        List<Opportunity> updated = [
            SELECT Id, Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id IN :opps
        ];
        System.assertEquals(200, updated.size());
        for (Opportunity opp : updated) {
            System.assertEquals('Success', opp.Fulfillment_Sync_Status__c,
                'Expected every record across both chained batches to sync successfully.');
        }
    }

    @isTest
    static void testBulkOtherFieldChangeDoesNotTriggerSync() {
        List<Opportunity> opps = buildOpportunities(200, 'Bulk NoSync Deal ');
        insert opps;

        for (Opportunity opp : opps) {
            opp.Amount = opp.Amount + 500;
        }

        Test.startTest();
        update opps;
        Test.stopTest();

        List<Opportunity> updated = [
            SELECT Id, Fulfillment_Sync_Status__c
            FROM Opportunity
            WHERE Id IN :opps
        ];
        System.assertEquals(200, updated.size());
        for (Opportunity opp : updated) {
            System.assertEquals(null, opp.Fulfillment_Sync_Status__c,
                'Expected no sync to occur for a non-stage-change update.');
        }
    }
}