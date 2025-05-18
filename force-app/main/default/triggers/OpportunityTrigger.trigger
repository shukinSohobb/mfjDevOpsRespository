trigger OpportunityTrigger on Opportunity(
    before insert,
    before update,
    before delete,
    after insert,
    after delete,
    after update,
    after undelete
) {
    new OpportunityTriggerHandler().run();
}