@isTest
global with sharing class MapAPIHandler_T {
    global class MapAPIHandlerCalloutMock implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            // Mock レスポンス
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (endpoint.contains('error_test')) {
                // エラーテストの場合
                res.setBody('{"status":"ERROR", "results": [], "error_message":"Mock Error"}');
                res.setStatusCode(400);
            } else {
                // 成功結果の場合
                res.setBody(
                    '{"status":"OK", "results": [{"geometry": {"location": {"lat": 90.12345678, "lng": 180.12345678}}}]}'
                );
                res.setStatusCode(200);
            }
            return res;
        }
    }

    @TestSetup
    static void makeData() {
        Account acc = TestDataFactory.createAccount('12345', false);
        insert acc;
    }

    // 直接APIハンドラーを使用する。成功結果が取得されて、発着地の「緯度」と「経度」が設定される
    @isTest
    static void testMapAPIHandler_Handler_LatLngIsSet() {
        Decimal mockLat = 90.12345678;
        Decimal mockLng = 180.12345678;
        Test.setMock(HttpCalloutMock.class, new MapAPIHandlerCalloutMock());

        // 発着地レコードを作成
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriginDestination__c origin = new OriginDestination__c();
        origin.Account__c = acc.Id;
        origin.Prefecture__c = '1';
        insert origin;
        origin = [
            SELECT Id, Prefecture__c, City__c, Street__c, PrefectureLabel_F__c, Latitude__c, Longitude__c
            FROM OriginDestination__c
            WHERE Id = :origin.Id
            LIMIT 1
        ];
        Assert.areEqual(null, origin.Latitude__c);
        Assert.areEqual(null, origin.Longitude__c);
        origin.City__c = '習志野市';
        origin.Street__c = '津田沼２－１７－１';
        Test.startTest();
        // API 実行
        System.enqueueJob(new MapAPIHandler(origin));
        Test.stopTest();
        // 発着地の緯度と経度を取得
        origin = [SELECT Latitude__c, Longitude__c FROM OriginDestination__c WHERE Id = :origin.Id LIMIT 1];
        // 設定された緯度と経度を確認
        Assert.areEqual(mockLat, origin.Latitude__c);
        Assert.areEqual(mockLng, origin.Longitude__c);
    }

    // 発着地を作成して、フローにてAPIハンドラーを使用する。成功結果が取得されて、発着地の「緯度」と「経度」が設定される
    @isTest
    static void testMapAPIHandler_FlowInsert_LatLngIsSet() {
        Decimal mockLat = 90.12345678;
        Decimal mockLng = 180.12345678;
        Test.setMock(HttpCalloutMock.class, new MapAPIHandlerCalloutMock());

        // 発着地レコードを作成
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriginDestination__c origin = new OriginDestination__c();
        origin.Account__c = acc.Id;
        origin.Prefecture__c = '1';
        origin.City__c = '習志野市';
        origin.Street__c = '津田沼２－１７－１';
        Test.startTest();
        // API 実行
        insert origin;
        Test.stopTest();
        // 発着地の緯度と経度を取得
        origin = [SELECT Latitude__c, Longitude__c FROM OriginDestination__c WHERE Id = :origin.Id LIMIT 1];
        // 設定された緯度と経度を確認
        Assert.areEqual(mockLat, origin.Latitude__c);
        Assert.areEqual(mockLng, origin.Longitude__c);
    }

    // 発着地を更新して、フローにてAPIハンドラーを使用する。成功結果が取得されて、発着地の「緯度」と「経度」が設定される
    @isTest
    static void testMapAPIHandler_FlowUpdate_LatLngIsSet() {
        Decimal mockLat = 90.12345678;
        Decimal mockLng = 180.12345678;
        Test.setMock(HttpCalloutMock.class, new MapAPIHandlerCalloutMock());

        // 発着地レコードを作成
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriginDestination__c origin = new OriginDestination__c();
        origin.Account__c = acc.Id;
        origin.Prefecture__c = '1';
        insert origin;
        // 発着地の緯度と経度が設定されないことを確認。
        origin = [
            SELECT Id, Prefecture__c, City__c, Street__c, PrefectureLabel_F__c, Latitude__c, Longitude__c
            FROM OriginDestination__c
            WHERE Id = :origin.Id
            LIMIT 1
        ];
        Assert.areEqual(null, origin.Latitude__c);
        Assert.areEqual(null, origin.Longitude__c);
        // 発着地の住所情報を更新
        origin.City__c = '習志野市';
        origin.Street__c = '津田沼２－１７－１';
        Test.startTest();
        // API 実行
        update origin;
        Test.stopTest();
        // 発着地の緯度と経度を取得
        origin = [SELECT Latitude__c, Longitude__c FROM OriginDestination__c WHERE Id = :origin.Id LIMIT 1];
        // 設定された緯度と経度を確認
        Assert.areEqual(mockLat, origin.Latitude__c);
        Assert.areEqual(mockLng, origin.Longitude__c);
    }

    // 住所情報が不足している。発着地の緯度と経度が設定されない。
    @isTest
    static void testMapAPIHandler_AddressMissing_LatLngIsNotSet() {
        Test.setMock(HttpCalloutMock.class, new MapAPIHandlerCalloutMock());

        // 発着地レコードを作成
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriginDestination__c origin = new OriginDestination__c();
        origin.Account__c = acc.Id;
        origin.Prefecture__c = '1';
        origin.City__c = '習志野市';
        origin.Street__c = null;
        Test.startTest();
        // API 実行
        insert origin;
        Test.stopTest();
        // 発着地の緯度と経度を取得
        origin = [SELECT Latitude__c, Longitude__c FROM OriginDestination__c WHERE Id = :origin.Id LIMIT 1];
        // 設定された緯度と経度を確認
        Assert.areEqual(null, origin.Latitude__c);
        Assert.areEqual(null, origin.Longitude__c);
    }

    // エラー処理のテスト。発着地の緯度と経度が設定されない。
    @isTest
    static void testMapAPIHandler_Error_LatLngIsNotSet() {
        Test.setMock(HttpCalloutMock.class, new MapAPIHandlerCalloutMock());

        // 発着地レコードを作成
        Account acc = [SELECT Id FROM Account LIMIT 1];
        OriginDestination__c origin = new OriginDestination__c();
        origin.Account__c = acc.Id;
        origin.Prefecture__c = '1';
        insert origin;
        origin = [
            SELECT Id, Prefecture__c, City__c, Street__c, PrefectureLabel_F__c, Latitude__c, Longitude__c
            FROM OriginDestination__c
            WHERE Id = :origin.Id
            LIMIT 1
        ];
        origin.City__c = '習志野市';
        origin.Street__c = 'error_test';
        Test.startTest();
        // API 実行
        System.enqueueJob(new MapAPIHandler(origin));
        Test.stopTest();
        // 発着地の緯度と経度を取得
        origin = [SELECT Latitude__c, Longitude__c FROM OriginDestination__c WHERE Id = :origin.Id LIMIT 1];
        // 設定された緯度と経度を確認
        Assert.areEqual(null, origin.Latitude__c);
        Assert.areEqual(null, origin.Longitude__c);
    }
}