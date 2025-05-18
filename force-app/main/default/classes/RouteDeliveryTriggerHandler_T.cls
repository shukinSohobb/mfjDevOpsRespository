/**
 * 路線便から注文と注文明細を作成トリガーハンドラテストクラス
 */
@istest
public with sharing class RouteDeliveryTriggerHandler_T {
    @TestSetup
    static void setup() {
        // テストユーザーを作成
        createTestUser();
    }

    /**
     * 正常パターン１
     * 注文が１つレコードを作成
     * 注文の注文明細が１つレコードを作成
     */
    @isTest
    static void testNormalPatten1() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            list<RouteDelivery__c> routeDelList = new List<RouteDelivery__c>();
            RouteDelivery__c route = new RouteDelivery__c();
            route.SlipNumber__c = 'TestRoute999999911';
            route.LineNumber__c = 1;
            route.SalesReservationCategory__c = '確定';
            route.DataCategory__c = '売上';
            route.ReservationSlipNumber__c = '伝票№408956';
            route.SlipKindDesignated__c = '客先専用伝票';
            route.SalesRep__c = '700-348';
            route.InputBy__c = '寺西　明男';
            route.ReceptionDate__c = Date.valueOf('2025-03-20');
            route.ShippingDate__c = Date.valueOf('2025-03-20');
            route.ExpectedDeliveryDate__c = Date.valueOf('2025-03-20');
            route.StockLocationCD__c = '366';
            route.StockLocationName__c = 'MFJ';
            route.DestinationCD__c = '5520';
            route.ProductCD__c = '195419';
            route.ItemName__c = 'ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml';
            route.Quantity__c = 50;
            route.UnitQuantity__c = 10;
            route.CSQuantity__c = 5;
            route.UnitPrice__c = 1000;
            route.WeightKG__c = 339.98;
            route.Amount__c = 12888;
            route.ShippingCD__c = '3356';
            route.DestinationName__c = '業務スーパー小手指店';
            route.ShippingPostCode__c = '823-0011';
            route.ShippingAddress1__c = '福岡県宮若市宮田542-4';
            route.ShippingAddress2__c = '三菱食品　宮田常温物流ｾﾝ';
            route.ShippingAddress3__c = 'ﾀｰ内';
            route.ShippingPhone__c = '0949-34-7667';
            route.ShippingDistrictCode__c = '40000';
            route.SenderName__c = 'ｾﾝﾄﾐﾊｴﾙﾜｲﾝｱﾝﾄﾞｽﾋﾟﾘｯﾂ㈱';
            route.InvoiceField__c = '岡山本店酒売場';
            route.DeliveryCD__c = '800041';
            route.DeliveryName__c = '甲府通運(小口)';
            route.DepartureTime__c = 'AM';
            route.BurdenDepartment__c = '700';
            route.ShippingArranger__c = '888-9090';
            route.Purpose__c = '路線便用';
            route.Distance__c = 100;
            route.DistrictPremium__c = 500;
            route.RelayFee__c = 130;
            route.Remarks__c = '路線便備考';
            route.AccountCD__c = '5930';
            route.AccountName__c = '国分東北(株)卸事業部営業課';
            route.AccountPhone__c = '018-823-8501';
            routeDelList.add(route);

            Test.startTest();
            insert routeDelList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 路線便
            RouteDelivery__c routeDel = [
                SELECT Id, OrderHeader__c
                FROM RouteDelivery__c
                WHERE SlipNumber__c = :route.SlipNumber__c
            ];
            // 注文
            OrderHeader__c ordHeader = [
                SELECT
                    Id,
                    OrderNumber__c, // 依頼番号
                    SlipKindDesignated__c, // 伝票種別指定
                    ReceptionDatetime__c, // 受付日時
                    LoadingDate__c, // 積込日
                    ExpectedDeliveryDate__c, // 納品日
                    InportedDeliveryDestination__c, // 納品先
                    DeliveryDestinationPostalCode__c, // 納品先郵便番号
                    DeliveryDestinationAddress__c, // 納品先住所1
                    DeliveryDestinationAddress2__c, // 納品先住所2
                    ImportedDeliveryDestinationPhone__c, // 納品先電話番号
                    DepartureTime__c, // 出発時間帯
                    UnitPriceRoute__c, // 単価
                    AmountRoute__c, // 運賃（路線便）
                    ImportedAccountName__c, // 取引先
                    Status__c, // 状態
                    ShippingCompany__c, // 配送会社
                    DistanceRoute__c, // 距離（路線便）
                    AreaDifferential__c, // 地区割増
                    RelayFee__c, // 中継費
                    ShippingName__c, // 配送名
                    TransportationMode__c // 輸送形態
                FROM OrderHeader__c
                WHERE OrderNumber__c = :route.SlipNumber__c
            ];
            // 注文明細
            OrderDetail__c ordDetail = [
                SELECT
                    Id,
                    ItemCode__c, // 品目コード
                    ItemName__c, // 品名
                    SequenceNumber__c, // 枝番
                    Quantity__c, // 数量
                    UnitQuantity__c, // 入数
                    CSQuantity__c, // CS数
                    WeightKG__c, // 重量（Kg）
                    Remarks__c, // 備考
                    OrderHeader__c // 注文
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader.Id
                ORDER BY SequenceNumber__c
            ];
            // 期待値と実行結果の検証
            // 注文
            System.assertEquals(routeDel.OrderHeader__c, ordHeader.Id); // ID
            System.assertEquals('TestRoute999999911', ordHeader.OrderNumber__c); // 依頼番号
            System.assertEquals('客先専用伝票', ordHeader.SlipKindDesignated__c); // 伝票種別指定
            System.assertEquals(Datetime.valueOf('2025-03-19 15:00:00').addHours(9), ordHeader.ReceptionDatetime__c); // 受付日時
            System.assertEquals(Date.valueOf('2025-03-20'), ordHeader.LoadingDate__c); // 積込日
            System.assertEquals(Date.valueOf('2025-03-20'), ordHeader.ExpectedDeliveryDate__c); // 納品日
            System.assertEquals(1000, ordHeader.UnitPriceRoute__c); // 単価
            System.assertEquals(13518, ordHeader.AmountRoute__c); // 運賃（路線便）
            System.assertEquals('業務スーパー小手指店', ordHeader.InportedDeliveryDestination__c); // 納品先
            System.assertEquals('823-0011', ordHeader.DeliveryDestinationPostalCode__c); // 納品先郵便番号
            System.assertEquals('福岡県宮若市宮田542-4三菱食品　宮田常温物流ｾﾝ', ordHeader.DeliveryDestinationAddress__c); // 納品先住所１
            System.assertEquals('ﾀｰ内', ordHeader.DeliveryDestinationAddress2__c); // 納品先住所２
            System.assertEquals('0949-34-7667', ordHeader.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals('甲府通運(小口)', ordHeader.ShippingName__c); // 配送名
            System.assertEquals('AM', ordHeader.DepartureTime__c); // 出発時間帯
            System.assertEquals(100, ordHeader.DistanceRoute__c); // 距離（路線便）
            System.assertEquals('国分東北(株)卸事業部営業課', ordHeader.ImportedAccountName__c); // 取引先名
            System.assertEquals('Reception', ordHeader.Status__c); // 状態
            System.assertEquals('Route', ordHeader.TransportationMode__c); // 輸送形態

            // 注文明細
            System.assertEquals('ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml', ordDetail.ItemName__c); // 品名
            System.assertEquals(50, ordDetail.Quantity__c); // 数量
            System.assertEquals(10, ordDetail.UnitQuantity__c); // 入数
            System.assertEquals(5, ordDetail.CSQuantity__c); // CS数
            System.assertEquals(339.98, ordDetail.WeightKG__c); // 重量（Kg）
            System.assertEquals('路線便用路線便備考', ordDetail.Remarks__c); // 備考
            System.assertEquals(1, ordDetail.SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader.Id, ordDetail.OrderHeader__c); // 注文
        }
    }

    /**
     * 正常パターン２
     * 注文が２つレコードを作成
     * 注文1の注文明細が２つレコードを作成
     * 注文2の注文明細1レコードを作成、注文明細2レコードを削除、注文明細3レコードを更新
     */
    @isTest
    static void testNormalPatten2() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            // 注文を作成する
            List<OrderHeader__c> newOrderHeaderList = new List<OrderHeader__c>();
            OrderHeader__c newOrderHeader = new OrderHeader__c();
            newOrderHeader.ImportedAccountName__c = 'ImportedAccountName__c'; // 取引先
            newOrderHeader.InportedDeliveryDestination__c = 'InportedDeliveryDestination__c'; //納品先
            newOrderHeader.ImportedDeliveryDestinationPhone__c = '123456789'; // 納品先電話番号
            newOrderHeader.OrderNumber__c = 'TestRoute999999922'; // 依頼番号
            newOrderHeader.DeliveryDestinationAddress__c = 'DeliveryDestinationAddress__c'; //納品先住所
            newOrderHeader.ReceptionDatetime__c = Datetime.parse('2025/03/17 00:00'); // 受付日
            newOrderHeader.CloseDate__c = date.parse('2025/03/17'); // 取引日
            newOrderHeaderList.add(newOrderHeader);
            insert newOrderHeaderList;

            // 注文明細を作成する
            List<OrderDetail__c> newOrderDetailList = new List<OrderDetail__c>();
            OrderDetail__c newOrderDetail1 = new OrderDetail__c();
            newOrderDetail1.ItemName__c = '品名１'; // 品名
            newOrderDetail1.SequenceNumber__c = 1; // 枝番
            newOrderDetail1.Quantity__c = 100; // 数量
            newOrderDetail1.UnitQuantity__c = 10; // 入数
            newOrderDetail1.CSQuantity__c = 10; // CS数
            newOrderDetail1.WeightKG__c = 9008; // 重量（Kg）
            newOrderDetail1.Remarks__c = '備考テスト1'; // 備考
            newOrderDetail1.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail1);

            OrderDetail__c newOrderDetail3 = new OrderDetail__c();
            newOrderDetail3.ItemName__c = '品名３'; // 品名
            newOrderDetail3.SequenceNumber__c = 3; // 枝番
            newOrderDetail3.Quantity__c = 90; // 数量
            newOrderDetail3.UnitQuantity__c = 30; // 入数
            newOrderDetail3.CSQuantity__c = 3; // CS数
            newOrderDetail3.WeightKG__c = 900; // 重量（Kg）
            newOrderDetail3.Remarks__c = '備考テスト3'; // 備考
            newOrderDetail3.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail3);
            insert newOrderDetailList;

            // 路線便を作成
            list<RouteDelivery__c> routeDelList = new List<RouteDelivery__c>();
            RouteDelivery__c route1 = new RouteDelivery__c();
            route1.SlipNumber__c = 'TestRoute999999921';
            route1.LineNumber__c = 1;
            route1.SalesReservationCategory__c = '確定';
            route1.DataCategory__c = '売上';
            route1.ReservationSlipNumber__c = '伝票№408956';
            route1.SlipKindDesignated__c = '客先専用伝票2-1';
            route1.SalesRep__c = '700-348';
            route1.InputBy__c = '寺西　明男';
            route1.ReceptionDate__c = Date.valueOf('2025-04-20');
            route1.ShippingDate__c = Date.valueOf('2025-04-20');
            route1.ExpectedDeliveryDate__c = Date.valueOf('2025-04-20');
            route1.StockLocationCD__c = '366';
            route1.StockLocationName__c = 'MFJ';
            route1.DestinationCD__c = '5520';
            route1.ProductCD__c = '195419';
            route1.ItemName__c = 'ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml';
            route1.Quantity__c = 50;
            route1.UnitQuantity__c = 10;
            route1.CSQuantity__c = 5;
            route1.UnitPrice__c = 1000;
            route1.WeightKG__c = 339.98;
            route1.Amount__c = 12888;
            route1.ShippingCD__c = '3356';
            route1.DestinationName__c = '業務スーパー小手指店';
            route1.ShippingPostCode__c = '823-0011';
            route1.ShippingAddress1__c = '福岡県宮若市宮田542-4';
            route1.ShippingAddress2__c = '三菱食品　宮田常温物流ｾﾝ';
            route1.ShippingAddress3__c = 'ﾀｰ内';
            route1.ShippingPhone__c = '0949-34-7667';
            route1.ShippingDistrictCode__c = '40000';
            route1.SenderName__c = 'ｾﾝﾄﾐﾊｴﾙﾜｲﾝｱﾝﾄﾞｽﾋﾟﾘｯﾂ㈱';
            route1.InvoiceField__c = '岡山本店酒売場';
            route1.DeliveryCD__c = '800041';
            route1.DeliveryName__c = '甲府通運(小口)';
            route1.DepartureTime__c = 'AM';
            route1.BurdenDepartment__c = '700';
            route1.ShippingArranger__c = '888-9090';
            route1.Purpose__c = '路線便用';
            route1.Distance__c = 100;
            route1.DistrictPremium__c = 500;
            route1.RelayFee__c = 130;
            route1.Remarks__c = '路線便備考';
            route1.AccountCD__c = '5930';
            route1.AccountName__c = '国分東北(株)卸事業部営業課';
            route1.AccountPhone__c = '018-823-8501';
            routeDelList.add(route1);

            RouteDelivery__c route2 = new RouteDelivery__c();
            route2.SlipNumber__c = 'TestRoute999999921';
            route2.LineNumber__c = 2;
            route2.SalesReservationCategory__c = '確定';
            route2.DataCategory__c = '売上';
            route2.ReservationSlipNumber__c = '伝票№408956';
            route2.SlipKindDesignated__c = '客先専用伝票2-2';
            route2.SalesRep__c = '700-348';
            route2.InputBy__c = '寺西　明男';
            route2.ReceptionDate__c = Date.valueOf('2025-04-21');
            route2.ShippingDate__c = Date.valueOf('2025-04-22');
            route2.ExpectedDeliveryDate__c = Date.valueOf('2025-04-23');
            route2.StockLocationCD__c = '366';
            route2.StockLocationName__c = 'MFJ';
            route2.DestinationCD__c = '5520';
            route2.ProductCD__c = '195419';
            route2.ItemName__c = 'ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 900ml';
            route2.Quantity__c = 90;
            route2.UnitQuantity__c = 9;
            route2.CSQuantity__c = 10;
            route2.UnitPrice__c = 79;
            route2.WeightKG__c = 339.98;
            route2.Amount__c = 4000;
            route2.ShippingCD__c = '3356';
            route2.DestinationName__c = '業務スーパー小手指店';
            route2.ShippingPostCode__c = '823-0022';
            route2.ShippingAddress1__c = '福岡県宮若市宮田542-4';
            route2.ShippingAddress2__c = '三菱食品　宮田常温物流ｾﾝﾀｰ内';
            route2.ShippingPhone__c = '';
            route2.ShippingDistrictCode__c = '40000';
            route2.SenderName__c = 'ｾﾝﾄﾐﾊｴﾙﾜｲﾝｱﾝﾄﾞｽﾋﾟﾘｯﾂ㈱';
            route2.InvoiceField__c = '岡山本店酒売場';
            route2.DeliveryCD__c = '800041';
            route2.DeliveryName__c = '甲府通運(小口)2';
            route2.DepartureTime__c = 'PM';
            route2.BurdenDepartment__c = '700';
            route2.ShippingArranger__c = '888-9090';
            route2.Purpose__c = '路線便用';
            route2.Distance__c = 900;
            route2.DistrictPremium__c = 500;
            route2.RelayFee__c = 400;
            route2.Remarks__c = '路線便備考2';
            route2.AccountCD__c = '5930';
            route2.AccountName__c = '国分東北(株)卸事業部営業課';
            route2.AccountPhone__c = '018-823-8501';
            routeDelList.add(route2);

            RouteDelivery__c route3 = new RouteDelivery__c();
            route3.SlipNumber__c = 'TestRoute999999922';
            route3.LineNumber__c = 1;
            route3.SalesReservationCategory__c = '確定';
            route3.DataCategory__c = '売上';
            route3.ReservationSlipNumber__c = '伝票№408956';
            route3.SlipKindDesignated__c = '客先専用伝票2-2';
            route3.SalesRep__c = '700-348';
            route3.InputBy__c = '寺西　明男';
            route3.ReceptionDate__c = Date.valueOf('2025-04-21');
            route3.ShippingDate__c = Date.valueOf('2025-04-22');
            route3.ExpectedDeliveryDate__c = Date.valueOf('2025-04-23');
            route3.StockLocationCD__c = '366';
            route3.StockLocationName__c = 'MFJ';
            route3.DestinationCD__c = '5520';
            route3.ProductCD__c = '195419';
            route3.ItemName__c = 'ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml';
            route3.Quantity__c = 50;
            route3.UnitQuantity__c = 10;
            route3.CSQuantity__c = 5;
            route3.UnitPrice__c = 500;
            route3.WeightKG__c = 339.98;
            route3.Amount__c = 4000;
            route3.ShippingCD__c = '3356';
            route3.DestinationName__c = '業務スーパー小手指店2';
            route3.ShippingPostCode__c = '823-0022';
            route3.ShippingAddress1__c = '福岡県宮若市宮田542-4';
            route3.ShippingAddress2__c = '三菱食品　宮田常温物流ｾﾝﾀｰ内';
            route3.ShippingPhone__c = '';
            route3.ShippingDistrictCode__c = '40000';
            route3.SenderName__c = 'ｾﾝﾄﾐﾊｴﾙﾜｲﾝｱﾝﾄﾞｽﾋﾟﾘｯﾂ㈱';
            route3.InvoiceField__c = '岡山本店酒売場';
            route3.DeliveryCD__c = '800041';
            route3.DeliveryName__c = '甲府通運(小口)2';
            route3.DepartureTime__c = 'PM';
            route3.BurdenDepartment__c = '700';
            route3.ShippingArranger__c = '888-9090';
            route3.Purpose__c = '路線便用';
            route3.Distance__c = 900;
            route3.DistrictPremium__c = 500;
            route3.RelayFee__c = 400;
            route3.Remarks__c = '路線便備考2-2';
            route3.AccountCD__c = '5930';
            route3.AccountName__c = '国分東北(株)卸事業部営業課';
            route3.AccountPhone__c = '018-823-8501';
            routeDelList.add(route3);

            RouteDelivery__c route4 = new RouteDelivery__c();
            route4.SlipNumber__c = 'TestRoute999999922';
            route4.LineNumber__c = 2;
            route4.SalesReservationCategory__c = '確定';
            route4.DataCategory__c = '売上';
            route4.ReservationSlipNumber__c = '伝票№408956';
            route4.SlipKindDesignated__c = '客先専用伝票2-2';
            route4.SalesRep__c = '700-348';
            route4.InputBy__c = '寺西　明男';
            route4.ReceptionDate__c = Date.valueOf('2025-04-21');
            route4.ShippingDate__c = Date.valueOf('2025-04-22');
            route4.ExpectedDeliveryDate__c = Date.valueOf('2025-04-23');
            route4.StockLocationCD__c = '366';
            route4.StockLocationName__c = 'MFJ';
            route4.DestinationCD__c = '5520';
            route4.ProductCD__c = '195419';
            route4.ItemName__c = 'ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml';
            route4.Quantity__c = 50;
            route4.UnitQuantity__c = 10;
            route4.CSQuantity__c = 5;
            route4.UnitPrice__c = 500;
            route4.WeightKG__c = 339.98;
            route4.Amount__c = 4000;
            route4.ShippingCD__c = '3356';
            route4.DestinationName__c = '業務スーパー小手指店2';
            route4.ShippingPostCode__c = '823-0022';
            route4.ShippingAddress1__c = '福岡県宮若市宮田542-4';
            route4.ShippingAddress2__c = '三菱食品　宮田常温物流ｾﾝﾀｰ内';
            route4.ShippingPhone__c = '';
            route4.ShippingDistrictCode__c = '40000';
            route4.SenderName__c = 'ｾﾝﾄﾐﾊｴﾙﾜｲﾝｱﾝﾄﾞｽﾋﾟﾘｯﾂ㈱';
            route4.InvoiceField__c = '岡山本店酒売場';
            route4.DeliveryCD__c = '800041';
            route4.DeliveryName__c = '甲府通運(小口)2';
            route4.DepartureTime__c = 'PM';
            route4.BurdenDepartment__c = '700';
            route4.ShippingArranger__c = '888-9090';
            route4.Purpose__c = '路線便用';
            route4.Distance__c = 900;
            route4.DistrictPremium__c = 500;
            route4.RelayFee__c = 400;
            route4.Remarks__c = '路線便備考2-3';
            route4.AccountCD__c = '5930';
            route4.AccountName__c = '国分東北(株)卸事業部営業課';
            route4.AccountPhone__c = '018-823-8501';
            routeDelList.add(route4);

            Test.startTest();
            insert routeDelList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    OrderNumber__c, // 依頼番号
                    SlipKindDesignated__c, // 伝票種別指定
                    ReceptionDatetime__c, // 受付日時
                    LoadingDate__c, // 積込日
                    ExpectedDeliveryDate__c, // 納品日
                    InportedDeliveryDestination__c, // 納品先
                    DeliveryDestinationPostalCode__c, // 納品先郵便番号
                    DeliveryDestinationAddress__c, // 納品先住所1
                    DeliveryDestinationAddress2__c, // 納品先住所2
                    ImportedDeliveryDestinationPhone__c, // 納品先電話番号
                    DepartureTime__c, // 出発時間帯
                    UnitPriceRoute__c, // 単価
                    AmountRoute__c, // 運賃（路線便）
                    ImportedAccountName__c, // 取引先
                    Status__c, // 状態
                    ShippingCompany__c, // 配送会社
                    DistanceRoute__c, // 距離（路線便）
                    AreaDifferential__c, // 地区割増
                    RelayFee__c, // 中継費
                    ShippingName__c, // 配送名
                    TransportationMode__c // 輸送形態
                FROM OrderHeader__c
                WHERE OrderNumber__c = 'TestRoute999999921'
            ];

            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    OrderNumber__c, // 依頼番号
                    SlipKindDesignated__c, // 伝票種別指定
                    ReceptionDatetime__c, // 受付日時
                    LoadingDate__c, // 積込日
                    ExpectedDeliveryDate__c, // 納品日
                    InportedDeliveryDestination__c, // 納品先
                    DeliveryDestinationPostalCode__c, // 納品先郵便番号
                    DeliveryDestinationAddress__c, // 納品先住所1
                    DeliveryDestinationAddress2__c, // 納品先住所2
                    ImportedDeliveryDestinationPhone__c, // 納品先電話番号
                    DepartureTime__c, // 出発時間帯
                    UnitPriceRoute__c, // 単価
                    AmountRoute__c, // 運賃（路線便）
                    ImportedAccountName__c, // 取引先
                    Status__c, // 状態
                    ShippingCompany__c, // 配送会社
                    DistanceRoute__c, // 距離（路線便）
                    AreaDifferential__c, // 地区割増
                    RelayFee__c, // 中継費
                    ShippingName__c, // 配送名
                    TransportationMode__c // 輸送形態
                FROM OrderHeader__c
                WHERE OrderNumber__c = 'TestRoute999999922'
            ];

            // 注文明細
            List<OrderDetail__c> ordDetail1 = [
                SELECT
                    Id,
                    ItemCode__c, // 品目コード
                    ItemName__c, // 品名
                    SequenceNumber__c, // 枝番
                    Quantity__c, // 数量
                    UnitQuantity__c, // 入数
                    CSQuantity__c, // CS数
                    WeightKG__c, // 重量（Kg）
                    Remarks__c, // 備考
                    OrderHeader__c // 注文
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
                ORDER BY SequenceNumber__c
            ];

            List<OrderDetail__c> ordDetail2 = [
                SELECT
                    Id,
                    ItemCode__c, // 品目コード
                    ItemName__c, // 品名
                    SequenceNumber__c, // 枝番
                    Quantity__c, // 数量
                    UnitQuantity__c, // 入数
                    CSQuantity__c, // CS数
                    WeightKG__c, // 重量（Kg）
                    Remarks__c, // 備考
                    OrderHeader__c // 注文
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
                ORDER BY SequenceNumber__c
            ];

            // 期待値と実行結果の検証
            // 注文１
            System.assertEquals('TestRoute999999921', ordHeader1.OrderNumber__c); // 依頼番号
            System.assertEquals('客先専用伝票2-2', ordHeader1.SlipKindDesignated__c); // 伝票種別指定
            System.assertEquals(Datetime.valueOf('2025-04-20 15:00:00').addHours(9), ordHeader1.ReceptionDatetime__c); // 受付日時
            System.assertEquals(Date.valueOf('2025-04-22'), ordHeader1.LoadingDate__c); // 積込日
            System.assertEquals(Date.valueOf('2025-04-23'), ordHeader1.ExpectedDeliveryDate__c); // 納品日
            System.assertEquals(79, ordHeader1.UnitPriceRoute__c); // 単価
            System.assertEquals(4900, ordHeader1.AmountRoute__c); // 運賃（路線便）
            System.assertEquals('業務スーパー小手指店', ordHeader1.InportedDeliveryDestination__c); // 納品先
            System.assertEquals('823-0022', ordHeader1.DeliveryDestinationPostalCode__c); // 納品先郵便番号
            System.assertEquals(
                '福岡県宮若市宮田542-4三菱食品　宮田常温物流ｾﾝﾀｰ内',
                ordHeader1.DeliveryDestinationAddress__c
            ); // 納品先住所１
            Assert.isTrue(String.isBlank(ordHeader1.DeliveryDestinationAddress2__c)); // 納品先住所２
            //System.assertEquals('0949-34-7667', ordHeader1.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals('甲府通運(小口)2', ordHeader1.ShippingName__c); // 配送名
            System.assertEquals('PM', ordHeader1.DepartureTime__c); // 出発時間帯
            System.assertEquals(900.000, ordHeader1.DistanceRoute__c); // 距離（路線便）
            System.assertEquals('国分東北(株)卸事業部営業課', ordHeader1.ImportedAccountName__c); // 取引先名
            System.assertEquals('Reception', ordHeader1.Status__c); // 状態
            System.assertEquals('Route', ordHeader1.TransportationMode__c); // 輸送形態

            // 注文明細1
            System.assertEquals('ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml', ordDetail1[0].ItemName__c); // 品名
            System.assertEquals(50, ordDetail1[0].Quantity__c); // 数量
            System.assertEquals(10, ordDetail1[0].UnitQuantity__c); // 入数
            System.assertEquals(5, ordDetail1[0].CSQuantity__c); // CS数
            System.assertEquals(339.98, ordDetail1[0].WeightKG__c); // 重量（Kg）
            System.assertEquals('路線便用路線便備考', ordDetail1[0].Remarks__c); // 備考
            System.assertEquals(1, ordDetail1[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[0].OrderHeader__c); // 注文
            // 注文明細2
            System.assertEquals('ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 900ml', ordDetail1[1].ItemName__c); // 品名
            System.assertEquals(90, ordDetail1[1].Quantity__c); // 数量
            System.assertEquals(9, ordDetail1[1].UnitQuantity__c); // 入数
            System.assertEquals(10, ordDetail1[1].CSQuantity__c); // CS数
            System.assertEquals(339.98, ordDetail1[1].WeightKG__c); // 重量（Kg）
            System.assertEquals('路線便用路線便備考2', ordDetail1[1].Remarks__c); // 備考
            System.assertEquals(2, ordDetail1[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[0].OrderHeader__c); // 注文

            // 注文２
            System.assertEquals('TestRoute999999922', ordHeader2.OrderNumber__c); // 依頼番号
            System.assertEquals('客先専用伝票2-2', ordHeader2.SlipKindDesignated__c); // 伝票種別指定
            System.assertEquals(Datetime.valueOf('2025-04-20 15:00:00').addHours(9), ordHeader2.ReceptionDatetime__c); // 受付日時
            System.assertEquals(Date.valueOf('2025-04-22'), ordHeader2.LoadingDate__c); // 積込日
            System.assertEquals(Date.valueOf('2025-04-23'), ordHeader2.ExpectedDeliveryDate__c); // 納品日
            System.assertEquals(500, ordHeader2.UnitPriceRoute__c); // 単価
            System.assertEquals(4900, ordHeader2.AmountRoute__c); // 運賃（路線便）
            System.assertEquals('業務スーパー小手指店2', ordHeader2.InportedDeliveryDestination__c); // 納品先
            System.assertEquals('823-0022', ordHeader2.DeliveryDestinationPostalCode__c); // 納品先郵便番号
            System.assertEquals(
                '福岡県宮若市宮田542-4三菱食品　宮田常温物流ｾﾝﾀｰ内',
                ordHeader2.DeliveryDestinationAddress__c
            ); // 納品先住所１
            Assert.isTrue(String.isBlank(ordHeader2.DeliveryDestinationAddress2__c)); // 納品先住所２
            //System.assertEquals('0949-34-7667', ordHeader2.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals('甲府通運(小口)2', ordHeader2.ShippingName__c); // 配送名
            System.assertEquals('PM', ordHeader2.DepartureTime__c); // 出発時間帯
            System.assertEquals(900.000, ordHeader2.DistanceRoute__c); // 距離（路線便）
            System.assertEquals('国分東北(株)卸事業部営業課', ordHeader2.ImportedAccountName__c); // 取引先名
            System.assertEquals('Reception', ordHeader2.Status__c); // 状態
            System.assertEquals('Route', ordHeader2.TransportationMode__c); // 輸送形態

            // 注文明細1
            System.assertEquals('ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml', ordDetail2[0].ItemName__c); // 品名
            System.assertEquals(50, ordDetail2[0].Quantity__c); // 数量
            System.assertEquals(10, ordDetail2[0].UnitQuantity__c); // 入数
            System.assertEquals(5, ordDetail2[0].CSQuantity__c); // CS数
            System.assertEquals(339.98, ordDetail2[0].WeightKG__c); // 重量（Kg）
            System.assertEquals('路線便用路線便備考2-2', ordDetail2[0].Remarks__c); // 備考
            System.assertEquals(1, ordDetail2[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[0].OrderHeader__c); // 注文
            // 注文明細2
            System.assertEquals('ﾌｪﾘｼﾀﾙ ｿｰｳﾞｨﾆﾖﾝﾌﾞﾗﾝ 750ml', ordDetail2[1].ItemName__c); // 品名
            System.assertEquals(50, ordDetail2[1].Quantity__c); // 数量
            System.assertEquals(10, ordDetail2[1].UnitQuantity__c); // 入数
            System.assertEquals(5, ordDetail2[1].CSQuantity__c); // CS数
            System.assertEquals(339.98, ordDetail2[1].WeightKG__c); // 重量（Kg）
            System.assertEquals('路線便用路線便備考2-3', ordDetail2[1].Remarks__c); // 備考
            System.assertEquals(2, ordDetail2[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[0].OrderHeader__c); // 注文
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
}