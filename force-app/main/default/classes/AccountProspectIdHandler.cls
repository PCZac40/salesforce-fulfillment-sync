public class AccountProspectIdHandler {
    public static void assignProspectId(List<Account> newAccounts) {
        for (Account acc : newAccounts) {
            if (String.isBlank(acc.ERP_Prospect_ID__c)) {
                acc.ERP_Prospect_ID__c = 'PROSPECT-' + String.valueOf(Uuid.randomUUID()).left(8).toUpperCase();
            }
        }
    }
}