public inherited sharing class PickingListTriggerHandler extends CommonTriggerHandler {
    private Map<Id, PickingList__c> newMap;
    private Map<Id, PickingList__c> oldMap;
    private List<PickingList__c> newList;
    private List<PickingList__c> oldList;

    public PickingListTriggerHandler() {
        this.newMap = (Map<Id, PickingList__c>) Trigger.newMap;
        this.oldMap = (Map<Id, PickingList__c>) Trigger.oldMap;
        this.newList = (List<PickingList__c>) Trigger.new;
        this.oldList = (List<PickingList__c>) Trigger.old;
    }

    public override void afterInsert() {
        // 在庫情報へのRollup 引き当て済み数
        productStockInfoRollupAllocatedQuantity();
        // 在庫情報へのRollup 出庫済み数
        productStockInfoRollupShippedQuantity();
    }

    public override void afterUpdate() {
        // 在庫情報へのRollup 引き当て済み数
        productStockInfoRollupAllocatedQuantity();
        // 在庫情報へのRollup 出庫済み数
        productStockInfoRollupShippedQuantity();
        // 注文の「Firstピッキングの倉庫」を更新する
        updateOrderHeaderFirstWarehouse();
    }

    public override void afterDelete() {
        // 在庫情報へのRollup 引き当て済み数
        productStockInfoRollupAllocatedQuantity();
        // 在庫情報へのRollup 出庫済み数
        productStockInfoRollupShippedQuantity();
        // 注文の「Firstピッキングの倉庫」を更新する
        updateOrderHeaderFirstWarehouse();
    }

    public override void afterUnDelete() {
        // 在庫情報へのRollup 引き当て済み数
        productStockInfoRollupAllocatedQuantity();
        // 在庫情報へのRollup 出庫済み数
        productStockInfoRollupShippedQuantity();
    }

    /******************** 以下はTriggerのビジネスロジック ********************/
    // PickingList__c.Quantity__c を在庫情報に積み上げ
    private void productStockInfoRollupAllocatedQuantity() {
        // 在庫情報の一覧
        Set<Id> parentIdSet = new Set<Id>();
        List<Id> parentIdList = new List<Id>();
        String triggerOperation = '';
        Map<Id, List<PickingList__c>> stockInfoIdPickingListsMap = new Map<Id, List<PickingList__c>>();
        if ((Trigger.IsInsert || Trigger.IsUnDelete) && Trigger.isAfter) {
            for (PickingList__c nObj : newList) {
                // oldMap の値確認しない（できない）
                if (nObj.Quantity__c != null && nObj.Quantity__c != 0) {
                    if (stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c) == null) {
                        stockInfoIdPickingListsMap.put(nObj.ProductStockInfo__c, new List<PickingList__c>());
                    }
                    stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c).add(nObj);
                    if (nObj.ProductStockInfo__c != null && !parentIdSet.contains(nObj.ProductStockInfo__c)) {
                        parentIdSet.add(nObj.ProductStockInfo__c);
                        parentIdList.add(nObj.ProductStockInfo__c);
                    }
                }
            }
            if (Trigger.IsInsert) {
                triggerOperation = '' + System.TriggerOperation.AFTER_INSERT;
            } else {
                triggerOperation = '' + System.TriggerOperation.AFTER_UNDELETE;
            }
        } else if ((Trigger.isDelete) && Trigger.isAfter) {
            for (PickingList__c oldObj : oldList) {
                if (oldObj.Quantity__c != null && oldObj.Quantity__c != 0) {
                    if (oldObj.ProductStockInfo__c != null && !parentIdSet.contains(oldObj.ProductStockInfo__c)) {
                        parentIdSet.add(oldObj.ProductStockInfo__c);
                        parentIdList.add(oldObj.ProductStockInfo__c);
                    }
                }
            }
            triggerOperation = '' + System.TriggerOperation.AFTER_DELETE;
        } else if (Trigger.isUpdate && Trigger.isAfter) {
            for (PickingList__c nObj : newList) {
                PickingList__c oldObj = oldMap.get(nObj.Id);

                if (stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c) == null) {
                    stockInfoIdPickingListsMap.put(nObj.ProductStockInfo__c, new List<PickingList__c>());
                }
                if (stockInfoIdPickingListsMap.get(oldObj.ProductStockInfo__c) == null) {
                    stockInfoIdPickingListsMap.put(oldObj.ProductStockInfo__c, new List<PickingList__c>());
                }

                // 在庫情報の変更
                if (oldObj.ProductStockInfo__c != nObj.ProductStockInfo__c) {
                    stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c).add(nObj);
                    if (nObj.ProductStockInfo__c != null) {
                        stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c).add(nObj);
                        if (!parentIdSet.contains(nObj.ProductStockInfo__c)) {
                            if (nObj.Quantity__c != null && nObj.Quantity__c != 0) {
                                parentIdSet.add(nObj.ProductStockInfo__c);
                                parentIdList.add(nObj.ProductStockInfo__c);
                            }
                        }
                    }
                    if (oldObj.ProductStockInfo__c != null) {
                        stockInfoIdPickingListsMap.get(oldObj.ProductStockInfo__c).add(nObj);
                        if (!parentIdSet.contains(oldObj.ProductStockInfo__c)) {
                            if (oldObj.Quantity__c != null && oldObj.Quantity__c != 0) {
                                parentIdSet.add(oldObj.ProductStockInfo__c);
                                parentIdList.add(oldObj.ProductStockInfo__c);
                            }
                        }
                    }
                }
                if (oldObj.Quantity__c != nObj.Quantity__c) {
                    // 数量の変更
                    if (nObj.ProductStockInfo__c != null) {
                        stockInfoIdPickingListsMap.get(nObj.ProductStockInfo__c).add(nObj);
                        if (!parentIdSet.contains(nObj.ProductStockInfo__c)) {
                            parentIdSet.add(nObj.ProductStockInfo__c);
                            parentIdList.add(nObj.ProductStockInfo__c);
                        }
                    }
                }
            }
            triggerOperation = '' + System.TriggerOperation.AFTER_UPDATE;
        }
        // 在庫情報IDとエラーメッセージのマップ
        Map<Id, String> stockInfoIdErrorMessageMap = new Map<Id, String>();
        if (!parentIdList.isEmpty()) {
            stockInfoIdErrorMessageMap = productStockInfoRollupAllocatedQuantity(parentIdList, '' + triggerOperation);
        }
        if (!stockInfoIdErrorMessageMap.keySet().isEmpty()) {
            for (Id stockInfoId : stockInfoIdErrorMessageMap.keySet()) {
                List<PickingList__c> errorPickingList = stockInfoIdPickingListsMap.get(stockInfoId);
                if (errorPickingList != null && !errorPickingList.isEmpty()) {
                    for (PickingList__c pickingList : errorPickingList) {
                        pickingList.addError(stockInfoIdErrorMessageMap.get(stockInfoId));
                    }
                }
            }
        }
    }

    // できるだけ、@futureつけない、付けない場合、エラー内容すぐ画面に表示できます
    // PickingList__c.Quantity__c を ProductStockInfo__c.AllocatedQuantity__c に積み上げ
    private static Map<Id, String> productStockInfoRollupAllocatedQuantity(List<Id> parentIdList, String triggerOperation) {
        Map<Id, ProductStockInfo__c> updateMap = new Map<Id, ProductStockInfo__c>();
        Map<Id, ProductStockInfo__c> arMap = new Map<Id, ProductStockInfo__c>();

        Savepoint sp = Database.setSavepoint(); // ２回の soql を同じトランザクションにするため

        Map<Id, Decimal> productStockInfoIdToAllocatedMap = new Map<Id, Decimal>();
        List<ProductStockInfo__c> productStockInfoList = [
            SELECT Id, AllocatedQuantity__c
            FROM ProductStockInfo__c
            WHERE Id IN :parentIdList
            ORDER BY ArrivalDate__c
        ];

        for (ProductStockInfo__c psi : productStockInfoList) {
            productStockInfoIdToAllocatedMap.put(psi.Id, psi.AllocatedQuantity__c);
        }

        // 積み上げ条件 設定して、集計 soqlを発行、TODO 子が50000件以上の場合、エラーになります。
        AggregateResult[] groupbyResults = [
            SELECT ProductStockInfo__c, SUM(Quantity__c) newAggr
            FROM PickingList__c
            WHERE ProductStockInfo__c IN :parentIdList
            GROUP BY ProductStockInfo__c
        ];

        // 集計値の計算
        for (AggregateResult ar : groupbyResults) {
            ProductStockInfo__c pObj = new ProductStockInfo__c();
            pObj.Id = String.ValueOf(ar.get('ProductStockInfo__c'));
            pObj.AllocatedQuantity__c = ar.get('newAggr') != null ? (Decimal) ar.get('newAggr') : 0;
            // 集計値変わった場合、更新対象に
            if (productStockInfoIdToAllocatedMap.get(pObj.Id) != pObj.AllocatedQuantity__c) {
                updateMap.put(pObj.Id, pObj);
            }
            arMap.put(pObj.Id, pObj);
        }
        for (Id pObjId : parentIdList) {
            // arMapにない場合 つまり、子がない場合
            // 集計全部初期化になる
            if (false == arMap.containsKey(pObjId)) {
                ProductStockInfo__c pObj = new ProductStockInfo__c(Id = pObjId);
                pObj.AllocatedQuantity__c = 0;
                // TODO ほかの初期化すべき項目あれば
                updateMap.put(pObj.Id, pObj);
            }
        }

        Map<Id, String> stockInfoIdErrorMessageMap = new Map<Id, String>();
        // 在庫情報の「引き当て済数」の更新
        if (false == updateMap.isEmpty()) {
            List<ProductStockInfo__c> updateList = updateMap.values();
            // optAllOrNone = false エラーは手動ハンドリング
            Database.SaveResult[] saveResultList = Database.update(updateList, false);
            for (Integer i = 0; i < updateList.size(); i++) {
                if (!saveResultList[i].isSuccess()) {
                    // エラー集合
                    String errorMessage = '';
                    for (Database.Error err : saveResultList[i].getErrors()) {
                        errorMessage += err.getMessage() + '\n';
                    }
                    stockInfoIdErrorMessageMap.put(updateList[i].Id, errorMessage);
                }
            }
        }
        return stockInfoIdErrorMessageMap;
    }

    // ピッキングリストの在庫情報が変更される場合 とピッキングリストが削除される場合、と注文の「Firstピッキングの倉庫」を更新する
    private void updateOrderHeaderFirstWarehouse() {
        List<OrderHeader__c> updateList = new List<OrderHeader__c>();
        List<Id> orderHeaderIdList = new List<Id>();
        String triggerOperation = '';

        // 変更したピッキングリストと削除したピッキングリストの注文ID一覧を作る
        if (Trigger.isUpdate && Trigger.isAfter) {
            for (PickingList__c nObj : newList) {
                PickingList__c oldObj = oldMap.get(nObj.Id);
                // 在庫情報の変更
                if (
                    oldObj.ProductStockInfo__c != nObj.ProductStockInfo__c &&
                    !orderHeaderIdList.contains(nObj.OrderHeader__c)
                ) {
                    orderHeaderIdList.add(nObj.OrderHeader__c);
                }
            }
            triggerOperation = '' + System.TriggerOperation.AFTER_UPDATE;
        } else if (Trigger.isDelete && Trigger.isAfter) {
            for (PickingList__c oldObj : oldList) {
                if (!orderHeaderIdList.contains(oldObj.OrderHeader__c)) {
                    orderHeaderIdList.add(oldObj.OrderHeader__c);
                }
            }
            triggerOperation = '' + System.TriggerOperation.AFTER_DELETE;
        }

        // 注文のID一覧から、１枝番のFirstピッキングリストを取得
        List<OrderDetail__c> orderDetailList = [
            SELECT
                Id,
                OrderHeader__c,
                OrderHeader__r.FirstWarehouseMaster__c,
                SequenceNumber__c,
                (
                    SELECT Id, ProductStockInfo__c, ProductStockInfo__r.WarehouseMaster__c
                    FROM PickingList__r
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                )
            FROM OrderDetail__c
            WHERE SequenceNumber__c = 1 AND OrderHeader__c IN :orderHeaderIdList
        ];

        List<Id> pickingUpdateList = new List<Id>();
        for (OrderDetail__c orderDetail : orderDetailList) {
            if (orderDetail.PickingList__r.size() > 0) {
                if (orderDetail.PickingList__r[0].ProductStockInfo__r.WarehouseMaster__c != null) {
                    updateList.add(
                        new OrderHeader__c(
                            Id = orderDetail.OrderHeader__c,
                            FirstWarehouseMaster__c = orderDetail.PickingList__r[0].ProductStockInfo__r.WarehouseMaster__c
                        )
                    );
                    pickingUpdateList.add(orderDetail.PickingList__r[0].Id);
                }
            }
        }

        // 注文の更新
        if (false == updateList.isEmpty()) {
            // optAllOrNone = false エラーは手動ハンドリング
            Database.SaveResult[] saveResultList = Database.update(updateList, false);
            for (Integer i = 0; i < updateList.size(); i++) {
                if (!saveResultList[i].isSuccess()) {
                    // エラー集合
                    String errorMessage = '';
                    for (Database.Error err : saveResultList[i].getErrors()) {
                        errorMessage += err.getMessage() + '\n';
                    }
                    PickingList__c errorPickingList = this.newMap.get(pickingUpdateList[i]);
                    if (errorPickingList != null) {
                        errorPickingList.addError(errorMessage);
                    }
                }
            }
        }
    }

    // PickingList__c.ShippedQuantity__c を在庫情報に積み上げ
    private void productStockInfoRollupShippedQuantity() {
        // 在庫情報IDとピッキングリストレコードの一覧 のマップ
        Map<Id, List<PickingList__c>> stockInfoIdPickingListsMap = new Map<Id, List<PickingList__c>>();
        // 変更された出庫済みピッキングリストレコードの一覧
        List<Id> productStockInfoIdList = new List<Id>();
        // 新規作成、または復元の場合
        if (Trigger.isInsert || Trigger.IsUnDelete) {
            for (PickingList__c pl : this.newList) {
                if (!productStockInfoIdList.contains(pl.ProductStockInfo__c) && pl.Shipped__c) {
                    productStockInfoIdList.add(pl.ProductStockInfo__c);
                    if (stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c) == null) {
                        stockInfoIdPickingListsMap.put(pl.ProductStockInfo__c, new List<PickingList__c>());
                    }
                    stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c).add(pl);
                }
            }
        }
        // 削除の場合
        else if (Trigger.isDelete) {
            for (PickingList__c pl : this.oldList) {
                if (
                    !productStockInfoIdList.contains(this.oldMap.get(pl.Id).ProductStockInfo__c) &&
                    this.oldMap.get(pl.Id).Shipped__c
                ) {
                    productStockInfoIdList.add(this.oldMap.get(pl.Id).ProductStockInfo__c);
                }
            }
        }
        // 更新の場合
        else if (Trigger.isUpdate) {
            for (PickingList__c pl : this.newList) {
                // ピッキングリストレコードの在庫情報が変更された場合
                if (pl.ProductStockInfo__c != this.oldMap.get(pl.Id).ProductStockInfo__c) {
                    if (
                        pl.Shipped__c &&
                        pl.ProductStockInfo__c != null &&
                        !productStockInfoIdList.contains(pl.ProductStockInfo__c)
                    ) {
                        productStockInfoIdList.add(pl.ProductStockInfo__c);
                        if (stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c) == null) {
                            stockInfoIdPickingListsMap.put(pl.ProductStockInfo__c, new List<PickingList__c>());
                        }
                        stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c).add(pl);
                    }
                    if (
                        this.oldMap.get(pl.Id).Shipped__c &&
                        this.oldMap.get(pl.Id).ProductStockInfo__c != null &&
                        !productStockInfoIdList.contains(this.oldMap.get(pl.Id).ProductStockInfo__c)
                    ) {
                        productStockInfoIdList.add(this.oldMap.get(pl.Id).ProductStockInfo__c);
                        if (stockInfoIdPickingListsMap.get(this.oldMap.get(pl.Id).ProductStockInfo__c) == null) {
                            stockInfoIdPickingListsMap.put(
                                this.oldMap.get(pl.Id).ProductStockInfo__c,
                                new List<PickingList__c>()
                            );
                        }
                        stockInfoIdPickingListsMap.get(this.oldMap.get(pl.Id).ProductStockInfo__c).add(pl);
                    }
                }
                if (pl.ProductStockInfo__c != null && !productStockInfoIdList.contains(pl.ProductStockInfo__c)) {
                    // ピッキングリストレコードが出庫済み
                    if (pl.Shipped__c) {
                        // 数量が変更された場合
                        if (pl.Quantity__c != this.oldMap.get(pl.Id).Quantity__c) {
                            productStockInfoIdList.add(pl.ProductStockInfo__c);
                            if (stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c) == null) {
                                stockInfoIdPickingListsMap.put(pl.ProductStockInfo__c, new List<PickingList__c>());
                            }
                            stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c).add(pl);
                        }
                    }
                    // 出庫済みの状態が変更された場合
                    else if (pl.Shipped__c != this.oldMap.get(pl.Id).Shipped__c) {
                        productStockInfoIdList.add(pl.ProductStockInfo__c);
                        if (stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c) == null) {
                            stockInfoIdPickingListsMap.put(pl.ProductStockInfo__c, new List<PickingList__c>());
                        }
                        stockInfoIdPickingListsMap.get(pl.ProductStockInfo__c).add(pl);
                    }
                }
            }
        }

        // 更新用のピッキングリスト一覧が空の場合、処理しない
        if (productStockInfoIdList.isEmpty())
            return;

        // 積み上げ条件 設定して、集計 soqlを発行、TODO 子が50000件以上の場合、エラーになります。
        AggregateResult[] groupbyResults = [
            SELECT ProductStockInfo__c, SUM(Quantity__c) newAggr
            FROM PickingList__c
            WHERE ProductStockInfo__c IN :productStockInfoIdList AND Shipped__c = TRUE
            GROUP BY ProductStockInfo__c
        ];

        Map<Id, ProductStockInfo__c> updateMap = new Map<Id, ProductStockInfo__c>();
        Map<Id, ProductStockInfo__c> arMap = new Map<Id, ProductStockInfo__c>();
        // Map<Id, Decimal> productStockInfoIdToAllocatedMap = new Map<Id, Decimal>();
        // 集計値の計算
        for (AggregateResult ar : groupbyResults) {
            ProductStockInfo__c pObj = new ProductStockInfo__c();
            pObj.Id = String.ValueOf(ar.get('ProductStockInfo__c'));
            pObj.ShippedQuantity__c = ar.get('newAggr') != null ? (Decimal) ar.get('newAggr') : 0;
            updateMap.put(pObj.Id, pObj);
            arMap.put(pObj.Id, pObj);
        }
        for (Id pObjId : productStockInfoIdList) {
            // arMapにない場合 つまり、子がない場合
            // 集計全部初期化になる
            if (false == arMap.containsKey(pObjId)) {
                ProductStockInfo__c pObj = new ProductStockInfo__c(Id = pObjId);
                pObj.ShippedQuantity__c = 0;
                // TODO ほかの初期化すべき項目あれば
                updateMap.put(pObj.Id, pObj);
            }
        }

        Map<Id, String> stockInfoIdErrorMessageMap = new Map<Id, String>();
        // 在庫情報の「出庫済み数」の更新
        if (false == updateMap.isEmpty()) {
            List<ProductStockInfo__c> updateList = updateMap.values();
            // optAllOrNone = false エラーは手動ハンドリング
            Database.SaveResult[] saveResultList = Database.update(updateList, false);
            for (Integer i = 0; i < updateList.size(); i++) {
                if (!saveResultList[i].isSuccess()) {
                    // エラー集合
                    String errorMessage = '';
                    for (Database.Error err : saveResultList[i].getErrors()) {
                        errorMessage += err.getMessage() + '\n';
                    }
                    stockInfoIdErrorMessageMap.put(updateList[i].Id, errorMessage);
                }
            }
        }

        // エラー出す処理
        if (!stockInfoIdErrorMessageMap.keySet().isEmpty()) {
            for (Id stockInfoId : stockInfoIdErrorMessageMap.keySet()) {
                List<PickingList__c> errorPickingList = stockInfoIdPickingListsMap.get(stockInfoId);
                if (errorPickingList != null && !errorPickingList.isEmpty()) {
                    for (PickingList__c pickingList : errorPickingList) {
                        pickingList.addError(stockInfoIdErrorMessageMap.get(stockInfoId));
                    }
                }
            }
        }
    }
}