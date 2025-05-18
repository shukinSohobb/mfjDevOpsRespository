@isTest
public class StorageFeeAccountingDetailCreateBatch_T {
    @TestSetup
    static void makeData() {
        Account acc1 = new Account(Name = 'Acc1');
        acc1.ClosingDate__c = 'Month_15';
        insert acc1;

        Account acc2 = new Account(Name = 'Acc1');
        acc2.ClosingDate__c = 'Month_20';
        insert acc2;

        PriceTable__c pt1 = new PriceTable__c();
        insert pt1;

        PriceTable__c pt2 = new PriceTable__c();
        insert pt2;

        StorageFee__c sf1 = new StorageFee__c();
        sf1.UnitPriceShipping__c = 10;
        sf1.UnitPriceArrival__c = 100;
        sf1.UnitPriceStorage__c = 1000;
        sf1.PriceTable__c = pt1.Id;
        insert sf1;

        StorageFee__c sf2 = new StorageFee__c();
        sf2.UnitPriceShipping__c = 20;
        sf2.UnitPriceArrival__c = 200;
        sf2.UnitPriceStorage__c = 2000;
        sf2.PriceTable__c = pt1.Id;
        insert sf2;

        ProductMaster__c prod1 = new ProductMaster__c(Name = 'Prod1');
        prod1.Account__c = acc1.Id;
        prod1.StorageFee__c = sf1.Id;
        prod1.ProductCode__c = '1';
        prod1.StandardUnit__c = 'Case';
        insert prod1;

        ProductMaster__c prod2 = new ProductMaster__c(Name = 'Prod2');
        prod2.Account__c = acc2.Id;
        prod2.StorageFee__c = sf2.Id;
        prod2.ProductCode__c = '2';
        prod2.StandardUnit__c = 'Case';
        insert prod2;

        InvoiceDocument__c inv = new InvoiceDocument__c();
        inv.Account__c = acc1.Id;
        // inv.Type__c = 'Invoice';
        inv.InvoiceDate__c = Date.newInstance(1900, 1, 1);
        insert inv;

        Date executeDate = Date.newInstance(2025, 4, 20);

        ProductStockInfo__c psi1 = new ProductStockInfo__c();
        psi1.ProductMaster__c = prod1.Id;
        // psi1.HandlingCargoCostBurden__c = 'Pay';
        psi1.Status__c = 'Arrived';
        psi1.ArrivalQuantity__c = 100;
        psi1.ArrivalDate__c = executeDate;
        psi1.ExpirationDate__c = executeDate + 365;
        insert psi1;

        ProductStockInfo__c psi2 = new ProductStockInfo__c();
        psi2.ProductMaster__c = prod1.Id;
        // psi2.HandlingCargoCostBurden__c = 'Pay';
        psi2.Status__c = 'Arrived';
        psi2.ArrivalQuantity__c = 100;
        psi2.ArrivalDate__c = executeDate + 15;
        psi2.ExpirationDate__c = executeDate + 365;
        insert psi2;

        ProductStockInfo__c psi3 = new ProductStockInfo__c();
        psi3.ProductMaster__c = prod2.Id;
        // psi3.HandlingCargoCostBurden__c = 'Pay';
        psi3.Status__c = 'Arrived';
        psi3.ArrivalQuantity__c = 200;
        psi3.ArrivalDate__c = executeDate;
        psi3.ExpirationDate__c = executeDate + 365;
        insert psi3;

        OrderHeader__c order = new OrderHeader__c();
        order.Status__c = 'Reception';
        order.LoadingDate__c = executeDate;
        insert order;

        OrderDetail__c orderDetail = new OrderDetail__c();
        orderDetail.OrderHeader__c = order.Id;
        orderDetail.ProductMaster__c = prod1.Id;
        orderDetail.Quantity__c = 50;
        insert orderDetail;

        PickingList__c pl1 = new PickingList__c();
        pl1.ProductStockInfo__c = psi1.Id;
        pl1.Quantity__c = 50;
        pl1.OrderHeader__c = order.Id;
        pl1.OrderDetail__c = orderDetail.Id;
        pl1.Shipped__c = true;
        insert pl1;

        PickingList__c pl2 = new PickingList__c();
        pl2.ProductStockInfo__c = psi3.Id;
        pl2.Quantity__c = 50;
        pl2.OrderHeader__c = order.Id;
        pl2.OrderDetail__c = orderDetail.Id;
        pl2.Shipped__c = true;
        insert pl2;

        PickingList__c pl3 = new PickingList__c();
        pl3.ProductStockInfo__c = psi3.Id;
        pl3.Quantity__c = 50;
        pl3.OrderHeader__c = order.Id;
        pl3.OrderDetail__c = orderDetail.Id;
        pl3.Shipped__c = true;
        insert pl3;
    }

    // 取引先の締日＝15日
    // 期待結果：新規の保管料の請求・支払明細が作成される
    @isTest
    public static void storageFeeAccountingDetailCreateBatch_close15_success() {
        // 保管料の請求・支払明細のレコードがない
        List<AccountingDetail__c> acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Assert.areEqual(0, acdList.size());
        // 締日が15日の取引先を取得
        Account acc = [SELECT Id, ClosingDate__c FROM Account WHERE ClosingDate__c = 'Month_15'];
        Date executeDate = MfjUtil.getTargetTermEndDate(Date.newInstance(2025, 4, 20), acc.ClosingDate__c) - 1;
        // 商品マスタを取得
        ProductMaster__c prod = [
            SELECT Id, UnitPriceStorage_F__c, StockQuantity_Sum__c
            FROM ProductMaster__c
            WHERE Account__c = :acc.Id
            LIMIT 1
        ];
        // 在庫情報を取得して、期入庫数を計算
        List<ProductStockInfo__c> psiList = [
            SELECT Id, ArrivalQuantity__c
            FROM ProductStockInfo__c
            WHERE ProductMaster__c = :prod.Id AND ArrivalDate__c <= :executeDate
        ];
        Decimal inQuantity = 0;
        for (ProductStockInfo__c psi : psiList) {
            inQuantity += psi.ArrivalQuantity__c;
        }
        // ピッキングリストを取得して、
        List<PickingList__c> plList = [
            SELECT Id, Quantity__c
            FROM PickingList__c
            WHERE ProductStockInfo__r.ProductMaster__c = :prod.Id
        ];
        Decimal outQuantity = 0;
        for (PickingList__c pl : plList) {
            outQuantity += pl.Quantity__c;
        }

        // バッチ実行
        Test.startTest();
        StorageFeeAccountingDetailCreateBatch batch = new StorageFeeAccountingDetailCreateBatch(executeDate);
        Database.executeBatch(batch);
        Test.stopTest();
        // 保管料の請求・支払明細を取得
        acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c, Amount__c, TermArrivedQuantity__c, TermShippedQuantity__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Assert.areEqual(1, acdList.size()); // レコードがある
        Assert.areEqual(MfjUtil.getTargetTermStartDate(Date.newInstance(2025, 4, 20), 'Month_15'), acdList[0].Date__c); // 日付を確認
        Assert.areEqual(
            MfjUtil.getTargetTermCycleStartDate(Date.newInstance(2025, 4, 20), 'Month_15'),
            acdList[0].TermCycleStartDate__c
        ); // 期制の開始日を確認
        Assert.areEqual(prod.UnitPriceStorage_F__c * prod.StockQuantity_Sum__c, acdList[0].Amount__c); // 金額（保管料）を確認
        Assert.areEqual(inQuantity, acdList[0].TermArrivedQuantity__c); // 期入庫数を確認
        Assert.areEqual(outQuantity, acdList[0].TermShippedQuantity__c); // 期出庫数を確認
        // 一括処理ログを取得
        List<BulkProcessLog__c> logList = [
            SELECT Id, ProcessStatus__c, ProcessSubject__c
            FROM BulkProcessLog__c
        ];
        for (BulkProcessLog__c log : logList) {
            // System.debug('件名：' + log.ProcessSubject__c);
            Assert.areEqual('Success', log.ProcessStatus__c); // 処理ログの状態が「正常」
        }
    }

    // 保管料の請求・支払明細はすでに存在している。
    // 期待結果：請求・支払明細を更新する。新規作成しない。
    @isTest
    public static void storageFeeAccountingDetailCreateBatch_accountingDetailExist_updated() {
        // 保管料の請求・支払明細を作成
        Account acc = [SELECT Id, ClosingDate__c FROM Account WHERE ClosingDate__c = 'Month_20' LIMIT 1];
        ProductMaster__c prod = [SELECT Id FROM ProductMaster__c WHERE Account__c = :acc.Id LIMIT 1];
        List<AccountingDetail__c> acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Date dummyDate = Date.newInstance(1900, 1, 1);
        InvoiceDocument__c dummyInvoice = [SELECT Id FROM InvoiceDocument__c WHERE InvoiceDate__c = :dummyDate LIMIT 1];
        AccountingDetail__c newAcd = new AccountingDetail__c();
        newAcd.Date__c = MfjUtil.getTargetTermStartDate(Date.newInstance(2025, 4, 20), 'Month_20');
        newAcd.TermCycleStartDate__c = MfjUtil.getTargetTermCycleStartDate(Date.newInstance(2025, 4, 20), 'Month_20');
        newAcd.AccountItem__c = '1_90';
        newAcd.Item__c = '保管料';
        newAcd.AccountingType__c = '1';
        newAcd.TargetDepartment__c = '倉庫課';
        newAcd.InvoiceAccount__c = acc.Id;
        newAcd.ProductMaster__c = prod.Id;
        newAcd.InvoiceDocument__c = dummyInvoice.Id;
        insert newAcd;
        // バッチ実行
        Test.startTest();
        Date executeDate = MfjUtil.getTargetTermEndDate(Date.newInstance(2025, 4, 20), 'Month_20') - 1;
        StorageFeeAccountingDetailCreateBatch batch = new StorageFeeAccountingDetailCreateBatch(executeDate);
        Database.executeBatch(batch);
        Test.stopTest();
        // 保管料の請求・支払明細を取得
        acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c, Amount__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Assert.areEqual(1, acdList.size()); // 取得できることを確認
        Assert.areEqual(newAcd.Id, acdList[0].Id); // 更新を確認(IDが変更されなかった)
        Assert.isTrue(acdList[0].Amount__c != null); // 金額の更新を確認

        // 一括処理ログを取得
        List<BulkProcessLog__c> logList = [
            SELECT Id, ProcessStatus__c, ProcessSubject__c
            FROM BulkProcessLog__c
        ];
        for (BulkProcessLog__c log : logList) {
            // System.debug('件名：' + log.ProcessSubject__c);
            Assert.areEqual('Success', log.ProcessStatus__c); // 処理ログの状態が「正常」
        }
    }

    // 3期の場合、保管料の請求・支払明細はすでに存在している。そのレコードの「日付」は三つの期制の開始日以外。
    // 期待結果：存在しているレコードが削除される。新規のレコードが作成される。
    @isTest
    public static void storageFeeAccountingDetailCreateBatch_invoiceExist_deleted() {
        // 保管料の請求・支払明細を作成
        Account acc = [SELECT Id, ClosingDate__c FROM Account WHERE ClosingDate__c = 'Month_20' LIMIT 1];
        ProductMaster__c prod = [SELECT Id FROM ProductMaster__c WHERE Account__c = :acc.Id LIMIT 1];
        List<AccountingDetail__c> acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Date dummyDate = Date.newInstance(1900, 1, 1);
        InvoiceDocument__c dummyInvoice = [SELECT Id FROM InvoiceDocument__c WHERE InvoiceDate__c = :dummyDate LIMIT 1];
        AccountingDetail__c newAcd = new AccountingDetail__c();
        newAcd.Date__c = MfjUtil.getTargetTermStartDate(Date.newInstance(2025, 4, 20), 'Month_20') - 1;
        newAcd.TermCycleStartDate__c = MfjUtil.getTargetTermCycleStartDate(Date.newInstance(2025, 4, 20), 'Month_20');
        newAcd.AccountItem__c = '1_90';
        newAcd.Item__c = '保管料';
        newAcd.AccountingType__c = '1';
        newAcd.TargetDepartment__c = '倉庫課';
        newAcd.InvoiceAccount__c = acc.Id;
        newAcd.ProductMaster__c = prod.Id;
        newAcd.InvoiceDocument__c = dummyInvoice.Id;
        insert newAcd;
        // バッチ実行
        Test.startTest();
        Date executeDate = MfjUtil.getTargetTermCycleEndDate(Date.newInstance(2025, 4, 20), 'Month_20') - 1;
        StorageFeeAccountingDetailCreateBatch batch = new StorageFeeAccountingDetailCreateBatch(executeDate);
        Database.executeBatch(batch);
        Test.stopTest();
        // 保管料の請求・支払明細を取得
        acdList = [
            SELECT Id, Date__c, TermCycleStartDate__c, Amount__c
            FROM AccountingDetail__c
            WHERE Item__c = '保管料'
        ];
        Assert.areEqual(1, acdList.size());
        Assert.areNotEqual(newAcd.Id, acdList[0].Id);
        Assert.isTrue(acdList[0].Amount__c != null);

        // 一括処理ログを取得
        List<BulkProcessLog__c> logList = [
            SELECT Id, ProcessStatus__c, ProcessSubject__c
            FROM BulkProcessLog__c
        ];
        for (BulkProcessLog__c log : logList) {
            // System.debug('件名：' + log.ProcessSubject__c);
            Assert.areEqual('Success', log.ProcessStatus__c);
        }
    }

    // 取引先の今期請求書の状況が「処理済み」の場合、バッチは処理しない。
    // 確認：「処理開始」のログ状態の一括処理ログしかない。
    @isTest
    public static void storageFeeAccountingDetailCreateBatch_invoiceConfirmed_skip() {
        // 「保管・荷役明細書」の請求書の状態を「処理済み」に変更
        List<InvoiceDocument__c> invList = [
            SELECT Id, Status__c, Account__r.ClosingDate__c
            FROM InvoiceDocument__c
            WHERE Type__c = '保管・荷役明細書'
        ];
        for (InvoiceDocument__c inv : invList) {
            inv.Status__c = 'Confirmed';
        }
        update invList;
        // バッチ実行
        Test.startTest();
        Date executeDate = MfjUtil.getTargetTermEndDate(Date.newInstance(2025, 4, 20), 'Month_15') - 1;
        StorageFeeAccountingDetailCreateBatch batch = new StorageFeeAccountingDetailCreateBatch(executeDate);
        Database.executeBatch(batch);
        executeDate = MfjUtil.getTargetTermEndDate(Date.newInstance(2025, 4, 20), 'Month_20') - 1;
        batch = new StorageFeeAccountingDetailCreateBatch(executeDate);
        Database.executeBatch(batch);
        Test.stopTest();
        // 一括処理ログを取得
        List<BulkProcessLog__c> logList = [
            SELECT Id, ProcessStatus__c, ProcessSubject__c
            FROM BulkProcessLog__c
        ];
        // 「処理開始」のログしかないことを確認
        for (BulkProcessLog__c log : logList) {
            System.debug('件名：' + log.ProcessSubject__c);
            Assert.areEqual('Start', log.ProcessStatus__c);
        }
    }
}