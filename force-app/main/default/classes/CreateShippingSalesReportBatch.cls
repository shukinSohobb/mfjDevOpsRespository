/**
 * 請求・支払明細から運送売上実績表を作成バッチ
 * 起動時間：毎日
 */
public with sharing class CreateShippingSalesReportBatch implements Database.Batchable<Date>, Database.Stateful, Schedulable {
    public List<String> ItemSelectList = new List<String>{
        '運賃',
        '付帯作業',
        '待機料',
        '燃料サーチャージ',
        'シャトレーゼの請求',
        'キャンセル料',
        '下請け運賃'
    };
    public final String MetaDataDeveloperName = 'CreateShippingSalesReportParameter'; //メタデータDeveloperName
    public List<String> errorMessageList = new List<String>(); // 変数で処理時のエラーメッセージを保存する
    public Integer allCount = 0; // 処理件数
    public Integer sucessCount = 0; //処理成功件数
    public Integer errorCount = 0; //処理失敗件数
    String ChateraiseAccountCode; //シャトレーゼの取引先コード
    String FujiEchoAccountCode; //富士エコーの取引先コード
    Date StartDateMonthFirstDay; //開始日の月初日
    Date EndDateMonthLastDay; //終了日の月末日

    public List<String> errorNaiyouList = new List<String>(); // 処理時のエラーメッセージを保存する。
    BulkProcessLog__c processLog = new BulkProcessLog__c(); // ログ
    public static final String BATCH_JOB_PROCESS_TYPE = 'CreateShippingSalesReportBatch'; // バッチジョブ処理分類

    //スケジュール起動、バッチサイズ：１
    public void execute(SchedulableContext sc) {
        CreateShippingSalesReportBatch batch = new CreateShippingSalesReportBatch();
        Database.executeBatch(batch, 1);
    }

    public Iterable<Date> start(Database.BatchableContext BC) {
        // バッチ処理ログ
        String log = BATCH_JOB_PROCESS_TYPE + ',' + ' Date={' + System.Today() + '}, {' + datetime.now() + '}';
        // 処理内容
        String details = '運送売上実績表作成バッチ実行開始' + datetime.now();
        String subject = System.Today().format().replace('/', '') + ': 運送売上実績表作成バッチ実行開始';
        processLog = logBatchStatus(log, subject, details, 'Start', '');
        insert processLog;

        List<Date> DateList = new List<Date>();
        MFJSetting__mdt metadate = MFJSetting__mdt.getInstance(MetaDataDeveloperName);
        if (metadate == null) {
            return DateList;
        }
        Integer PastDays = metadate.Value__c == null ? 0 : Integer.valueOf(metadate.Value__c); ////過去日数
        Integer FutureDays = metadate.Value2__c == null ? 0 : Integer.valueOf(metadate.Value2__c); //未来日数
        ChateraiseAccountCode = String.valueOf(metadate.Value3__c); //シャトレーゼの取引先コード
        FujiEchoAccountCode = String.valueOf(metadate.Value4__c); //富士エコーの取引先コード
        Date StartDate = Date.today().addDays(-PastDays); //開始日
        Date EndDate = Date.today().addDays(FutureDays); //終了日
        StartDateMonthFirstDay = Date.newInstance(StartDate.year(), StartDate.month(), 1); //開始日の月初日
        EndDateMonthLastDay = Date.newInstance(EndDate.year(), EndDate.month(), 1).addMonths(1).addDays(-1); //終了日の月末日

        Date currentDate = StartDate;
        while (currentDate <= EndDate) {
            DateList.add(currentDate);
            currentDate = currentDate.addDays(1);
        }
        return DateList;
    }

    public void execute(Database.BatchableContext BC, List<Date> scope) {
        if (scope.isEmpty()) {
            return;
        }

        //請求・支払明細レコードを取得
        List<AccountingDetail__c> AccDetailList = [
            SELECT
                Id,
                Date__c, //日付
                Amount__c, //金額
                OrderHeader__c, //注文
                //OrderHeader__r.Amount__c, //注文.運賃
                OrderHeader__r.SubcontractFee__c, //注文.下請け運賃
                Item__c, //項目
                AccountingType__c, //収支区分 1:収入;2:支出
                InvoiceAccount__c, //取引先Id
                InvoiceAccount__r.AccountCode__c, //取引先.取引先コード
                InvoiceAccount__r.ParentId, //取引先.親取引先Id
                InvoiceAccount__r.Parent.AccountCode__c //取引先.親取引先.取引先コード
            FROM AccountingDetail__c
            WHERE
                Date__c IN :scope
                //AND  OrderHeader__c <> NUll
                AND Item__c IN :ItemSelectList
        ];
        //運送売上実績表レコードを取得
        List<ShippingSalesReport__c> shippingSalesReportList = [
            SELECT
                Id,
                Date__c, //日付
                MARUSMfjVehicleSales__c, //マルエス（MFJ車）実績
                ChateraiseSales__c, //シャトレーゼ実績
                FujiEchoMfjVehicleSales__c, //富士エコー・ローソン（MFJ車）実績
                CharteredVehicleSales__c, //傭車全体（シャト除く）実績
                FujiEchoCharteredVehicleSales__c, //富士エコー・ローソン（傭車）実績
                ChateraiseSubcontractorSales__c, //シャトレーゼ下払い
                CharteredVehicleSubcontractorSales__c, //傭車全体（シャト除く）下払い
                FujiEchoCharteredVehicleSubcontractSales__c, //富士エコー・ローソン（傭車）下払い
                ObjectiveManagement__c //目標管理Id
            FROM ShippingSalesReport__c
            WHERE Date__c IN :scope
        ];
        //目標管理レコードを取得
        List<ObjectiveManagement__c> objectiveManagementList = [
            SELECT Id, TargetMonth__c //対象月
            FROM ObjectiveManagement__c
            WHERE TargetMonth__c >= :StartDateMonthFirstDay AND TargetMonth__c <= :EndDateMonthLastDay
        ];

        Map<Date, List<AccountingDetail__c>> AccDetailMap = new Map<Date, List<AccountingDetail__c>>(); //Map<日付,請求・支払明細リスト>
        Map<Date, ShippingSalesReport__c> ShippingSalesReportMap = new Map<Date, ShippingSalesReport__c>(); //Map<日付,運送売上実績表>
        Map<Integer, Id> ObjectiveManagementMap = new Map<Integer, Id>(); //Map<月,目標管理Id>
        //Map<日付,請求・支払明細リスト>を作成
        for (AccountingDetail__c accDetail : AccDetailList) {
            if (accDetail.Date__c != null) {
                if (!AccDetailMap.containsKey(accDetail.Date__c)) {
                    List<AccountingDetail__c> accDetailSubList = new List<AccountingDetail__c>();
                    accDetailSubList.add(accDetail);
                    AccDetailMap.put(accDetail.Date__c, accDetailSubList);
                } else {
                    List<AccountingDetail__c> accDetailSubList = AccDetailMap.get(accDetail.Date__c);
                    accDetailSubList.add(accDetail);
                }
            }
        }
        //Map<日付,運送売上実績表>を作成
        for (ShippingSalesReport__c shippingSalesReport : shippingSalesReportList) {
            if (shippingSalesReport.Date__c != null) {
                ShippingSalesReportMap.put(shippingSalesReport.Date__c, shippingSalesReport);
            }
        }
        //Map<月,目標管理Id>を作成
        for (ObjectiveManagement__c objectiveManagement : objectiveManagementList) {
            if (objectiveManagement.TargetMonth__c != null) {
                Integer targetMonth = objectiveManagement.TargetMonth__c.month();
                ObjectiveManagementMap.put(targetMonth, objectiveManagement.Id);
            }
        }

        //日別で運送売上実績表を計算する
        for (Date keyDate : AccDetailMap.keySet()) {
            List<AccountingDetail__c> accountingDetails = AccDetailMap.get(keyDate);

            //注文NULLの場合、下請け運賃なし
            Decimal MARUSMfjVehicleSales = 0; //マルエス（MFJ車）実績　⇒　シャトレーゼ除くの注文 且つ 下請け運賃 = nullの運賃
            Decimal ChateraiseSales = 0; //シャトレーゼ実績　⇒　シャトレーゼの注文の運賃
            Decimal FujiEchoMfjVehicleSales = 0; //富士エコー・ローソン（MFJ車）実績　⇒　富士エコーの注文 且つ 下請け運賃 = nullの運賃
            Decimal CharteredVehicleSales = 0; //傭車全体（シャト除く）実績　⇒　シャトレーゼ除くの注文 且つ 下請け運賃 <> nullの運賃
            Decimal FujiEchoCharteredVehicleSales = 0; //富士エコー・ローソン（傭車）実績　⇒　富士エコーの注文 且つ 下請け運賃 <> nullの運賃

            Decimal ChateraiseSubcontractorSales = 0; //シャトレーゼ下払い　⇒　シャトレーゼの注文の下請け運賃
            Decimal CharteredVehicleSubcontractorSales = 0; //傭車全体（シャト除く）下払い　⇒　シャトレーゼ除くの注文 且つ 下請け運賃 <> nullの下請け運賃
            Decimal FujiEchoCharteredVehicleSubcontractSales = 0; //富士エコー・ローソン（傭車）下払い　⇒　富士エコーの注文 且つ 下請け運賃 <> nullの下請け運賃

            for (AccountingDetail__c accDetail : accountingDetails) {
                String accountCode = accDetail.InvoiceAccount__r.AccountCode__c; //取引先コード
                String parentAccountCode = null; //親取引先コード
                if (accDetail.InvoiceAccount__r.ParentId != null) {
                    parentAccountCode = accDetail.InvoiceAccount__r.Parent.AccountCode__c;
                }

                //取引先/親取引先：シャトレーゼの場合
                if (accountCode == ChateraiseAccountCode || parentAccountCode == ChateraiseAccountCode) {
                    //System.debug('★シャトレーゼ');
                    if (accDetail.AccountingType__c == '2') {
                        ChateraiseSubcontractorSales += accDetail.Amount__c; //シャトレーゼ下払い
                    } else if (accDetail.AccountingType__c == '1') {
                        ChateraiseSales += accDetail.Amount__c; //シャトレーゼ実績
                    }
                }
                //取引先/親取引先：富士エコーの場合
                else if (accountCode == FujiEchoAccountCode || parentAccountCode == FujiEchoAccountCode) {
                    //System.debug('★富士エコー');
                    if (accDetail.AccountingType__c == '2') {
                        CharteredVehicleSubcontractorSales += accDetail.Amount__c; //傭車全体（シャト除く）下払い
                        FujiEchoCharteredVehicleSubcontractSales += accDetail.Amount__c; //富士エコー・ローソン（傭車）下払い
                    } else if (accDetail.AccountingType__c == '1') {
                        if (accDetail.OrderHeader__c != null) {
                            //注文<>null
                            if (accDetail.OrderHeader__r.SubcontractFee__c == null) {
                                MARUSMfjVehicleSales += accDetail.Amount__c; //マルエス（MFJ車）実績
                                FujiEchoMfjVehicleSales += accDetail.Amount__c; //富士エコー・ローソン（MFJ車）実績
                            } else {
                                CharteredVehicleSales += accDetail.Amount__c; //傭車全体（シャト除く）実績
                                FujiEchoCharteredVehicleSales += accDetail.Amount__c; //富士エコー・ローソン（傭車）実績
                            }
                        }
                    }
                }
                //取引先/親取引先：他の場合
                else {
                    //System.debug('★シャトレーゼと富士エコーの以外');
                    if (accDetail.AccountingType__c == '2') {
                        CharteredVehicleSubcontractorSales += accDetail.Amount__c; //傭車全体（シャト除く）下払い
                    } else if (accDetail.AccountingType__c == '1') {
                        if (accDetail.OrderHeader__c != null) {
                            //注文<>null
                            if (accDetail.OrderHeader__r.SubcontractFee__c == null) {
                                MARUSMfjVehicleSales += accDetail.Amount__c; //マルエス（MFJ車）実績
                            } else {
                                CharteredVehicleSales += accDetail.Amount__c; //傭車全体（シャト除く）実績
                            }
                        }
                    }
                }
            } ////for

            ShippingSalesReport__c shippingSalesReport;

            if (ShippingSalesReportMap.containsKey(keyDate)) {
                shippingSalesReport = ShippingSalesReportMap.get(keyDate);
            } else {
                shippingSalesReport = new ShippingSalesReport__c();
                shippingSalesReport.Date__c = keyDate;
                if (ObjectiveManagementMap.containsKey(keyDate.month())) {
                    shippingSalesReport.ObjectiveManagement__c = ObjectiveManagementMap.get(keyDate.month()); //目標管理Idを付与
                }
                ShippingSalesReportMap.put(keyDate, shippingSalesReport);
            }

            shippingSalesReport.MARUSMfjVehicleSales__c = MARUSMfjVehicleSales; //マルエス（MFJ車）実績
            shippingSalesReport.ChateraiseSales__c = ChateraiseSales; //シャトレーゼ実績
            shippingSalesReport.FujiEchoMfjVehicleSales__c = FujiEchoMfjVehicleSales; //富士エコー・ローソン（MFJ車）実績
            shippingSalesReport.CharteredVehicleSales__c = CharteredVehicleSales; //傭車全体（シャト除く）実績
            shippingSalesReport.FujiEchoCharteredVehicleSales__c = FujiEchoCharteredVehicleSales; //富士エコー・ローソン（傭車）実績
            shippingSalesReport.ChateraiseSubcontractorSales__c = ChateraiseSubcontractorSales; //シャトレーゼ下払い
            shippingSalesReport.CharteredVehicleSubcontractorSales__c = CharteredVehicleSubcontractorSales; //傭車全体（シャト除く）下払い
            shippingSalesReport.FujiEchoCharteredVehicleSubcontractSales__c = FujiEchoCharteredVehicleSubcontractSales; //富士エコー・ローソン（傭車）下払い
        } ////for

        List<ShippingSalesReport__c> shippingSalesReportUpsertList = new List<ShippingSalesReport__c>(
            ShippingSalesReportMap.values()
        );

        Savepoint sp;
        try {
            allCount += shippingSalesReportUpsertList.size(); //処理件数

            sp = Database.setSavepoint();
            Database.UpsertResult[] saveResultList = Database.upsert(shippingSalesReportUpsertList, false);

            for (Integer i = 0; i < saveResultList.size(); i++) {
                Database.UpsertResult sr = saveResultList[i];
                ShippingSalesReport__c eObj = shippingSalesReportUpsertList[i];

                if (false == sr.isSuccess()) {
                    errorCount++; //処理失敗件数累計
                    for (Database.Error err : sr.getErrors()) {
                        String errorMessage =
                            '日付：' +
                            eObj.Date__c +
                            'の運送売上実績表の作成または更新に失敗しました。' +
                            err;
                        errorMessageList.add(errorMessage);
                    }
                }
            }
            sucessCount = allCount - errorCount; //処理成功件数

            // ログの状態とメッセージを更新
            processLog.ProcessStatus__c = 'Processing'; // 処理状態
            // ログレコードを更新
            update processLog;
        } catch (Exception e) {
            Database.rollback(sp);
            errorNaiyouList.add(e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
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
                '運送売上実績表作成バッチ実行完了' +
                datetime.now() +
                '<br /> 処理失敗<br />' +
                '処理対象日数: {' +
                allCount +
                '処理成功した日数: {' +
                sucessCount +
                '}<br />' +
                '処理失敗した日数: {' +
                errorCount +
                '}<br />' +
                'エラーメッセージ: ' +
                errMessage;

            // ログの状態とメッセージを更新
            processLog.ProcessSubject__c = System.Today().format().replace('/', '') + ': 運送売上実績表作成バッチ実行失敗'; // 処理件名
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
            processLog.ProcessLog__c = '処理成功対象処理日数: {' + allCount + '}'; // 処理ログ
            // ログレコードを更新
            update processLog;
        } else {
            // 処理内容を整理する
            String errMessage = '';
            for (String msg : errorMessageList) {
                errMessage += msg + ';';
            }
            errMessage =
                '運送売上実績表作成バッチ実行完了' +
                datetime.now() +
                '<br /> 処理失敗<br />' +
                '処理対象日数: {' +
                allCount +
                '}<br />' +
                '処理成功した日数: {' +
                sucessCount +
                '}<br />' +
                '処理失敗した日数: {' +
                errorCount +
                '}<br />' +
                'エラーメッセージ: ' +
                errMessage;

            // ログの状態とメッセージを更新
            processLog.ProcessSubject__c = System.Today().format().replace('/', '') + ': 運送売上実績表作成バッチ実行失敗'; // 処理件名
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
}