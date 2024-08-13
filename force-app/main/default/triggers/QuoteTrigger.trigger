trigger QuoteTrigger on Quote (before insert, before update, after insert, after update) {
    QuoteTriggerHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate);
}