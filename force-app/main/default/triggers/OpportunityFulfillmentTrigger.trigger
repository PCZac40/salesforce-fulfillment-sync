trigger OpportunityFulfillmentTrigger on Opportunity (after update) {
    Set<Id> oppIdsToSync = new Set<Id>();
    
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        // Only fire when the Stage actually CHANGES to Closed Won
        // (not every time someone edits an already-closed deal)
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            oppIdsToSync.add(opp.Id);
        }
    }
    
    if (!oppIdsToSync.isEmpty()) {
        FulfillmentSyncQueueable.enqueueSync(oppIdsToSync);
    }

}