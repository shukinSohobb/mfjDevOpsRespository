public with sharing class ArrivedScheduleBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
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
    // 処理時のエラーメッセージを変数で保存する
    private List<String> errorMessageList = new List<String>();

    public ArrivedScheduleBatch() {
    }
    public ArrivedScheduleBatch(Date executeDate) {
        this.executeDate = executeDate;
    }

    public void execute(SchedulableContext sc) {
        ArrivedScheduleBatch batch = new ArrivedScheduleBatch();
        Database.executeBatch(batch, 200);
    }

    public Database.Querylocator start(Database.BatchableContext bc) {
        // 処理ログを生成
        // 処理状態＝「処理開始」
        processLog.ProcessStatus__c = 'Start';
        // 処理件名
        processLog.ProcessSubject__c = '入庫済みに変更のバッチログ：' + executeDate;
        // 処理分類
        processLog.ProcessType__c = 'ArrivedScheduleBatch';

        // 在庫情報一覧を取得
        return Database.getQueryLocator(
            [
                SELECT Id, Status__c
                FROM ProductStockInfo__c
                WHERE
                    Status__c = NULL // 在庫条件＝NULL
                    AND ArrivalQuantity__c > 0 // 数量（入庫）＞０
                    AND ArrivalDate__c <= :executeDate // 入庫日 ＜＝ 現在の日
            ]
        );
    }

    public void execute(Database.BatchableContext bc, List<ProductStockInfo__c> psiList) {
        // 処理状態を更新
        processLog.ProcessStatus__c = 'Processing';
        // 一覧をチェック
        if (psiList == null || psiList.isEmpty())
            return;
        allCount += psiList.size();
        Savepoint sp = Database.setSavepoint();
        try {
            // 入庫済みに変更
            for (ProductStockInfo__c psi : psiList) {
                psi.Status__c = 'Arrived';
            }

            // 在庫情報を一つずつ更新
            for (ProductStockInfo__c psi : psiList) {
                List<ProductStockInfo__c> singleRecord = new List<ProductStockInfo__c>{ psi };
                Database.SaveResult[] saveResultList = Database.update(singleRecord, false);
                // 更新結果を確認
                for (Integer i = 0; i < saveResultList.size(); i++) {
                    Database.SaveResult ur = saveResultList[i];
                    if (false == ur.isSuccess()) {
                        // エラー集合
                        String errorMessage = singleRecord[i].Id + ' の在庫情報: \n';
                        for (Database.Error err : ur.getErrors()) {
                            errorMessage += err + '\n';
                        }
                        errorMessageList.add(errorMessage);
                    } else {
                        successCount++;
                    }
                }
                processCount += singleRecord.size();
            }
        } catch (Exception e) {
            System.debug('ArrivedScheduleBatch Error: ' + e.getMessage() + ': ' + e.getStackTraceString());
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
        } else if (!errorMessageList.isEmpty()) {
            for (String error : errorMessageList) {
                System.debug('更新のERROR: ' + error);
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