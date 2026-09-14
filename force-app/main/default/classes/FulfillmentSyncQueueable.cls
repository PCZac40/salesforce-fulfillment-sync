public class FulfillmentSyncQueueable implements Queueable, Database.AllowsCallouts {
    private static final Integer MAX_CALLOUTS_PER_BATCH = 100;
    private List<Id> opportunityIdsToProcess;

    public FulfillmentSyncQueueable(Set<Id> opportunityIds) {
        this.opportunityIdsToProcess = new List<Id>(opportunityIds);
    }

    private FulfillmentSyncQueueable(List<Id> opportunityIds) {
        this.opportunityIdsToProcess = opportunityIds;
    }

    public static void enqueueSync(Set<Id> opportunityIds) {
        System.enqueueJob(new FulfillmentSyncQueueable(opportunityIds));
    }

    public void execute(QueueableContext context) {
        Integer batchSize = Math.min(MAX_CALLOUTS_PER_BATCH, opportunityIdsToProcess.size());
        List<Id> currentBatchIds = new List<Id>();
        for (Integer i = 0; i < batchSize; i++) {
            currentBatchIds.add(opportunityIdsToProcess[i]);
        }

        List<Opportunity> opps = [
            SELECT Id, Name, Amount, StageName, Shipping_Priority__c
            FROM Opportunity
            WHERE Id IN :currentBatchIds
        ];

        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Fulfillment_Sync_Log__c> logsToInsert = new List<Fulfillment_Sync_Log__c>();

        for (Opportunity opp : opps) {
            Fulfillment_Sync_Log__c log = new Fulfillment_Sync_Log__c(
                Opportunity__c = opp.Id,
                Sync_DateTime__c = System.now(),
                Name = 'Sync - ' + opp.Name
            );

            try {
                String externalOrderId = FulfillmentSyncService.sendFulfillmentOrder(opp);

                if (externalOrderId != null) {
                    opp.Fulfillment_Order_ID__c = externalOrderId;
                    opp.Fulfillment_Sync_Status__c = 'Success';

                    log.Status__c = 'Success';
                    log.External_Order_ID__c = externalOrderId;
                } else {
                    opp.Fulfillment_Sync_Status__c = 'Failed';
                    log.Status__c = 'Failed';
                    log.Error_Message__c = 'Callout completed but returned no usable order id.';
                }
            } catch (Exception e) {
                System.debug('Fulfillment sync threw an exception: ' + e.getMessage());
                opp.Fulfillment_Sync_Status__c = 'Failed';

                log.Status__c = 'Failed';
                log.Error_Message__c = e.getMessage();
            }
            oppsToUpdate.add(opp);
            logsToInsert.add(log);
        }

        update oppsToUpdate;
        insert logsToInsert;

        if (opportunityIdsToProcess.size() > batchSize) {
            List<Id> remainingIds = new List<Id>();
            for (Integer i = batchSize; i < opportunityIdsToProcess.size(); i++) {
                remainingIds.add(opportunityIdsToProcess[i]);
            }
            System.enqueueJob(new FulfillmentSyncQueueable(remainingIds));
        }
    }
}