@isTest
public class GetTargetTermDateHandler_T {
    // 「15日」の締日の期制の開始日を取得
    @isTest
    public static void getTargetTermDate_15TermCycleStart() {
        Date today = Date.newInstance(2025, 3, 15);
        String stringDate = String.valueOf(today);
        Test.startTest();
        List<Date> dateList = GetTargetTermDateHandler.getTargetTermDate(
            new List<String>{ stringDate + ';MONTH_15;TermCycleStart' }
        );
        Test.stopTest();
        Assert.areEqual(1, dateList.size());
        Assert.areEqual(Date.newInstance(2025, 2, 16), dateList[0]);
    }

    // 「15日」の締日の期制の終了日を取得
    @isTest
    public static void getTargetTermDate_15TermCycleEnd() {
        Date today = Date.newInstance(2025, 2, 16);
        String stringDate = String.valueOf(today);
        Test.startTest();
        List<Date> dateList = GetTargetTermDateHandler.getTargetTermDate(
            new List<String>{ stringDate + ';MONTH_15;TermCycleEnd' }
        );
        Test.stopTest();
        Assert.areEqual(1, dateList.size());
        Assert.areEqual(Date.newInstance(2025, 3, 15), dateList[0]);
    }

    // 「15日」の締日の期の開始日を取得
    @isTest
    public static void getTargetTermDate_15TermStart() {
        Date today = Date.newInstance(2025, 2, 5);
        String stringDate = String.valueOf(today);
        Test.startTest();
        List<Date> dateList = GetTargetTermDateHandler.getTargetTermDate(
            new List<String>{ stringDate + ';MONTH_15;TermStart' }
        );
        Test.stopTest();
        Assert.areEqual(1, dateList.size());
        Assert.areEqual(Date.newInstance(2025, 1, 26), dateList[0]);
    }

    // 「15日」の締日の期の終了日を取得
    @isTest
    public static void getTargetTermDate_15TermEnd() {
        Date today = Date.newInstance(2025, 2, 26);
        String stringDate = String.valueOf(today);
        Test.startTest();
        List<Date> dateList = GetTargetTermDateHandler.getTargetTermDate(
            new List<String>{ stringDate + ';MONTH_15;TermEnd' }
        );
        Test.stopTest();
        Assert.areEqual(1, dateList.size());
        Assert.areEqual(Date.newInstance(2025, 3, 5), dateList[0]);
    }

    // 無効なパラメータの場合、NULLを取得
    @isTest
    public static void getTargetTermDate_invalidNull() {
        Test.startTest();
        List<Date> dateList = GetTargetTermDateHandler.getTargetTermDate(
            new List<String>{ '日付じゃない;MONTH_15;TermEnd' }
        );
        Test.stopTest();
        Assert.areEqual(1, dateList.size());
        Assert.areEqual(null, dateList[0]);
    }
}