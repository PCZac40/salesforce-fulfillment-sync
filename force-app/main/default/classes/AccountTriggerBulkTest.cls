@isTest
private class AccountTriggerBulkTest {

    private static User createNormalUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User normalUser = new User(
            FirstName = 'BulkNormal',
            LastName = 'Tester',
            Email = 'bulk.normal.tester@example.com',
            Username = 'bulk.normal.tester' + DateTime.now().getTime() + '@example.com',
            Alias = 'blknt',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert normalUser;
        }
        return normalUser;
    }

    private static User createBypassUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User bypassUser = new User(
            FirstName = 'BulkBypass',
            LastName = 'Tester',
            Email = 'bulk.bypass.tester@example.com',
            Username = 'bulk.bypass.tester' + DateTime.now().getTime() + '@example.com',
            Alias = 'blkbt',
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
        return bypassUser;
    }

    private static List<Account> buildAccounts(Integer count, String namePrefix, Boolean presetProspectId) {
        List<Account> accts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            Account acc = new Account(Name = namePrefix + i);
            if (presetProspectId) {
                acc.ERP_Prospect_ID__c = 'PRESET-' + i;
            }
            accts.add(acc);
        }
        return accts;
    }

    @isTest
    static void testBulkInsertGeneratesProspectIds() {
        List<Account> accts = buildAccounts(200, 'Bulk Insert Co ', false);

        Test.startTest();
        insert accts;
        Test.stopTest();

        List<Account> inserted = [
            SELECT Id, ERP_Prospect_ID__c FROM Account WHERE Id IN :accts
        ];
        System.assertEquals(200, inserted.size());

        Set<String> generatedIds = new Set<String>();
        for (Account acc : inserted) {
            System.assert(String.isNotBlank(acc.ERP_Prospect_ID__c),
                'Expected every bulk-inserted Account to receive a generated prospect ID.');
            System.assert(acc.ERP_Prospect_ID__c.startsWith('PROSPECT-'));
            generatedIds.add(acc.ERP_Prospect_ID__c);
        }
        System.assertEquals(200, generatedIds.size(),
            'Expected all 200 generated prospect IDs to be unique.');
    }

        @isTest
    static void testBulkInsertPreservesExistingProspectIds() {
        List<Account> accts = buildAccounts(200, 'Bulk Preset Co ', true);

        Test.startTest();
        insert accts;
        Test.stopTest();

        Map<String, Account> insertedByName = new Map<String, Account>();
        for (Account acc : [SELECT Id, Name, ERP_Prospect_ID__c FROM Account WHERE Id IN :accts]) {
            insertedByName.put(acc.Name, acc);
        }
        System.assertEquals(200, insertedByName.size());

        for (Integer i = 0; i < 200; i++) {
            Account acc = insertedByName.get('Bulk Preset Co ' + i);
            System.assertNotEquals(null, acc, 'Missing expected Account: Bulk Preset Co ' + i);
            System.assertEquals('PRESET-' + i, acc.ERP_Prospect_ID__c,
                'Preset prospect ID should not be overwritten by the trigger.');
        }
    }

    @isTest
    static void testBulkUpdateBlockedForNormalUser() {
        List<Account> accts = buildAccounts(200, 'Bulk Locked Co ', false);
        insert accts;
        for (Account acc : accts) {
            acc.Account_Status__c = 'Customer';
        }
        update accts;

        User normalUser = createNormalUser();

        List<Account> toUpdate = [SELECT Id, Name FROM Account WHERE Id IN :accts];
        for (Account acc : toUpdate) {
            acc.Name = acc.Name + ' - Attempted Change';
        }

        Test.startTest();
        List<Database.SaveResult> results;
        System.runAs(normalUser) {
            results = Database.update(toUpdate, false);
        }
        Test.stopTest();

        System.assertEquals(200, results.size());
        for (Database.SaveResult sr : results) {
            System.assert(!sr.isSuccess(),
                'Expected every locked-field update to be blocked for a normal user.');
            System.assert(sr.getErrors()[0].getMessage().contains('Name can only be updated by the ERP system'));
        }
    }

    @isTest
    static void testBulkUpdateAllowedWithBypassPermission() {
        List<Account> accts = buildAccounts(200, 'Bulk Bypass Co ', false);
        insert accts;
        for (Account acc : accts) {
            acc.Account_Status__c = 'Customer';
        }
        update accts;

        User bypassUser = createBypassUser();

        List<Account> toUpdate = [SELECT Id, Name FROM Account WHERE Id IN :accts];
        for (Account acc : toUpdate) {
            acc.Name = acc.Name + ' - ERP Update';
        }

        Test.startTest();
        List<Database.SaveResult> results;
        System.runAs(bypassUser) {
            results = Database.update(toUpdate, false);
        }
        Test.stopTest();

        System.assertEquals(200, results.size());
        for (Database.SaveResult sr : results) {
            System.assert(sr.isSuccess(),
                'Expected bypass-permission user to update locked fields successfully in bulk.');
        }

        List<Account> verified = [SELECT Name FROM Account WHERE Id IN :accts];
        for (Account acc : verified) {
            System.assert(acc.Name.endsWith('ERP Update'));
        }
    }
}