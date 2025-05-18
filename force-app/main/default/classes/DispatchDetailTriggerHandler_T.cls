@isTest
private class DispatchDetailTriggerHandler_T {
    @TestSetup
    static void makeData() {
        Account acc = TestDataFactory.createAccount('12345', false);
        insert acc;

        OriginDestination__c origin = TestDataFactory.createOriginDestination(acc.Id, false);
        origin.Name = 'Test origin';
        insert origin;
        OriginDestination__c destination = TestDataFactory.createOriginDestination(acc.Id, false);
        destination.Name = 'Test destination';
        insert destination;

        PriceTable__c priceTable = new PriceTable__c();
        priceTable.Name = 'Test';
        insert priceTable;

        ShippingFee__c shippingFee = new ShippingFee__c();
        shippingFee.PriceTable__c = priceTable.Id;
        shippingFee.ArrivalPrefecture__c = '13';
        insert shippingFee;

        OrderHeader__c order = new OrderHeader__c();
        order.Status__c = 'Reception';
        order.ShippingFee__c = shippingFee.Id;
        order.Account__c = acc.Id;
        order.OriginPlace__c = origin.Id;
        order.Destination__c = destination.Id;
        order.InvoiceAccount__c = acc.Id;
        order.UnitForShippingFeeCal__c = 'Case';
        insert order;

        DispatchDetail__c dispatchDetail = new DispatchDetail__c();
        dispatchDetail.OrderHeader__c = order.Id;
        insert dispatchDetail;
        update dispatchDetail;
    }
    @isTest
    public static void insertManualUpdateLogTest() {
        DispatchDetail__c dispatchDetail = [
            SELECT Id, ManualUpdateDatetime__c
            FROM DispatchDetail__c
            LIMIT 1
        ];

        Test.startTest();
        dispatchDetail.ManualUpdateNote__c = 'insertManualUpdateLogTest()による手動更新のデモ';
        update dispatchDetail;
        Test.stopTest();

        List<DispatchDetail__c> updatedDispatchDetails = [
            SELECT Id, ManualUpdateDatetime__c, ManualUpdateNote__c
            FROM DispatchDetail__c
            LIMIT 1
        ];

        List<BulkProcessLog__c> logs = [
            SELECT Id, ProcessType__c, ProcessDetails__c
            FROM BulkProcessLog__c
            WHERE ProcessType__c = 'RecordManualUpdate'
        ];

        System.debug('配車明細手動更新メモ' + updatedDispatchDetails[0].ManualUpdateNote__c);
        System.debug('ログ内容' + logs[0].ProcessDetails__c);
        Assert.areEqual(null, updatedDispatchDetails[0].ManualUpdateNote__c);
        Assert.areEqual('手動更新メモ: insertManualUpdateLogTest()による手動更新のデモ', logs[0].ProcessDetails__c);
    }
}