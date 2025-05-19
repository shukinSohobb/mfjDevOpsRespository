trigger OrderHeaderTrigger on OrderHeader__c(
  before insert,
  before update,
  before delete,
  after insert,
  after delete,
  after update,
  after undelete
) {
  new OrderHeaderTriggerHandler().run();
}