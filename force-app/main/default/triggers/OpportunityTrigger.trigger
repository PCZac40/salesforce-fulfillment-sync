trigger OpportunityTrigger on Opportunity (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        OpportunityFulfillmentHandler.syncClosedWonDeals(Trigger.new, Trigger.oldMap);
    }
}