public class FulfillmentSyncQueueable implements Queueable, Database.AllowsCallouts {
    private Set<Id> opportunityIds;

    public FulfillmentSyncQueueable(Set<Id> opportunityIds) {
        this.opportunityIds = opportunityIds;
    }

    public static void enqueueSync(Set<Id> opportunityIds) {
        System.enqueueJob(new FulfillmentSyncQueueable(opportunityIds));
    }

    public void execute(QueueableContext context) {
        List<Opportunity> opps = [
            SELECT Id, Name, Amount, StageName
            FROM Opportunity
            WHERE Id IN :opportunityIds
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
                    log.Error_Message__c = 'Callout completed by returned no usable order id.';
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
    }
}