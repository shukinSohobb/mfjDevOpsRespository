/**
 * 商談から注文と注文明細を作成トリガーハンドラテストクラス
 */
@istest
public class OpportunityTriggerHandler_T {
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
            list<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.OrderNumber__c = '999999999911';
            opp.Name = '運送発注書_ソフトドリンク_999999999911.pdf';
            opp.ContentsType__c = 'application/pdf';
            opp.OrderPerson__c = '田中 太郎 ［asdfg48］';
            opp.FAXCreationTimeStr__c = '2025-03-17 11:15:00';
            opp.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp.AccountName__c = 'ソフト飲料';
            opp.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp.DocumenType__c = '［fbj08752］運送発注書_マルエス様';
            opp.Item_1__c = 'ポカリスエット';
            //opp.ItemCode_1__c = '大塚製薬１';
            opp.ModelType1_1__c = '12126(kg)';
            opp.ModelType2_1__c = '122(ケース)';
            opp.DeliveryNumber__c = '20250319-452209|';
            opp.DeliveryDestinationPhone__c = '080-3458-7016';
            opp.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp.DesiredDeliveryDate__c = '2025/03/17 00:00';
            opp.CloseDate = Date.valueOf('2025-03-20');
            opp.StageName = '確認済み';
            opp.Title__c = '運送発注書';
            opp.ProcessingPerson__c = '自主荷役';
            opp.SupplierEmailAddress__c = 'aaaa@ddd.co.jp';
            opp.DeliveryDestination__c = 'AmazonTPGT 海老名';
            oppList.add(opp);

            Test.startTest();
            insert oppList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 商談
            Opportunity oppor = [
                SELECT Id, OrderHeader__c
                FROM Opportunity
                WHERE OrderNumber__c = :opp.OrderNumber__c
            ];
            // 注文
            OrderHeader__c ordHeader = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = :opp.OrderNumber__c
            ];
            // 注文明細
            OrderDetail__c ordDetail = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader.Id
                ORDER BY SequenceNumber__c
            ];
            // 期待値と実行結果の検証
            // 注文
            System.assertEquals(oppor.OrderHeader__c, ordHeader.Id); // ID
            System.assertEquals(opp.AccountName__c, ordHeader.ImportedAccountName__c); // 取引先
            System.assertEquals(opp.DeliveryDestination__c, ordHeader.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp.DeliveryDestinationPhone__c, ordHeader.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp.OrderNumber__c, ordHeader.OrderNumber__c); // 依頼番号
            System.assertEquals(opp.DeliveryDestinationAddress__c, ordHeader.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-17 00:00:00', String.valueOf(ordHeader.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp.CloseDate, ordHeader.CloseDate__c); // 取引日
            System.assertEquals(opp.Remarks__c, ordHeader.Remarks3__c); // 備考
            // 注文明細
            //System.assertEquals(opp.ItemCode_1__c, ordDetail.ItemCode__c); // 品目コード
            System.assertEquals(opp.Item_1__c, ordDetail.ItemName__c); // 品名
            System.assertEquals((opp.ModelType1_1__c + opp.ModelType2_1__c), ordDetail.Model__c); // 型式
            System.assertEquals(1, ordDetail.SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader.Id, ordDetail.OrderHeader__c); // 注文
        }
    }

    /**
     * 正常パターン２
     * 注文が２つレコードを作成
     * 各注文の注文明細が２つレコードを作成
     */
    @isTest
    static void testNormalPatten2() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            list<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = new Opportunity();
            opp1.OrderNumber__c = '999999999921';
            opp1.Name = '運送発注書_ソフトドリンク_999999999921.pdf';
            opp1.ContentsType__c = 'application/pdf';
            opp1.OrderPerson__c = '田中 太郎 ［asdfg48］';
            opp1.FAXCreationTimeStr__c = '2025-03-17 11:15:00';
            opp1.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp1.AccountName__c = 'ソフト飲料';
            opp1.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp1.DocumenType__c = '［fbj08752］運送発注書_マルエス様１';
            opp1.Item_1__c = 'ポカリスエット';
            opp1.ItemCode_1__c = '大塚製薬１ー１';
            opp1.ModelType1_1__c = '12126(kg)';
            opp1.ModelType2_1__c = '122(ケース)';
            opp1.Item_2__c = 'イオンウォーター';
            opp1.ItemCode_2__c = '大塚製薬１－２';
            opp1.ModelType1_2__c = '13336(kg)';
            opp1.ModelType2_2__c = '432(ケース)';
            opp1.DeliveryNumber__c = '20250319-452209|';
            opp1.DeliveryDestinationPhone__c = '080-3458-7016';
            opp1.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp1.DesiredDeliveryDate__c = '2025/03/17 00:00';
            opp1.CloseDate = Date.valueOf('2025-03-20');
            opp1.StageName = '確認済み';
            opp1.Title__c = '運送発注書';
            opp1.ProcessingPerson__c = '自主荷役';
            opp1.SupplierEmailAddress__c = 'aaaa@ddd.co.jp';
            opp1.DeliveryDestination__c = 'AmazonTPGT 海老名';
            oppList.add(opp1);

            Opportunity opp2 = new Opportunity();
            opp2.OrderNumber__c = '999999999922';
            opp2.Name = '運送発注書_ソフトドリンク_999999999922.pdf';
            opp2.ContentsType__c = 'application/pdf';
            opp2.OrderPerson__c = '田中 二郎 ［asdfg48］';
            opp2.FAXCreationTimeStr__c = '2025-03-20 13:21:00';
            opp2.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp2.AccountName__c = 'ソフト飲料';
            opp2.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp2.DocumenType__c = '［fbj08752］運送発注書_マルエス様２';
            opp2.Item_1__c = 'ポカリスエット';
            opp2.ItemCode_1__c = '大塚製薬２－１';
            opp2.ModelType1_1__c = '12126(kg)';
            opp2.ModelType2_1__c = '';
            opp2.Item_2__c = 'イオンウォーター';
            opp2.ItemCode_2__c = '大塚製薬２ー２';
            opp2.ModelType1_2__c = '';
            opp2.ModelType2_2__c = '432(ケース)';
            opp2.DeliveryNumber__c = '20250319-452209|';
            opp2.DeliveryDestinationPhone__c = '080-3458-7016';
            opp2.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp2.DesiredDeliveryDate__c = '2025/03/20 00:00';
            opp2.CloseDate = Date.valueOf('2025-03-23');
            opp2.StageName = '確認済み';
            opp2.Title__c = '運送発注書';
            opp2.ProcessingPerson__c = '自主荷役';
            opp2.SupplierEmailAddress__c = 'bbbb@ddd.co.jp';
            opp2.DeliveryDestination__c = 'AmazonTPGT 伊豆';
            oppList.add(opp2);

            Test.startTest();
            insert oppList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 商談
            Opportunity oppor1 = [
                SELECT Id, OrderHeader__c
                FROM Opportunity
                WHERE OrderNumber__c = '999999999921'
            ];
            Opportunity oppor2 = [
                SELECT Id, OrderHeader__c
                FROM Opportunity
                WHERE OrderNumber__c = '999999999922'
            ];
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999921'
            ];
            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999922'
            ];
            // 注文明細
            List<OrderDetail__c> ordDetail1 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
                ORDER BY SequenceNumber__c
            ];

            List<OrderDetail__c> ordDetail2 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
                ORDER BY SequenceNumber__c
            ];
            // 期待値と実行結果の検証
            // 注文１
            System.assertEquals(oppor1.OrderHeader__c, ordHeader1.Id); // ID
            System.assertEquals(opp1.AccountName__c, ordHeader1.ImportedAccountName__c); // 取引先
            System.assertEquals(opp1.DeliveryDestination__c, ordHeader1.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp1.DeliveryDestinationPhone__c, ordHeader1.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp1.OrderNumber__c, ordHeader1.OrderNumber__c); // 依頼番号
            System.assertEquals(opp1.DeliveryDestinationAddress__c, ordHeader1.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-17 00:00:00', String.valueOf(ordHeader1.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp1.CloseDate, ordHeader1.CloseDate__c); // 取引日
            System.assertEquals(opp1.Remarks__c, ordHeader1.Remarks3__c); // 備考
            // 注文１の注文明細１
            System.assertEquals(opp1.ItemCode_1__c, ordDetail1[0].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_1__c, ordDetail1[0].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_1__c + opp1.ModelType2_1__c), ordDetail1[0].Model__c); // 型式
            System.assertEquals(1, ordDetail1[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[0].OrderHeader__c); // 注文
            // 注文１の注文明細２
            System.assertEquals(opp1.ItemCode_2__c, ordDetail1[1].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_2__c, ordDetail1[1].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_2__c + opp1.ModelType2_2__c), ordDetail1[1].Model__c); // 型式
            System.assertEquals(2, ordDetail1[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[1].OrderHeader__c); // 注文

            // 注文２
            System.assertEquals(ordHeader2.Id, oppor2.OrderHeader__c); // ID
            System.assertEquals(opp2.AccountName__c, ordHeader2.ImportedAccountName__c); // 取引先
            System.assertEquals(opp2.DeliveryDestination__c, ordHeader2.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp2.DeliveryDestinationPhone__c, ordHeader2.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp2.OrderNumber__c, ordHeader2.OrderNumber__c); // 依頼番号
            System.assertEquals(opp2.DeliveryDestinationAddress__c, ordHeader2.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-20 00:00:00', String.valueOf(ordHeader2.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp2.CloseDate, ordHeader2.CloseDate__c); // 取引日
            System.assertEquals(opp2.Remarks__c, ordHeader2.Remarks3__c); // 備考
            // 注文２の注文明細１
            System.assertEquals(opp2.ItemCode_1__c, ordDetail2[0].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_1__c, ordDetail2[0].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_1__c + opp2.ModelType2_1__c), ordDetail2[0].Model__c); // 型式
            System.assertEquals(1, ordDetail2[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[0].OrderHeader__c); // 注文
            // 注文２の注文明細２
            System.assertEquals(opp2.ItemCode_2__c, ordDetail2[1].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_2__c, ordDetail2[1].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_2__c + opp2.ModelType2_2__c), ordDetail2[1].Model__c); // 型式
            System.assertEquals(2, ordDetail2[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[1].OrderHeader__c); // 注文
        }
    }
    /**
     * 正常パターン３
     * 注文①は４つ注文明細レコードがあります
     * 注文①はレコードを更新、注文②はレコードを新規
     * 注文①の注文明細が１つレコードを更新、１つレコード新規、１つレコードを削除、他は変更されない
     * 注文②の注文明細が３つレコードを作成
     */
    @isTest
    static void testNormalPatten3() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            // 注文を作成する
            List<OrderHeader__c> newOrderHeaderList = new List<OrderHeader__c>();
            OrderHeader__c newOrderHeader = new OrderHeader__c();
            newOrderHeader.ImportedAccountName__c = 'ImportedAccountName__c'; // 取引先
            newOrderHeader.InportedDeliveryDestination__c = 'InportedDeliveryDestination__c'; //納品先
            newOrderHeader.ImportedDeliveryDestinationPhone__c = '123456789'; // 納品先電話番号
            newOrderHeader.OrderNumber__c = '999999999931'; // 依頼番号
            newOrderHeader.DeliveryDestinationAddress__c = 'DeliveryDestinationAddress__c'; //納品先住所
            newOrderHeader.ReceptionDatetime__c = Datetime.parse('2025/03/17 00:00'); // 受付日
            newOrderHeader.CloseDate__c = date.parse('2025/03/17'); // 取引日
            newOrderHeader.Remarks3__c = 'Remarks3__c'; // 備考
            newOrderHeaderList.add(newOrderHeader);
            insert newOrderHeaderList;

            // 注文明細を作成する
            List<OrderDetail__c> newOrderDetailList = new List<OrderDetail__c>();
            OrderDetail__c newOrderDetail1 = new OrderDetail__c();
            newOrderDetail1.ItemCode__c = '品目コード１'; // 品目コード
            newOrderDetail1.ItemName__c = '品名１'; // 品名
            newOrderDetail1.Model__c = ''; // 型式０１+ 型式０２
            newOrderDetail1.SequenceNumber__c = 1; // 枝番
            newOrderDetail1.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail1);

            OrderDetail__c newOrderDetail2 = new OrderDetail__c();
            newOrderDetail2.ItemCode__c = ''; // 品目コード
            newOrderDetail2.ItemName__c = '品名２'; // 品名
            newOrderDetail2.Model__c = '型式０２'; // 型式０１+ 型式０２
            newOrderDetail2.SequenceNumber__c = 2; // 枝番
            newOrderDetail2.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail2);

            OrderDetail__c newOrderDetail3 = new OrderDetail__c();
            newOrderDetail3.ItemCode__c = '品目コード４'; // 品目コード
            newOrderDetail3.ItemName__c = ''; // 品名
            newOrderDetail3.Model__c = ''; // 型式０１+ 型式０２
            newOrderDetail3.SequenceNumber__c = 4; // 枝番
            newOrderDetail3.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail3);

            OrderDetail__c newOrderDetail4 = new OrderDetail__c();
            newOrderDetail4.ItemCode__c = '品目コード５'; // 品目コード
            newOrderDetail4.ItemName__c = '品名５'; // 品名
            newOrderDetail4.Model__c = 'ああああ'; // 型式０１+ 型式０２
            newOrderDetail4.SequenceNumber__c = 5; // 枝番
            newOrderDetail4.OrderHeader__c = newOrderHeader.Id; // 注文
            newOrderDetailList.add(newOrderDetail4);

            insert newOrderDetailList;

            //　商談を作成する
            list<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = new Opportunity();
            opp1.OrderNumber__c = '999999999931';
            opp1.Name = '運送発注書_ソフトドリンク_999999999931.pdf';
            opp1.ContentsType__c = 'application/pdf';
            opp1.OrderPerson__c = '田中 太郎 ［asdfg48］';
            opp1.FAXCreationTimeStr__c = '2025-03-17 11:15:00';
            opp1.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp1.AccountName__c = 'ソフト飲料';
            opp1.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp1.DocumenType__c = '［fbj08752］運送発注書_マルエス様１';
            opp1.Item_1__c = '品名１';
            opp1.ItemCode_1__c = '品目コード１';
            opp1.ModelType1_1__c = '';
            opp1.ModelType2_1__c = '';
            opp1.Item_2__c = 'イオンウォーター';
            opp1.ItemCode_2__c = '大塚製薬１－２';
            opp1.ModelType1_2__c = '13336(kg)';
            opp1.ModelType2_2__c = '432(ケース)';
            opp1.Item_3__c = '';
            opp1.ItemCode_3__c = '大塚製薬１－３';
            opp1.ModelType1_3__c = '13336(kg)';
            opp1.ModelType2_3__c = '432(ケース)';
            opp1.Item_5__c = '品目コード５';
            opp1.ItemCode_5__c = '品名５';
            opp1.ModelType1_5__c = 'あああ';
            opp1.ModelType2_5__c = 'あ';
            opp1.DeliveryNumber__c = '20250319-452209|';
            opp1.DeliveryDestinationPhone__c = '080-3458-7016';
            opp1.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp1.DesiredDeliveryDate__c = '2025/03/17 00:00';
            opp1.CloseDate = Date.valueOf('2025-03-20');
            opp1.StageName = '確認済み';
            opp1.Title__c = '運送発注書';
            opp1.ProcessingPerson__c = '自主荷役';
            opp1.SupplierEmailAddress__c = 'aaaa@ddd.co.jp';
            opp1.DeliveryDestination__c = 'AmazonTPGT 海老名';
            oppList.add(opp1);

            Opportunity opp2 = new Opportunity();
            opp2.OrderNumber__c = '999999999932';
            opp2.Name = '運送発注書_ソフトドリンク_999999999932.pdf';
            opp2.ContentsType__c = 'application/pdf';
            opp2.OrderPerson__c = '田中 二郎 ［asdfg48］';
            opp2.FAXCreationTimeStr__c = '2025-03-20 13:21:00';
            opp2.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp2.AccountName__c = 'ソフト飲料';
            opp2.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp2.DocumenType__c = '［fbj08752］運送発注書_マルエス様２';
            opp2.Item_1__c = 'ポカリスエット';
            opp2.ItemCode_1__c = '大塚製薬２－１';
            opp2.ModelType1_1__c = '12126(kg)';
            opp2.ModelType2_1__c = '';
            opp2.Item_2__c = 'イオンウォーター';
            opp2.ItemCode_2__c = '大塚製薬２ー２';
            opp2.ModelType1_2__c = '';
            opp2.ModelType2_2__c = '432(ケース)';
            opp2.Item_7__c = 'イオンウォーター';
            opp2.ItemCode_7__c = '大塚製薬２ー７';
            opp2.ModelType1_7__c = '777';
            opp2.ModelType2_7__c = '432(ケース)';
            opp2.DeliveryNumber__c = '20250319-452209|';
            opp2.DeliveryDestinationPhone__c = '080-3458-7016';
            opp2.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp2.DesiredDeliveryDate__c = '2025/03/20 00:00';
            opp2.CloseDate = Date.valueOf('2025-03-23');
            opp2.StageName = '確認済み';
            opp2.Title__c = '運送発注書';
            opp2.ProcessingPerson__c = '自主荷役';
            opp2.SupplierEmailAddress__c = 'bbbb@ddd.co.jp';
            opp2.DeliveryDestination__c = 'AmazonTPGT 伊豆';
            oppList.add(opp2);

            Test.startTest();
            insert oppList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999931'
            ];
            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999932'
            ];
            // 注文明細
            List<OrderDetail__c> ordDetail1 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
                ORDER BY SequenceNumber__c
            ];

            List<OrderDetail__c> ordDetail2 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
                ORDER BY SequenceNumber__c
            ];
            string blankString = '';
            // 期待値と実行結果の検証
            // 注文１
            System.assertEquals(opp1.AccountName__c, ordHeader1.ImportedAccountName__c); // 取引先
            System.assertEquals(opp1.DeliveryDestination__c, ordHeader1.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp1.DeliveryDestinationPhone__c, ordHeader1.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp1.OrderNumber__c, ordHeader1.OrderNumber__c); // 依頼番号
            System.assertEquals(opp1.DeliveryDestinationAddress__c, ordHeader1.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-17 00:00:00', String.valueOf(ordHeader1.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp1.CloseDate, ordHeader1.CloseDate__c); // 取引日
            System.assertEquals(opp1.Remarks__c, ordHeader1.Remarks3__c); // 備考
            // 注文１の注文明細１
            System.assertEquals(opp1.ItemCode_1__c, ordDetail1[0].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_1__c, ordDetail1[0].ItemName__c); // 品名
            Assert.isTrue(String.isBlank(ordDetail1[0].Model__c)); // 型式
            System.assertEquals(1, ordDetail1[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[0].OrderHeader__c); // 注文
            // 注文１の注文明細２
            System.assertEquals(opp1.ItemCode_2__c, ordDetail1[1].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_2__c, ordDetail1[1].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_2__c + opp1.ModelType2_2__c), ordDetail1[1].Model__c); // 型式
            System.assertEquals(2, ordDetail1[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[1].OrderHeader__c); // 注文
            // 注文１の注文明細３
            System.assertEquals(opp1.ItemCode_3__c, ordDetail1[2].ItemCode__c); // 品目コード
            Assert.isTrue(String.isBlank(ordDetail1[2].ItemName__c)); // 品名
            System.assertEquals((opp1.ModelType1_3__c + opp1.ModelType2_3__c), ordDetail1[2].Model__c); // 型式
            System.assertEquals(3, ordDetail1[2].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[2].OrderHeader__c); // 注文
            // 注文１の注文明細４
            System.assertEquals(opp1.ItemCode_5__c, ordDetail1[3].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_5__c, ordDetail1[3].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_5__c + opp1.ModelType2_5__c), ordDetail1[3].Model__c); // 型式
            System.assertEquals(5, ordDetail1[3].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[3].OrderHeader__c); // 注文

            // 注文２
            System.assertEquals(opp2.AccountName__c, ordHeader2.ImportedAccountName__c); // 取引先
            System.assertEquals(opp2.DeliveryDestination__c, ordHeader2.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp2.DeliveryDestinationPhone__c, ordHeader2.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp2.OrderNumber__c, ordHeader2.OrderNumber__c); // 依頼番号
            System.assertEquals(opp2.DeliveryDestinationAddress__c, ordHeader2.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-20 00:00:00', String.valueOf(ordHeader2.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp2.CloseDate, ordHeader2.CloseDate__c); // 取引日
            System.assertEquals(opp2.Remarks__c, ordHeader2.Remarks3__c); // 備考
            // 注文２の注文明細１
            System.assertEquals(opp2.ItemCode_1__c, ordDetail2[0].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_1__c, ordDetail2[0].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_1__c + opp2.ModelType2_1__c), ordDetail2[0].Model__c); // 型式
            System.assertEquals(1, ordDetail2[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[0].OrderHeader__c); // 注文
            // 注文２の注文明細２
            System.assertEquals(opp2.ItemCode_2__c, ordDetail2[1].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_2__c, ordDetail2[1].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_2__c + opp2.ModelType2_2__c), ordDetail2[1].Model__c); // 型式
            System.assertEquals(2, ordDetail2[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[1].OrderHeader__c); // 注文
            // 注文２の注文明細３
            System.assertEquals(opp2.ItemCode_7__c, ordDetail2[2].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_7__c, ordDetail2[2].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_7__c + opp2.ModelType2_7__c), ordDetail2[2].Model__c); // 型式
            System.assertEquals(7, ordDetail2[2].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[2].OrderHeader__c); // 注文
        }
    }
    /**
     * 正常パターン４
     * 注文①は７つ注文明細レコードがあります
     * 注文②は６つ注文明細レコードがあります
     * 注文①、②はレコードを更新
     * 注文①の注文明細が１つレコードを更新、１つレコード新規、１つレコードを削除、他は変更されない
     * 注文②の注文明細が２つレコードを更新、２つレコード新規、２つレコードを削除、他は変更されない
     *
     */
    @isTest
    static void testNormalPatten4() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            // 注文を作成する
            List<OrderHeader__c> newOrderHeaderList = new List<OrderHeader__c>();
            OrderHeader__c newOrderHeader1 = new OrderHeader__c();
            newOrderHeader1.ImportedAccountName__c = 'ImportedAccountName__c'; // 取引先
            newOrderHeader1.InportedDeliveryDestination__c = 'InportedDeliveryDestination__c'; //納品先
            newOrderHeader1.ImportedDeliveryDestinationPhone__c = '123456789'; // 納品先電話番号
            newOrderHeader1.OrderNumber__c = '999999999941'; // 依頼番号
            newOrderHeader1.DeliveryDestinationAddress__c = 'DeliveryDestinationAddress__c'; //納品先住所
            newOrderHeader1.ReceptionDatetime__c = Datetime.parse('2025/03/17 00:00'); // 受付日
            newOrderHeader1.CloseDate__c = date.parse('2025/03/17'); // 取引日
            newOrderHeader1.Remarks3__c = 'Remarks3__c'; // 備考
            newOrderHeaderList.add(newOrderHeader1);

            OrderHeader__c newOrderHeader2 = new OrderHeader__c();
            newOrderHeader2.ImportedAccountName__c = 'ImportedAccountName__c'; // 取引先
            newOrderHeader2.InportedDeliveryDestination__c = 'InportedDeliveryDestination__c'; //納品先
            newOrderHeader2.ImportedDeliveryDestinationPhone__c = '98765432'; // 納品先電話番号
            newOrderHeader2.OrderNumber__c = '999999999942'; // 依頼番号
            newOrderHeader2.DeliveryDestinationAddress__c = 'DeliveryDestinationAddress__c'; //納品先住所
            newOrderHeader2.ReceptionDatetime__c = Datetime.parse('2025/03/17 00:00'); // 受付日
            newOrderHeader2.CloseDate__c = date.parse('2025/03/17'); // 取引日
            newOrderHeader2.Remarks3__c = 'Remarks3__c'; // 備考
            newOrderHeaderList.add(newOrderHeader2);
            insert newOrderHeaderList;

            // 注文１の注文明細１～８を作成する
            List<OrderDetail__c> newOrderDetailList = new List<OrderDetail__c>();
            OrderDetail__c newOrderDetail1 = new OrderDetail__c();
            newOrderDetail1.ItemCode__c = '品目コード１ー１'; // 品目コード
            newOrderDetail1.ItemName__c = '品名１'; // 品名
            newOrderDetail1.Model__c = '型式０１'; // 型式０１+ 型式０２
            newOrderDetail1.SequenceNumber__c = 1; // 枝番
            newOrderDetail1.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail1);

            OrderDetail__c newOrderDetail2 = new OrderDetail__c();
            newOrderDetail2.ItemCode__c = '品目コード１ー２'; // 品目コード
            newOrderDetail2.ItemName__c = '品名２'; // 品名
            newOrderDetail2.Model__c = '型式０２'; // 型式０１+ 型式０２
            newOrderDetail2.SequenceNumber__c = 2; // 枝番
            newOrderDetail2.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail2);

            OrderDetail__c newOrderDetail3 = new OrderDetail__c();
            newOrderDetail3.ItemCode__c = '品目コード１－３'; // 品目コード
            newOrderDetail3.ItemName__c = '品名３'; // 品名
            newOrderDetail3.Model__c = '型式０３'; // 型式０１+ 型式０２
            newOrderDetail3.SequenceNumber__c = 3; // 枝番
            newOrderDetail3.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail3);

            OrderDetail__c newOrderDetail4 = new OrderDetail__c();
            newOrderDetail4.ItemCode__c = '品目コード１－４'; // 品目コード
            newOrderDetail4.ItemName__c = '品名４'; // 品名
            newOrderDetail4.Model__c = '型式０４'; // 型式０１+ 型式０２
            newOrderDetail4.SequenceNumber__c = 4; // 枝番
            newOrderDetail4.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail4);

            OrderDetail__c newOrderDetail6 = new OrderDetail__c();
            newOrderDetail6.ItemCode__c = '品目コード１－６'; // 品目コード
            newOrderDetail6.ItemName__c = '品名６'; // 品名
            newOrderDetail6.Model__c = '型式０６'; // 型式０１+ 型式０２
            newOrderDetail6.SequenceNumber__c = 6; // 枝番
            newOrderDetail6.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail6);

            OrderDetail__c newOrderDetail7 = new OrderDetail__c();
            newOrderDetail7.ItemCode__c = '品目コード１－７'; // 品目コード
            newOrderDetail7.ItemName__c = '品名７'; // 品名
            newOrderDetail7.Model__c = '型式０７'; // 型式０１+ 型式０２
            newOrderDetail7.SequenceNumber__c = 7; // 枝番
            newOrderDetail7.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail7);

            OrderDetail__c newOrderDetail8 = new OrderDetail__c();
            newOrderDetail8.ItemCode__c = '品目コード１－８'; // 品目コード
            newOrderDetail8.ItemName__c = '品名８'; // 品名
            newOrderDetail8.Model__c = '型式０８'; // 型式０１+ 型式０２
            newOrderDetail8.SequenceNumber__c = 8; // 枝番
            newOrderDetail8.OrderHeader__c = newOrderHeader1.Id; // 注文
            newOrderDetailList.add(newOrderDetail8);

            // 注文２の注文明細１～８を作成する
            OrderDetail__c newOrderDetail9 = new OrderDetail__c();
            newOrderDetail9.ItemCode__c = '品目コード２ー１'; // 品目コード
            newOrderDetail9.ItemName__c = '品名１'; // 品名
            newOrderDetail9.Model__c = ''; // 型式０１+ 型式０２
            newOrderDetail9.SequenceNumber__c = 1; // 枝番
            newOrderDetail9.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail9);

            OrderDetail__c newOrderDetail10 = new OrderDetail__c();
            newOrderDetail10.ItemCode__c = '品目コード２ー２'; // 品目コード
            newOrderDetail10.ItemName__c = '品名２'; // 品名
            newOrderDetail10.Model__c = '型式２'; // 型式０１+ 型式０２
            newOrderDetail10.SequenceNumber__c = 2; // 枝番
            newOrderDetail10.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail10);

            OrderDetail__c newOrderDetail11 = new OrderDetail__c();
            newOrderDetail11.ItemCode__c = '品目コード２－３'; // 品目コード
            newOrderDetail11.ItemName__c = '品名３'; // 品名
            newOrderDetail11.Model__c = '型式３'; // 型式０１+ 型式０２
            newOrderDetail11.SequenceNumber__c = 3; // 枝番
            newOrderDetail11.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail11);

            OrderDetail__c newOrderDetail12 = new OrderDetail__c();
            newOrderDetail12.ItemCode__c = '品目コード２－４'; // 品目コード
            newOrderDetail12.ItemName__c = '品名４'; // 品名
            newOrderDetail12.Model__c = '型式４'; // 型式０１+ 型式０２
            newOrderDetail12.SequenceNumber__c = 4; // 枝番
            newOrderDetail12.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail12);

            OrderDetail__c newOrderDetail13 = new OrderDetail__c();
            newOrderDetail13.ItemCode__c = '品目コード２－５'; // 品目コード
            newOrderDetail13.ItemName__c = '品名５'; // 品名
            newOrderDetail13.Model__c = '型式５'; // 型式０１+ 型式０２
            newOrderDetail13.SequenceNumber__c = 5; // 枝番
            newOrderDetail13.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail13);

            OrderDetail__c newOrderDetail14 = new OrderDetail__c();
            newOrderDetail14.ItemCode__c = '品目コード２－６'; // 品目コード
            newOrderDetail14.ItemName__c = '品名６'; // 品名
            newOrderDetail14.Model__c = '型式６'; // 型式０１+ 型式０２
            newOrderDetail14.SequenceNumber__c = 6; // 枝番
            newOrderDetail14.OrderHeader__c = newOrderHeader2.Id; // 注文
            newOrderDetailList.add(newOrderDetail14);
            insert newOrderDetailList;

            //　商談を作成する
            list<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp1 = new Opportunity();
            opp1.OrderNumber__c = '999999999941';
            opp1.Name = '運送発注書_ソフトドリンク_999999999941.pdf';
            opp1.ContentsType__c = 'application/pdf';
            opp1.OrderPerson__c = '田中 太郎 ［asdfg48］';
            opp1.FAXCreationTimeStr__c = '2025-03-17 11:15:00';
            opp1.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp1.AccountName__c = 'ソフト飲料';
            opp1.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp1.DocumenType__c = '［fbj08752］運送発注書_マルエス様１';
            opp1.Item_1__c = '品名１';
            opp1.ItemCode_1__c = '品目コード１ー１';
            opp1.ModelType1_1__c = '';
            opp1.ModelType2_1__c = '';
            opp1.Item_2__c = 'イオンウォーター';
            opp1.ItemCode_2__c = '大塚製薬１－２';
            opp1.ModelType1_2__c = '13336(kg)';
            opp1.ModelType2_2__c = '432(ケース)';
            opp1.Item_3__c = '';
            opp1.ItemCode_3__c = '品目コード１－３';
            opp1.ModelType1_3__c = '型式０３';
            opp1.ModelType2_3__c = '';
            opp1.Item_5__c = '品名５';
            opp1.ItemCode_5__c = '品目コード５';
            opp1.ModelType1_5__c = 'あああ';
            opp1.ModelType2_5__c = 'あ';
            opp1.Item_6__c = '品名６';
            opp1.ItemCode_6__c = '品目コード１－６';
            opp1.ModelType1_6__c = '型式０６';
            opp1.ModelType2_6__c = '';
            opp1.Item_7__c = '品名７';
            opp1.ItemCode_7__c = '品目コード１－７';
            opp1.ModelType1_7__c = '型式０７';
            opp1.ModelType2_7__c = '';
            opp1.Item_8__c = '品名８';
            opp1.ItemCode_8__c = '品目コード１－８';
            opp1.ModelType1_8__c = '型式０８';
            opp1.ModelType2_8__c = '';
            opp1.DeliveryNumber__c = '20250319-452209|';
            opp1.DeliveryDestinationPhone__c = '080-3458-7016';
            opp1.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp1.DesiredDeliveryDate__c = '2025/03/17 00:00';
            opp1.CloseDate = Date.valueOf('2025-03-20');
            opp1.StageName = '確認済み';
            opp1.Title__c = '運送発注書';
            opp1.ProcessingPerson__c = '自主荷役';
            opp1.SupplierEmailAddress__c = 'aaaa@ddd.co.jp';
            opp1.DeliveryDestination__c = 'AmazonTPGT 海老名';
            oppList.add(opp1);

            Opportunity opp2 = new Opportunity();
            opp2.OrderNumber__c = '999999999942';
            opp2.Name = '運送発注書_ソフトドリンク_999999999942.pdf';
            opp2.ContentsType__c = 'application/pdf';
            opp2.OrderPerson__c = '田中 二郎 ［asdfg48］';
            opp2.FAXCreationTimeStr__c = '2025-03-20 13:21:00';
            opp2.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp2.AccountName__c = 'ソフト飲料';
            opp2.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp2.DocumenType__c = '［fbj08752］運送発注書_マルエス様２';
            opp2.Item_1__c = '品名１change';
            opp2.ItemCode_1__c = '品目コード１ー１change';
            opp2.ModelType1_1__c = '型式０１';
            opp2.ModelType2_1__c = 'change';
            opp2.Item_3__c = '品名３';
            opp2.ItemCode_3__c = '品目コード２－３';
            opp2.ModelType1_3__c = '型式０３';
            opp2.ModelType2_3__c = '';
            opp2.Item_4__c = '品名４';
            opp2.ItemCode_4__c = '品目コード２－４';
            opp2.ModelType1_4__c = '型式０４';
            opp2.ModelType2_4__c = '';
            opp2.Item_5__c = '品目コード５change';
            opp2.ItemCode_5__c = '品名５change';
            opp2.ModelType1_5__c = 'あああchange';
            opp2.ModelType2_5__c = 'あ';
            opp2.Item_7__c = '品名７';
            opp2.ItemCode_7__c = '品目コード２－７';
            opp2.ModelType1_7__c = '型式０７';
            opp2.ModelType2_7__c = '';
            opp2.Item_8__c = '品名８';
            opp2.ItemCode_8__c = '品目コード２－８';
            opp2.ModelType1_8__c = '型式０８';
            opp2.ModelType2_8__c = '';
            opp2.DeliveryNumber__c = '20250319-452209|';
            opp2.DeliveryDestinationPhone__c = '080-3458-7016';
            opp2.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp2.DesiredDeliveryDate__c = '2025/03/20 00:00';
            opp2.CloseDate = Date.valueOf('2025-03-23');
            opp2.StageName = '確認済み';
            opp2.Title__c = '運送発注書';
            opp2.ProcessingPerson__c = '自主荷役';
            opp2.SupplierEmailAddress__c = 'bbbb@ddd.co.jp';
            opp2.DeliveryDestination__c = 'AmazonTPGT 伊豆';
            oppList.add(opp2);

            Test.startTest();
            insert oppList;
            Test.stopTest();

            /* ＝＝＝＝＝＝結果検証＝＝＝＝＝＝ */
            // 注文
            OrderHeader__c ordHeader1 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999941'
            ];
            OrderHeader__c ordHeader2 = [
                SELECT
                    Id,
                    ImportedAccountName__c,
                    InportedDeliveryDestination__c,
                    ImportedDeliveryDestinationPhone__c,
                    OrderNumber__c,
                    DeliveryDestinationAddress__c,
                    ReceptionDatetime__c,
                    CloseDate__c,
                    Remarks3__c
                FROM OrderHeader__c
                WHERE OrderNumber__c = '999999999942'
            ];
            // 注文明細
            List<OrderDetail__c> ordDetail1 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader1.Id
                ORDER BY SequenceNumber__c
            ];

            List<OrderDetail__c> ordDetail2 = [
                SELECT Id, ItemCode__c, ItemName__c, Model__c, SequenceNumber__c, OrderHeader__c
                FROM OrderDetail__c
                WHERE OrderHeader__c = :ordHeader2.Id
                ORDER BY SequenceNumber__c
            ];
            string blankString = '';
            // 期待値と実行結果の検証
            // 注文１
            System.assertEquals(opp1.AccountName__c, ordHeader1.ImportedAccountName__c); // 取引先
            System.assertEquals(opp1.DeliveryDestination__c, ordHeader1.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp1.DeliveryDestinationPhone__c, ordHeader1.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp1.OrderNumber__c, ordHeader1.OrderNumber__c); // 依頼番号
            System.assertEquals(opp1.DeliveryDestinationAddress__c, ordHeader1.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-17 00:00:00', String.valueOf(ordHeader1.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp1.CloseDate, ordHeader1.CloseDate__c); // 取引日
            System.assertEquals(opp1.Remarks__c, ordHeader1.Remarks3__c); // 備考
            // 注文１の注文明細１
            System.assertEquals(opp1.ItemCode_1__c, ordDetail1[0].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_1__c, ordDetail1[0].ItemName__c); // 品名
            system.debug('***ordDetail1[0].Model__c :' + ordDetail1[0].Model__c);
            Assert.isTrue(String.isBlank(ordDetail1[0].Model__c)); // 型式
            System.assertEquals(1, ordDetail1[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[0].OrderHeader__c); // 注文
            // 注文１の注文明細２
            System.assertEquals(opp1.ItemCode_2__c, ordDetail1[1].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_2__c, ordDetail1[1].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_2__c + opp1.ModelType2_2__c), ordDetail1[1].Model__c); // 型式
            System.assertEquals(2, ordDetail1[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[1].OrderHeader__c); // 注文
            // 注文１の注文明細３
            System.assertEquals(opp1.ItemCode_3__c, ordDetail1[2].ItemCode__c); // 品目コード
            Assert.isTrue(String.isBlank(ordDetail1[2].ItemName__c)); // 品名
            System.assertEquals((opp1.ModelType1_3__c + opp1.ModelType2_3__c), ordDetail1[2].Model__c); // 型式
            System.assertEquals(3, ordDetail1[2].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[2].OrderHeader__c); // 注文
            // 注文１の注文明細４
            System.assertEquals(opp1.ItemCode_5__c, ordDetail1[3].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_5__c, ordDetail1[3].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_5__c + opp1.ModelType2_5__c), ordDetail1[3].Model__c); // 型式
            System.assertEquals(5, ordDetail1[3].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[3].OrderHeader__c); // 注文
            // 注文１の注文明細５
            System.assertEquals(opp1.ItemCode_6__c, ordDetail1[4].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_6__c, ordDetail1[4].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_6__c + opp1.ModelType2_6__c), ordDetail1[4].Model__c); // 型式
            System.assertEquals(6, ordDetail1[4].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[4].OrderHeader__c); // 注文
            // 注文１の注文明細６
            System.assertEquals(opp1.ItemCode_7__c, ordDetail1[5].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_7__c, ordDetail1[5].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_7__c + opp1.ModelType2_7__c), ordDetail1[5].Model__c); // 型式
            System.assertEquals(7, ordDetail1[5].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[5].OrderHeader__c); // 注文
            // 注文１の注文明細７
            System.assertEquals(opp1.ItemCode_8__c, ordDetail1[6].ItemCode__c); // 品目コード
            System.assertEquals(opp1.Item_8__c, ordDetail1[6].ItemName__c); // 品名
            System.assertEquals((opp1.ModelType1_8__c + opp1.ModelType2_8__c), ordDetail1[6].Model__c); // 型式
            System.assertEquals(8, ordDetail1[6].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader1.Id, ordDetail1[6].OrderHeader__c); // 注文

            // 注文２
            System.assertEquals(opp2.AccountName__c, ordHeader2.ImportedAccountName__c); // 取引先
            System.assertEquals(opp2.DeliveryDestination__c, ordHeader2.InportedDeliveryDestination__c); // 納品先
            System.assertEquals(opp2.DeliveryDestinationPhone__c, ordHeader2.ImportedDeliveryDestinationPhone__c); // 納品先電話番号
            System.assertEquals(opp2.OrderNumber__c, ordHeader2.OrderNumber__c); // 依頼番号
            System.assertEquals(opp2.DeliveryDestinationAddress__c, ordHeader2.DeliveryDestinationAddress__c); // 納品先住所
            System.assertEquals('2025-03-20 00:00:00', String.valueOf(ordHeader2.ReceptionDatetime__c)); // 受付日
            System.assertEquals(opp2.CloseDate, ordHeader2.CloseDate__c); // 取引日
            System.assertEquals(opp2.Remarks__c, ordHeader2.Remarks3__c); // 備考
            // 注文２の注文明細１
            System.assertEquals(opp2.ItemCode_1__c, ordDetail2[0].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_1__c, ordDetail2[0].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_1__c + opp2.ModelType2_1__c), ordDetail2[0].Model__c); // 型式
            System.assertEquals(1, ordDetail2[0].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[0].OrderHeader__c); // 注文
            // 注文２の注文明細２
            System.assertEquals(opp2.ItemCode_3__c, ordDetail2[1].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_3__c, ordDetail2[1].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_3__c + opp2.ModelType2_3__c), ordDetail2[1].Model__c); // 型式
            System.assertEquals(3, ordDetail2[1].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[1].OrderHeader__c); // 注文
            // 注文２の注文明細３
            System.assertEquals(opp2.ItemCode_4__c, ordDetail2[2].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_4__c, ordDetail2[2].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_4__c + opp2.ModelType2_4__c), ordDetail2[2].Model__c); // 型式
            System.assertEquals(4, ordDetail2[2].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[2].OrderHeader__c); // 注文
            // 注文２の注文明細４
            System.assertEquals(opp2.ItemCode_5__c, ordDetail2[3].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_5__c, ordDetail2[3].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_5__c + opp2.ModelType2_5__c), ordDetail2[3].Model__c); // 型式
            System.assertEquals(5, ordDetail2[3].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[3].OrderHeader__c); // 注文
            // 注文２の注文明細５
            System.assertEquals(opp2.ItemCode_7__c, ordDetail2[4].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_7__c, ordDetail2[4].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_7__c + opp2.ModelType2_7__c), ordDetail2[4].Model__c); // 型式
            System.assertEquals(7, ordDetail2[4].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[4].OrderHeader__c); // 注文
            // 注文２の注文明細６
            System.assertEquals(opp2.ItemCode_8__c, ordDetail2[5].ItemCode__c); // 品目コード
            System.assertEquals(opp2.Item_8__c, ordDetail2[5].ItemName__c); // 品名
            System.assertEquals((opp2.ModelType1_8__c + opp2.ModelType2_8__c), ordDetail2[5].Model__c); // 型式
            System.assertEquals(8, ordDetail2[5].SequenceNumber__c); // 枝番
            System.assertEquals(ordHeader2.Id, ordDetail2[5].OrderHeader__c); // 注文
        }
    }
    /**
     * 異常パターン１
     * 注文の状態：受付以外（受付確認済）
     *
     */
    @isTest
    static void testErrorPatten1() {
        User u = [SELECT Id FROM User WHERE UserName = 'CreateOrderFromRegServiceBatchTest@testorg.com'];
        System.runAs(u) {
            // 荷主を作成
            Account acc1 = new Account(
                Name = '荷主１',
                Type = 'Account',
                BillingCountry = '日本',
                BillingState = '千葉県',
                BillingCity = '松戸市'
                // AccountCode__c = '12345'
            );
            insert acc1;
            OriginDestination__c origDes1 = new OriginDestination__c(
                Name = '着地',
                Account__c = acc1.Id,
                DeliveryArea__c = 'Medium',
                Prefecture__c = '埼玉県'
            );
            insert origDes1;
            // 注文を作成する
            List<OrderHeader__c> newOrderHeaderList = new List<OrderHeader__c>();
            OrderHeader__c newOrderHeader1 = new OrderHeader__c();
            newOrderHeader1.Account__c = acc1.Id; // 荷主
            newOrderHeader1.OriginPlace__c = origDes1.Id; // 発地
            newOrderHeader1.Destination__c = origDes1.Id; // 着地
            newOrderHeader1.UnitForShippingFeeCal__c = 'Case'; // 運賃計算用単位
            newOrderHeader1.ShippingFeeManualFlag__c = true;
            newOrderHeader1.Amount__c = 1000;
            newOrderHeader1.InvoiceAccount__c = acc1.Id; // 請求先
            newOrderHeader1.ImportedAccountName__c = 'ImportedAccountName__c'; // 取引先
            newOrderHeader1.InportedDeliveryDestination__c = 'InportedDeliveryDestination__c'; //納品先
            newOrderHeader1.ImportedDeliveryDestinationPhone__c = '123456789'; // 納品先電話番号
            newOrderHeader1.OrderNumber__c = '999999999951'; // 依頼番号
            newOrderHeader1.DeliveryDestinationAddress__c = 'DeliveryDestinationAddress__c'; //納品先住所
            newOrderHeader1.ReceptionDatetime__c = Datetime.parse('2025/03/17 00:00'); // 受付日
            newOrderHeader1.CloseDate__c = date.parse('2025/03/17'); // 取引日
            newOrderHeader1.Remarks3__c = 'Remarks3__c'; // 備考
            newOrderHeader1.Status__c = 'ReceptionCompleted'; // 状態

            newOrderHeaderList.add(newOrderHeader1);
            insert newOrderHeaderList;

            list<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = new Opportunity();
            opp.OrderNumber__c = '999999999951';
            opp.Name = '運送発注書_ソフトドリンク_999999999951.pdf';
            opp.ContentsType__c = 'application/pdf';
            opp.OrderPerson__c = '田中 太郎 ［asdfg48］';
            opp.FAXCreationTimeStr__c = '2025-03-17 11:15:00';
            opp.URL__c = 'https://fbiwpro.fujifilm.com/ST18BA948D9F4/document-9348';
            opp.AccountName__c = 'ソフト飲料';
            opp.Remarks__c = 'MFLP海老名1 2F/4FアポイントID: 18616614296';
            opp.DocumenType__c = '［fbj08752］運送発注書_マルエス様';
            opp.Item_1__c = 'ポカリスエット';
            opp.ItemCode_1__c = '大塚製薬１';
            opp.ModelType1_1__c = '12126(kg)';
            opp.ModelType2_1__c = '122(ケース)';
            opp.DeliveryNumber__c = '20250319-452209|';
            opp.DeliveryDestinationPhone__c = '080-3458-7016';
            opp.DeliveryDestinationAddress__c = '神奈川県海老名市中新田3290-38';
            opp.DesiredDeliveryDate__c = '2025/03/17 00:00';
            opp.CloseDate = Date.valueOf('2025-03-20');
            opp.StageName = '確認済み';
            opp.Title__c = '運送発注書';
            opp.ProcessingPerson__c = '自主荷役';
            opp.SupplierEmailAddress__c = 'aaaa@ddd.co.jp';
            opp.DeliveryDestination__c = 'AmazonTPGT 海老名';
            oppList.add(opp);

            Test.startTest();
            try {
                insert oppList;
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
}