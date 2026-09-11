trigger AccountProspectIdTrigger on Account (before insert) {
    for(Account acc : Trigger.new) {
        if (String.isBlank(acc.ERP_Prospect_ID__c)) {
            acc.ERP_Prospect_ID__c = 'PROSPECT-' + String.valueOf(Uuid.randomUUID()).left(8).toUpperCase();
        }
    }

}