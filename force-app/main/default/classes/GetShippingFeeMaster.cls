public with sharing class GetShippingFeeMaster {
    @InvocableMethod(label='運賃自動計算' description='当てはまる運賃を探す')
    public static List<ShippingFee__c> calculateShippingFee(List<OrderHeader__c> orderHeaders) {
        // System.debug(orderHeaders.size());
        List<ShippingFee__c> shippingFeeList = new List<ShippingFee__c>();
        // try{
        Set<Id> originPlaceIds = new Set<Id>();
        Set<Id> destinationPlaceIds = new Set<Id>();

        for (OrderHeader__c order : orderHeaders) {
            if (!String.isBlank(order.OriginPlace__c)) {
                originPlaceIds.add(order.OriginPlace__c);
            }
            if (!String.isBlank(order.Destination__c)) {
                destinationPlaceIds.add(order.Destination__c);
            }
        }

        // トリガーレコードに参照関係の発着地のデータを取得して、こちらのListにセットする
        List<OrderHeader__c> orderHeaderList = getOriginDestinationInfo(orderHeaders, originPlaceIds, destinationPlaceIds);
        List<OrderHeader__c> updateorderHeaderList = new List<OrderHeader__c>();
        for (OrderHeader__c orderHeader : orderHeaderList) {
            if (String.isNotBlank(orderHeader.Destination__c)) {
                // フローから呼び出すため、レコードが１つだけの予定で、ForループにSOQLを書いても大丈夫
                ShippingFee__c tempShippingFee = calculateFee(orderHeader);
                // System.debug('tempShippingFee: ' + tempShippingFee);
                // 注文の「配送会社」= ( 運賃.「特別下請け業者１」OR 運賃.「特別下請け業者２」OR 運賃.「特別下請け業者３」 )の場合
                if (
                    orderHeader.ShippingCompany__c != null &&
                    tempShippingFee.PriceTable__r.SubcontractorReductionFee__c != null &&
                    (orderHeader.ShippingCompany__c == tempShippingFee.PriceTable__r.Subcontractor1__c ||
                    orderHeader.ShippingCompany__c == tempShippingFee.PriceTable__r.Subcontractor2__c ||
                    orderHeader.ShippingCompany__c == tempShippingFee.PriceTable__r.Subcontractor3__c)
                ) {
                    // System.debug(tempShippingFee);
                    // Todo BeanClassを使用してほしい。
                    // ShippingFeeMaster.「運賃」-ShippingFeeMaster.価格管理.「特別運賃差額」
                    tempShippingFee.SubcontractFee__c =
                        tempShippingFee.ShippingFee__c - tempShippingFee.PriceTable__r.SubcontractorReductionFee__c;
                }
                OrderHeader__c oh2 = new OrderHeader__c();
                oh2.Id = orderHeader.Id;
                if (String.isNotBlank(tempShippingFee.Id)) {
                    oh2.AncillaryWorkFee__c = tempShippingFee.AncillaryWorkFee__c;
                    oh2.ShippingFee__c = tempShippingFee.Id;
                    oh2.SubcontractFee__c = tempShippingFee.SubcontractFee__c;

                    oh2.CargoInsuranceCost__c = tempShippingFee.CargoInsuranceCost__c;
                    oh2.ShippingFeeCalComment__c = tempShippingFee.PriceTable__r.Name;
                    if (tempShippingFee.FixedFeeFlag__c) {
                        oh2.Amount__c = tempShippingFee.ShippingFee__c;
                        oh2.UnitPrice__c = null;
                        oh2.ShippingFeeCalComment__c += '一律料金';
                    } else {
                        oh2.UnitPrice__c = tempShippingFee.ShippingFee__c == null ? 0 : tempShippingFee.ShippingFee__c;
                        oh2.Amount__c =
                            oh2.UnitPrice__c *
                            (orderHeader.QuantityForShippingFeeCal__c == null
                                ? 1
                                : orderHeader.QuantityForShippingFeeCal__c);
                        oh2.ShippingFeeCalComment__c += '単価 ';
                    }
                    oh2.ShippingFeeCalComment__c += String.isBlank(tempShippingFee.Memo__c) ? '' : tempShippingFee.Memo__c;
                } else {
                    oh2.Id = orderHeader.Id;
                    oh2.Amount__c = null;
                    oh2.ShippingFeeCalComment__c = '運賃が見つかりません';
                    oh2.ShippingFee__c = null;
                    oh2.UnitPrice__c = null;
                }

                updateorderHeaderList.add(oh2);
                shippingFeeList.add(tempShippingFee);
            } else {
                OrderHeader__c oh2 = new OrderHeader__c();
                oh2.Id = orderHeader.Id;
                oh2.Amount__c = null;
                oh2.ShippingFeeCalComment__c = '運賃が見つかりません';
                oh2.ShippingFee__c = null;
                oh2.UnitPrice__c = null;
                updateorderHeaderList.add(oh2);
            }
        }
        if (updateorderHeaderList.size() > 0) {
            update updateorderHeaderList;
        }
        // }
        // catch(Exception e) {
        //     System.debug(e.getMessage() + e.getStackTraceString());
        // }
        // System.debug(shippingFeeList);
        return shippingFeeList;
    }

    // 運賃の発着地情報取得
    public static List<OrderHeader__c> getOriginDestinationInfo(
        List<OrderHeader__c> orderHeaders,
        Set<Id> originPlaceIds,
        Set<Id> destinationPlaceIds
    ) {
        // 参照関係にある発地・着地の情報を取得
        Map<Id, OriginDestination__c> originPlaceMap = new Map<Id, OriginDestination__c>();
        Map<Id, OriginDestination__c> destinationPlaceMap = new Map<Id, OriginDestination__c>();

        // トリガーレコードに参照関係の発着地のデータを取得して、こちらのListにセットする
        List<OrderHeader__c> orderHeaderList = new List<OrderHeader__c>();

        if (!originPlaceIds.isEmpty()) {
            for (OriginDestination__c origin : [
                SELECT Id, Prefecture__c, City__c, Street__c
                FROM OriginDestination__c
                WHERE Id IN :originPlaceIds
                WITH SECURITY_ENFORCED
            ]) {
                originPlaceMap.put(origin.Id, origin);
            }
        }

        if (!destinationPlaceIds.isEmpty()) {
            for (OriginDestination__c destination : [
                SELECT Id, Prefecture__c, City__c, Street__c
                FROM OriginDestination__c
                WHERE Id IN :destinationPlaceIds
                WITH SECURITY_ENFORCED
            ]) {
                destinationPlaceMap.put(destination.Id, destination);
            }
        }

        // 取得した情報を orderHeaders にセット
        for (OrderHeader__c order : orderHeaders) {
            OrderHeader__c orderHeaderTemp = new OrderHeader__c();
            orderHeaderTemp = order.clone();
            orderHeaderTemp.Id = order.Id; // IDを設定
            orderHeaderTemp.UnitPrice__c = null;
            orderHeaderTemp.Amount__c = null;
            orderHeaderTemp.ShippingFee__c = null;
            if (originPlaceMap.containsKey(order.OriginPlace__c)) {
                OriginDestination__c origin = originPlaceMap.get(order.OriginPlace__c);
                orderHeaderTemp.OriginPlace__r = new OriginDestination__c(
                    Prefecture__c = origin.Prefecture__c,
                    City__c = origin.City__c,
                    Street__c = origin.Street__c
                );
            }

            if (destinationPlaceMap.containsKey(order.Destination__c)) {
                OriginDestination__c destination = destinationPlaceMap.get(order.Destination__c);
                orderHeaderTemp.Destination__r = new OriginDestination__c(
                    Prefecture__c = destination.Prefecture__c,
                    City__c = destination.City__c,
                    Street__c = destination.Street__c
                );
            }
            orderHeaderList.add(orderHeaderTemp);
        }

        return orderHeaderList;
    }

    // 運賃マスタを探すロジック
    public static ShippingFee__c calculateFee(OrderHeader__c orderHeader) {
        List<ShippingFee__c> shippingFeeList = new List<ShippingFee__c>();
        Set<String> allType = new Set<String>{ 'Charter', 'Small', 'AccountTransfer', 'Route', 'Material', 'Line' };
        Set<String> notElseType = new Set<String>{ 'Small', 'AccountTransfer', 'Route' };

        // 輸送形態Fの決定
        String shiptype = '';
        if (!String.isBlank(orderHeader.TransportationMode__c)) {
            if (allType.contains(orderHeader.TransportationMode__c)) {
                if (notElseType.contains(orderHeader.TransportationMode__c)) {
                    shiptype = orderHeader.TransportationMode__c;
                } else {
                    shiptype = 'Charter';
                }
            }
        }
        String orderHeaderOriginPrefecture = String.isBlank(orderHeader.OriginPlace__c)
            ? '19'
            : orderHeader.OriginPlace__r.Prefecture__c;
        String orderHeaderDestinationPrefecture = String.isBlank(orderHeader.Destination__c)
            ? '19'
            : orderHeader.Destination__r.Prefecture__c;

        // 着地IDがマッピングできる場合

        // パターン１注文に着地、発地ともにある場合
        // パターン２注文に着地、発地片方だけある場合]
        String soqlbase =
            'SELECT Id' +
            ' , ShippingFee__c' +
            '  , SubcontractFee__c' +
            '  , CargoInsuranceCost__c' +
            '  , FixedFeeFlag__c' +
            '  , AncillaryWorkFee__c' +
            '  , Memo__c ' +
            '  , PriceTable__r.Name' +
            '  , PriceTable__r.SubcontractorReductionFee__c' +
            '  , PriceTable__r.Subcontractor1__c' +
            '  , PriceTable__r.Subcontractor2__c' +
            '  , PriceTable__r.Subcontractor3__c' +
            '  FROM ShippingFee__c WHERE Active_F__c = true' +
            '  AND CarryOutDate_F__c <=: ReceptionDate';
        String soqlmid =
            '  AND (Destination__c =: Destination AND ' +
            (String.isBlank(orderHeader.OriginPlace__c)
                ? 'OriginPrefecture__c = \'19\''
                : ' OriginPrefecture__c =:OriginPrefecture') +
            ')';
        // +'  AND ((Destination__c =: Destination AND ' + (String.isBlank(orderHeader.OriginPlace__c) ? 'OriginPrefecture__c = \'19\'' : ' OriginPlace__c =:Origin')
        // +')  OR (OriginPlace__c =: Destination AND ' + (String.isBlank(orderHeader.OriginPlace__c) ? 'Destination__r.Prefecture__c = \'19\'' : ' Destination__c =:Origin')
        // +' ))';
        String soqlend =
            +' AND MinQuantity__c < : QuantityForShippingFeeCal' +
            ' AND (MaxQuantity__c = null OR MaxQuantity__c >=: QuantityForShippingFeeCal)' +
            ' AND Unit__c =: UnitForShippingFeeCal' +
            ' AND (Account__c =: Account OR Account__c = null)' +
            // ' AND PriceTable__r.PriceTableType__c =: shiptype' +
            // ' WITH SECURITY_ENFORCED' +
            ' Order by Account__c NULLS LAST';
        Date receptionDate = null;
        if (orderHeader.ReceptionDatetime__c != null) {
            receptionDate = orderHeader.ReceptionDatetime__c.date();
        }
        Map<String, Object> bindVariablesx = new Map<String, Object>{
            'ReceptionDate' => receptionDate,
            'Destination' => orderHeader.Destination__c,
            'Origin' => orderHeader.OriginPlace__c,
            'OriginPrefecture' => orderHeader.OriginPlace__r.Prefecture__c,
            'DestinationPrefecture' => orderHeader.Destination__r.Prefecture__c,
            'QuantityForShippingFeeCal' => orderHeader.QuantityForShippingFeeCal__c,
            'UnitForShippingFeeCal' => orderHeader.UnitForShippingFeeCal__c,
            'Account' => orderHeader.Account__c,
            'shiptype' => shiptype
        };
        String soql = soqlbase + soqlmid + soqlend;
        shippingFeeList = Database.queryWithBinds(soql, bindVariablesx, AccessLevel.SYSTEM_MODE);
        // System.debug('shippingFeeList1: ' + shippingFeeList);
        if (shippingFeeList.size() == 0) {
            soqlmid =
                '  AND (Destination__r.Prefecture__c =: OriginPrefecture AND ' +
                (String.isBlank(orderHeader.OriginPlace__c)
                    ? 'OriginPrefecture__c = \'19\''
                    : ' OriginPrefecture__c =:DestinationPrefecture') +
                ')';
            soql = soqlbase + soqlmid + soqlend;
            shippingFeeList = Database.queryWithBinds(soql, bindVariablesx, AccessLevel.SYSTEM_MODE);
            // System.debug('shippingFeeList2: ' + shippingFeeList);
        }
        // shippingFeeList = [SELECT Id
        //     , ShippingFee__c
        //     , SubcontractFee__c
        //     , FixedFeeFlag__c
        //     , AncillaryWorkFee__c
        //     , Memo__c
        //     , PriceTable__r.Name
        //     , PriceTable__r.SubcontractorReductionFee__c
        //     , PriceTable__r.Subcontractor1__c
        //     , PriceTable__r.Subcontractor2__c
        //     , PriceTable__r.Subcontractor3__c
        //     FROM ShippingFee__c WHERE Active_F__c = true //数式の「有効」
        //     AND CarryOutDate_F__c <=: orderHeader.ReceptionDate__c //QA回答まで、運賃.「実施日」(適用日) <=  注文.「受付日」（積込日）
        //     AND (
        //         ( Destination__c =: orderHeader.Destination__c AND OriginPrefecture__c =: OriginPlace__c  )
        //         )
        //         // OR
        //         // ( Destination__c =: orderHeader.OriginPlace__c AND OriginPrefecture__c =: orderHeaderDestinationPrefecture  )
        //     AND MinQuantity__c <=: orderHeader.QuantityForShippingFeeCal__c
        //     AND (MaxQuantity__c = null OR MaxQuantity__c >=: orderHeader.QuantityForShippingFeeCal__c)
        //     AND Unit__c =: orderHeader.UnitForShippingFeeCal__c
        //     AND (Account__c =: orderHeader.Account__c OR Account__c = '')
        //     AND PriceTable__r.DeliveryType__c =: shiptype
        //     WITH SECURITY_ENFORCED
        //     Order by Account__c NULLS LAST
        // ];

        // 着地IDがマッピングできない場合
        if (shippingFeeList.size() == 0) {
            String likeCity = '%' + orderHeader.Destination__r.City__c + '%';
            String likeStreet = '%' + orderHeader.Destination__r.Street__c + '%';
            // バインド変数のマップを作成
            Map<String, Object> bindVariables = new Map<String, Object>{
                'ReceptionDate' => receptionDate,
                // 'Destination' => orderHeader.Destination__c,
                // 'Origin' => orderHeader.OriginPlace__c,
                'DestinationPrefecture' => orderHeader.Destination__r.Prefecture__c,
                'QuantityForShippingFeeCal' => orderHeader.QuantityForShippingFeeCal__c,
                'UnitForShippingFeeCal' => orderHeader.UnitForShippingFeeCal__c,
                'Account' => orderHeader.Account__c,
                'shiptype' => shiptype,
                'likeCity' => likeCity,
                'likeStreet' => likeStreet
            };
            if (!String.isBlank(orderHeader.OriginPlace__c)) {
                // 発地があれば
                bindVariables.put('OriginPrefecture', orderHeader.OriginPlace__r.Prefecture__c);
            }

            // SOQL を実行
            shippingFeeList = getShippingFees(orderHeader, bindVariables);
            // System.debug('shippingFeeList3: ' + shippingFeeList);

            // 結果がなく、かつ発地があれば、発地と着地を逆にして、再度検索
            if (shippingFeeList.size() == 0 && !String.isBlank(orderHeader.OriginPlace__c)) {
                likeCity = '%' + orderHeader.OriginPlace__r.City__c + '%';
                likeStreet = '%' + orderHeader.OriginPlace__r.Street__c + '%';
                // バインド変数のマップを作成
                bindVariables = new Map<String, Object>{
                    'ReceptionDate' => receptionDate,
                    // 'Destination' => orderHeader.Destination__c,
                    // 'Origin' => orderHeader.OriginPlace__c,
                    'OriginPrefecture' => orderHeader.Destination__r.Prefecture__c,
                    'DestinationPrefecture' => orderHeader.OriginPlace__r.Prefecture__c,
                    'QuantityForShippingFeeCal' => orderHeader.QuantityForShippingFeeCal__c,
                    'UnitForShippingFeeCal' => orderHeader.UnitForShippingFeeCal__c,
                    'Account' => orderHeader.Account__c,
                    'shiptype' => shiptype,
                    'likeCity' => likeCity,
                    'likeStreet' => likeStreet
                };
                // SOQL を実行
                shippingFeeList = getShippingFees(orderHeader, bindVariables);
                // System.debug('shippingFeeList4: ' + shippingFeeList);
            }
        }

        // 運賃見つからない:パターン７
        ShippingFee__c shippingFeeRecord = new ShippingFee__c();
        if (shippingFeeList.size() > 0) {
            // 荷主が存在するレコードを優先に
            shippingFeeRecord = shippingFeeList[0];
        }

        return shippingFeeRecord;
    }

    public static List<ShippingFee__c> getShippingFees(OrderHeader__c orderHeader, Map<String, Object> bindVariables) {
        String shiptype = String.isBlank(orderHeader.TransportationMode__c) ? 'Charter' : orderHeader.TransportationMode__c;

        List<ShippingFee__c> shippingFeeList = new List<ShippingFee__c>();

        String soqlQuery =
            'SELECT ' +
            '   Id ' +
            '   ,Memo__c  ' +
            '   ,ShippingFee__c ' +
            '   ,SubcontractFee__c ' +
            '  , CargoInsuranceCost__c' +
            '   ,FixedFeeFlag__c ' +
            '   ,AncillaryWorkFee__c ' +
            ', PriceTable__r.Name ' +
            ', PriceTable__r.SubcontractorReductionFee__c ' +
            ', PriceTable__r.Subcontractor1__c ' +
            ', PriceTable__r.Subcontractor2__c ' +
            ', PriceTable__r.Subcontractor3__c ' +
            'FROM ShippingFee__c ' +
            //数式の有効を参照すべき
            'WHERE Active_F__c = true ' +
            'AND CarryOutDate_F__c <= :ReceptionDate ' +
            'AND MinQuantity__c < :QuantityForShippingFeeCal ' +
            'AND (MaxQuantity__c = null OR MaxQuantity__c >= :QuantityForShippingFeeCal) ' +
            'AND Unit__c = :UnitForShippingFeeCal ' +
            'AND (Account__c = :Account OR Account__c = \'\') ' +
            'AND PriceTable__r.PriceTableType__c = :shiptype ';
        String soqlQueryEnd =
            // 'WITH SECURITY_ENFORCED ' +
            ' ORDER BY Account__c NULLS LAST ';
        if (
            //注文に着地、発地ともにある場合
            !String.isBlank(orderHeader.OriginPlace__c) && !String.isBlank(orderHeader.Destination__c)
        ) {
            // パターン３
            soqlQuery += 'AND OriginPrefecture__c = :OriginPrefecture ';
        }
        //着地の判断が必ず必要
        String soqlQueryTemp = soqlQuery;
        soqlQueryTemp +=
            ' AND ArrivalPrefecture__c = :DestinationPrefecture ' +
            'AND ArrivalCity__c LIKE :likeCity ' +
            +'AND ArrivalStreet__c LIKE :likeStreet ' +
            soqlQueryEnd;
        // SOQL を実行し、結果をリストに保存
        // パターン４
        shippingFeeList = Database.queryWithBinds(soqlQueryTemp, bindVariables, AccessLevel.SYSTEM_MODE);
        // System.debug('shippingFeeList5: ' + shippingFeeList);

        if (shippingFeeList.size() == 0) {
            soqlQueryTemp = soqlQuery;
            soqlQueryTemp +=
                'AND ArrivalPrefecture__c = :DestinationPrefecture ' +
                'AND ArrivalCity__c LIKE :likeCity ' +
                soqlQueryEnd;
            // SOQL を実行し、結果をリストに保存
            // パターン５
            shippingFeeList = Database.queryWithBinds(soqlQueryTemp, bindVariables, AccessLevel.SYSTEM_MODE);
            // System.debug('shippingFeeList6: ' + shippingFeeList);
        }
        if (shippingFeeList.size() == 0) {
            soqlQueryTemp = soqlQuery;
            soqlQueryTemp += 'AND ArrivalPrefecture__c = :DestinationPrefecture ' + soqlQueryEnd;
            // SOQL を実行し、結果をリストに保存
            // パターン６
            shippingFeeList = Database.queryWithBinds(soqlQueryTemp, bindVariables, AccessLevel.SYSTEM_MODE);
            // System.debug('shippingFeeList7: ' + shippingFeeList);
        }

        // SOQL を実行
        return shippingFeeList;
    }
}