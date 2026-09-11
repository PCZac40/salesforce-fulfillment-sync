@isTest
private class AccountLockTriggerTest {

    @isTest
    static void testLockedFieldBlockedForNormalUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User normalUser = new User(
            FirstName = 'Normal',
            LastName = 'Tester',
            Email = 'normal.tester@example.com',
            Username = 'normal.tester' + DateTime.now().getTime() + '@example.com',
            Alias = 'normtu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );

        // Insert the User in its own runAs block to avoid mixing
        // setup-object DML with business-object DML in one transaction
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert normalUser;
        }

        Account acc = new Account(Name = 'Locked Test Co');
        insert acc;
        acc.Account_Status__c = 'Customer';
        update acc;

        Boolean exceptionThrown = false;

        System.runAs(normalUser) {
            acc.Name = 'Attempted Change';
            try {
                update acc;
            } catch (DmlException e) {
                exceptionThrown = true;
                System.assert(e.getMessage().contains('Name can only be updated by the ERP system'));
            }
        }

        System.assert(exceptionThrown, 'Expected the Name change to be blocked for a normal user.');
    }

    @isTest
    static void testLockedFieldAllowedWithBypassPermission() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];

        User bypassUser = new User(
            FirstName = 'Bypass',
            LastName = 'Tester',
            Email = 'bypass.tester@example.com',
            Username = 'bypass.tester' + DateTime.now().getTime() + '@example.com',
            Alias = 'byptu',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );

        PermissionSet erpPermSet = [
            SELECT Id FROM PermissionSet WHERE Name = 'ERP_Integration_User' LIMIT 1
        ];

        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert bypassUser;
            insert new PermissionSetAssignment(
                AssigneeId = bypassUser.Id,
                PermissionSetId = erpPermSet.Id
            );
        }

        Account acc = new Account(Name = 'Bypass Test Co');
        insert acc;
        acc.Account_Status__c = 'Customer';
        update acc;

        System.runAs(bypassUser) {
            acc.Name = 'Changed By ERP User';
            update acc; // should succeed without error
        }

        Account updatedAcc = [SELECT Name FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Changed By ERP User', updatedAcc.Name);
    }
}