trigger RouteDeliveryTrigger on RouteDelivery__c(
    before insert,
    before update,
    before delete,
    after insert,
    after delete,
    after update,
    after undelete
) {
    new RouteDeliveryTriggerHandler().run();
}