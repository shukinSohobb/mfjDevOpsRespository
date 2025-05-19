/**
 * 定期便から注文と注文明細を作成バッチテストクラス
 */
@istest
public with sharing class CreateOrderFromRegServiceBatch_T {
    @TestSetup
    static void setup() {
        // テストユーザーを作成
        createTestUser();
        // 荷主を作成
        createAccount();
        // ドライバーを作成
        createDriver();
        // 発着地を作成
        createOriginDestination();
        // 商品を作成
        createProductMaster();
    }

    /**
     * 正常パターン１
     * 注文が１つレコードを作成
     * 周期種別：週
     */
    @isTest
    static void testNormalPatten1() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            // 荷主を取得
            Account acc1 = [SELECT Id FROM Account WHERE Name = '荷主１'];
            Account acc2 = [SELECT Id FROM Account WHERE Name = '荷主２'];
            // 発地を取得
            OriginDestination__c orgDes1 = [SELECT Id FROM OriginDestination__c WHERE Name = '発地'];
            // 着地を取得
            OriginDestination__c orgDes2 = [SELECT Id FROM OriginDestination__c WHERE Name = '着地'];
            // ドライバーを取得
            DriverMaster__c driver = [SELECT Id FROM DriverMaster__c WHERE Name = 'driver'];
            // 商品マスタを取得
            ProductMaster__c product = [SELECT Id FROM ProductMaster__c WHERE Name = '商品１'];

            RegularServiceInformation__c regSerInfo = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc2.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/19'),
                RecurringEndDate__c = Date.parse('2025/03/19'),
                Tuesday__c = true,
                Status__c = 'Reception'
            );
            insert regSerInfo;

            Test.startTest();
            // バッチ処理の開始
            SchedulableContext sc = null;
            CreateOrderFromRegularServiceBatch b = new CreateOrderFromRegularServiceBatch();
            CreateOrderFromRegularServiceBatch.today = Date.parse('2025/03/10');
            b.execute(sc);
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
            ];
            // 注文明細
            OrderDetail__c ordDetail = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
            ];
            // 期待値と実行結果の検証
            // 注文
            System.assertEquals(ordHeader.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordHeader.Destination__c, regSerInfo.Destination__c); // 着地
            System.assertEquals(ordHeader.VehicleNumber__c, regSerInfo.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader.DriverMaster__c, regSerInfo.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader.ExpectedDeliveryDate__c, Date.parse('2025/03/19')); // 納品日
            System.assertEquals(ordHeader.LoadingDate__c, Date.parse('2025/03/18')); // 積込日
            System.assertEquals(ordHeader.OriginPlace__c, regSerInfo.OriginPlace__c); // 発地
            System.assertEquals(ordHeader.Amount__c, regSerInfo.Amount__c); // 運賃
            System.assertEquals(ordHeader.QuantityForShippingFeeCal__c, regSerInfo.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader.UnitForShippingFeeCal__c, regSerInfo.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader.InvoiceAccount__c, regSerInfo.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader.RegularServiceInformation__c, regSerInfo.Id); // 定期便情報#
            System.assertEquals(ordHeader.Remarks1__c, regSerInfo.Remarks1__c); // 備考①
            System.assertEquals(ordHeader.Remarks2__c, regSerInfo.Remarks2__c); // 備考②
            System.assertEquals(ordHeader.ShippingFeeManualFlag__c, regSerInfo.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader.ShippingCompany__c, regSerInfo.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader.TransportationMode__c, regSerInfo.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader.UnitPrice__c, regSerInfo.UnitPrice__c); // 単価
            System.assertEquals(ordHeader.AncillaryWorkFee__c, regSerInfo.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader.SubcontractFee__c, regSerInfo.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader.DepartureTime__c, regSerInfo.DepartureTime__c); // 出発時間帯
            // 注文明細
            System.assertEquals(ordDetail.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordDetail.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail.OrderHeader__c, ordHeader.Id); // 注文
            System.assertEquals(ordDetail.ProductMaster__c, regSerInfo.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail.Quantity__c, regSerInfo.Quantity__c); // 数量
            System.assertEquals(ordDetail.Unit__c, 'Pallet'); // 単位
        }
    }

    /**
     * 正常パターン２
     * 注文が２つレコードを作成
     * 周期種別：週
     */
    @isTest
    static void testNormalPatten2() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            // 荷主を取得
            Account acc1 = [SELECT Id FROM Account WHERE Name = '荷主１'];
            Account acc2 = [SELECT Id FROM Account WHERE Name = '荷主２'];
            // 発地を取得
            OriginDestination__c orgDes1 = [SELECT Id FROM OriginDestination__c WHERE Name = '発地'];
            // 着地を取得
            OriginDestination__c orgDes2 = [SELECT Id FROM OriginDestination__c WHERE Name = '着地'];
            // ドライバーを取得
            DriverMaster__c driver = [SELECT Id FROM DriverMaster__c WHERE Name = 'driver'];
            // 商品マスタを取得
            ProductMaster__c product = [SELECT Id FROM ProductMaster__c WHERE Name = '商品１'];

            RegularServiceInformation__c regSerInfo = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc1.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/19'),
                RecurringEndDate__c = Date.parse('2025/03/19'),
                Tuesday__c = true,
                Friday__c = true,
                Status__c = 'Reception'
            );
            insert regSerInfo;

            Test.startTest();
            // バッチ処理の開始
            SchedulableContext sc = null;
            CreateOrderFromRegularServiceBatch b = new CreateOrderFromRegularServiceBatch();
            CreateOrderFromRegularServiceBatch.today = Date.parse('2025/03/10');
            b.execute(sc);
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
                WHERE ExpectedDeliveryDate__c = :Date.parse('2025/03/19')
            ];
            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
                WHERE ExpectedDeliveryDate__c = :Date.parse('2025/03/22')
            ];
            // 注文明細
            OrderDetail__c ordDetail1 = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
            ];
            OrderDetail__c ordDetail2 = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
            ];
            // 期待値と実行結果の検証
            // 注文1
            System.assertEquals(ordHeader1.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordHeader1.Destination__c, regSerInfo.Destination__c); // 着地
            System.assertEquals(ordHeader1.VehicleNumber__c, regSerInfo.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader1.DriverMaster__c, regSerInfo.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader1.ExpectedDeliveryDate__c, Date.parse('2025/03/19')); // 納品日
            System.assertEquals(ordHeader1.LoadingDate__c, Date.parse('2025/03/18')); // 積込日
            System.assertEquals(ordHeader1.OriginPlace__c, regSerInfo.OriginPlace__c); // 発地
            System.assertEquals(ordHeader1.Amount__c, regSerInfo.Amount__c); // 運賃
            System.assertEquals(ordHeader1.QuantityForShippingFeeCal__c, regSerInfo.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader1.UnitForShippingFeeCal__c, regSerInfo.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader1.InvoiceAccount__c, regSerInfo.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader1.RegularServiceInformation__c, regSerInfo.Id); // 定期便情報#
            System.assertEquals(ordHeader1.Remarks1__c, regSerInfo.Remarks1__c); // 備考①
            System.assertEquals(ordHeader1.Remarks2__c, regSerInfo.Remarks2__c); // 備考②
            System.assertEquals(ordHeader1.ShippingFeeManualFlag__c, regSerInfo.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader1.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader1.ShippingCompany__c, regSerInfo.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader1.TransportationMode__c, regSerInfo.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader1.UnitPrice__c, regSerInfo.UnitPrice__c); // 単価
            System.assertEquals(ordHeader1.AncillaryWorkFee__c, regSerInfo.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader1.SubcontractFee__c, regSerInfo.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader1.DepartureTime__c, regSerInfo.DepartureTime__c); // 出発時間帯
            // 注文明細1
            System.assertEquals(ordDetail1.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordDetail1.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail1.OrderHeader__c, ordHeader1.Id); // 注文
            System.assertEquals(ordDetail1.ProductMaster__c, regSerInfo.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail1.Quantity__c, regSerInfo.Quantity__c); // 数量
            System.assertEquals(ordDetail1.Unit__c, 'Pallet'); // 単位
            // 注文2
            System.assertEquals(ordHeader2.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordHeader2.Destination__c, regSerInfo.Destination__c); // 着地
            System.assertEquals(ordHeader2.VehicleNumber__c, regSerInfo.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader2.DriverMaster__c, regSerInfo.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader2.ExpectedDeliveryDate__c, Date.parse('2025/03/22')); // 納品日
            System.assertEquals(ordHeader2.LoadingDate__c, Date.parse('2025/03/21')); // 積込日
            System.assertEquals(ordHeader2.OriginPlace__c, regSerInfo.OriginPlace__c); // 発地
            System.assertEquals(ordHeader2.Amount__c, regSerInfo.Amount__c); // 運賃
            System.assertEquals(ordHeader2.QuantityForShippingFeeCal__c, regSerInfo.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader2.UnitForShippingFeeCal__c, regSerInfo.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader2.InvoiceAccount__c, regSerInfo.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader2.RegularServiceInformation__c, regSerInfo.Id); // 定期便情報#
            System.assertEquals(ordHeader2.Remarks2__c, regSerInfo.Remarks2__c); // 備考①
            System.assertEquals(ordHeader2.Remarks2__c, regSerInfo.Remarks2__c); // 備考②
            System.assertEquals(ordHeader2.ShippingFeeManualFlag__c, regSerInfo.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader2.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader2.ShippingCompany__c, regSerInfo.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader2.TransportationMode__c, regSerInfo.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader2.UnitPrice__c, regSerInfo.UnitPrice__c); // 単価
            System.assertEquals(ordHeader2.AncillaryWorkFee__c, regSerInfo.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader2.SubcontractFee__c, regSerInfo.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader2.DepartureTime__c, regSerInfo.DepartureTime__c); // 出発時間帯
            // 注文明細2
            System.assertEquals(ordDetail2.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordDetail2.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail2.OrderHeader__c, ordHeader2.Id); // 注文
            System.assertEquals(ordDetail2.ProductMaster__c, regSerInfo.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail2.Quantity__c, regSerInfo.Quantity__c); // 数量
            System.assertEquals(ordDetail2.Unit__c, 'Pallet'); // 単位
        }
    }

    /**
     * 正常パターン３
     * 注文が１つレコードを作成
     * 周期種別：月
     */
    @isTest
    static void testNormalPatten3() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            // 荷主を取得
            Account acc1 = [SELECT Id FROM Account WHERE Name = '荷主１'];
            Account acc2 = [SELECT Id FROM Account WHERE Name = '荷主２'];
            // 発地を取得
            OriginDestination__c orgDes1 = [SELECT Id FROM OriginDestination__c WHERE Name = '発地'];
            // 着地を取得
            OriginDestination__c orgDes2 = [SELECT Id FROM OriginDestination__c WHERE Name = '着地'];
            // ドライバーを取得
            DriverMaster__c driver = [SELECT Id FROM DriverMaster__c WHERE Name = 'driver'];
            // 商品マスタを取得
            ProductMaster__c product = [SELECT Id FROM ProductMaster__c WHERE Name = '商品１'];

            RegularServiceInformation__c regSerInfo = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc1.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/31'),
                RecurringEndDate__c = Date.parse('2025/04/02'),
                PeriodKind__c = 'Monthly',
                Date__c = 'MonthEnd',
                Status__c = 'Reception'
            );
            insert regSerInfo;

            Test.startTest();
            // バッチ処理の開始
            SchedulableContext sc = null;
            CreateOrderFromRegularServiceBatch b = new CreateOrderFromRegularServiceBatch();
            CreateOrderFromRegularServiceBatch.today = Date.parse('2025/03/24');
            b.execute(sc);
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
            ];
            // 注文明細
            OrderDetail__c ordDetail = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
            ];
            // 期待値と実行結果の検証
            // 注文
            System.assertEquals(ordHeader.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordHeader.Destination__c, regSerInfo.Destination__c); // 着地
            System.assertEquals(ordHeader.VehicleNumber__c, regSerInfo.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader.DriverMaster__c, regSerInfo.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader.ExpectedDeliveryDate__c, Date.parse('2025/04/01')); // 納品日
            System.assertEquals(ordHeader.LoadingDate__c, Date.parse('2025/03/31')); // 積込日
            System.assertEquals(ordHeader.OriginPlace__c, regSerInfo.OriginPlace__c); // 発地
            System.assertEquals(ordHeader.Amount__c, regSerInfo.Amount__c); // 運賃
            System.assertEquals(ordHeader.QuantityForShippingFeeCal__c, regSerInfo.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader.UnitForShippingFeeCal__c, regSerInfo.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader.InvoiceAccount__c, regSerInfo.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader.RegularServiceInformation__c, regSerInfo.Id); // 定期便情報#
            System.assertEquals(ordHeader.Remarks1__c, regSerInfo.Remarks1__c); // 備考①
            System.assertEquals(ordHeader.Remarks2__c, regSerInfo.Remarks2__c); // 備考②
            System.assertEquals(ordHeader.ShippingFeeManualFlag__c, regSerInfo.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader.ShippingCompany__c, regSerInfo.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader.TransportationMode__c, regSerInfo.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader.UnitPrice__c, regSerInfo.UnitPrice__c); // 単価
            System.assertEquals(ordHeader.AncillaryWorkFee__c, regSerInfo.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader.SubcontractFee__c, regSerInfo.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader.DepartureTime__c, regSerInfo.DepartureTime__c); // 出発時間帯
            // 注文明細
            System.assertEquals(ordDetail.Account__c, regSerInfo.Account__c); // 荷主
            System.assertEquals(ordDetail.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail.OrderHeader__c, ordHeader.Id); // 注文
            System.assertEquals(ordDetail.ProductMaster__c, regSerInfo.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail.Quantity__c, regSerInfo.Quantity__c); // 数量
            System.assertEquals(ordDetail.Unit__c, 'Pallet'); // 単位
        }
    }

    /**
     * 正常パターン４
     * 注文が２つレコードを作成
     * 周期種別：月
     */
    @isTest
    static void testNormalPatten4() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            // 荷主を取得
            Account acc1 = [SELECT Id FROM Account WHERE Name = '荷主１'];
            Account acc2 = [SELECT Id FROM Account WHERE Name = '荷主２'];
            // 発地を取得
            OriginDestination__c orgDes1 = [SELECT Id FROM OriginDestination__c WHERE Name = '発地'];
            // 着地を取得
            OriginDestination__c orgDes2 = [SELECT Id FROM OriginDestination__c WHERE Name = '着地'];
            // ドライバーを取得
            DriverMaster__c driver = [SELECT Id FROM DriverMaster__c WHERE Name = 'driver'];
            // 商品マスタを取得
            ProductMaster__c product = [SELECT Id FROM ProductMaster__c WHERE Name = '商品１'];

            RegularServiceInformation__c regSerInfo1 = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc1.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/25'),
                RecurringEndDate__c = Date.parse('2025/03/30'),
                PeriodKind__c = 'Monthly',
                Date__c = '25',
                Status__c = 'Reception'
            );
            insert regSerInfo1;

            RegularServiceInformation__c regSerInfo2 = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc1.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/25'),
                RecurringEndDate__c = Date.parse('2025/03/30'),
                PeriodKind__c = 'Monthly',
                Date__c = 'MonthEnd',
                Status__c = 'Reception'
            );
            insert regSerInfo2;

            RegularServiceInformation__c regSerInfo3 = new RegularServiceInformation__c(
                Account__c = acc1.Id,
                InvoiceAccount__c = acc1.Id,
                TransportationMode__c = 'Route',
                Destination__c = orgDes2.Id,
                DriverMaster__c = driver.Id,
                DeliveryDate__c = 1,
                OriginPlace__c = orgDes1.Id,
                Amount__c = 10000,
                QuantityForShippingFeeCal__c = 10,
                UnitForShippingFeeCal__c = 'Case',
                Remarks1__c = '備考１',
                Remarks2__c = '備考２',
                ShippingFeeManualFlag__c = true,
                ShippingCompany__c = acc2.Id,
                UnitPrice__c = 1000,
                SubcontractFee__c = 199,
                DepartureTime__c = 'AM',
                ProductMaster__c = product.Id,
                RecurringStartDate__c = Date.parse('2025/03/25'),
                RecurringEndDate__c = Date.parse('2025/03/30'),
                PeriodKind__c = 'Monthly',
                Date__c = '29',
                Status__c = 'Reception'
            );
            insert regSerInfo3;

            Test.startTest();
            // バッチ処理の開始
            SchedulableContext sc = null;
            CreateOrderFromRegularServiceBatch b = new CreateOrderFromRegularServiceBatch();
            CreateOrderFromRegularServiceBatch.today = Date.parse('2025/03/17');
            b.execute(sc);
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
                WHERE ExpectedDeliveryDate__c = :Date.parse('2025/03/26')
            ];
            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    Account__c,
                    Destination__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    ExpectedDeliveryDate__c,
                    LoadingDate__c,
                    OriginPlace__c,
                    Amount__c,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    InvoiceAccount__c,
                    RegularServiceInformation__c,
                    Remarks1__c,
                    Remarks2__c,
                    ShippingFeeManualFlag__c,
                    Status__c,
                    ShippingCompany__c,
                    TransportationMode__c,
                    UnitPrice__c,
                    AncillaryWorkFee__c,
                    SubcontractFee__c,
                    DepartureTime__c
                FROM OrderHeader__c
                WHERE ExpectedDeliveryDate__c = :Date.parse('2025/03/30')
            ];
            // 注文明細
            OrderDetail__c ordDetail1 = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
            ];
            OrderDetail__c ordDetail2 = [
                SELECT Id, Account__c, SequenceNumber__c, OrderHeader__c, ProductMaster__c, Quantity__c, Unit__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
            ];
            // 期待値と実行結果の検証
            // 注文1
            System.assertEquals(ordHeader1.Account__c, regSerInfo1.Account__c); // 荷主
            System.assertEquals(ordHeader1.Destination__c, regSerInfo1.Destination__c); // 着地
            System.assertEquals(ordHeader1.VehicleNumber__c, regSerInfo1.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader1.DriverMaster__c, regSerInfo1.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader1.ExpectedDeliveryDate__c, Date.parse('2025/03/26')); // 納品日
            System.assertEquals(ordHeader1.LoadingDate__c, Date.parse('2025/03/25')); // 積込日
            System.assertEquals(ordHeader1.OriginPlace__c, regSerInfo1.OriginPlace__c); // 発地
            System.assertEquals(ordHeader1.Amount__c, regSerInfo1.Amount__c); // 運賃
            System.assertEquals(ordHeader1.QuantityForShippingFeeCal__c, regSerInfo1.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader1.UnitForShippingFeeCal__c, regSerInfo1.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader1.InvoiceAccount__c, regSerInfo1.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader1.RegularServiceInformation__c, regSerInfo1.Id); // 定期便情報#
            System.assertEquals(ordHeader1.Remarks1__c, regSerInfo1.Remarks1__c); // 備考①
            System.assertEquals(ordHeader1.Remarks2__c, regSerInfo1.Remarks2__c); // 備考②
            System.assertEquals(ordHeader1.ShippingFeeManualFlag__c, regSerInfo1.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader1.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader1.ShippingCompany__c, regSerInfo1.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader1.TransportationMode__c, regSerInfo1.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader1.UnitPrice__c, regSerInfo1.UnitPrice__c); // 単価
            System.assertEquals(ordHeader1.AncillaryWorkFee__c, regSerInfo1.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader1.SubcontractFee__c, regSerInfo1.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader1.DepartureTime__c, regSerInfo1.DepartureTime__c); // 出発時間帯
            // 注文明細1
            System.assertEquals(ordDetail1.Account__c, regSerInfo1.Account__c); // 荷主
            System.assertEquals(ordDetail1.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail1.OrderHeader__c, ordHeader1.Id); // 注文
            System.assertEquals(ordDetail1.ProductMaster__c, regSerInfo1.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail1.Quantity__c, regSerInfo1.Quantity__c); // 数量
            System.assertEquals(ordDetail1.Unit__c, 'Pallet'); // 単位
            // 注文2
            System.assertEquals(ordHeader2.Account__c, regSerInfo3.Account__c); // 荷主
            System.assertEquals(ordHeader2.Destination__c, regSerInfo3.Destination__c); // 着地
            System.assertEquals(ordHeader2.VehicleNumber__c, regSerInfo3.VehicleNumber__c); // 車番
            System.assertEquals(ordHeader2.DriverMaster__c, regSerInfo3.DriverMaster__c); // ドライバー
            System.assertEquals(ordHeader2.ExpectedDeliveryDate__c, Date.parse('2025/03/30')); // 納品日
            System.assertEquals(ordHeader2.LoadingDate__c, Date.parse('2025/03/29')); // 積込日
            System.assertEquals(ordHeader2.OriginPlace__c, regSerInfo3.OriginPlace__c); // 発地
            System.assertEquals(ordHeader2.Amount__c, regSerInfo3.Amount__c); // 運賃
            System.assertEquals(ordHeader2.QuantityForShippingFeeCal__c, regSerInfo3.QuantityForShippingFeeCal__c); // 運賃計算用数量
            System.assertEquals(ordHeader2.UnitForShippingFeeCal__c, regSerInfo3.UnitForShippingFeeCal__c); // 運賃計算用単位
            System.assertEquals(ordHeader2.InvoiceAccount__c, regSerInfo3.InvoiceAccount__c); // 請求先（集計使用名）
            System.assertEquals(ordHeader2.RegularServiceInformation__c, regSerInfo3.Id); // 定期便情報#
            System.assertEquals(ordHeader2.Remarks2__c, regSerInfo3.Remarks2__c); // 備考①
            System.assertEquals(ordHeader2.Remarks2__c, regSerInfo3.Remarks2__c); // 備考②
            System.assertEquals(ordHeader2.ShippingFeeManualFlag__c, regSerInfo3.ShippingFeeManualFlag__c); // 運賃手動計算フラグ
            System.assertEquals(ordHeader2.Status__c, 'Reception'); // 状態
            System.assertEquals(ordHeader2.ShippingCompany__c, regSerInfo3.ShippingCompany__c); // 配送会社
            System.assertEquals(ordHeader2.TransportationMode__c, regSerInfo3.TransportationMode__c); // 輸送形態
            System.assertEquals(ordHeader2.UnitPrice__c, regSerInfo3.UnitPrice__c); // 単価
            System.assertEquals(ordHeader2.AncillaryWorkFee__c, regSerInfo3.AncillaryWorkFee__c); // 付帯作業費
            System.assertEquals(ordHeader2.SubcontractFee__c, regSerInfo3.SubcontractFee__c); // 下請け料金
            System.assertEquals(ordHeader2.DepartureTime__c, regSerInfo3.DepartureTime__c); // 出発時間帯
            // 注文明細2
            System.assertEquals(ordDetail2.Account__c, regSerInfo3.Account__c); // 荷主
            System.assertEquals(ordDetail2.SequenceNumber__c, 1); // 枝番
            System.assertEquals(ordDetail2.OrderHeader__c, ordHeader2.Id); // 注文
            System.assertEquals(ordDetail2.ProductMaster__c, regSerInfo3.ProductMaster__c); // 商品マスタ
            System.assertEquals(ordDetail2.Quantity__c, regSerInfo3.Quantity__c); // 数量
            System.assertEquals(ordDetail2.Unit__c, 'Pallet'); // 単位
        }
    }

    /**
     * 異常パターン１
     * 実行日は月曜日でない場合
     */
    @isTest
    static void testErrorPatten1() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            Test.startTest();
            try {
                // バッチ処理の開始
                SchedulableContext sc = null;
                CreateOrderFromRegularServiceBatch b = new CreateOrderFromRegularServiceBatch();
                CreateOrderFromRegularServiceBatch.today = Date.parse('2025/03/11');
                b.execute(sc);
            } catch (Exception e) {
            }
            Test.stopTest();
        }
    }

    /**
     * 異常パターン２
     */
    @isTest
    static void testErrorPatten2() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            Test.startTest();
            try {
                CreateOrderFromRegularServiceBatch batch = new CreateOrderFromRegularServiceBatch();
                batch.allCount = 1;
                batch.executeDate = Date.parse('2025/03/11');
                batch.errorNaiyouList.add('テストエラー');
                batch.finish(null);
            } catch (Exception e) {
            }
            Test.stopTest();
        }
    }

    /**
     * 異常パターン３
     */
    @isTest
    static void testErrorPatten3() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];

        System.runAs(u) {
            Test.startTest();
            try {
                CreateOrderFromRegularServiceBatch batch = new CreateOrderFromRegularServiceBatch();
                batch.allCount = 1;
                batch.executeDate = Date.parse('2025/03/11');
                batch.errorMessageList.add('テストエラー');
                batch.finish(null);
            } catch (Exception e) {
            }
            Test.stopTest();
        }
    }

    /**
     * テスト用のユーザを作成
     */
    static void createTestUser() {
        Profile p = [
            SELECT Id
            FROM Profile
            WHERE Name = 'システム管理者'
        ];
        User u = new User(
            Alias = 'standt',
            Email = 'CreateOrderFromRegServiceBatchTest@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'ja',
            LocaleSidKey = 'ja_JP',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Tokyo',
            UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'
        );
        insert u;
    }

    /**
     * 荷主を作成
     */
    static void createAccount() {
        Account acc1 = new Account(
            Name = '荷主１',
            Type = 'Account',
            BillingCountry = '日本',
            BillingState = '千葉県',
            BillingCity = '松戸市'
            // AccountCode__c = '12345'
        );
        insert acc1;

        Account acc2 = new Account(
            Name = '荷主２',
            Type = 'Account',
            BillingCountry = '日本',
            BillingState = '千葉県',
            BillingCity = '松戸市'
            // AccountCode__c = '67890'
        );
        insert acc2;
    }

    /**
     * ドライバーを作成
     */
    static void createDriver() {
        DriverMaster__c driver = new DriverMaster__c(Name = 'driver', UniqueKey__c = 'driver');
        insert driver;
    }

    /**
     * 発着地を作成
     */
    static void createOriginDestination() {
        // 荷主を取得
        // Account acc = [SELECT Id FROM Account WHERE AccountCode__c = '12345' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = '荷主１' LIMIT 1];

        OriginDestination__c origDes1 = new OriginDestination__c(
            Name = '発地',
            Account__c = acc.Id,
            DeliveryArea__c = 'Medium',
            Prefecture__c = '埼玉県'
        );
        insert origDes1;

        OriginDestination__c origDes2 = new OriginDestination__c(
            Name = '着地',
            Account__c = acc.Id,
            DeliveryArea__c = 'Medium',
            Prefecture__c = '千葉県'
        );
        insert origDes2;
    }

    /**
     * 商品を作成
     */
    static void createProductMaster() {
        // 荷主を取得
        // Account acc = [SELECT Id FROM Account WHERE AccountCode__c = '12345' LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE Name = '荷主１' LIMIT 1];

        ProductMaster__c product = new ProductMaster__c(
            Name = '商品１',
            Account__c = acc.Id,
            ProductCode__c = 'HM3142'
            // ,PackageForm1UnitName__c = 'Case'
        );
        insert product;
    }
}