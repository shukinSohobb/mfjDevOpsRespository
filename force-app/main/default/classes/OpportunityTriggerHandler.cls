/**
 * 商談から注文と注文明細を作成トリガーハンドラ
 * OpportunityTriggerHandler
 */
public class OpportunityTriggerHandler extends CommonTriggerHandler {
    private Map<Id, Opportunity> newMap;
    private Map<Id, Opportunity> oldMap;
    private List<Opportunity> newList;
    private List<Opportunity> oldList;

    public OpportunityTriggerHandler() {
        this.newMap = (Map<Id, Opportunity>) Trigger.newMap;
        this.oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
        this.newList = (List<Opportunity>) Trigger.new;
        this.oldList = (List<Opportunity>) Trigger.old;
    }

    public override void beforeInsert() {
        // 注文作成、注文Idをoppに設定
        createOrderFromOpportunity();
    }
    public override void afterInsert() {
        // 注文と注文詳細を更新
        updateOrderFromOpportunity();
    }

    /**
     * beforeInsert から「注文」を作成
     */
    private void createOrderFromOpportunity() {
        // Map＜商談「依頼番号」,商談＞
        Map<String, Opportunity> orderNumToOppMap = new Map<String, Opportunity>();
        // エラーメッセージリスト
        list<string> errorList = new List<string>();

        // Map＜商談「依頼番号」,商談＞に確認済みの商談をマップに格納する
        for (Opportunity opp : newList) {
            if (opp.StageName == '確認済み') {
                // 同じ opp.OrderNumber__c 複数同時にインポートした場合、最後のoppだけ、注文とリンクする
                orderNumToOppMap.put(opp.OrderNumber__c, opp);
            }
        }

        // 注文を取得
        List<OrderHeader__c> orderHeaderList = [
            SELECT id, OrderNumber__c, Status__c
            FROM OrderHeader__c
            WHERE OrderNumber__c IN :orderNumToOppMap.keyset()
        ];

        // Map＜商談「依頼番号」, 注文＞
        Map<String, OrderHeader__c> orderNumToOrderHeaderMap = new Map<String, OrderHeader__c>();
        for (OrderHeader__c orderHeader : orderHeaderList) {
            // Map＜商談「依頼番号」,注文＞に格納する
            orderNumToOrderHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
        }

        // 注文新規用リスト
        List<OrderHeader__c> orderHeaderListForInsertList = new List<OrderHeader__c>();
        for (Opportunity opp : orderNumToOppMap.values()) {
            if (opp.StageName == '確認済み' && !orderNumToOrderHeaderMap.containsKey(opp.OrderNumber__c)) {
                // 依頼番号に対応する注文が見つかった場合、商談に注文を関連付け
                OrderHeader__c newOrderHeader = new OrderHeader__c();
                newOrderHeader.OrderNumber__c = opp.OrderNumber__c;
                orderHeaderListForInsertList.add(newOrderHeader);
            }
        }

        // 作成必要な注文があれば、一度に挿入
        if (!orderHeaderListForInsertList.isEmpty()) {
            Database.SaveResult[] insertHeaderResultList = Database.insert(orderHeaderListForInsertList, false);
            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < insertHeaderResultList.size(); i++) {
                OrderHeader__c eObj = orderHeaderListForInsertList[i];
                Opportunity newObj = orderNumToOppMap.get(eObj.OrderNumber__c);
                Database.SaveResult sr = insertHeaderResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'OppTriggerHandler_upsert_orderHeaderListForInsertList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.get('Id');
                        newObj.addError(message);
                        errorList.add(message);
                    }
                }
            }
        }

        if (errorList.size() == 0) {
            List<OrderHeader__c> insertedOrderHeaderList = [
                SELECT id, OrderNumber__c
                FROM OrderHeader__c
                WHERE OrderNumber__c IN :orderNumToOppMap.keyset()
            ];
            // Map＜商談「依頼番号」, 注文＞
            Map<String, OrderHeader__c> insertedOrderHeaderMap = new Map<String, OrderHeader__c>();
            for (OrderHeader__c orderHeader : insertedOrderHeaderList) {
                // Map＜商談「依頼番号」,注文＞に格納する
                insertedOrderHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
            }

            for (Opportunity opp : orderNumToOppMap.values()) {
                if (insertedOrderHeaderMap.containsKey(opp.OrderNumber__c)) {
                    opp.OrderHeader__c = insertedOrderHeaderMap.get(opp.OrderNumber__c).Id;
                }
            }
        }
    }

    /**
     * afterInsert から注文と注文詳細を更新
     */
    private void updateOrderFromOpportunity() {
        // Map＜商談「依頼番号」,商談＞
        Map<String, Opportunity> orderNumToOppMap = new Map<String, Opportunity>();
        // エラーメッセージリスト
        list<string> errorList = new List<string>();

        // Map＜商談「依頼番号」,商談＞に確認済みの商談をマップに格納する
        for (Opportunity opp : newList) {
            if (opp.StageName == '確認済み') {
                // 同じ opp.OrderNumber__c 複数同時にインポートした場合、最後のoppだけ、注文とリンクする
                orderNumToOppMap.put(opp.OrderNumber__c, opp);
            }
        }

        // 注文明細削除用IDリスト
        List<Id> orderDetailForDelIdList = new List<Id>();

        // 注文＆注文明細を検索する
        List<OrderHeader__c> orderHeaderList = [
            SELECT
                id,
                Name, // #注文
                OrderNumber__c, // 依頼番号
                ImportedAccountName__c, // 取引先名
                AccountEmail__c, // 取引先メールアドレス
                CloseDate__c, // 取引日
                InportedDeliveryDestination__c, // 納品先
                DeliveryDestinationAddress__c, // 納品先住所
                ImportedDeliveryDestinationPhone__c, // 納品先電話番号
                Status__c, // 状態
                (
                    SELECT
                        Id,
                        UniqueKey__c, // 一意キー
                        ItemCode__c, // 品目コード
                        ItemName__c, // 品名
                        Model__c, // 型式
                        SequenceNumber__c, // 枝番
                        OrderHeader__c, // 注文
                        OrderHeader__r.OrderNumber__c // 依頼番号
                    FROM OrderDetailList__r
                    ORDER BY SequenceNumber__c
                )
            FROM OrderHeader__c
            WHERE OrderNumber__c IN :orderNumToOppMap.keyset()
        ];

        // 注文をマップに格納する（＜注文．依頼番号, 注文＞）
        Map<String, OrderHeader__c> orderHeaderMap = new Map<String, OrderHeader__c>();
        for (OrderHeader__c orderHeader : orderHeaderList) {
            orderHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
        }

        // マップに格納する（＜注文明細．一意キー, 注文明細＞）
        Map<String, OrderDetail__c> uKToDetailMap = new Map<String, OrderDetail__c>();
        for (OrderHeader__c orderHeader : orderHeaderMap.values()) {
            if (false == orderHeader.OrderDetailList__r.isempty()) {
                for (OrderDetail__c orderDetail : orderHeader.OrderDetailList__r) {
                    uKToDetailMap.put(orderDetail.UniqueKey__c, orderDetail);
                }
            }
        }

        // 注文更新用リスト
        List<OrderHeader__c> orderHeaderListForUpdateList = new List<OrderHeader__c>();
        // 注文明細更新用リスト
        List<OrderDetail__c> orderDetailListForUpsertList = new List<OrderDetail__c>();
        for (Opportunity opp : orderNumToOppMap.values()) {
            if ('Reception' == orderHeaderMap.get(opp.OrderNumber__c).Status__c) {
                OrderHeader__c newOrderHeader = new OrderHeader__c();
                // 注文を更新する
                newOrderHeader.Id = orderHeaderMap.get(opp.OrderNumber__c).Id;
                newOrderHeader.ImportedAccountName__c = opp.AccountName__c; // 取引先
                newOrderHeader.InportedDeliveryDestination__c = opp.DeliveryDestination__c; //納品先
                newOrderHeader.ImportedDeliveryDestinationPhone__c = opp.DeliveryDestinationPhone__c; // 納品先電話番号
                newOrderHeader.OrderNumber__c = opp.OrderNumber__c; // 依頼番号
                newOrderHeader.DeliveryDestinationAddress__c = opp.DeliveryDestinationAddress__c; //納品先住所
                newOrderHeader.ReceptionDatetime__c = Datetime.parse(opp.DesiredDeliveryDate__c); // 受付日
                newOrderHeader.CloseDate__c = opp.CloseDate; // 取引日
                newOrderHeader.Remarks3__c = opp.Remarks__c; // 備考
                orderHeaderListForUpdateList.add(newOrderHeader);
            } else {
                String message = '注文の状態は受付以外は商談から変更できません。';
                opp.addError(message);
            }

            for (Integer i = 1; i <= 8; i++) {
                // 品目コード
                String ItemCode = 'ItemCode_' + i + '__c';
                // 品目名
                String Item = 'Item_' + i + '__c';
                // 型式０１
                String ModelType1 = 'ModelType1_' + i + '__c';
                // 型式０２
                String ModelType2 = 'ModelType2_' + i + '__c';

                OrderDetail__c newOrderDetail = new OrderDetail__c();

                if (orderHeaderMap.get(opp.OrderNumber__c).OrderDetailList__r.size() > 0) {
                    if (
                        opp.get(ItemCode) != null ||
                        opp.get(Item) != null ||
                        opp.get(ModelType1) != null ||
                        opp.get(ModelType2) != null
                    ) {
                        string key = orderHeaderMap.get(opp.OrderNumber__c).Name + ',0' + i;
                        if (uKToDetailMap.containsKey(key)) {
                            // 注文明細を更新する
                            OrderDetail__c orderDetail = uKToDetailMap.get(key);
                            orderDetail.Id = orderDetail.Id;
                            orderDetail.ItemCode__c = opp.get(ItemCode) == null ? '' : (String) opp.get(ItemCode); // 品目コード
                            orderDetail.ItemName__c = opp.get(Item) == null ? '' : (String) opp.get(Item); // 品名
                            orderDetail.Model__c =
                                (opp.get(ModelType1) == null ? '' : (String) opp.get(ModelType1)) +
                                (opp.get(ModelType2) == null ? '' : (String) opp.get(ModelType2)); // 型式０１+ 型式０２
                            orderDetailListForUpsertList.add(orderDetail);
                        } else {
                            newOrderDetail.ItemCode__c = opp.get(ItemCode) == null ? '' : (String) opp.get(ItemCode); // 品目コード
                            newOrderDetail.ItemName__c = opp.get(Item) == null ? '' : (String) opp.get(Item); // 品名
                            newOrderDetail.Model__c =
                                (opp.get(ModelType1) == null ? '' : (String) opp.get(ModelType1)) +
                                (opp.get(ModelType2) == null ? '' : (String) opp.get(ModelType2)); // 型式０１+ 型式０２
                            newOrderDetail.SequenceNumber__c = i; // 枝番
                            newOrderDetail.OrderHeader__c = orderHeaderMap.get(opp.OrderNumber__c).Id; // 注文
                            orderDetailListForUpsertList.add(newOrderDetail);
                        }
                    } else {
                        string key = orderHeaderMap.get(opp.OrderNumber__c).Name + ',0' + i;
                        if (uKToDetailMap.get(key) != null) {
                            OrderDetail__c orderDetail = uKToDetailMap.get(key);
                            orderDetailForDelIdList.add(orderDetail.Id);
                        }
                    }
                } else {
                    // １～８から注文明細があるの場合
                    if (
                        opp.get(ItemCode) != null ||
                        opp.get(Item) != null ||
                        opp.get(ModelType1) != null ||
                        opp.get(ModelType2) != null
                    ) {
                        // 注文明細を作成する
                        //OrderDetail__c newOrderDetail = new OrderDetail__c();
                        newOrderDetail.ItemCode__c = opp.get(ItemCode) == null ? '' : (String) opp.get(ItemCode); // 品目コード
                        newOrderDetail.ItemName__c = opp.get(Item) == null ? '' : (String) opp.get(Item); // 品名
                        newOrderDetail.Model__c =
                            (opp.get(ModelType1) == null ? '' : (String) opp.get(ModelType1)) +
                            (opp.get(ModelType2) == null ? '' : (String) opp.get(ModelType2)); // 型式０１+ 型式０２
                        newOrderDetail.SequenceNumber__c = i; // 枝番
                        newOrderDetail.OrderHeader__c = orderHeaderMap.get(opp.OrderNumber__c).Id; // 注文
                        orderDetailListForUpsertList.add(newOrderDetail);
                    }
                }
            }
        }

        // 更新必要な注文があれば、一度に挿入
        if (false == orderHeaderListForUpdateList.isEmpty()) {
            Database.SaveResult[] updateHeaderResultList = Database.update(orderHeaderListForUpdateList, false);

            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < updateHeaderResultList.size(); i++) {
                OrderHeader__c eObj = orderHeaderListForUpdateList[i];
                Opportunity newObj = orderNumToOppMap.get(eObj.OrderNumber__c);
                Database.SaveResult sr = updateHeaderResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'OppTriggerHandler_upsert_orderHeaderListForUpdateList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.get('Id');
                        newObj.addError(message);
                        errorList.add(message);
                    }
                }
            }
        }

        // 更新＆作成必要な注文明細があれば、一度に挿入
        if (false == orderDetailListForUpsertList.isEmpty()) {
            Database.UpsertResult[] upsertDetailResultList = Database.upsert(orderDetailListForUpsertList, false);

            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < upsertDetailResultList.size(); i++) {
                OrderDetail__c eObj = orderDetailListForUpsertList[i];
                Opportunity newObj = orderNumToOppMap.get(eObj.OrderHeader__r.OrderNumber__c);
                Database.UpsertResult sr = upsertDetailResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'OppTriggerHandler_upsert_orderDetailListForUpsertList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.Id;
                        eObj.get('Id');
                        newObj.addError(message);
                        errorList.add(message);
                    }
                }
            }
        }

        if (true == errorList.isEmpty()) {
            List<OrderDetail__c> deleteOrserDetailList = [
                SELECT Id, ItemName__c, OrderHeader__r.OrderNumber__c
                FROM OrderDetail__c
                WHERE Id IN :orderDetailForDelIdList
            ];
            if (false == deleteOrserDetailList.isEmpty()) {
                Database.DeleteResult[] deleteDetailResults = Database.delete(deleteOrserDetailList, false);
                // エラー発生の場合、エラーメッセージを表示する
                for (Integer i = 0; i < deleteDetailResults.size(); i++) {
                    OrderDetail__c eObj = deleteOrserDetailList[i];
                    Opportunity newObj = orderNumToOppMap.get(eObj.OrderHeader__r.OrderNumber__c);
                    Database.DeleteResult sr = deleteDetailResults[i];
                    if (false == sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            String message =
                                'OppTriggerHandler_delete_deleteOrserDetailList' +
                                ':' +
                                err +
                                ' Data:' +
                                eObj.get('Id');
                            newObj.addError(message);
                            errorList.add(message);
                        }
                    }
                }
            }
        }
    }
}