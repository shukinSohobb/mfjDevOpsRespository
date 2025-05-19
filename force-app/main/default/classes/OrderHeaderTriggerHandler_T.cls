@isTest
private class OrderHeaderTriggerHandler_T {
    @TestSetup
    static void makeData() {
        Account acc = TestDataFactory.createAccount('12345', false);
        acc.AllocationPriority__c = 'ExpirationDate';
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
        update order;

        ProductMaster__c product = new ProductMaster__c();
        product.Name = 'TestProduct';
        product.ProductCode__c = 'Test';
        product.ProductManagementCategory__c = '4';
        // product.AllocableQuantity__c = 10;
        product.StandardUnit__c = 'Piece';
        product.Account__c = acc.Id;
        insert product;

        OrderDetail__c orderDetail = new OrderDetail__c();
        orderDetail.Account__c = acc.Id;
        orderDetail.OrderHeader__c = order.Id;
        orderDetail.ProductMaster__c = product.Id;
        orderDetail.Quantity__c = 9;
        insert orderDetail;

        WarehouseMaster__c wm = new WarehouseMaster__c();
        wm.Name = 'TestSouko';
        wm.WarehouseCode__c = 'Test';
        insert wm;

        ProductStockInfo__c psi = new ProductStockInfo__c();
        psi.WarehouseMaster__c = wm.Id;
        psi.ProductMaster__c = product.Id;
        psi.ArrivalQuantity__c = 10;
        psi.ArrivalDate__c = Date.today() - 1;
        psi.AllocatedQuantity__c = 0;
        psi.ExpirationDate__c = Date.today() - 100;
        insert psi;

        ProductStockInfo__c psi2 = new ProductStockInfo__c();
        psi2.WarehouseMaster__c = wm.Id;
        psi2.ProductMaster__c = product.Id;
        psi2.ArrivalQuantity__c = 10;
        psi2.ArrivalDate__c = Date.today();
        psi2.AllocatedQuantity__c = 0;
        psi2.ExpirationDate__c = Date.today() - 100;
        insert psi2;
    }

    // 注文明細の数量　＜在庫情報の引き当て可能数
    // 結果：ピッキングリストが作成される
    @isTest
    public static void lotAutoAllocateTest_StockLarger_PickingCreated() {
        OrderHeader__c order = [SELECT Id, Status__c FROM OrderHeader__c LIMIT 1];
        OrderDetail__c orderDetail = [SELECT Id, Quantity__c FROM OrderDetail__c LIMIT 1];
        ProductStockInfo__c psi = [SELECT Id, AllocableQuantity_F__c FROM ProductStockInfo__c LIMIT 1];

        Test.startTest();
        order.Status__c = 'ReceptionCompleted';
        order.ExpectedDeliveryDate__c = Date.today();
        order.LoadingDate__c = Date.today() + 10;
        update order;
        Test.stopTest();

        List<PickingList__c> pl = [
            SELECT
                Id,
                OrderHeader__c,
                OrderHeader__r.FirstWarehouseMaster__c,
                OrderDetail__c,
                Quantity__c,
                ProductStockInfo__c,
                ProductStockInfo__r.WarehouseMaster__c
            FROM PickingList__c
        ];

        Assert.areEqual(1, pl.size());
        Assert.areEqual(order.Id, pl[0].OrderHeader__c);
        Assert.areEqual(orderDetail.Id, pl[0].OrderDetail__c);
        Assert.areEqual(orderDetail.Quantity__c, pl[0].Quantity__c);
        Assert.areEqual(psi.Id, pl[0].ProductStockInfo__c);
        Assert.areEqual(pl[0].OrderHeader__r.FirstWarehouseMaster__c, pl[0].ProductStockInfo__r.WarehouseMaster__c);
    }

    // 注文明細の数量　＞在庫情報の引き当て可能数
    // 結果：未引当のピッキングのピッキングリストが作成される
    @isTest
    public static void lotAutoAllocateTest_orderDetailLarger_remainingPickingListCreated() {
        OrderHeader__c order = [SELECT Id, Status__c FROM OrderHeader__c LIMIT 1];
        OrderDetail__c orderDetail = [SELECT Id, Quantity__c FROM OrderDetail__c LIMIT 1];
        orderDetail.Quantity__c = 11;
        update orderDetail;

        Test.startTest();
        order.Status__c = 'ReceptionCompleted';
        order.ExpectedDeliveryDate__c = Date.today();
        order.LoadingDate__c = Date.today() + 10;
        update order;
        Test.stopTest();

        List<PickingList__c> pl = [
            SELECT
                Id,
                OrderHeader__c,
                OrderHeader__r.FirstWarehouseMaster__c,
                OrderDetail__c,
                Quantity__c,
                ProductStockInfo__c,
                RemainingQuantity_F__c
            FROM PickingList__c
        ];

        Assert.areEqual(1, pl.size());
        Assert.areEqual(orderDetail.Quantity__c, pl[0].RemainingQuantity_F__c);
        Assert.areEqual(null, pl[0].Quantity__c);
        Assert.areEqual(null, pl[0].ProductStockInfo__c);
    }

    // 在庫情報がない
    //　結果：ピッキングリストの「数量」＝NULL
    @isTest
    public static void lotAutoAllocateTest_NoProductStockInfo_QuantityNull() {
        OrderHeader__c order = [SELECT Id, Status__c FROM OrderHeader__c LIMIT 1];
        OrderDetail__c orderDetail = [SELECT Id, Quantity__c FROM OrderDetail__c LIMIT 1];
        List<ProductStockInfo__c> psiList = [SELECT Id FROM ProductStockInfo__c];

        Test.startTest();
        delete psiList;
        order.Status__c = 'ReceptionCompleted';
        order.ExpectedDeliveryDate__c = Date.today();
        order.LoadingDate__c = Date.today() + 10;
        update order;
        Test.stopTest();

        List<PickingList__c> pl = [
            SELECT Id, OrderHeader__c, OrderDetail__c, Quantity__c, ProductStockInfo__c
            FROM PickingList__c
        ];

        Assert.areEqual(1, pl.size());
        Assert.areEqual(order.Id, pl[0].OrderHeader__c);
        Assert.areEqual(orderDetail.Id, pl[0].OrderDetail__c);
        Assert.areEqual(null, pl[0].Quantity__c);
        Assert.areEqual(null, pl[0].ProductStockInfo__c);
    }

    // 注文明細と1番の在庫情報の指定情報は一致しない
    // 注文明細と2番の在庫情報の指定情報は一致する
    // 1番の注文明細と2番の注文明細の指定情報は一致しない
    // 期待結果：注文明細のピッキングリストは引き当てができる。ピッキングリストは2番在庫情報に参照。
    @isTest
    public static void lotAutoAllocateTest_specifiedDetailMatchingStock_pickinglistCreated() {
        // 商品の取得
        ProductMaster__c product = [SELECT Id FROM ProductMaster__c LIMIT 1];
        // 注文の取得
        OrderHeader__c order = [SELECT Id, Status__c FROM OrderHeader__c LIMIT 1];
        OrderDetail__c orderDetail = [
            SELECT Id, Account__c, Quantity__c, ExpirationDate__c, LotNumber_F__c
            FROM OrderDetail__c
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocableQuantity_F__c, LotNumber__c
            FROM ProductStockInfo__c
            LIMIT 1
        ];
        ProductStockInfo__c psi2 = [
            SELECT Id, AllocableQuantity_F__c, LotNumber__c
            FROM ProductStockInfo__c
            WHERE Id != :psi.Id
            LIMIT 1
        ];

        Test.startTest();
        psi.ExpirationDate__c = Date.today() + 1;
        update psi;
        psi2.ExpirationDate__c = Date.today();
        update psi2;
        orderDetail.ExpirationDate__c = Date.today();
        update orderDetail;
        order.Status__c = 'ReceptionCompleted';
        order.ExpectedDeliveryDate__c = Date.today();
        order.LoadingDate__c = Date.today() + 10;
        update order;
        Test.stopTest();

        // 更新された注文明細を取得
        orderDetail = [
            SELECT Id, OrderHeader__c, Quantity__c, ExpirationDate__c, LotNumber_F__c
            FROM OrderDetail__c
            WHERE Id = :orderDetail.Id
            LIMIT 1
        ];

        psi2 = [
            SELECT Id, AllocableQuantity_F__c, LotNumber__c
            FROM ProductStockInfo__c
            WHERE Id != :psi.Id
            LIMIT 1
        ];

        // 作成されたピッキングリストを取得
        List<PickingList__c> pl = [
            SELECT Id, OrderHeader__c, OrderDetail__c, Quantity__c, ProductStockInfo__c
            FROM PickingList__c
        ];

        Assert.areEqual(1, pl.size()); // 1件のピッキングリストが作成された

        // 1番の注文明細とピッキングリスト
        Assert.areNotEqual(orderDetail.LotNumber_F__c, psi.LotNumber__c); // 注文明細と最初の在庫情報の「指定情報」は一致しない
        Assert.areEqual(orderDetail.LotNumber_F__c, psi2.LotNumber__c); // 注文明細と2番在庫情報の「指定情報」は一致する
        Assert.areEqual(orderDetail.Id, pl[0].OrderDetail__c); // ピッキングリストの注文明細の確認
        Assert.areEqual(orderDetail.OrderHeader__c, pl[0].OrderHeader__c); // 作成されたピッキングリストの注文は注文明細の注文
        Assert.areEqual(psi2.Id, pl[0].ProductStockInfo__c); // 2番在庫情報の「指定情報」は一致しているから、そのレコードに参照
        Assert.areEqual(orderDetail.Quantity__c, pl[0].Quantity__c); // ピッキングリストの「数量」は注文明細の「数量」
    }

    // 注文明細は指定がある
    // 指定情報と一致する在庫情報がない
    // 在庫情報：未引当のピッキングリストが作成される
    @isTest
    public static void lotAutoAllocateTest_specifiedDetailNoMatchingStock_remainingPickinglistCreated() {
        OrderHeader__c order = [SELECT Id, Status__c FROM OrderHeader__c LIMIT 1];
        OrderDetail__c orderDetail = [
            SELECT Id, Quantity__c, ExpirationDate__c
            FROM OrderDetail__c
            LIMIT 1
        ];

        Test.startTest();
        orderDetail.ExpirationDate__c = Date.today();
        update orderDetail;
        order.Status__c = 'ReceptionCompleted';
        order.ExpectedDeliveryDate__c = Date.today();
        order.LoadingDate__c = Date.today() + 10;
        update order;
        Test.stopTest();

        // 作成されたピッキングリストを取得
        List<PickingList__c> pl = [
            SELECT Id, OrderHeader__c, OrderDetail__c, Quantity__c, ProductStockInfo__c, RemainingQuantity_F__c
            FROM PickingList__c
        ];
        // 指定情報と一致する在庫情報がないから、ピッキングリストが作成される
        Assert.areEqual(1, pl.size());
        Assert.areEqual(orderDetail.Quantity__c, pl[0].RemainingQuantity_F__c);
        Assert.areEqual(null, pl[0].Quantity__c);
        Assert.areEqual(null, pl[0].ProductStockInfo__c);
    }

    /*
        input & 前提条件
        - 注文レコードの手動更新フラグをON、手動更新メモを記述。
        - 注文の高速フローによってレコード更新後、beforeトリガー実行。

        Output
        - 手動更新メモがnullになった注文レコード
        - 一括処理ログの確認
            - 処理内容が下記になっていること
                注文レコードの更新 {注文レコードの手動更新日時}
                更新されたレコードの内容：{注文レコードのカスタムオブジェクトID}
                手動更新メモ: insertManualUpdateLogTest()による手動更新のデモ
    */
    @isTest
    public static void insertManualUpdateLogTest() {
        OrderHeader__c order = [
            SELECT Id, Status__c, ManualUpdateDatetime__c
            FROM OrderHeader__c
            LIMIT 1
        ];

        Test.startTest();
        order.ManualUpdateFlag__c = true;
        order.ManualUpdateNote__c = 'insertManualUpdateLogTest()による手動更新のデモ';
        update order;
        Test.stopTest();

        List<OrderHeader__c> updatedOrders = [
            SELECT Id, Status__c, ManualUpdateDatetime__c, ManualUpdateNote__c
            FROM OrderHeader__c
            LIMIT 1
        ];

        List<BulkProcessLog__c> logs = [
            SELECT Id, ProcessType__c, ProcessDetails__c
            FROM BulkProcessLog__c
            WHERE ProcessType__c = 'RecordManualUpdate'
        ];

        Assert.areEqual(null, updatedOrders[0].ManualUpdateNote__c);
        Assert.areEqual('手動更新メモ: insertManualUpdateLogTest()による手動更新のデモ', logs[0].ProcessDetails__c);
    }

    // 他の注文がない。新規注文を作成。
    // 結果：作成された注文の名前に、日付の部分と番号の部分を確認。形式：{（今日）YYMMDD}{00001}
    @isTest
    public static void orderHeaderNamingTest_firstOrderToday_numberIs1() {
        // 今日の注文を削除
        List<OrderHeader__c> oldOrders = [SELECT Id FROM OrderHeader__c];
        delete oldOrders;

        // 新規注文を作成
        OrderHeader__c newOrder = new OrderHeader__c();
        Test.startTest();
        insert newOrder;
        Test.stopTest();
        // 今日の注文名の日付の部分
        Date today = Date.today();
        String datePartYear = String.valueOf(today.year()).right(2);
        String datePartMonth = String.valueOf(today.month()).leftPad(2, '0');
        String datePartDay = String.valueOf(today.day()).leftPad(2, '0');
        String datePart = datePartYear + datePartMonth + datePartDay;
        // 作成された注文を取得
        List<OrderHeader__c> orders = [SELECT Name FROM OrderHeader__c];
        // 一つ注文が作成された
        Assert.areEqual(1, orders.size());
        // 注文名を確認：{（今日）YYMMDD}{00001}
        Assert.areEqual(datePart + '00001', orders[0].Name);
    }

    // 昨日のレコードがある。複数の注文を作成
    // 結果：レコードの名前が正しい形式に設定：日付の部分が同じ、番号部分が異なる。新規作成された注文の番号が１から。
    @isTest
    public static void orderHeaderNamingTest_multipleRecords_differentNumbersFrom1() {
        // 現在の注文の作成日を昨日に変更
        List<OrderHeader__c> oldOrders = [SELECT Id, Name, CreatedDate FROM OrderHeader__c];
        for (OrderHeader__c oldOrder : oldOrders) {
            Date today = Date.today() - 1;
            String datePartYear = String.valueOf(today.year()).right(2);
            String datePartMonth = String.valueOf(today.month()).leftPad(2, '0');
            String datePartDay = String.valueOf(today.day()).leftPad(2, '0');
            String datePart = datePartYear + datePartMonth + datePartDay;
            oldOrder.Name = datePart + oldOrder.Name.right(5);
            Test.setCreatedDate(oldOrder.Id, Datetime.newInstance(today.year(), today.month(), today.day()));
        }
        update oldOrders;

        // 新規注文を作成
        OrderHeader__c newOrder1 = new OrderHeader__c();
        OrderHeader__c newOrder2 = new OrderHeader__c();
        OrderHeader__c newOrder3 = new OrderHeader__c();

        Test.startTest();
        insert newOrder1;
        insert new List<OrderHeader__c>{ newOrder2, newOrder3 };
        Test.stopTest();

        // 今日の注文名の日付の部分
        Date today = Date.today();
        String datePartYear = String.valueOf(today.year()).right(2);
        String datePartMonth = String.valueOf(today.month()).leftPad(2, '0');
        String datePartDay = String.valueOf(today.day()).leftPad(2, '0');
        String datePart = datePartYear + datePartMonth + datePartDay;
        Decimal numberPart = 1;
        // 作成された注文を取得
        List<OrderHeader__c> orders = [SELECT Name FROM OrderHeader__c WHERE CreatedDate = TODAY ORDER BY CreatedDate ASC];
        //
        Assert.isTrue(oldOrders.size() > 0);
        // 一つ注文が作成された
        Assert.areEqual(3, orders.size());
        for (OrderHeader__c order : orders) {
            // 注文名を確認：{（今日）YYMMDD} + {00001}/{00002}/{00003}
            Assert.areEqual(datePart + String.valueOf(numberPart).leftPad(5, '0'), order.Name);
            numberPart += 1;
        }
    }
}