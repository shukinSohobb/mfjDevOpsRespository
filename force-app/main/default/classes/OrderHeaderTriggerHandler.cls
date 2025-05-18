public inherited sharing class OrderHeaderTriggerHandler extends CommonTriggerHandler {
    private List<OrderHeader__c> oldList;
    private List<OrderHeader__c> newList;
    private Map<Id, OrderHeader__c> oldMap;
    private Map<Id, OrderHeader__c> newMap;

    public OrderHeaderTriggerHandler() {
        this.oldList = (List<OrderHeader__c>) Trigger.old;
        this.newList = (List<OrderHeader__c>) Trigger.new;
        this.oldMap = (Map<Id, OrderHeader__c>) Trigger.oldMap;
        this.newMap = (Map<Id, OrderHeader__c>) Trigger.newMap;
    }

    // 商品IDから、在庫情報一覧へのマップ
    Map<Id, List<OrderHeaderTriggerHandler.StockInfo>> productToStockInfoMap = new Map<Id, List<OrderHeaderTriggerHandler.StockInfo>>();
    // 「商品マスタ_賞味期限」から、指定あり在庫情報一覧へのマップ
    Map<String, List<OrderHeaderTriggerHandler.StockInfo>> productToStockInfoWithDateMap = new Map<String, List<OrderHeaderTriggerHandler.StockInfo>>();

    public override void beforeInsert() {
        // 名前設定
        this.orderHeaderNaming();
    }

    public override void beforeUpdate() {
        this.insertManualUpdateLog();
    }

    public override void afterUpdate() {
        this.lotAutoAllocate();
    }

    // afterUpdate,ロットの自動引き当てメソッド
    private void lotAutoAllocate() {
        // 「受付確認済」に変更した注文のマップ
        Map<Id, OrderHeader__c> orderHeaderMap = new Map<Id, OrderHeader__c>();
        // 注文の「受付」状態のAPI参照名
        String receptionStatus = 'Reception';
        // 注文の「受付確認済」状態のAPI参照名
        String receptionCompletedStatus = 'ReceptionCompleted';
        for (OrderHeader__c newListRecord : this.newList) {
            // 「受付確認済」になった注文しか対応しない
            if (
                receptionCompletedStatus.equals(newListRecord.Status__c) &&
                receptionStatus.equals(this.oldMap.get(newListRecord.Id).Status__c) &&
                false == newListRecord.NotNeedShipping__c
            ) {
                orderHeaderMap.put(newListRecord.Id, newListRecord);
            }
        }
        // マップが空の場合、処理しない
        if (orderHeaderMap.isEmpty())
            return;

        // 注文の注文明細を取得
        List<Id> orderHeaderIdList = new List<Id>(orderHeaderMap.keySet());
        List<OrderDetail__c> orderDetailList = [
            SELECT
                Id,
                Name,
                ProductMaster__c,
                OrderHeader__c,
                Quantity__c,
                SequenceNumber__c,
                ExpirationDate__c,
                LotNumber_F__c
            FROM OrderDetail__c
            WHERE OrderHeader__c IN :orderHeaderIdList AND Quantity__c > 0 AND ProductMaster__c != NULL
            ORDER BY Name
        ];

        // 有効な注文明細がない場合、処理しない
        if (orderDetailList.size() == 0) {
            return;
        }

        // 注文に関連するすべての注文詳細のマップ
        Map<Id, List<OrderDetail__c>> mapOrderIdToOrderDetail = new Map<Id, List<OrderDetail__c>>();
        // 注文明細IDの注文明細詳細のマップ
        Map<Id, OrderDetail__c> mapOrderDetailIdToOrderDetail = new Map<Id, OrderDetail__c>();
        // 商品マスタ_賞味期限一覧
        List<String> conditionExpirationDateList = new List<String>();
        // 商品マスタID一覧
        List<Id> productMasterIdList = new List<Id>();
        for (OrderDetail__c orderDetail : orderDetailList) {
            // マップにデータがない場合、空の一覧を追加
            if (mapOrderIdToOrderDetail.get(orderDetail.OrderHeader__c) == null) {
                mapOrderIdToOrderDetail.put(orderDetail.OrderHeader__c, new List<OrderDetail__c>());
            }
            mapOrderIdToOrderDetail.get(orderDetail.OrderHeader__c).add(orderDetail);
            mapOrderDetailIdToOrderDetail.put(orderDetail.Id, orderDetail);
            // 賞味期限がる場合、商品マスタ_賞味期限一覧に追加
            if (!String.isBlank(orderDetail.LotNumber_F__c) && !(orderDetail.LotNumber_F__c.endsWith('_'))) {
                conditionExpirationDateList.add(orderDetail.LotNumber_F__c);
            }
            // 商品マスタID一覧に追加
            if (!productMasterIdList.contains(orderDetail.ProductMaster__c)) {
                productMasterIdList.add(orderDetail.ProductMaster__c);
            }
        }
        // 在庫情報IDの在庫情報詳細のマップ
        Map<Id, ProductStockInfo__c> mapProductStockInfoIdToProductStockInfo = new Map<Id, ProductStockInfo__c>();

        // 商品ID一覧を使用して在庫情報の一覧を取得
        List<ProductStockInfo__c> productStockInfoList = new List<ProductStockInfo__c>();
        if (productMasterIdList.size() > 0) {
            productStockInfoList = [
                SELECT
                    Id,
                    ProductMaster__c,
                    AllocableQuantity_F__c,
                    LotNumber__c,
                    WarehouseMaster__c,
                    WarehouseMaster__r.Name,
                    ArrivalDate__c
                FROM ProductStockInfo__c
                WHERE
                    ProductMaster__c IN :productMasterIdList
                    AND AllocableQuantity_F__c > 0
                    AND AllocableQuantity_F__c != NULL
                ORDER BY LotNumber__c, ArrivalDate__c, CreatedDate, Id
            ];
        }

        // 在庫情報一覧へのマップを作成
        for (ProductStockInfo__c productStockInfo : productStockInfoList) {
            if (productToStockInfoWithDateMap.get(productStockInfo.LotNumber__c) == null) {
                productToStockInfoWithDateMap.put(
                    productStockInfo.LotNumber__c,
                    new List<OrderHeaderTriggerHandler.StockInfo>()
                );
            }
            if (productToStockInfoMap.get(productStockInfo.ProductMaster__c) == null) {
                productToStockInfoMap.put(
                    productStockInfo.ProductMaster__c,
                    new List<OrderHeaderTriggerHandler.StockInfo>()
                );
            }
            OrderHeaderTriggerHandler.StockInfo stockInfoTemp = new OrderHeaderTriggerHandler.StockInfo(
                productStockInfo.Id,
                productStockInfo.AllocableQuantity_F__c,
                productStockInfo.LotNumber__c
            );
            // 商品マスタ_賞味期限一覧に含まれれば、指定あり在庫情報マップに追加される
            if (conditionExpirationDateList.contains(productStockInfo.LotNumber__c)) {
                productToStockInfoWithDateMap.get(productStockInfo.LotNumber__c).add(stockInfoTemp);
            }
            productToStockInfoMap.get(productStockInfo.ProductMaster__c).add(stockInfoTemp);
            mapProductStockInfoIdToProductStockInfo.put(productStockInfo.Id, productStockInfo);
        }

        // 新規作成用のピッキングリストの一覧
        List<PickingList__c> pickingListForInsertList = new List<PickingList__c>();
        // ピッキングリストデータ一覧の作成処理
        for (Id orderHeaderId : orderHeaderIdList) {
            if (mapOrderIdToOrderDetail.get(orderHeaderId) != null) {
                for (OrderDetail__c orderDetail : mapOrderIdToOrderDetail.get(orderHeaderId)) {
                    // ピッキングリストデータの作成メソッド
                    this.createPickingList(pickingListForInsertList, orderDetail);
                }
            }
        }

        // ピッキングリストレコドを新規作成
        if (pickingListForInsertList.size() > 0) {
            // 更新するための 注文からFirst倉庫へのマップ
            Map<Id, OrderHeader__c> orderHeaderFirstWarehouseMasterUpdateMap = new Map<Id, OrderHeader__c>();
            for (PickingList__c pl : pickingListForInsertList) {
                // 注文はまだFirst倉庫がなければ、処理する
                if (orderHeaderFirstWarehouseMasterUpdateMap.get(pl.OrderHeader__c) == null) {
                    // ピッキングリストの注文明細が１枝番の場合、処理する
                    if (
                        mapOrderDetailIdToOrderDetail.get(pl.OrderDetail__c) != null &&
                        mapOrderDetailIdToOrderDetail.get(pl.OrderDetail__c).SequenceNumber__c == 1
                    ) {
                        // 倉庫レコードのID
                        String warehouseMasterId = mapProductStockInfoIdToProductStockInfo.get(pl.ProductStockInfo__c)
                            ?.WarehouseMaster__c;
                        // 倉庫レコードの名前
                        String warehouseMasterName = mapProductStockInfoIdToProductStockInfo.get(pl.ProductStockInfo__c)
                            ?.WarehouseMaster__r.Name;
                        // 在庫情報レコードのロット番号
                        String lotNumber = mapProductStockInfoIdToProductStockInfo.get(pl.ProductStockInfo__c)?.LotNumber__c;
                        // マップに、注文の更新情報を追加
                        orderHeaderFirstWarehouseMasterUpdateMap.put(
                            pl.OrderHeader__c,
                            new OrderHeader__c(
                                Id = pl.OrderHeader__c,
                                LotNumber__c = lotNumber,
                                WarehouseMasterName__c = warehouseMasterName,
                                FirstWarehouseMaster__c = warehouseMasterId
                            )
                        );
                    }
                }
            }

            Map<Id, String> orderHeaderIdErrorMessageMap = new Map<Id, String>();
            // ピッキングリストの作成
            if (false == pickingListForInsertList.isEmpty()) {
                // 重複エラーを回避するため、1件ずつレコードを作成。
                for (PickingList__c eObj : pickingListForInsertList) {
                    Database.SaveResult[] saveResultList = Database.insert(new List<PickingList__c>{ eObj }, false);
                    Database.SaveResult sr = saveResultList[0];
                    if (false == sr.isSuccess()) {
                        // １件目エラー
                        Database.Error err = (sr.getErrors())[0];
                        String errorMessage =
                            'OrderHeaderTriggerHandler_insert_pickingListForInsertList' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.get('Id');
                        if (orderHeaderIdErrorMessageMap.get(eObj.OrderHeader__c) == null) {
                            orderHeaderIdErrorMessageMap.put(eObj.OrderHeader__c, '');
                        }
                        orderHeaderIdErrorMessageMap.put(
                            eObj.OrderHeader__c,
                            orderHeaderIdErrorMessageMap.get(eObj.OrderHeader__c) + errorMessage
                        );
                    }
                }
            }
            // 注文の更新
            if (false == orderHeaderFirstWarehouseMasterUpdateMap.values().isEmpty()) {
                List<OrderHeader__c> orderHeaderUpdateList = orderHeaderFirstWarehouseMasterUpdateMap.values();
                // optAllOrNone = false エラーは手動ハンドリング
                Database.SaveResult[] saveResultList = Database.update(orderHeaderUpdateList, false);
                // エラー発生の場合、エラーメッセージを表示する
                for (Integer i = 0; i < saveResultList.size(); i++) {
                    OrderHeader__c eObj = orderHeaderUpdateList[i];
                    Database.SaveResult sr = saveResultList[i];
                    if (false == sr.isSuccess()) {
                        // １件目エラー
                        Database.Error err = (sr.getErrors())[0];
                        String errorMessage =
                            'OrderHeaderTriggerHandler_afterUpdate_orderHeaderFirstWarehouseMasterUpdateMap.values' +
                            ':' +
                            err +
                            ' Data:' +
                            eObj.get('Id');
                        if (orderHeaderIdErrorMessageMap.get(eObj.Id) == null) {
                            orderHeaderIdErrorMessageMap.put(eObj.Id, '');
                        }
                        orderHeaderIdErrorMessageMap.put(eObj.Id, orderHeaderIdErrorMessageMap.get(eObj.Id) + errorMessage);
                    }
                }
            }
            // エラー表示
            for (Id orderHeaderId : orderHeaderIdErrorMessageMap.keySet()) {
                orderHeaderMap.get(orderHeaderId).addError(orderHeaderIdErrorMessageMap.get(orderHeaderId));
            }
        }
    }

    // ピッキングリストを作成するメソッド
    private void createPickingList(List<PickingList__c> pickingListForInsertList, OrderDetail__c orderDetail) {
        // 一時的なピッキングリストのレコード。デフォルトは未引当のピッキングリスト。
        PickingList__c pickingListTemp = new PickingList__c();
        pickingListTemp.OrderHeader__c = orderDetail.OrderHeader__c;
        pickingListTemp.OrderDetail__c = orderDetail.Id;
        pickingListTemp.ProductStockInfo__c = null;
        pickingListTemp.Quantity__c = null;

        // 在庫情報一覧
        List<OrderHeaderTriggerHandler.StockInfo> productStockInfoList = new List<OrderHeaderTriggerHandler.StockInfo>();

        if (!String.isBlank(orderDetail.LotNumber_F__c) && !(orderDetail.LotNumber_F__c.endsWith('_'))) {
            productStockInfoList = productToStockInfoWithDateMap.get(orderDetail.LotNumber_F__c);
        } else {
            productStockInfoList = productToStockInfoMap.get(orderDetail.ProductMaster__c);
        }

        // 在庫情報がない場合
        if (productStockInfoList != null && productStockInfoList.size() > 0) {
            // 在庫情報
            // for (OrderHeaderTriggerHandler.StockInfo productStockInfo : productStockInfoList) {
            // 最初の在庫情報のみをチェックする
            OrderHeaderTriggerHandler.StockInfo productStockInfo = productStockInfoList[0];
            // 在庫情報の「残りの引き当て可能数」は注文明細の「数量」より大きい
            if (orderDetail.Quantity__c <= productStockInfo.allocableQuantity) {
                pickingListTemp.ProductStockInfo__c = productStockInfo.Id;
                pickingListTemp.ProductMaster__c = orderDetail.ProductMaster__c;
                pickingListTemp.Quantity__c = orderDetail.Quantity__c;
                // 在庫情報の「残りの引き当て可能数」を修正
                productStockInfo.allocableQuantity = productStockInfo.allocableQuantity - orderDetail.Quantity__c;
                // break;
            }
            // }
        }
        pickingListForInsertList.add(pickingListTemp);
    }

    // 手動更新実行時、手動更新メモを一括処理ログに残し、項目をリセット。
    private void insertManualUpdateLog() {
        List<BulkProcessLog__c> bulkProcessList = new List<BulkProcessLog__c>();

        for (OrderHeader__c orderHeaderNew : this.newList) {
            if (orderHeaderNew.ManualUpdateDatetime__c != this.oldMap.get(orderHeaderNew.Id).ManualUpdateDatetime__c) {
                BulkProcessLog__c bulkProcess = new BulkProcessLog__c();
                bulkProcess.ProcessSubject__c = '注文レコードの手動更新';
                bulkProcess.ProcessStatus__c = 'Success';
                bulkProcess.ProcessType__c = 'RecordManualUpdate';
                bulkProcess.OrderHeader__c = orderHeaderNew.Id;
                bulkProcess.ProcessDetails__c = '手動更新メモ: ' + orderHeaderNew.ManualUpdateNote__c;

                // 手動更新メモを削除
                orderHeaderNew.ManualUpdateNote__c = null;

                bulkProcessList.add(bulkProcess);
            }
        }

        // 一括処理ログにinsert
        insert bulkProcessList;
    }

    // 注文の採番を設定するメソッド（作成の前）
    private void orderHeaderNaming() {
        if (Trigger.isInsert && Trigger.isBefore) {
            //　日の部分：YYMMDD
            Date today = Date.today();
            String datePartYear = String.valueOf(today.year()).right(2);
            String datePartMonth = String.valueOf(today.month()).leftPad(2, '0');
            String datePartDay = String.valueOf(today.day()).leftPad(2, '0');
            String datePart = datePartYear + datePartMonth + datePartDay;
            // 今日の最新の注文レコードを取得
            List<OrderHeader__c> lastestOrder = [
                SELECT Name
                FROM OrderHeader__c
                WHERE Name != NULL AND CreatedDate = TODAY
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            // 今日の最新レコードの採番。レコードがない場合、０になる。
            Decimal lastestNumber = 0;
            if (lastestOrder.size() > 0) {
                lastestNumber = Decimal.valueOf(lastestOrder[0].Name.right(5));
            }
            // 作成されたレコードの名前を設定：YYMMDD{00001}
            for (OrderHeader__c orderHeader : this.newList) {
                lastestNumber += 1;
                orderHeader.Name = datePart + String.valueOf(lastestNumber).leftpad(5, '0');
            }
        }
    }

    // 在庫情報の情報を持つデータクラス (DTO)
    private class StockInfo {
        // 在庫のID
        public Id Id;
        // 残りの引き当て可能数
        public Decimal allocableQuantity;
        // 商品マスタ_賞味期限
        public String productMasterExpirationDate;

        public StockInfo(Id Id, Decimal allocableQuantity, String productMasterExpirationDate) {
            this.Id = Id;
            this.allocableQuantity = allocableQuantity;
            this.productMasterExpirationDate = productMasterExpirationDate;
        }
    }
}