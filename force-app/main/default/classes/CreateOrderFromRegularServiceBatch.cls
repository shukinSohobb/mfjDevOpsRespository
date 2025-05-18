/**
 * 定期便から注文と注文明細を作成バッチ
 * 前提：月曜日起動するバッチ、batchsize = 100
 * 例： 2024-01-01  (月曜日)
 * Date executeDate = Date.newInstance(2024, 1, 1);
 * CreateOrderFromRegularServiceBatch.executeBatch(executeDate);
 */
public with sharing class CreateOrderFromRegularServiceBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    // 処理時のエラーメッセージを変数で保存する
    public List<String> errorMessageList = new List<String>();
    // 総処理件数
    public Integer allCount = 0;
    // 処理済件数
    public Integer allCountDone = 0;
    // 処理時のエラーメッセージを保存する。
    public List<String> errorNaiyouList = new List<String>();
    // ログ
    BulkProcessLog__c processLog = new BulkProcessLog__c();
    // バッチ実行日
    public Date executeDate;
    // バッチジョブ処理分類
    public static final String BATCH_JOB_PROCESS_TYPE = 'CreateOrderFromRegularServiceBatch';
    @TestVisible
    public static Date today {
        get {
            return today == null ? System.today() : today;
        }
        set;
    }

    public CreateOrderFromRegularServiceBatch() {
    }

    // スケジュール起動
    public void execute(SchedulableContext sc) {
        executeBatch(today);
    }
    // batchsize = 100
    public static void executeBatch(Date executeDate) {
        CreateOrderFromRegularServiceBatch batch = new CreateOrderFromRegularServiceBatch();
        batch.executeDate = executeDate;

        // 月曜日ではない場合、exception
        Datetime dt = Datetime.newInstance(executeDate.year(), executeDate.month(), executeDate.day());
        if (((DateTime) executeDate).format('E') == 'Mon') {
            Database.executeBatch(batch, 1);
        } else {
            // 月曜日でない場合、エラーメッセージをリストに追加
            throw new CommonTriggerHandler.MyException('月曜日ではないので、バッチ実行ができない。');
        }
    }

    // バッチ start
    public Iterable<SObject> start(Database.BatchableContext bc) {
        // バッチ処理ログの開始
        // 処理ログ
        String log = BATCH_JOB_PROCESS_TYPE + ',' + ' Date={' + executeDate + '}, {' + datetime.now() + '}';
        // 処理内容
        String details = '定期便注文作成バッチ実行開始' + datetime.now();
        String subject = executeDate.format().replace('/', '') + ': 定期便注文作成バッチ実行開始';
        processLog = logBatchStatus(log, subject, details, 'Start', '');
        insert processLog;

        // 来週の月曜日から作成
        Date startDate = executeDate.addDays(7);
        // 来週の日曜日から作成
        Date endDate = executeDate.addDays(13);

        /**
         * 下記条件に一致する定期便情報レコードを取得
         */
        return Database.getQueryLocator(
            [
                SELECT
                    Id,
                    Name,
                    Account__c,
                    Account__r.Name,
                    TransportationMode__c,
                    VehicleNumber__c,
                    DriverMaster__c,
                    OriginPlace__c,
                    OriginPlace__r.Name,
                    DeliveryDate__c,
                    Destination__c,
                    Destination__r.Name,
                    QuantityForShippingFeeCal__c,
                    UnitForShippingFeeCal__c,
                    UnitPrice__c,
                    SubcontractFee__c,
                    Monday__c,
                    Tuesday__c,
                    Wednesday__c,
                    Thursday__c,
                    Friday__c,
                    Saturday__c,
                    Sunday__c,
                    ProductMaster__c,
                    ProductMaster__r.Name,
                    Quantity__c,
                    Unit__c,
                    DepartureTime__c,
                    Remarks1__c,
                    Remarks2__c,
                    RecurringEndDate__c,
                    RecurringStartDate__c,
                    Active_F__c,
                    Amount__c,
                    ShippingFeeManualFlag__c,
                    ShippingCompany__c,
                    AncillaryWorkFee__c,
                    InvoiceAccount__c,
                    PeriodKind__c,
                    Date__c,
                    Status__c,
                    Category__c,
                    ItemName__c
                FROM RegularServiceInformation__c
                WHERE RecurringStartDate__c <= :endDate AND RecurringEndDate__c >= :startDate AND Active_F__c = TRUE
            ]
        );
    }

    // バッチ execute, batchsize = 1の前提
    public void execute(Database.BatchableContext bc, List<RegularServiceInformation__c> rsiList) {
        if (rsiList.isEmpty()) {
            return;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            // 一番先頭に件数を集計する
            allCount += rsiList.size();

            // 来週の月曜日から作成
            Date startDate = executeDate.addDays(7);
            // 来週の日曜日から作成
            Date endDate = executeDate.addDays(13);

            // 来週の注文レコード
            List<OrderHeader__c> orderList = new List<OrderHeader__c>();
            for (RegularServiceInformation__c rsi : rsiList) {
                for (Date loadingDate = startDate; loadingDate <= endDate; loadingDate = loadingDate.addDays(1)) {
                    String weekday = ((DateTime) loadingDate).format('E');
                    if (
                        rsi.PeriodKind__c == 'Weekly' &&
                        ((rsi.Monday__c && 'Mon' == weekday) ||
                        (rsi.Tuesday__c && 'Tue' == weekday) ||
                        (rsi.Wednesday__c && 'Wed' == weekday) ||
                        (rsi.Thursday__c && 'Thu' == weekday) ||
                        (rsi.Friday__c && 'Fri' == weekday) ||
                        (rsi.Saturday__c && 'Sat' == weekday) ||
                        (rsi.Sunday__c && 'Sun' == weekday))
                    ) {
                        // 注文レコードを作成
                        orderList.add(createOrderHeaderFromReg(rsi, loadingDate));
                    }

                    if (rsi.PeriodKind__c == 'Monthly') {
                        Date exeDay;
                        if (rsi.Date__c == 'MonthEnd') {
                            exeDay = MfjUtil.getEndOfMonth(executeDate);
                        } else {
                            Integer year = endDate.year();
                            Integer month = endDate.month();
                            String day = rsi.Date__c;
                            String strExeDate = year + '-' + month + '-' + day;
                            exeDay = Date.valueOf(strExeDate);
                        }
                        if (loadingDate == exeDay) {
                            // 注文レコードを作成
                            orderList.add(createOrderHeaderFromReg(rsi, loadingDate));
                        }
                    }
                }
            }

            List<Database.SaveResult> saveResultList = new List<Database.SaveResult>();

            // DML オプションを作成し、重複ルール設定を行う
            Database.DMLOptions dml = new Database.DMLOptions(); 
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true;

            for (OrderHeader__c order : orderList) {
                // 個々のレコードに DML オプションを適用
                order.setOptions(dml);
                // 挿入時に DML オプションを個別に適用
                Database.SaveResult result = Database.insert(order, dml);
                saveResultList.add(result);
            }

            for (Integer i = 0; i < saveResultList.size(); i++) {
                Database.SaveResult sr = saveResultList[i];
                OrderHeader__c eObj = orderList[i];

                if (false == sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String errorMessage =
                            '定期便情報：' +
                            eObj.RegularServiceInformation__c +
                            'から注文を作成失敗します。' +
                            err;
                        errorMessageList.add(errorMessage);
                    }
                }
            }

            // ログの状態とメッセージを更新
            processLog.ProcessStatus__c = 'Processing'; // 処理状態
            // ログレコードを更新
            update processLog;

            // 来週の注文明細レコード
            if (errorMessageList.isEmpty()) {
                List<OrderDetail__c> orderDetailList = new List<OrderDetail__c>();
                Map<Id, String> ordDetToRegSerInfoMap = new Map<Id, String>();
                Integer idx = -1;
                for (RegularServiceInformation__c rsi : rsiList) {
                    for (Date loadingDate = startDate; loadingDate <= endDate; loadingDate = loadingDate.addDays(1)) {
                        String weekday = ((DateTime) loadingDate).format('E');
                        if (
                            rsi.ProductMaster__c != null &&
                            rsi.PeriodKind__c == 'Weekly' &&
                            ((rsi.Monday__c && 'Mon' == weekday) ||
                            (rsi.Tuesday__c && 'Tue' == weekday) ||
                            (rsi.Wednesday__c && 'Wed' == weekday) ||
                            (rsi.Thursday__c && 'Thu' == weekday) ||
                            (rsi.Friday__c && 'Fri' == weekday) ||
                            (rsi.Saturday__c && 'Sat' == weekday) ||
                            (rsi.Sunday__c && 'Sun' == weekday))
                        ) {
                            idx++;

                            // 注文明細レコードを作成
                            orderDetailList.add(
                                new OrderDetail__c(
                                    Account__c = rsi.Account__c, // 荷主
                                    SequenceNumber__c = 1, // 枝番
                                    OrderHeader__c = orderList[idx].Id, // 注文
                                    ProductMaster__c = rsi.ProductMaster__c, // 商品マスタ
                                    Quantity__c = rsi.Quantity__c, // 数量
                                    Unit__c = rsi.Unit__c // 単位
                                )
                            );
                            ordDetToRegSerInfoMap.put(orderList[idx].Id, rsi.Id);
                        }

                        if (rsi.ProductMaster__c != null && rsi.PeriodKind__c == 'Monthly') {
                            Date exeDay;
                            if (rsi.Date__c == 'MonthEnd') {
                                exeDay = MfjUtil.getEndOfMonth(executeDate);
                            } else {
                                Integer year = endDate.year();
                                Integer month = endDate.month();
                                String day = rsi.Date__c;
                                String strExeDate = year + '-' + month + '-' + day;
                                exeDay = Date.valueOf(strExeDate);
                            }
                            if (loadingDate == exeDay) {
                                idx++;

                                // 注文明細レコードを作成
                                orderDetailList.add(
                                    new OrderDetail__c(
                                        Account__c = rsi.Account__c, // 荷主
                                        SequenceNumber__c = 1, // 枝番
                                        OrderHeader__c = orderList[idx].Id, // 注文
                                        ProductMaster__c = rsi.ProductMaster__c, // 商品マスタ
                                        Quantity__c = rsi.Quantity__c, // 数量
                                        Unit__c = rsi.Unit__c // 単位
                                    )
                                );
                                ordDetToRegSerInfoMap.put(orderList[idx].Id, rsi.Id);
                            }
                        }
                    }
                }
                saveResultList = Database.insert(orderDetailList, false);

                for (Integer i = 0; i < saveResultList.size(); i++) {
                    Database.SaveResult sr = saveResultList[i];
                    OrderDetail__c eObj = orderDetailList[i];

                    if (false == sr.isSuccess()) {
                        for (Database.Error err : sr.getErrors()) {
                            String errorMessage =
                                '定期便情報：' +
                                OrdDetToRegSerInfoMap.get(eObj.OrderHeader__c) +
                                'から注文明細を作成失敗します。' +
                                err;
                            errorMessageList.add(errorMessage);
                        }
                    }
                }
            }

            allCountDone += rsiList.size();
        } catch (Exception e) {
            // throw e したら、処理途中のデータ、ログ　全部　rollback なるので、コメントアウト
            Database.rollback(sp);
            errorNaiyouList.add(e.getMessage());
        }
    }

    // バッチ finish
    public void finish(Database.BatchableContext bc) {
        if (0 == allCount) {
            return;
        }
        if (!errorNaiyouList.isEmpty()) {
            // 処理内容を整理する
            String errMessage = '';
            for (String msg : errorNaiyouList) {
                errMessage += msg + ';';
            }
            errMessage =
                '定期便注文作成バッチ実行完了' +
                datetime.now() +
                '<br /> 処理失敗<br />' +
                '対象処理件数: {' +
                allCount +
                '}<br />' +
                '処理できた件数: {' +
                allCountDone +
                '}<br />' +
                'エラーメッセージ: ' +
                errMessage;

            // ログの状態とメッセージを更新
            processLog.ProcessSubject__c = executeDate.format().replace('/', '') + ': 定期便注文作成バッチ実行失敗'; // 処理件名
            processLog.ProcessDetails__c = errMessage; // 処理内容
            processLog.ProcessLog__c = '処理失敗'; // 処理ログ
            processLog.ProcessStatus__c = 'Error'; // 処理状態
            processLog.ToEmailGroupAddresses__c = 'OrderGroup;SystemGroup'; // 送信先の課
            // ログレコードを更新
            update processLog;
            return;
        }
        // ログを記録する
        if (errorMessageList.isEmpty()) {
            // ログの状態を更新
            processLog.ProcessStatus__c = 'Success'; // 処理状態
            processLog.ProcessLog__c = '処理成功対象処理件数: {' + allCountDone + '}'; // 処理ログ
            // ログレコードを更新
            update processLog;
        } else {
            // 処理内容を整理する
            String errMessage = '';
            for (String msg : errorMessageList) {
                errMessage += msg + ';';
            }
            errMessage =
                '定期便注文作成バッチ実行完了' +
                datetime.now() +
                '<br /> 処理失敗<br />' +
                '対象処理件数: {' +
                allCount +
                '}<br />' +
                '処理できた件数: {' +
                allCountDone +
                '}<br />' +
                'エラーメッセージ: ' +
                errMessage;

            // ログの状態とメッセージを更新
            processLog.ProcessSubject__c = executeDate.format().replace('/', '') + ': 定期便注文作成バッチ実行失敗'; // 処理件名
            processLog.ProcessDetails__c = errMessage; // 処理内容
            processLog.ProcessLog__c = '処理失敗'; // 処理ログ
            processLog.ProcessStatus__c = 'Error'; // 処理状態
            processLog.ToEmailGroupAddresses__c = 'OrderGroup;SystemGroup'; // 送信先の課
            // ログレコードを更新
            update processLog;
        }
    }

    /**
     * 一括処理ログのレコードを作成
     * @param log 処理ログ
     * @param subject 処理件名
     * @param message 処理内容
     * @param status 処理状態
     * @param groupAddresses 送信先の課
     * @return 一括処理ログのList
     */
    private BulkProcessLog__c logBatchStatus(
        String log,
        String subject,
        String details,
        String status,
        String groupAddresses
    ) {
        // 処理ログ
        processLog.ProcessLog__c = log;
        // 処理件名
        processLog.ProcessSubject__c = subject;
        // 処理内容
        processLog.ProcessDetails__c = details;
        // 処理分類
        processLog.ProcessType__c = BATCH_JOB_PROCESS_TYPE;
        // 処理状態
        processLog.ProcessStatus__c = status;
        // 送信先の課
        processLog.ToEmailGroupAddresses__c = groupAddresses;
        return processLog;
    }

    /**
     * 注文を作成
     */
    private OrderHeader__c createOrderHeaderFromReg(RegularServiceInformation__c rsi, Date loadingDate) {
        return new OrderHeader__c(
            Account__c = rsi.Account__c, // 荷主
            Destination__c = rsi.Destination__c, // 着地
            VehicleNumber__c = rsi.VehicleNumber__c, // 車番
            DriverMaster__c = rsi.DriverMaster__c, // ドライバー
            ExpectedDeliveryDate__c = loadingDate.addDays(Integer.valueOf(rsi.DeliveryDate__c)), // 納品日
            LoadingDate__c = loadingDate, // 積込日
            OriginPlace__c = rsi.OriginPlace__c, // 発地
            Amount__c = rsi.Amount__c, // 運賃
            QuantityForShippingFeeCal__c = rsi.QuantityForShippingFeeCal__c, // 運賃計算用数量
            UnitForShippingFeeCal__c = rsi.UnitForShippingFeeCal__c, // 運賃計算用単位
            InvoiceAccount__c = rsi.InvoiceAccount__c, // 請求先（集計使用名）
            RegularServiceInformation__c = rsi.Id, // 定期便情報#
            Remarks1__c = rsi.Remarks1__c, // 備考①
            Remarks2__c = rsi.Remarks2__c, // 備考②
            ShippingFeeManualFlag__c = rsi.ShippingFeeManualFlag__c, // 運賃手動計算フラグ
            Status__c = rsi.Status__c, // 状態
            ShippingCompany__c = rsi.ShippingCompany__c, // 配送会社
            TransportationMode__c = rsi.TransportationMode__c, // 輸送形態
            UnitPrice__c = rsi.UnitPrice__c, // 単価
            AncillaryWorkFee__c = rsi.AncillaryWorkFee__c, // 付帯作業費
            SubcontractFee__c = rsi.SubcontractFee__c, // 下請け運賃
            DepartureTime__c = rsi.DepartureTime__c, // 出発時間帯
            Category__c = rsi.Category__c, // カテゴリー
            FirstProductName__c = rsi.ItemName__c //品名
        );
    }
}