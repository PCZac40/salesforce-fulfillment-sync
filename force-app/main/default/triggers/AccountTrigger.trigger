trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountProspectIdHandler.assignProspectId(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        AccountLockHandler.enforceFieldLock(Trigger.new, Trigger.oldMap);
    }
}