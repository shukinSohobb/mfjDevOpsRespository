public inherited sharing class DispatchDetailTriggerHandler extends CommonTriggerHandler {
    private List<DispatchDetail__c> oldList;
    private List<DispatchDetail__c> newList;
    private Map<Id, DispatchDetail__c> oldMap;
    private Map<Id, DispatchDetail__c> newMap;

    public DispatchDetailTriggerHandler() {
        this.oldList = (List<DispatchDetail__c>) Trigger.old;
        this.newList = (List<DispatchDetail__c>) Trigger.new;
        this.oldMap = (Map<Id, DispatchDetail__c>) Trigger.oldMap;
        this.newMap = (Map<Id, DispatchDetail__c>) Trigger.newMap;
    }

    public override void beforeUpdate() {
        this.insertManualUpdateLog();
    }
    // 手動更新実行時、手動更新メモを一括処理ログに残し、項目をリセット。
    private void insertManualUpdateLog() {
        List<BulkProcessLog__c> bulkProcessList = new List<BulkProcessLog__c>();

        for (DispatchDetail__c dispatchDetailNew : this.newList) {
            if (dispatchDetailNew.ManualUpdateDatetime__c != this.oldMap.get(dispatchDetailNew.Id).ManualUpdateDatetime__c) {
                BulkProcessLog__c bulkProcess = new BulkProcessLog__c();
                bulkProcess.ProcessSubject__c = '配車明細レコードの手動更新';
                bulkProcess.ProcessStatus__c = 'Success';
                bulkProcess.ProcessType__c = 'RecordManualUpdate';
                bulkProcess.DispatchDetail__c = dispatchDetailNew.Id;
                bulkProcess.ProcessDetails__c = '手動更新メモ: ' + dispatchDetailNew.ManualUpdateNote__c;

                // 手動更新メモを削除
                dispatchDetailNew.ManualUpdateNote__c = null;

                bulkProcessList.add(bulkProcess);
            }
        }

        // 一括処理ログにinsert
        insert bulkProcessList;
    }
}