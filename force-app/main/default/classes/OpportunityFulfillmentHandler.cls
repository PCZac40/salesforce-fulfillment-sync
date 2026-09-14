public class OpportunityFulfillmentHandler {
    public static void syncClosedWonDeals(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        Set<Id> oppIdsToSync = new Set<Id>();

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                oppIdsToSync.add(opp.Id);
            }
        }

        if (!oppIdsToSync.isEmpty()) {
            FulfillmentSyncQueueable.enqueueSync(oppIdsToSync);
        }
    }
}