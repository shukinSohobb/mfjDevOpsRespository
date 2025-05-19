/**
 * 路線便情報から注文と注文明細を作成トリガーハンドラ
 * RouteDeliveryTriggerHandler
 */
public class RouteDeliveryTriggerHandler extends CommonTriggerHandler {
    private Map<Id, RouteDelivery__c> newMap;
    private Map<Id, RouteDelivery__c> oldMap;
    private List<RouteDelivery__c> newList;
    private List<RouteDelivery__c> oldList;

    public RouteDeliveryTriggerHandler() {
        this.newMap = (Map<Id, RouteDelivery__c>) Trigger.newMap;
        this.oldMap = (Map<Id, RouteDelivery__c>) Trigger.oldMap;
        this.newList = (List<RouteDelivery__c>) Trigger.new;
        this.oldList = (List<RouteDelivery__c>) Trigger.old;
    }

    public override void beforeInsert() {
        // 注文作成、注文Idをに設定
        createOrderFromRouteDelivery();
    }
    public override void afterInsert() {
        // 注文と注文詳細を更新
        updateOrderFromRouteDelivery();
    }

    /**
     * beforeInsert から「注文」を作成
     */
    private void createOrderFromRouteDelivery() {
        // Map＜路線便情報「伝票番号」,路線便情報＞
        Map<String, RouteDelivery__c> slipNumToRouteMap = new Map<String, RouteDelivery__c>();
        // エラーメッセージリスト
        list<string> errorList = new List<string>();

        // Map＜路線便情報「伝票番号」,路線便情報＞マップに格納する
        for (RouteDelivery__c route : newList) {
            // 同じ route.SlipNumber__c 複数同時にインポートした場合、最後のrouteだけ、注文とリンクする
            slipNumToRouteMap.put(route.SlipNumber__c, route);
        }

        // 注文を取得
        List<OrderHeader__c> orderHeaderList = [
            SELECT id, OrderNumber__c, Status__c
            FROM OrderHeader__c
            WHERE OrderNumber__c IN :slipNumToRouteMap.keyset()
        ];

        // Map＜注文「依頼番号」, 注文＞
        Map<String, OrderHeader__c> orderNumToHeaderMap = new Map<String, OrderHeader__c>();
        for (OrderHeader__c orderHeader : orderHeaderList) {
            // Map＜路線便情報「伝票番号」,注文＞に格納する
            orderNumToHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
        }

        // 注文新規用リスト
        List<OrderHeader__c> headerForInsertList = new List<OrderHeader__c>();
        for (RouteDelivery__c route : slipNumToRouteMap.values()) {
            if (!orderNumToHeaderMap.containsKey(route.SlipNumber__c)) {
                // 伝票番号に対応する注文が見つかった場合、路線便情報に注文を関連付け
                OrderHeader__c newOrderHeader = new OrderHeader__c();
                newOrderHeader.OrderNumber__c = route.SlipNumber__c;
                headerForInsertList.add(newOrderHeader);
            }
        }
        // 作成必要な注文があれば、一度に挿入
        if (!headerForInsertList.isEmpty()) {
            Database.SaveResult[] insertHeaderResultList = Database.insert(headerForInsertList, false);
            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < insertHeaderResultList.size(); i++) {
                OrderHeader__c eObj = headerForInsertList[i];
                RouteDelivery__c newObj = slipNumToRouteMap.get(eObj.OrderNumber__c);
                Database.SaveResult sr = insertHeaderResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'RouteDeliveryTriggerHandler_insert_headerForInsertList' +
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
                WHERE OrderNumber__c IN :slipNumToRouteMap.keyset()
            ];
            // Map＜注文「依頼番号」, 注文＞
            Map<String, OrderHeader__c> insertedorderNumToHeaderMap = new Map<String, OrderHeader__c>();
            for (OrderHeader__c orderHeader : insertedOrderHeaderList) {
                // Map＜注文「依頼番号」,注文＞に格納する
                insertedorderNumToHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
            }

            for (RouteDelivery__c route : newList) {
                if (insertedorderNumToHeaderMap.containsKey(route.SlipNumber__c)) {
                    route.OrderHeader__c = insertedorderNumToHeaderMap.get(route.SlipNumber__c).Id;
                }
            }
        }
    }

    /**
     * afterInsert から注文と注文詳細を更新
     */
    private void updateOrderFromRouteDelivery() {
        // Map＜定期便情報「伝票番号」,定期便情報＞
        Map<String, RouteDelivery__c> slipNumToRouteMap = new Map<String, RouteDelivery__c>();
        // Map＜定期便情報「伝票番号」+「ライン№」,定期便情報＞
        Map<String, RouteDelivery__c> slipNumSequToRouteMap = new Map<String, RouteDelivery__c>();
        // エラーメッセージリスト
        list<string> errorList = new List<string>();

        // Map＜定期便情報「伝票番号」,定期便情報＞マップに格納する
        for (RouteDelivery__c route : newList) {
            // 同じ route.SlipNumber__c 複数同時にインポートした場合、最後のrouteだけ、注文とリンクする
            slipNumToRouteMap.put(route.SlipNumber__c, route);
            string key = route.SlipNumber__c + ',' + route.LineNumber__c;
            slipNumSequToRouteMap.put(key, route);
        }

        // 注文＆注文明細を検索する
        List<OrderHeader__c> orderHeaderList = [
            SELECT
                id,
                Name, // #注文
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
                (
                    SELECT
                        Id,
                        UniqueKey__c, // 一意キー
                        ItemCode__c, // 品目コード
                        ItemName__c, // 品名
                        SequenceNumber__c, // 枝番
                        Quantity__c, // 数量
                        UnitQuantity__c, // 入数
                        CSQuantity__c, // CS数
                        WeightKG__c, // 重量（Kg）
                        Remarks__c, // 備考
                        OrderHeader__c, // 注文
                        OrderHeader__r.OrderNumber__c // 依頼番号
                    FROM OrderDetailList__r
                    ORDER BY SequenceNumber__c
                )
            FROM OrderHeader__c
            WHERE OrderNumber__c IN :slipNumToRouteMap.keyset()
        ];

        // 注文をマップに格納する（＜注文．依頼番号, 注文＞）
        Map<String, OrderHeader__c> orderNumToHeaderMap = new Map<String, OrderHeader__c>();
        for (OrderHeader__c orderHeader : orderHeaderList) {
            orderNumToHeaderMap.put(orderHeader.OrderNumber__c, orderHeader);
        }

        // マップに格納する（＜注文明細．一意キー, 注文明細＞）
        Map<String, OrderDetail__c> uKToDetailMap = new Map<String, OrderDetail__c>();
        for (OrderHeader__c orderHeader : orderNumToHeaderMap.values()) {
            if (false == orderHeader.OrderDetailList__r.isempty()) {
                for (OrderDetail__c orderDetail : orderHeader.OrderDetailList__r) {
                    uKToDetailMap.put(orderDetail.UniqueKey__c, orderDetail);
                }
            }
        }

        // 注文更新用リスト
        List<OrderHeader__c> orderHeaderForUpdateList = new List<OrderHeader__c>();
        // 注文明細更新用リスト
        List<OrderDetail__c> orderDetailForUpsertList = new List<OrderDetail__c>();

        for (RouteDelivery__c route : slipNumToRouteMap.values()) {
            // 注文の状態は「受付」の場合、注文を更新する
            string slipNumber = '';
            if ('Reception' == orderNumToHeaderMap.get(route.SlipNumber__c).Status__c) {
                // 注文を更新する
                OrderHeader__c orderHeader = new OrderHeader__c();
                // 注文.ID
                orderHeader.Id = orderNumToHeaderMap.get(route.SlipNumber__c).Id;
                // 注文.伝票種別指定 ← 路線便.伝票種別指定
                orderHeader.SlipKindDesignated__c = route.SlipKindDesignated__c;
                // 注文.受付日時 ← 路線便.受付日時
                orderHeader.ReceptionDatetime__c = route.ReceptionDate__c == null
                    ? Datetime.now()
                    : DateTime.newInstance(route.ReceptionDate__c, Time.newInstance(0, 0, 0, 0));
                // 注文.積込日 ← 路線便.出荷日
                orderHeader.LoadingDate__c = route.ShippingDate__c;
                // 注文.納品日 ← 路線便.納品日
                orderHeader.ExpectedDeliveryDate__c = route.ExpectedDeliveryDate__c;
                // 注文.納品先 ← 路線便.送付先
                orderHeader.InportedDeliveryDestination__c = route.DestinationName__c;
                // 注文.納品先郵便番号 ← 路線便.送付先郵便番号
                orderHeader.DeliveryDestinationPostalCode__c = route.ShippingPostCode__c;
                // 注文.納品先住所1 ← 路線便.送付先住所1 + 路線便.送付先住所2
                orderHeader.DeliveryDestinationAddress__c =
                    (route.ShippingAddress1__c == null ? '' : route.ShippingAddress1__c) +
                    (route.ShippingAddress2__c == null ? '' : route.ShippingAddress2__c);
                // 注文.納品先住所2 ← 路線便.送付先住所3
                orderHeader.DeliveryDestinationAddress2__c = route.ShippingAddress3__c;
                // 注文.納品先電話番号 ← 路線便.送付先電話番号
                orderHeader.ImportedDeliveryDestinationPhone__c = route.ShippingPhone__c;
                // 注文.出発時間帯 ← 路線便.出発時間帯
                orderHeader.DepartureTime__c = route.DepartureTime__c;
                // 注文.単価 ← 路線便.単価
                orderHeader.UnitPriceRoute__c = route.UnitPrice__c;
                // 注文.運賃（路線便） ← 路線便.運賃 + 地区割増 + 中継費
                orderHeader.AmountRoute__c =
                    (route.Amount__c == null ? 0 : route.Amount__c) +
                    (route.DistrictPremium__c == null ? 0 : route.DistrictPremium__c) +
                    (route.RelayFee__c == null ? 0 : route.RelayFee__c);
                // 注文.取引先 ← 路線便.取引先
                orderHeader.ImportedAccountName__c = route.AccountName__c;
                // 注文.距離（路線便） ← 路線便.距離
                orderHeader.DistanceRoute__c = route.Distance__c;
                // 注文.配送名 ← 路線便.配送名
                orderHeader.ShippingName__c = route.DeliveryName__c;
                // 注文.輸送形態 ← 路線便
                orderHeader.TransportationMode__c = 'Route';
                orderHeaderForUpdateList.add(orderHeader);
            } else {
                String message = '注文の状態は受付以外は路線便から変更できません。';
                route.addError(message);
            }
        }

        // マップに格納する（＜注文明細．一意キー, 路線便情報＞）
        Map<String, RouteDelivery__c> errorKeyToRouteMap = new Map<String, RouteDelivery__c>();

        for (RouteDelivery__c route : slipNumSequToRouteMap.values()) {
            // 注文明細の一意キー
            Integer len = String.valueOf(route.LineNumber__c).length();
            string key = '';
            string errorKey = '';
            if (len > 1) {
                key = orderNumToHeaderMap.get(route.SlipNumber__c).Name + ',' + route.LineNumber__c;
                errorKey = orderNumToHeaderMap.get(route.SlipNumber__c).Id + ',' + route.LineNumber__c;
            } else {
                key = orderNumToHeaderMap.get(route.SlipNumber__c).Name + ',0' + route.LineNumber__c;
                errorKey = orderNumToHeaderMap.get(route.SlipNumber__c).Id + ',0' + route.LineNumber__c;
            }

            OrderDetail__c newOrderDetail = new OrderDetail__c();

            if (orderNumToHeaderMap.get(route.SlipNumber__c).OrderDetailList__r.size() > 0) {
                if (uKToDetailMap.containsKey(key)) {
                    // 注文明細を更新する
                    OrderDetail__c orderDetail = uKToDetailMap.get(key);
                    orderDetail.Id = orderDetail.Id;
                    // 注文明細.品目コード ← 路線便.商品CD
                    orderDetail.ItemCode__c = route.ProductCD__c;
                    // 注文明細.品名 ← 路線便.品名
                    orderDetail.ItemName__c = route.ItemName__c;
                    // 注文明細.数量 ← 路線便.数量
                    orderDetail.Quantity__c = route.Quantity__c;
                    // 注文明細.入数 ← 路線便.入数
                    orderDetail.UnitQuantity__c = route.UnitQuantity__c;
                    // 注文明細.CS数 ← 路線便.CS数
                    orderDetail.CSQuantity__c = route.CSQuantity__c;
                    // 注文明細.重量（Kg） ← 路線便.重量（Kg）
                    orderDetail.WeightKG__c = route.WeightKG__c;
                    // 注文明細.備考 ← 路線便.用途 + 路線便.備考
                    orderDetail.Remarks__c =
                        (route.Purpose__c == null ? '' : route.Purpose__c) +
                        (route.Remarks__c == null ? '' : route.Remarks__c);
                    orderDetailForUpsertList.add(orderDetail);
                } else {
                    // 注文明細を新規する
                    // 注文明細.枝番 ← 路線便.ライン№
                    newOrderDetail.SequenceNumber__c = route.LineNumber__c;
                    // 注文明細.品目コード ← 路線便.商品CD
                    newOrderDetail.ItemCode__c = route.ProductCD__c;
                    // 注文明細.品名 ← 路線便.品名
                    newOrderDetail.ItemName__c = route.ItemName__c;
                    // 注文明細.数量 ← 路線便.数量
                    newOrderDetail.Quantity__c = route.Quantity__c;
                    // 注文明細.入数 ← 路線便.入数
                    newOrderDetail.UnitQuantity__c = route.UnitQuantity__c;
                    // 注文明細.CS数 ← 路線便.CS数
                    newOrderDetail.CSQuantity__c = route.CSQuantity__c;
                    // 注文明細.重量（Kg） ← 路線便.重量（Kg）
                    newOrderDetail.WeightKG__c = route.WeightKG__c;
                    // 注文明細.備考 ← 路線便.用途 + 路線便.備考
                    newOrderDetail.Remarks__c =
                        (route.Purpose__c == null ? '' : route.Purpose__c) +
                        (route.Remarks__c == null ? '' : route.Remarks__c);
                    // 注文明細.注文 ← 注文.ID
                    newOrderDetail.OrderHeader__c = orderNumToHeaderMap.get(route.SlipNumber__c).Id;
                    orderDetailForUpsertList.add(newOrderDetail);
                }
            } else {
                // 注文明細を新規する
                // 注文明細.枝番 ← 路線便.ライン№
                newOrderDetail.SequenceNumber__c = route.LineNumber__c;
                // 注文明細.品目コード ← 路線便.商品CD
                newOrderDetail.ItemCode__c = route.ProductCD__c;
                // 注文明細.品名 ← 路線便.品名
                newOrderDetail.ItemName__c = route.ItemName__c;
                // 注文明細.数量 ← 路線便.数量
                newOrderDetail.Quantity__c = route.Quantity__c;
                // 注文明細.入数 ← 路線便.入数
                newOrderDetail.UnitQuantity__c = route.UnitQuantity__c;
                // 注文明細.CS数 ← 路線便.CS数
                newOrderDetail.CSQuantity__c = route.CSQuantity__c;
                // 注文明細.重量（Kg） ← 路線便.重量（Kg）
                newOrderDetail.WeightKG__c = route.WeightKG__c;
                // 注文明細.備考 ← 路線便.用途 + 路線便.備考
                newOrderDetail.Remarks__c =
                    (route.Purpose__c == null ? '' : route.Purpose__c) + (route.Remarks__c == null ? '' : route.Remarks__c);
                // 注文明細.注文 ← 注文.ID
                newOrderDetail.OrderHeader__c = orderNumToHeaderMap.get(route.SlipNumber__c).Id;
                orderDetailForUpsertList.add(newOrderDetail);
            }
            errorKeyToRouteMap.put(errorKey, route);
        }

        // 更新必要な注文があれば、一度に挿入
        if (false == orderHeaderForUpdateList.isEmpty()) {
            Database.SaveResult[] updateHeaderResultList = Database.update(orderHeaderForUpdateList, false);

            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < updateHeaderResultList.size(); i++) {
                OrderHeader__c eObj = orderHeaderForUpdateList[i];
                RouteDelivery__c newObj = slipNumToRouteMap.get(eObj.OrderNumber__c);
                Database.SaveResult sr = updateHeaderResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'routeTriggerHandler_update_orderHeaderForUpdateList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.get('Id');
                        string errorMessage = err.getMessage();
                        newObj.addError(errorMessage);
                        errorList.add(message);
                    }
                }
            }
        }

        // 更新＆作成必要な注文明細があれば、一度に挿入
        if (false == orderDetailForUpsertList.isEmpty()) {
            Database.UpsertResult[] upsertDetailResultList = Database.upsert(orderDetailForUpsertList, false);

            // エラー発生の場合、エラーメッセージを表示する
            for (Integer i = 0; i < upsertDetailResultList.size(); i++) {
                OrderDetail__c eObj = orderDetailForUpsertList[i];
                Integer len = String.valueOf(eObj.SequenceNumber__c).length();
                string errKey = '';
                if (len > 1) {
                    errKey = eObj.OrderHeader__c + ',' + eObj.SequenceNumber__c;
                } else {
                    errKey = eObj.OrderHeader__c + ',0' + eObj.SequenceNumber__c;
                }
                RouteDelivery__c newObj = errorKeyToRouteMap.get(errKey);
                //RouteDelivery__c newObj = slipNumToRouteMap.get(eObj.OrderHeader__c);
                Database.UpsertResult sr = upsertDetailResultList[i];
                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String message =
                            'routeTriggerHandler_upsert_orderDetailForUpsertList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.Id;
                        eObj.get('Id');
                        string errorMessage = err.getMessage();
                        newObj.addError(errorMessage);
                        errorList.add(message);
                    }
                }
            }
        }

        if (true == errorList.isEmpty()) {
            List<OrderDetail__c> deleteOrderDetailList = [
                SELECT Id, OrderHeader__r.OrderNumber__c
                FROM OrderDetail__c
                WHERE Id NOT IN :orderDetailForUpsertList AND OrderHeader__c IN :orderHeaderForUpdateList
            ];

            if (false == deleteOrderDetailList.isEmpty()) {
                Database.DeleteResult[] deleteDetailResults = Database.delete(deleteOrderDetailList, false);
                // エラー発生の場合、エラーメッセージを表示する
                for (Integer i = 0; i < deleteDetailResults.size(); i++) {
                    OrderDetail__c eObj = deleteOrderDetailList[i];
                    RouteDelivery__c newObj = slipNumToRouteMap.get(eObj.OrderHeader__r.OrderNumber__c);
                    Database.DeleteResult sr = deleteDetailResults[i];
                    if (false == sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            String message =
                                'routeTriggerHandler_delete_deleteOrderDetailList' +
                                ':' +
                                err +
                                ' Data:' +
                                eObj.get('Id');
                            string errorMessage = err.getMessage();
                            newObj.addError(errorMessage);
                            errorList.add(message);
                        }
                    }
                }
            }
        }
    }
}