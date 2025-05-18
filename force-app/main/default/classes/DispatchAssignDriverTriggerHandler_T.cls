@isTest
private class DispatchAssignDriverTriggerHandler_T {
    @TestSetup
    static void makeData() {
        // ドライバーマスタの作成
        DriverMaster__c dm = new DriverMaster__c();
        dm.Name = 'Test Driver';
        dm.UniqueKey__c = '12345';
        insert dm;

        // 注文の作成
        OrderHeader__c oh = new OrderHeader__c();
        insert oh;

        // 配車明細の作成
        DispatchDetail__c dd = new DispatchDetail__c();
        dd.OrderHeader__c = oh.Id;
        insert dd;

        // 勤務情報の作成
        DriverSchedule__c ds1 = new DriverSchedule__c();
        ds1.Date__c = Date.today();
        ds1.Driver__c = dm.Id;
        insert ds1;

        DriverSchedule__c ds2 = new DriverSchedule__c();
        ds2.Date__c = Date.today() - 1;
        ds2.Driver__c = dm.Id;
        insert ds2;

        // 配車アサイン情報の作成
        DispatchAssignDriver__c dad1 = new DispatchAssignDriver__c();
        // dad1.DriverSchedule__c = ds1.Id;
        dad1.DispatchDetail__c = dd.Id;
        insert dad1;

        DispatchAssignDriver__c dad2 = new DispatchAssignDriver__c();
        // dad2.DriverSchedule__c = ds2.Id;
        dad2.DispatchDetail__c = dd.Id;
        insert dad2;
    }

    // パターン：配車アサイン情報の「勤務情報」を更新
    // 期待結果：勤務情報の「配車済件数」＋１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test1() {
        // 勤務情報のレコード
        DriverSchedule__c ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCnt = ds1.Dispatched_Cnt__c != null ? ds1.Dispatched_Cnt__c : 0; // 「配車済件数」の更新前の値

        // 配車アサイン情報の「勤務情報」を勤務情報のレコードのIdに更新
        DispatchAssignDriver__c dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = ds1.Id;
        Test.startTest();
        update dad;
        Test.stopTest();
        // 勤務情報のレコードを再取得
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Assert.areEqual(dispatchedCnt + 1, ds1.Dispatched_Cnt__c); // 「配車済件数」の変更を確認
    }

    // パターン：配車アサイン情報の「勤務情報」を勤務情報レコードのIdからNULLに変更
    // 期待結果：勤務情報レコードの「配車済件数」ー１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test2() {
        // 勤務情報レコード
        DriverSchedule__c ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        // 配車アサイン情報レコードの「勤務情報」を設定
        DispatchAssignDriver__c dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = ds1.Id;
        update dad;
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCnt = ds1.Dispatched_Cnt__c; // 「配車済件数」のNULLに変更前の値
        // 配車アサイン情報レコードの「勤務情報」をNULLに変更
        dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = null;
        Test.startTest();
        update dad;
        Test.stopTest();

        // 勤務情報のレコードを再取得
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Assert.areEqual(dispatchedCnt - 1, ds1.Dispatched_Cnt__c); // 「配車済件数」の変更を確認
    }

    // パターン：配車アサイン情報の「勤務情報」を別の勤務情報レコードのIdに変更
    // 期待結果：前の勤務情報レコードの「配車済件数」ー１、後の勤務情報レコードの「配車済件数」＋１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test3() {
        // 勤務情報レコード一覧
        List<DriverSchedule__c> dsList = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC];
        // 配車アサイン情報レコードの「勤務情報」を1番レコードにする
        DispatchAssignDriver__c dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = dsList[0].Id;
        update dad;
        dsList = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC];
        Decimal dispatchedCnt0 = dsList[0].Dispatched_Cnt__c; // 1番のレコードの「配車済件数」の変更前の値
        Decimal dispatchedCnt1 = dsList[1].Dispatched_Cnt__c; // ２番のレコードの「配車済件数」の変更前の値
        // 配車アサイン情報レコードの「勤務情報」を2番レコードにする
        dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = dsList[1].Id;
        Test.startTest();
        update dad;
        Test.stopTest();
        // 勤務情報のレコードを再取得
        dsList = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC];
        Assert.areEqual(dispatchedCnt0 - 1, dsList[0].Dispatched_Cnt__c); // 1番のレコードの「配車済件数」の変更を確認
        Assert.areEqual(dispatchedCnt1 + 1, dsList[1].Dispatched_Cnt__c); // 2番のレコードの「配車済件数」の変更を確認
    }

    // パターン：配車アサイン情報を削除
    // 期待結果：勤務情報レコードの「配車済件数」ー１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test4() {
        // 勤務情報レコード
        DriverSchedule__c ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        // 配車アサイン情報レコードの「勤務情報」を設定
        DispatchAssignDriver__c dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = ds1.Id;
        update dad;
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCnt = ds1.Dispatched_Cnt__c; //「配車済件数」の削除前の値
        // 配車アサイン情報を削除
        Test.startTest();
        delete dad;
        Test.stopTest();
        // 勤務情報のレコードを再取得
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Assert.areEqual(dispatchedCnt - 1, ds1.Dispatched_Cnt__c); //「配車済件数」の変更を確認
    }

    // パターン：削除された配車アサイン情報を復元
    // 期待結果：勤務情報レコードの「配車済件数」＋１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test5() {
        // 勤務情報レコード
        DriverSchedule__c ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        // 配車アサイン情報レコードの「勤務情報」を設定
        DispatchAssignDriver__c dad = [SELECT Id FROM DispatchAssignDriver__c LIMIT 1];
        dad.DriverSchedule__c = ds1.Id;
        update dad;
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCntB4 = ds1.Dispatched_Cnt__c; //「配車済件数」の削除前の値
        delete dad;
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCnt = ds1.Dispatched_Cnt__c; //「配車済件数」の削除後の値
        // 削除された配車アサイン情報を復元
        Test.startTest();
        undelete dad;
        Test.stopTest();
        // 勤務情報のレコードを再取得
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        //「配車済件数」の変更を確認
        Assert.areEqual(dispatchedCnt + 1, dispatchedCntB4); // 削除前＝削除後＋１
        Assert.areEqual(dispatchedCnt + 1, ds1.Dispatched_Cnt__c); // 復元後＝削除後＋１
    }

    // パターン：配車アサイン情報を新規作成
    // 期待結果：勤務情報レコードの「配車済件数」＋１
    @isTest
    public static void driverScheduleRollupDispatchedCount_test6() {
        // 勤務情報レコード
        DriverSchedule__c ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Decimal dispatchedCnt = ds1.Dispatched_Cnt__c != null ? ds1.Dispatched_Cnt__c : 0; //「配車済件数」の作成前の値
        // 配車アサイン情報を新規作成処理
        DispatchDetail__c dd = [SELECT Id FROM DispatchDetail__c LIMIT 1];
        DispatchAssignDriver__c dad = new DispatchAssignDriver__c();
        dad.DispatchDetail__c = dd.Id;
        dad.DriverSchedule__c = ds1.Id; // 配車アサイン情報レコードの「勤務情報」を設定
        Test.startTest();
        insert dad;
        Test.stopTest();
        // 勤務情報のレコードを再取得
        ds1 = [SELECT Id, Dispatched_Cnt__c FROM DriverSchedule__c ORDER BY Date__c DESC LIMIT 1];
        Assert.areEqual(dispatchedCnt + 1, ds1.Dispatched_Cnt__c); //「配車済件数」の変更を確認
    }
}