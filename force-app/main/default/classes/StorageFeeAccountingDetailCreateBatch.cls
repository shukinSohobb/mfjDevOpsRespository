public class StorageFeeAccountingDetailCreateBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
    // 実行日
    public Date executeDate = System.today();
    // 処理ログ
    private BulkProcessLog__c processLog = new BulkProcessLog__c();
    // 期制の開始日の一覧
    private List<Date> termCycleStartDateList = new List<Date>();
    // すべてのレコードの数量
    private Decimal allCount = 0;
    // 処理されたレコドの数量
    private Decimal processCount = 0;
    // 成功のレコードの数量
    private Decimal successCount = 0;
    // エラー一覧
    private List<String> errorList = new List<String>();
    // Upsertエラー一覧
    private List<String> upsertErrorList = new List<String>();
    // 取引先の「締め日」条件
    List<String> closingDateCondition = new List<String>();
    // 取引先の締め日が「15日」
    private final List<String> CLOSINGDATE_15 = new List<String>{ 'Month_15' };
    // 取引先の締め日が「20日」、「月末」、「イレギュラー」
    private final List<String> CLOSINGDATE_20_MONTHEND = new List<String>{ 'Month_20', 'Month_End', 'Irregular' };

    public StorageFeeAccountingDetailCreateBatch() {
    }
    public StorageFeeAccountingDetailCreateBatch(Date executeDate) {
        this.executeDate = executeDate;
    }

    public void execute(SchedulableContext sc) {
        StorageFeeAccountingDetailCreateBatch batch = new StorageFeeAccountingDetailCreateBatch();
        Database.executeBatch(batch, 200);
    }

    public Database.Querylocator start(Database.BatchableContext bc) {
        // 処理ログを生成
        // 処理状態＝「処理開始」
        processLog.ProcessStatus__c = 'Start';
        // 処理件名
        processLog.ProcessSubject__c = '保管料作成バッチのログ：' + executeDate;
        // 処理分類
        processLog.ProcessType__c = 'StorageFeeAccountingDetailCreateBatch';

        // 月末の日を取得
        Integer daysInMonth = Date.daysInMonth(executeDate.year(), executeDate.month());
        //
        if (executeDate.day() == 4 || executeDate.day() == 14 || executeDate.day() == 24) {
            closingDateCondition = CLOSINGDATE_15;
        } else if (executeDate.day() == 9 || executeDate.day() == 19 || executeDate.day() == daysInMonth - 1) {
            closingDateCondition = CLOSINGDATE_20_MONTHEND;
        }
        // 取引先を取得
        List<Account> accountList = [
            SELECT Id, ClosingDate__c
            FROM Account
            WHERE ClosingDate__c != NULL AND ClosingDate__c IN :closingDateCondition
        ];

        // 期制の終了日の一覧
        List<Date> termCycleEndDateList = new List<Date>();
        // 取引先IDと締日 のマップ
        Map<Id, String> accountIdClosingDateMap = new Map<Id, String>();
        for (Account acc : accountList) {
            accountIdClosingDateMap.put(acc.Id, acc.ClosingDate__c);
            Date termCycleStartDate = MfjUtil.getTargetTermCycleStartDate(executeDate, acc.ClosingDate__c);
            if (!termCycleStartDateList.contains(termCycleStartDate)) {
                termCycleStartDateList.add(termCycleStartDate);
            }
            Date termCycleEndDate = MfjUtil.getTargetTermCycleEndDate(executeDate, acc.ClosingDate__c);
            if (!termCycleEndDateList.contains(termCycleEndDate)) {
                termCycleEndDateList.add(termCycleEndDate);
            }
        }

        // 処理済みの請求書を取得
        List<InvoiceDocument__c> confirmedInvoiceList = [
            SELECT Id, Account__c, InvoiceDate__c
            FROM InvoiceDocument__c
            WHERE
                Type__c = '保管・荷役明細書'
                AND Status__c = 'Confirmed'
                AND Account__c IN :accountIdClosingDateMap.keyset()
                AND InvoiceDate__c IN :termCycleEndDateList
        ];
        // 処理済み請求書がある場合、取引先をスキップ、取引先の保管料の請求・支払明細が作成されない
        for (InvoiceDocument__c invoice : confirmedInvoiceList) {
            accountIdClosingDateMap.remove(invoice.Account__c);
        }

        // 処理用の商品マスタ一覧
        return Database.getQueryLocator(
            [
                SELECT Id, StockQuantity_Sum__c, Account__c, Account__r.ClosingDate__c, UnitPriceStorage_F__c
                FROM ProductMaster__c
                WHERE
                    Account__c IN :accountIdClosingDateMap.keySet()
                    AND UnitPriceStorage_F__c > 0
                    AND LastModifiedDate > :executeDate - 60
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<ProductMaster__c> productList) {
        // 処理状態を更新
        processLog.ProcessStatus__c = 'Processing';
        // 商品マスタ一覧をチェック
        if (productList == null || productList.isEmpty())
            return;
        allCount += productList.size();
        Savepoint sp = Database.setSavepoint();
        try {
            // 請求・支払明細を作成するため、Dummy請求書を取得
            InvoiceDocument__c dummyInvoice = [
                SELECT Id
                FROM InvoiceDocument__c
                WHERE InvoiceDate__c = :Date.newInstance(1900, 1, 1)
            ];
            // 大小の期の開始日
            Date minTermStartDate = executeDate;
            // 商品マスタIDと保管料の請求・支払明細レコードのマップ
            Map<Id, AccountingDetail__c> productIdStorageAcdMap = new Map<Id, AccountingDetail__c>();
            for (ProductMaster__c product : productList) {
                Date prodTermStartDate = MfjUtil.getTargetTermStartDate(executeDate, product.Account__r.ClosingDate__c);
                if (prodTermStartDate < minTermStartDate) {
                    minTermStartDate = prodTermStartDate;
                }

                // 保管料 ＝ 在庫数 ＊ 単価保管料
                Decimal storageFee = product.StockQuantity_Sum__c * product.UnitPriceStorage_F__c;
                // 新規の保管料の請求・支払明細
                AccountingDetail__c newAcd = new AccountingDetail__c();
                // 取引先
                newAcd.InvoiceAccount__c = product.Account__c;
                // 商品マスタ
                newAcd.ProductMaster__c = product.Id;
                // 金額 ＝ 計算された保管料
                newAcd.Amount__c = storageFee;
                // 前期の在庫数
                newAcd.PrevTermStockQuantity__c = product.StockQuantity_Sum__c;
                // 期入庫数
                newAcd.TermArrivedQuantity__c = 0;
                // 期出庫数
                newAcd.TermShippedQuantity__c = 0;
                // 項目 ＝ 保管料
                newAcd.Item__c = '保管料';
                // 収支区分 ＝ 収入
                newAcd.AccountingType__c = '1';
                // 勘定科目 ＝ 売掛_10%課税
                newAcd.AccountItem__c = '1_90';
                // 請求書 ＝ Dummy請求書
                newAcd.InvoiceDocument__c = dummyInvoice.Id;
                // 対象課 ＝ 倉庫課
                newAcd.TargetDepartment__c = '倉庫課';
                // 日付 ＝ 今期の開始日
                newAcd.Date__c = prodTermStartDate;
                // 期制の開始日
                newAcd.TermCycleStartDate__c = MfjUtil.getTargetTermCycleStartDate(
                    executeDate,
                    product.Account__r.ClosingDate__c
                );
                // マップに追加
                productIdStorageAcdMap.put(product.Id, newAcd);
            }

            // 今期の入庫済み在庫情報を取得
            List<ProductStockInfo__c> psiList = [
                SELECT Id, ProductMaster__c, ArrivalQuantity__c
                FROM ProductStockInfo__c
                WHERE
                    ProductMaster__c IN :productList
                    AND ArrivalDate__c <= :executeDate
                    AND ArrivalDate__c >= :minTermStartDate
                    AND Status__c = 'Arrived'
                    // AND HandlingCargoCostBurden__c != 'Free'
                    AND ProductMaster__r.UnitPriceStorage_F__c > 0
                    AND ArrivalQuantity__c > 0
            ];

            // 入庫情報で今期の保管料の請求・支払明細の修正
            for (ProductStockInfo__c psi : psiList) {
                AccountingDetail__c newAcd = productIdStorageAcdMap.get(psi.ProductMaster__c);
                if (newAcd != null) {
                    // 期入庫数の編集
                    newAcd.TermArrivedQuantity__c = newAcd.TermArrivedQuantity__c + psi.ArrivalQuantity__c;
                    // 前期の在庫数の編集
                    newAcd.PrevTermStockQuantity__c = newAcd.PrevTermStockQuantity__c - psi.ArrivalQuantity__c;
                }
            }

            // 今期の出庫済みピッキングリストを取得
            List<PickingList__c> plList = [
                SELECT Id, Quantity__c, ProductMaster__c
                FROM PickingList__c
                WHERE
                    LoadingDate_F__c <= :executeDate
                    AND LoadingDate_F__c >= :minTermStartDate
                    AND Shipped__c = TRUE
                    AND ProductStockInfo__r.ProductMaster__c IN :productList
                    AND ProductStockInfo__r.ProductMaster__r.UnitPriceStorage_F__c > 0
                    AND Quantity__c > 0
            ];

            // 出庫情報で今期の保管料の請求・支払明細を修正
            for (PickingList__c pl : plList) {
                AccountingDetail__c newAcd = productIdStorageAcdMap.get(pl.ProductMaster__c);
                if (newAcd != null) {
                    // 期出庫数の編集
                    newAcd.TermShippedQuantity__c = newAcd.TermShippedQuantity__c + pl.Quantity__c;
                    // 前期の在庫数の編集
                    newAcd.PrevTermStockQuantity__c = newAcd.PrevTermStockQuantity__c + pl.Quantity__c;
                }
            }

            // 今規制の保管料の請求・支払明細を取得
            List<AccountingDetail__c> existingStorageAcdList = [
                SELECT Id, InvoiceAccount__r.ClosingDate__c, Date__c, ProductMaster__c
                FROM AccountingDetail__c
                WHERE
                    ProductMaster__c IN :productIdStorageAcdMap.keySet()
                    AND TermCycleStartDate__c IN :termCycleStartDateList
                    AND Item__c = '保管料'
            ];
            // 削除用の3つの期制の開始日以外の保管料の請求・支払明細の一覧
            List<AccountingDetail__c> deleteAcdList = new List<AccountingDetail__c>();
            // 存在している保管料の請求・支払明細のループ
            for (AccountingDetail__c existingStorageAcd : existingStorageAcdList) {
                // すでに存在している保管料の請求・支払明細のIDで設定
                // 条件：同じ「期制の開始日」、同じ「商品マスタ」、同じ「日付」
                AccountingDetail__c newAcd = productIdStorageAcdMap.get(existingStorageAcd.ProductMaster__c);
                if (newAcd != null) {
                    if (existingStorageAcd.Date__c == newAcd.Date__c) {
                        newAcd.Id = existingStorageAcd.Id;
                    }
                }
                Date termCycleEndDate = MfjUtil.getTargetTermCycleEndDate(
                    executeDate,
                    existingStorageAcd.InvoiceAccount__r.ClosingDate__c
                );
                // 今期は取引先の3期の時、3つの期制の開始日以外の保管料の請求・支払明細を削除用一覧に追加
                if (termCycleEndDate == executeDate + 1) {
                    if (
                        // 取引先の締日が「15日」。日付が(6,16,26)以外
                        (existingStorageAcd.InvoiceAccount__r.ClosingDate__c.contains('15') &&
                        !(new List<Integer>{ 6, 16, 26 }.contains(existingStorageAcd.Date__c.day()))) ||
                        // 取引先の締日が「20日」、「月末」、「イレギュラー」。日付が(1,11,21)以外
                        (!existingStorageAcd.InvoiceAccount__r.ClosingDate__c.contains('15') &&
                        !(new List<Integer>{ 1, 11, 21 }.contains(existingStorageAcd.Date__c.day())))
                    ) {
                        // 削除用の一覧に追加
                        deleteAcdList.add(existingStorageAcd);
                    }
                }
            }
            // 保管料の請求・支払明細をUpsert
            List<AccountingDetail__c> upsertAcdList = productIdStorageAcdMap.values();
            Database.UpsertResult[] upsertResultList = Database.upsert(upsertAcdList, false);
            for (Integer i = 0; i < upsertResultList.size(); i++) {
                Database.UpsertResult ur = upsertResultList[i];
                if (false == ur.isSuccess()) {
                    String errorMessage = upsertAcdList[i].ProductMaster__c + ' の商品マスタ: \n';
                    for (Database.Error err : ur.getErrors()) {
                        errorMessage += err + '\n';
                    }
                    upsertErrorList.add(errorMessage);
                } else {
                    successCount++;
                }
            }
            processCount += upsertAcdList.size();

            // 保管料の請求・支払明細を削除
            Database.DeleteResult[] deleteResultList = Database.delete(deleteAcdList, false);
            for (Integer i = 0; i < deleteResultList.size(); i++) {
                Database.DeleteResult dr = deleteResultList[i];
                if (false == dr.isSuccess()) {
                    String errorMessage = deleteResultList[i].Id + ' の請求・支払明細: \n';
                    for (Database.Error err : dr.getErrors()) {
                        errorMessage += err + '\n';
                    }
                    upsertErrorList.add(errorMessage);
                }
            }
        } catch (Exception e) {
            errorList.add(e.getMessage() + ': ' + e.getStackTraceString());
            // データをロールバック
            Database.rollback(sp);
        }
    }

    // 処理完了、成功ログかエラーログを作成
    public void finish(Database.BatchableContext bc) {
        String log =
            'レコードの数量：' +
            allCount +
            '\n' +
            '処理されたレコードの数量：' +
            processCount +
            '\n成功の数量：' +
            successCount +
            '\n';
        String status = processLog.ProcessStatus__c;
        if (!errorList.isEmpty()) {
            for (String error : errorList) {
                System.debug('ERROR: ' + error);
                log += error + '\n';
            }
            status = 'Error';
        } else if (!upsertErrorList.isEmpty()) {
            for (String error : upsertErrorList) {
                System.debug('Upsert ERROR: ' + error);
                log += error + '\n';
            }
            status = 'Error';
        } else if (allCount > 0 && allCount == successCount) {
            status = 'Success';
        }
        processLog.ProcessStatus__c = status;
        processLog.ProcessLog__c = log;
        insert processLog;
    }
}