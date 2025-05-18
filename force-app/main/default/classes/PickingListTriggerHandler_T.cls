@isTest
private class PickingListTriggerHandler_T {
    @TestSetup
    static void makeData() {
        InvoiceDocument__c inv = new InvoiceDocument__c();
        inv.Type__c = '請求書';
        inv.Status__c = 'Confirm';
        inv.InvoiceDate__c = Date.newInstance(1900, 1, 1);
        insert inv;

        PriceTable__c priceTable = new PriceTable__c();
        priceTable.Name = 'Test';
        insert priceTable;

        ShippingFee__c shippingFee = new ShippingFee__c();
        shippingFee.PriceTable__c = priceTable.Id;
        insert shippingFee;

        OrderHeader__c order = new OrderHeader__c();
        order.Status__c = 'Reception';
        order.ShippingFee__c = shippingFee.Id;
        insert order;

        ProductMaster__c product = new ProductMaster__c();
        product.Name = 'TestProduct';
        product.ProductCode__c = 'Test';
        product.ProductManagementCategory__c = '4';
        insert product;

        OrderDetail__c orderDetail = new OrderDetail__c();
        orderDetail.OrderHeader__c = order.Id;
        orderDetail.ProductMaster__c = product.Id;
        orderDetail.Quantity__c = 5;
        insert orderDetail;

        WarehouseMaster__c wm = new WarehouseMaster__c();
        wm.Name = 'TestSouko';
        wm.WarehouseCode__c = 'Test';
        insert wm;

        ProductStockInfo__c psi = new ProductStockInfo__c();
        psi.WarehouseMaster__c = wm.Id;
        psi.ProductMaster__c = product.Id;
        psi.ArrivalQuantity__c = 20;
        psi.AllocatedQuantity__c = 0;
        psi.ShippedQuantity__c = 0;
        insert psi;

        ProductStockInfo__c psi2 = new ProductStockInfo__c();
        psi2.WarehouseMaster__c = wm.Id;
        psi2.ProductMaster__c = product.Id;
        psi2.ArrivalQuantity__c = 10;
        psi2.AllocatedQuantity__c = 0;
        psi2.ShippedQuantity__c = 0;
        insert psi2;

        PickingList__c pl = new PickingList__c();
        pl.ProductStockInfo__c = psi.Id;
        pl.Quantity__c = 5;
        pl.OrderHeader__c = order.Id;
        pl.OrderDetail__c = orderDetail.Id;
        insert pl;

        PickingList__c pl2 = new PickingList__c();
        pl2.ProductStockInfo__c = psi.Id;
        pl2.Quantity__c = 3;
        pl2.OrderHeader__c = order.Id;
        pl2.OrderDetail__c = orderDetail.Id;
        insert pl2;
    }

    // ピッキングリストを新規作成
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_insertQuantityChangeToValue_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Decimal priorAllocated = psi.AllocatedQuantity__c;

        OrderDetail__c orderDetail = [SELECT Id, OrderHeader__c FROM OrderDetail__c LIMIT 1];

        PickingList__c pl3 = new PickingList__c();
        pl3.ProductStockInfo__c = psi.Id;
        pl3.Quantity__c = 3;
        pl3.OrderHeader__c = orderDetail.OrderHeader__c;
        pl3.OrderDetail__c = orderDetail.Id;

        Test.startTest();
        insert pl3;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.areEqual(priorAllocated + 3, psi.AllocatedQuantity__c); // 前の値　＋　作成したピッキングリストの数量
    }

    // ピッキングリストの数量を更新
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_updateQuantityChangeToValue_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorAllocated = psi.AllocatedQuantity__c;

        pl.Quantity__c = pl.Quantity__c + 3;

        Test.startTest();
        update pl;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.areEqual(priorAllocated + 3, psi.AllocatedQuantity__c); // 前の値　＋　更新の差分
    }

    // ピッキングリストの数量を空に更新
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_updateQuantityChangeToNull_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorAllocated = psi.AllocatedQuantity__c;
        Decimal priorPLQuantity = pl.Quantity__c;
        pl.Quantity__c = null;

        Test.startTest();
        update pl;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.isTrue(priorAllocated != 0);
        Assert.areEqual(priorAllocated - priorPLQuantity, psi.AllocatedQuantity__c);
    }

    // ピッキングリストの在庫情報を空に更新
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_updateStockInfoChangeToNull_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorAllocated = psi.AllocatedQuantity__c;
        Decimal priorPLQuantity = pl.Quantity__c;
        pl.ProductStockInfo__c = null;

        Test.startTest();
        update pl;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.isTrue(priorAllocated != 0);
        Assert.areEqual(priorAllocated - priorPLQuantity, psi.AllocatedQuantity__c);
    }

    // ピッキングリストを別の在庫情報に変更
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_updateStockInfoChangeToValue_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorAllocated = psi.AllocatedQuantity__c;

        ProductStockInfo__c psi2 = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id != :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorAllocated2 = psi2.AllocatedQuantity__c;

        pl.ProductStockInfo__c = psi2.Id;

        Test.startTest();
        update pl;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        psi2 = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi2.Id
            LIMIT 1
        ];

        Assert.areEqual(priorAllocated - pl.Quantity__c, psi.AllocatedQuantity__c); // 前の在庫情報の引き当て済み数　ー　ピッキングリストの数量
        Assert.areEqual(priorAllocated2 + pl.Quantity__c, psi2.AllocatedQuantity__c); // 後の在庫情報の引き当て済み数を更新　＋　ピッキングリストの数量
    }

    // ピッキングリストを削除
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_delete_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Decimal priorAllocated = psi.AllocatedQuantity__c;

        Test.startTest();
        delete pl;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Assert.areEqual(priorAllocated - pl.Quantity__c, psi.AllocatedQuantity__c); // 在庫情報の引き当て済み数　ー　削除したピッキングリストの数量
    }

    // ピッキングリストを削除して、削除取消
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_undelete_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Decimal priorAllocated = psi.AllocatedQuantity__c;

        delete pl;

        // 削除した後の情報
        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Decimal afterDeleteAllocated = psi.AllocatedQuantity__c;

        Test.startTest();
        undelete pl;
        Test.stopTest();

        // 削除取り消した後の情報
        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Assert.areEqual(priorAllocated - pl.Quantity__c, afterDeleteAllocated); // 削除した時、引き当て済み数の変更を確認
        Assert.areEqual(priorAllocated, psi.AllocatedQuantity__c); // 削除取消した後、元々の引き当て済み数に戻す
    }

    // すべてのピッキングリストを削除
    @isTest
    public static void productStockInfoRollupAllocatedQuantity_deleteAll_stockInfoQuantityChange() {
        List<PickingList__c> plList = [
            SELECT Id, ProductStockInfo__c, Quantity__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
        ];

        ProductStockInfo__c psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        Decimal priorAllocated = psi.AllocatedQuantity__c;

        Test.startTest();
        delete plList;
        Test.stopTest();

        psi = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.areEqual(0, psi.AllocatedQuantity__c); // 出庫済み数を０になった
    }

    // 出庫済み数のテスト。ピッキングリストを新規作成
    @isTest
    public static void productStockInfoRollupShippedQuantity_insertQuantityChangeToValue_stockInfoShippedQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c, Shipped__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        ProductStockInfo__c psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Decimal priorShipped = psi.ShippedQuantity__c;
        if (priorShipped == null) {
            priorShipped = 0;
        }

        OrderDetail__c orderDetail = [SELECT Id, OrderHeader__c FROM OrderDetail__c LIMIT 1];

        PickingList__c pl3 = new PickingList__c();
        pl3.ProductStockInfo__c = psi.Id;
        pl3.Quantity__c = 3;
        pl3.OrderHeader__c = orderDetail.OrderHeader__c;
        pl3.OrderDetail__c = orderDetail.Id;
        pl3.Shipped__c = true;

        Test.startTest();
        insert pl3;
        Test.stopTest();

        psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.areEqual(priorShipped + 3, psi.ShippedQuantity__c); // 前の値　＋　作成したピッキングリストの数量
    }

    // 出庫済み数のテスト。ピッキングリストの数量を更新
    @isTest
    public static void productStockInfoRollupShippedQuantity_updateQuantityChangeToValue_stockInfoShippedQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c, OrderDetail__c, OrderDetail__r.OrderHeader__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        PickingList__c pl3 = new PickingList__c();
        pl3.ProductStockInfo__c = pl.ProductStockInfo__c;
        pl3.Quantity__c = 3;
        pl3.OrderHeader__c = pl.OrderDetail__r.OrderHeader__c;
        pl3.OrderDetail__c = pl.OrderDetail__c;
        pl3.Shipped__c = true;
        insert pl3;

        ProductStockInfo__c psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Assert.areEqual(pl3.Quantity__c, psi.ShippedQuantity__c);

        Decimal priorShipped = psi.ShippedQuantity__c;
        pl3.Quantity__c = priorShipped + 3;

        Test.startTest();
        update pl3;
        Test.stopTest();

        psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        Assert.areEqual(priorShipped + 3, psi.ShippedQuantity__c); // 前の値　＋　更新の差分
    }

    // 出庫済み数のテスト。ピッキングリストを別の在庫情報に変更
    @isTest
    public static void productStockInfoRollupShippedQuantity_updateStockInfoChangeToValue_stockInfoQuantityChange() {
        PickingList__c pl = [
            SELECT Id, ProductStockInfo__c, Quantity__c, OrderDetail__c, OrderDetail__r.OrderHeader__c
            FROM PickingList__c
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        pl.Shipped__c = true;
        update pl;

        ProductStockInfo__c psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :pl.ProductStockInfo__c
            LIMIT 1
        ];
        Assert.areEqual(pl.Quantity__c, psi.ShippedQuantity__c);

        Decimal priorShipped = psi.ShippedQuantity__c;

        ProductStockInfo__c psi2 = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id != :pl.ProductStockInfo__c
            LIMIT 1
        ];

        Decimal priorShipped2 = psi2.ShippedQuantity__c;

        pl.ProductStockInfo__c = psi2.Id;

        Test.startTest();
        update pl;
        Test.stopTest();

        psi = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi.Id
            LIMIT 1
        ];

        psi2 = [
            SELECT Id, ShippedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id = :psi2.Id
            LIMIT 1
        ];

        Assert.areEqual(priorShipped - pl.Quantity__c, psi.ShippedQuantity__c); // 前の在庫情報の出庫済み数　ー　ピッキングリストの数量
        Assert.areEqual(priorShipped2 + pl.Quantity__c, psi2.ShippedQuantity__c); // 後の在庫情報の出庫済み数を更新　＋　ピッキングリストの数量
    }
}