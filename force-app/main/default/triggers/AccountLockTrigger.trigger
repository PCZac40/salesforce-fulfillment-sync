trigger AccountLockTrigger on Account (before update) {
    
    // Users/integrations with this Custom Permission can edit locked
    // fields even after an Account becomes an official Customer.
    Boolean canBypassLock = FeatureManagement.checkPermission('Bypass_ERP_Account_Lock');
    
    if (canBypassLock) {
        return; // integration context - no restrictions
    }
    
    Set<String> lockedFields = new Set<String>{
        'Name', 'BillingStreet', 'BillingCity', 'BillingState', 'BillingPostalCode', 'BillingCountry', 'Phone'
    };
        
        for (Account acc : Trigger.new) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            // Only enforce the lock on Accounts that are already Customers
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