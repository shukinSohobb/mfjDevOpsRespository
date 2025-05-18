@istest
public with sharing class GetShippingFeeMasterTest {

    @isTest
    static void testPatten1CalculateShippingFee() {// パターン１
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, true);
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '19';//19:山梨県
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(null , testPriceTable.Id, testDestination.Id, false);
        testShippingFee.OriginPrefecture__c = '19';
        insert testShippingFee;
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestination.Id, testOrigin.Id, testDestination.Id, true);
        
        String departurePrefecture = testOrder.OriginPlace__r.Prefecture__c;
        // 発着地を逆転する
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestination.Id, testDestination.Id, testOrigin.Id, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder, testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(2, result.size(), '2注文なので、2件の送料データが返されるべき');
        Assert.areEqual(testShippingFee.ShippingFee__c, result[0].ShippingFee__c, '送料が一致するべき');
    }

    @isTest
    static void testPatten2CalculateShippingFee() {// パターン２
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, true);
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '福岡県';
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(testAccountDestination.Id, testPriceTable.Id, testDestination.Id, true);
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestination.Id, null, testDestination.Id, true);
        // 発着地を逆転する
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestination.Id, testDestination.Id, null, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder,testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(1, result.size(), '2注文なので、2件の送料データが返されるべき');
        Assert.areEqual(testShippingFee.ShippingFee__c, result[0].ShippingFee__c, '送料が一致するべき');
    }

    @isTest
    static void testPatten34CalculateShippingFee() {// パターン3、パターン4
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, true);
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '福岡県';
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        // 運賃作成:着地IDがない、着地詳細情報が一致している
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(testAccountDestination.Id, testPriceTable.Id, null, true);
        
        // 注文作成 パターン3
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestination.Id, null, testDestination.Id, true);
        // 発着地を逆転する パターン4
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestination.Id, testDestination.Id, testOrigin.Id, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder,testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(2, result.size(), '送料計算できる注文2件なので、2件の送料データが返されるべき');
        Assert.areEqual(testShippingFee.ShippingFee__c, result[0].ShippingFee__c, '送料が一致するべき');
    }

    @isTest
    static void testPatten35CalculateShippingFee() {// パターン3、パターン5
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, false);
        testDestination.Street__c = '';
        insert testDestination;
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '福岡県';
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        // 運賃作成:着地IDがない、着地詳細情報が一致している
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(testAccountDestination.Id, testPriceTable.Id, null, true);
        
        // 注文作成 パターン3
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestination.Id, null, testDestination.Id, true);
        // 発着地を逆転する パターン5
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestination.Id, testDestination.Id, testOrigin.Id, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder,testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(2, result.size(), '送料計算できる注文2件なので、2件の送料データが返されるべき');
        Assert.areEqual(testShippingFee.ShippingFee__c, result[0].ShippingFee__c, '送料が一致するべき');
    }

    @isTest
    static void testPatten36CalculateShippingFee() {// パターン3、パターン6
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, false);
        testDestination.City__c = '';
        testDestination.Street__c = '';
        insert testDestination;
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '福岡県';
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        // 運賃作成:着地IDがない、着地詳細情報が一致している
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(testAccountDestination.Id, testPriceTable.Id, null, true);
        
        // 注文作成 パターン3
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestination.Id, null, testDestination.Id, true);
        // 発着地を逆転する パターン6
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestination.Id, testDestination.Id, testOrigin.Id, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder,testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(2, result.size(), '送料計算できる注文2件なので、2件の送料データが返されるべき');
        Assert.areEqual(testShippingFee.ShippingFee__c, result[0].ShippingFee__c, '送料が一致するべき');
    }

    @isTest
    static void testPatten37CalculateShippingFee() {// パターン3、パターン7
        // テストデータの作成
        Account testAccountDestination = TestDataFactory.createAccount('aaa', true);
        Account testAccountOrigin = TestDataFactory.createAccount('bbb', true);
        Account testAccountDestinationFalse = TestDataFactory.createAccount('ccc', true);

        PriceTable__c testPriceTable = TestDataFactory.createPriceTable(testAccountDestination.Id, true);
        OriginDestination__c testDestination = TestDataFactory.createOriginDestination(testAccountDestination.Id, true);
        OriginDestination__c testDestinationFalse = TestDataFactory.createOriginDestination(testAccountDestinationFalse.Id, false);
        testDestinationFalse.Prefecture__c = 'XXXXX';
        testDestinationFalse.City__c = 'XXXX';
        testDestinationFalse.Street__c = 'XXX';
        insert testDestinationFalse;
        OriginDestination__c testOrigin = TestDataFactory.createOriginDestination(testAccountOrigin.Id, false);
        testOrigin.Prefecture__c = '福岡県';
        testOrigin.City__c = '';
        testOrigin.Street__c = '';
        insert testOrigin;
        // 運賃作成:着地IDがない、着地詳細情報が一致している
        ShippingFee__c testShippingFee = TestDataFactory.createShippingFee(testAccountDestination.Id, testPriceTable.Id, null, true);
        
        // 注文作成 パターン3
        OrderHeader__c testOrder = TestDataFactory.createOrderHeader(testAccountDestinationFalse.Id, null, testDestinationFalse.Id, true);
        // 発着地を逆転する パターン7
        OrderHeader__c testOrder2 = TestDataFactory.createOrderHeader(testAccountDestinationFalse.Id, testDestinationFalse.Id, testOrigin.Id, true);

        Test.startTest();
        List<ShippingFee__c> result = GetShippingFeeMaster.calculateShippingFee(new List<OrderHeader__c>{testOrder,testOrder2});
        Test.stopTest();

        // 検証
        Assert.isNotNull(result, '結果がnullであってはならない');
        Assert.areEqual(2, result.size(), '送料計算できる注文2件なので、2件の送料データが返されるべき');
        Assert.areEqual(null, result[0].ShippingFee__c, '送料が取得できない');
    }
}