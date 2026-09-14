public class AccountLockHandler {
    private static final Set<String> LOCKED_FIELDS = new Set<String>{
        'Name', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry', 'Phone'
    };

    public static void enforceFieldLock(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Boolean canBypassLock = FeatureManagement.checkPermission('Bypass_ERP_Account_Lock');
        if (canBypassLock) {
            return;
        }

        for (Account acc : newAccounts) {
            Account oldAcc = oldMap.get(acc.Id);
            if (oldAcc.Account_Status__c != 'Customer') {
                continue;
            }

            if (acc.Name != oldAcc.Name) {
                acc.Name.addError('This Account is a Customer of record. Name can only be updated by the ERP system.');
            }
            if (acc.BillingStreet != oldAcc.BillingStreet
               || acc.BillingCity != oldAcc.BillingCity
               || acc.BillingState != oldAcc.BillingState
               || acc.BillingPostalCode != oldAcc.BillingPostalCode
               || acc.BillingCountry != oldAcc.BillingCountry) {
               acc.BillingStreet.addError('Billing address can only be updated by the ERP system once this Account is an official Customer.');
            }
            if (acc.Phone != oldAcc.Phone) {
                acc.Phone.addError('Phone can only be updated by the ERP system once this Account is an official Customer.');
            }
        }
    }
}