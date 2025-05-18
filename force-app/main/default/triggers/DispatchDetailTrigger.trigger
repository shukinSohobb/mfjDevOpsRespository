trigger DispatchDetailTrigger on DispatchDetail__c(
    before insert,
    before update,
    before delete,
    after insert,
    after delete,
    after update,
    after undelete
    ) {
    new DispatchDetailTriggerHandler().run();
}