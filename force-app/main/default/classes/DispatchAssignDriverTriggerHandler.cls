public inherited sharing class DispatchAssignDriverTriggerHandler extends CommonTriggerHandler {
    private List<DispatchAssignDriver__c> oldList;
    private List<DispatchAssignDriver__c> newList;
    private Map<Id, DispatchAssignDriver__c> oldMap;
    private Map<Id, DispatchAssignDriver__c> newMap;

    public DispatchAssignDriverTriggerHandler() {
        this.oldList = (List<DispatchAssignDriver__c>) Trigger.old;
        this.newList = (List<DispatchAssignDriver__c>) Trigger.new;
        this.oldMap = (Map<Id, DispatchAssignDriver__c>) Trigger.oldMap;
        this.newMap = (Map<Id, DispatchAssignDriver__c>) Trigger.newMap;
    }

    public override void afterInsert() {
        // 勤務情報へのRollup 配車済件数
        driverScheduleRollupDispatchedCount();
    }
    public override void afterUpdate() {
        // 勤務情報へのRollup 配車済件数
        driverScheduleRollupDispatchedCount();
    }
    public override void afterDelete() {
        // 勤務情報へのRollup 配車済件数
        driverScheduleRollupDispatchedCount();
    }
    public override void afterUnDelete() {
        // 勤務情報へのRollup 配車済件数
        driverScheduleRollupDispatchedCount();
    }

    //
    private void driverScheduleRollupDispatchedCount() {
        // 変更された 配車アサイン情報のレコードの一覧
        List<DispatchAssignDriver__c> changedDadList = new List<DispatchAssignDriver__c>();
        // 勤務情報Idの一覧
        List<Id> driverScheduleIdList = new List<Id>();
        // 勤務情報Id と 配車アサイン情報のレコードの一覧　のマップ
        Map<Id, List<DispatchAssignDriver__c>> dsIdToDadListMap = new Map<Id, List<DispatchAssignDriver__c>>();

        if ((Trigger.IsInsert || Trigger.IsUnDelete) && Trigger.isAfter) {
            // 作成後の場合
            for (DispatchAssignDriver__c dad : newList) {
                if (String.isNotBlank(dad.DriverSchedule__c)) {
                    changedDadList.add(dad);
                }
            }
        } else if (Trigger.isDelete && Trigger.isAfter) {
            // 削除後の場合
            for (DispatchAssignDriver__c dad : oldList) {
                if (String.isNotBlank(dad.DriverSchedule__c)) {
                    changedDadList.add(dad);
                }
            }
        } else if (Trigger.isUpdate && Trigger.isAfter) {
            // 更新後の場合
            for (DispatchAssignDriver__c dad : newList) {
                // 「勤務情報」の項目が変更された場合
                if (oldMap.get(dad.Id) != null && dad.DriverSchedule__c != oldMap.get(dad.Id).DriverSchedule__c) {
                    if (String.isNotBlank(dad.DriverSchedule__c)) {
                        changedDadList.add(dad);
                    }
                    if (String.isNotBlank(oldMap.get(dad.Id).DriverSchedule__c)) {
                        changedDadList.add(oldMap.get(dad.Id));
                    }
                }
            }
        }

        // 一覧が空の場合、処理終了
        if (changedDadList.isEmpty()) {
            return;
        }

        // 一覧とマップの作成
        for (DispatchAssignDriver__c dad : changedDadList) {
            // 勤務情報Idの一覧
            if (!driverScheduleIdList.contains(dad.DriverSchedule__c)) {
                driverScheduleIdList.add(dad.DriverSchedule__c);
            }
            // 勤務情報と配車アサイン情報一覧 のマップ
            if (dsIdToDadListMap.get(dad.DriverSchedule__c) == null) {
                dsIdToDadListMap.put(dad.DriverSchedule__c, new List<DispatchAssignDriver__c>());
            }
            List<DispatchAssignDriver__c> dadList = dsIdToDadListMap.get(dad.DriverSchedule__c);
            dadList.add(dad);
        }

        // 積み上げ条件 設定して、集計 soqlを発行
        AggregateResult[] groupbyResults = [
            SELECT DriverSchedule__c, COUNT(Id) totalCount
            FROM DispatchAssignDriver__c
            WHERE DriverSchedule__c IN :driverScheduleIdList
            GROUP BY DriverSchedule__c
        ];

        // 勤務情報の更新用のマップ
        Map<Id, DriverSchedule__c> updateMap = new Map<Id, DriverSchedule__c>();

        // 集計値の計算
        for (AggregateResult ar : groupbyResults) {
            DriverSchedule__c dsRecord = new DriverSchedule__c();
            dsRecord.Id = String.ValueOf(ar.get('DriverSchedule__c'));
            dsRecord.Dispatched_Cnt__c = ar.get('totalCount') != null ? (Decimal) ar.get('totalCount') : 0;
            updateMap.put(dsRecord.Id, dsRecord);
        }

        for (Id dsRecordId : driverScheduleIdList) {
            // updateMapにない場合 つまり、子がない場合
            // 集計全部初期化になる
            if (false == updateMap.containsKey(dsRecordId)) {
                DriverSchedule__c dsRecord = new DriverSchedule__c(Id = dsRecordId);
                dsRecord.Dispatched_Cnt__c = 0;
                updateMap.put(dsRecord.Id, dsRecord);
            }
        }

        if (false == updateMap.isEmpty()) {
            // 勤務情報を更新
            List<DriverSchedule__c> updateList = updateMap.values();
            Database.SaveResult[] saveResultList = Database.update(updateList, false);
            for (Integer i = 0; i < updateList.size(); i++) {
                if (!saveResultList[i].isSuccess()) {
                    // エラー集合
                    String errorMessage = '';
                    for (Database.Error err : saveResultList[i].getErrors()) {
                        errorMessage += err.getMessage() + '\n';
                    }
                    // エラーの場合、勤務情報を参照している配車アサイン情報レコードにエラーを出す
                    List<DispatchAssignDriver__c> errorDadList = dsIdToDadListMap.get(updateList[i].Id);
                    for (DispatchAssignDriver__c errorDad : errorDadList) {
                        errorDad.addError(errorMessage);
                    }
                }
            }
        }
    }
}