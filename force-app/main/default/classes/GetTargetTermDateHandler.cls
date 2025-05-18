public class GetTargetTermDateHandler {
    @InvocableMethod(label='期制の日付' description='期と期制の開始日と終了日を取得')
    public static List<Date> getTargetTermDate(List<String> args) {
        Date resultDate = null;
        // パラメータが空の場合、処理しない
        if (args.size() > 0 || !String.isBlank(args[0])) {
            try {
                // パラメータの三つの部分を取得：
                // args[0]：日付
                // args[1]：取引先の「締日」
                // args[2]：取得したい日付の種類
                args = args[0].split(';', 3);
                Date targetDate = Date.valueOf(args[0]);
                String closingDate = args[1];
                String resultType = args[2];

                switch on resultType {
                    // 期制の開始日
                    when 'TermCycleStart' {
                        resultDate = MfjUtil.getTargetTermCycleStartDate(targetDate, closingDate);
                    }
                    // 期制の終了日
                    when 'TermCycleEnd' {
                        resultDate = MfjUtil.getTargetTermCycleEndDate(targetDate, closingDate);
                    }
                    // 期の開始日
                    when 'TermStart' {
                        resultDate = MfjUtil.getTargetTermStartDate(targetDate, closingDate);
                    }
                    // 期の終了日
                    when 'TermEnd' {
                        resultDate = MfjUtil.getTargetTermEndDate(targetDate, closingDate);
                    }
                }
            } catch (Exception e) {
                System.debug('期制の日付は取得できなかった：' + e.getStackTraceString());
            }
        }
        List<Date> results = new List<Date>{ resultDate };
        return results;
    }
}