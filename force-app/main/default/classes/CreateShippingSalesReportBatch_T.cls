@isTest
private class CreateShippingSalesReportBatch_T {
    @TestSetup
    static void setup() {
        Account acc1 = new Account(
            Name = '荷主１',
            Type = 'Account',
            BillingCountry = '日本',
            BillingState = '千葉県',
            BillingCity = '松戸市'
        );
        insert acc1;

        Account acc2 = new Account(
            Name = '荷主２',
            Type = 'Account',
            ParentId = acc1.Id,
            BillingCountry = '日本',
            BillingState = '千葉県',
            BillingCity = '松戸市'
        );
        insert acc2;

        Account acc3 = new Account(
            Name = '荷主４',
            Type = 'Subcontractor',
            BillingCountry = '日本',
            BillingState = '千葉県',
            BillingCity = '松戸市'
        );
        insert acc3;

        //発着地を作成
        OriginDestination__c origDes1 = new OriginDestination__c(
            Name = '発地',
            //Account__c = acc1.Id,
            DeliveryArea__c = 'Medium',
            Prefecture__c = '埼玉県'
        );
        insert origDes1;

        OriginDestination__c origDes2 = new OriginDestination__c(
            Name = '着地',
            //Account__c = acc1.Id,
            DeliveryArea__c = 'Medium',
            Prefecture__c = '千葉県'
        );
        insert origDes2;

        //注文を作成
        InvoiceDocument__c idDoc = new InvoiceDocument__c(
            Status__c = 'Confirm', //状態
            InvoiceDate__c = Date.newInstance(1900, 1, 1) //請求日
        );
        insert idDoc;
        List<OrderHeader__c> ohList = new List<OrderHeader__c>();
        OrderHeader__c oh1 = new OrderHeader__c(
            Status__c = 'ReceptionCompleted', //状態：受付確認済
            InvoiceAccount__c = acc1.Id, //請求先（集計使用名
            Account__c = acc1.Id, //荷主
            LoadingDate__c = System.today().addDays(-32), //積込日
            NotNeedShipping__c = true,
            ExpectedDeliveryDate__c = System.today().addDays(-32), //納品日
            BillingDate__c = System.today().addDays(-32), //請求日
            SubcontractBillingDate__c = System.today().addDays(-32), //下請け請求日
            ShippingCompany__c = acc1.Id, //配送会社
            TransportationMode__c = 'Route', //輸送形態：路線便
            OriginPlace__c = origDes1.Id, //発地
            Destination__c = origDes2.Id, //着地
            ShippingFeeManualFlag__c = true, //運賃手動計算フラグ
            //QuantityForShippingFeeCal__c = 10, //運賃計算用数量
            UnitForShippingFeeCal__c = 'Case', //運賃計算用単
            //UnitPrice__c = 2000, //単価
            Amount__c = 20000, //運賃
            //SubcontractFee__c = 10000, //下請け運賃
            FirstProductName__c = 'test1', //1件目商品名
            AncillaryWorkFee__c = 1000, //付帯作業費
            //TollFee__c = 1200, //使用通行料
            WaitTimeFee__c = 800 //待機料
        );
        ohList.add(oh1);
        OrderHeader__c oh2 = new OrderHeader__c(
            Status__c = 'ReceptionCompleted', //状態：受付確認済
            InvoiceAccount__c = acc2.Id, //請求先（集計使用名
            Account__c = acc2.Id, //荷主
            LoadingDate__c = System.today(), //積込日
            NotNeedShipping__c = true,
            ExpectedDeliveryDate__c = System.today(), //納品日
            BillingDate__c = System.today().addDays(32), //請求日
            SubcontractBillingDate__c = System.today().addDays(32), //下請け請求日
            ShippingCompany__c = acc3.Id, //配送会社
            TransportationMode__c = 'Route', //輸送形態：路線便
            OriginPlace__c = origDes1.Id, //発地
            Destination__c = origDes2.Id, //着地
            ShippingFeeManualFlag__c = true, //運賃手動計算フラグ
            //QuantityForShippingFeeCal__c = 10, //運賃計算用数量
            UnitForShippingFeeCal__c = 'Case', //運賃計算用単
            //UnitPrice__c = 1000, //単価
            Amount__c = 12000, //運賃
            SubcontractFee__c = 20000, //下請け運賃
            FirstProductName__c = 'test2', //1件目商品名
            AncillaryWorkFee__c = 1500, //付帯作業費
            //TollFee__c = 1000, //使用通行料
            WaitTimeFee__c = 1300 //待機料
        );
        ohList.add(oh2);

        insert ohList;
    }

    @isTest
    static void testNormalPatten1() {
        Test.startTest();
        //目標管理を作成
        Date dt = System.today().addDays(-32);
        ObjectiveManagement__c obj1 = new ObjectiveManagement__c(
            Name = 'test1',
            TargetMonth__c = Date.newInstance(dt.year(), dt.month(), 1)
        );
        insert obj1;

        //運送売上日報を作成
        ShippingSalesReport__c ssr = new ShippingSalesReport__c(
            MARUSMfjVehicleSales__c = 8000,
            ChateraiseSales__c = 2000,
            FujiEchoMfjVehicleSales__c = 3000,
            CharteredVehicleSales__c = 2000,
            FujiEchoCharteredVehicleSales__c = 1000,
            ChateraiseSubcontractorSales__c = 1000,
            CharteredVehicleSubcontractorSales__c = 1000,
            FujiEchoCharteredVehicleSubcontractSales__c = 1000,
            Date__c = dt,
            ObjectiveManagement__c = obj1.Id
        );
        insert ssr;
        try {
            CreateShippingSalesReportBatch batch = new CreateShippingSalesReportBatch();
            Database.executeBatch(batch);
        } catch (Exception e) {
        }
        Test.stopTest();
        List<ShippingSalesReport__c> ssrList = [
            SELECT Id, Date__c, CharteredVehicleSales__c, CharteredVehicleSubcontractorSales__c, MARUSMfjVehicleSales__c
            FROM ShippingSalesReport__c
        ];

        System.assertEquals(1, ssrList.size());
        System.assertEquals(System.today().addDays(-32), ssrList[0].Date__c);
        System.assertEquals(0, ssrList[0].CharteredVehicleSales__c);
        System.assertEquals(0, ssrList[0].CharteredVehicleSubcontractorSales__c);
        System.assertEquals(21800, ssrList[0].MARUSMfjVehicleSales__c);
    }

    @isTest
    static void testNormalPatten2() {
        //目標管理を作成
        Date dt1 = System.today().addDays(-32);
        ObjectiveManagement__c obj1 = new ObjectiveManagement__c(
            Name = 'test1',
            TargetMonth__c = Date.newInstance(dt1.year(), dt1.month(), 1)
        );
        insert obj1;

        Date dt2 = System.today().addDays(32);
        ObjectiveManagement__c obj2 = new ObjectiveManagement__c(
            Name = 'test2',
            TargetMonth__c = Date.newInstance(dt2.year(), dt2.month(), 1)
        );
        insert obj2;

        //運送売上日報を作成
        ShippingSalesReport__c ssr = new ShippingSalesReport__c(
            MARUSMfjVehicleSales__c = 8000,
            ChateraiseSales__c = 2000,
            FujiEchoMfjVehicleSales__c = 3000,
            CharteredVehicleSales__c = 2000,
            FujiEchoCharteredVehicleSales__c = 1000,
            ChateraiseSubcontractorSales__c = 1000,
            CharteredVehicleSubcontractorSales__c = 1000,
            FujiEchoCharteredVehicleSubcontractSales__c = 1000,
            Date__c = dt1,
            ObjectiveManagement__c = obj1.Id
        );
        insert ssr;

        Test.startTest();
        try {
            CreateShippingSalesReportBatch batch = new CreateShippingSalesReportBatch();
            Database.executeBatch(batch);
        } catch (Exception e) {
        }
        Test.stopTest();
        List<ShippingSalesReport__c> ssrList = [
            SELECT Id, Date__c, CharteredVehicleSales__c, CharteredVehicleSubcontractorSales__c, MARUSMfjVehicleSales__c
            FROM ShippingSalesReport__c
            ORDER BY Date__c
        ];

        System.assertEquals(2, ssrList.size());
        System.assertEquals(System.today().addDays(-32), ssrList[0].Date__c);
        System.assertEquals(System.today().addDays(32), ssrList[1].Date__c);
        System.assertEquals(0, ssrList[0].CharteredVehicleSales__c);
        System.assertEquals(0, ssrList[0].CharteredVehicleSubcontractorSales__c);
        System.assertEquals(21800, ssrList[0].MARUSMfjVehicleSales__c);
        System.assertEquals(14800, ssrList[1].CharteredVehicleSales__c);
        System.assertEquals(22800, ssrList[1].CharteredVehicleSubcontractorSales__c);
        System.assertEquals(0, ssrList[1].MARUSMfjVehicleSales__c);
    }

    @isTest
    static void testErrorPatten1() {
        Test.startTest();
        try {
            // バッチ処理の開始
            CreateShippingSalesReportBatch batch = new CreateShippingSalesReportBatch();
            Database.executeBatch(batch);
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @isTest
    static void testErrorPatten2() {
        Test.startTest();
        try {
            CreateShippingSalesReportBatch batch = new CreateShippingSalesReportBatch();
            batch.allCount = 1;
            batch.errorNaiyouList.add('テストエラー');
            batch.finish(null);
        } catch (Exception e) {
        }
        Test.stopTest();
    }
}