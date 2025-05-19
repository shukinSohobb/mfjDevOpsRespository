public with sharing class ShippingSalesReportOutputCtrl {
    public Id recordId { get; set; }
    public String errorMessage { get; private set; }
    public Boolean hasError { get; private set; }
    public ShippingSalesReport__c report { get; set; }
    public String formattedDate { get; set; } //日付
    public String formattedWeekday { get; set; } //曜日
    public Integer phase { get; set; } //期
    public Decimal phase1Actual { get; set; } //1期実績
    public Decimal phase2Actual { get; set; } //2期実績
    public Decimal phase3Actual { get; set; } //3期実績
    public Decimal monthActual { get; set; } //当月実績
    public Decimal monthTarget { get; set; } //当月目標
    public Decimal phase1AchievementRate { get; set; } //1期達成率
    public Decimal phase2AchievementRate { get; set; } //2期達成率
    public Decimal phase3AchievementRate { get; set; } //3期達成率
    public Decimal monthAchievementRate { get; set; } //当月達成率
    public Decimal lastYearSameMonthRate { get; set; } //前年同月比
    public Decimal TotalBalance { get; set; } //全体合計(差額)
    public Decimal GeneralBalance { get; set; } //一般(差額)
    public Decimal ChateraiseBalance { get; set; } //シャトレーゼ(差額)
    public Decimal FujiEchoBalance { get; set; } //富士エコー・ローソン(差額)
    public Decimal GeneralSalesPercent { get; set; } //占有率(一般)(売上細目)
    public Decimal ChateraiseSalesPercent { get; set; } //占有率(シャトレーゼ)(売上細目)
    public Decimal FujiEchoSalesPercent { get; set; } //占有率(富士エコー・ローソン)(売上細目)
    public Decimal TotalSalesPercent { get; set; } //占有率(全体合計)(売上細目)
    public Decimal GeneralPaymentPercent { get; set; } //占有率(一般)(下払い金額)
    public Decimal ChateraisePaymentPercent { get; set; } //占有率(シャトレーゼ)(下払い金額)
    public Decimal FujiEchoPaymentPercent { get; set; } //占有率(富士エコー・ローソン)(下払い金額)
    public Decimal TotalPaymentPercent { get; set; } //占有率(全体合計)(下払い金額)
    public Decimal GeneralBalancePercent { get; set; } //占有率(一般)(差額)
    public Decimal ChateraiseBalancePercent { get; set; } //占有率(シャトレーゼ)(差額)
    public Decimal FujiEchoBalancePercent { get; set; } //占有率(富士エコー・ローソン)(差額)
    public Decimal TotalBalancePercent { get; set; } //占有率(全体合計)(差額)

    private Integer year;
    public Integer month { get; set; }
    private Integer day;

    public ShippingSalesReportOutputCtrl(ApexPages.StandardController controller) {
        try {
            this.hasError = false;
            this.recordId = ApexPages.currentPage().getParameters().get('id');
            Date outputDay = Date.today();
            if (String.isNotBlank(recordId)) {
                List<ShippingSalesReport__c> report = [
                    SELECT Id, Date__c
                    FROM ShippingSalesReport__c
                    WHERE Id = :this.recordId
                    LIMIT 1
                ];
                if (!report.isEmpty()) {
                    outputDay = report[0].Date__c;
                }
            }

            String formattedDate = String.valueOf(outputDay).replace('-', '') + '_' + System.now().format('yyyyMMddHHmmss');
            String encodedFileName = EncodingUtil.urlEncode('日報売上実績表_' + formattedDate + '.pdf', 'UTF-8');
            String contentDispositionHeader = 'inline; filename*=UTF-8\'\'' + encodedFileName;
            ApexPages.currentPage().getHeaders().put('content-disposition', contentDispositionHeader);
        } catch (Exception ex) {
            this.hasError = true;
            errorMessage = '処理中に予期しないエラーが発生しました。<br/>お手数ですが、システム管理者までご連絡をお願いいたします。';
        }
    }

    public PageReference init() {
        try {
            if (this.hasError) {
                BulkProcessLog__c processLog = new BulkProcessLog__c(
                    ProcessSubject__c = '運送売上実績表PDF出力時エラー発生通知',
                    ProcessDetails__c = errorMessage,
                    ProcessStatus__c = 'Error',
                    ProcessType__c = 'ShippingSalesReportOutputCtrl',
                    ToEmailGroupAddresses__c = 'SystemGroup'
                );
                insert processLog;
                return null;
            }
            if (String.isNotBlank(recordId)) {
                List<ShippingSalesReport__c> reportList = [
                    SELECT
                        Id,
                        Name,
                        Date__c, //日付
                        GeneralSales_F__c, //一般(売上細目)
                        ChateraiseSales__c, //シャトレーゼ(売上細目)
                        FujiEchoSales_F__c, //富士エコー・ローソン(売上細目)
                        TotalSales_F__c, //全体合計(売上細目)
                        TotalSubcontractorSales_F__c, //全体合計(下払い金額)
                        GeneralSalesSubcontractorSales_F__c, //一般(下払い金額)
                        ChateraiseSubcontractorSales__c, //シャトレーゼ(下払い金額)
                        FujiEchoCharteredVehicleSubcontractSales__c, //富士エコー・ローソン(下払い金額)
                        ObjectiveManagement__r.FirstTermSalesTarget__c, //第1期目標
                        ObjectiveManagement__r.SecondTermSalesTarget__c, //第2期目標
                        ObjectiveManagement__r.ThirdTermSalesTarget__c, //第3期目標
                        ObjectiveManagement__r.SameMonthLastYearTotalSales_F__c //前年同月実績
                    FROM ShippingSalesReport__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                if (!reportList.isEmpty()) {
                    report = reportList[0];
                    if (report.Date__c != null) {
                        year = report.Date__c.year();
                        month = report.Date__c.month();
                        day = report.Date__c.day();
                        phase = getPhase(report.Date__c);
                        formattedDate = year + '年' + month + '月' + day + '日';
                        Datetime dt = (Datetime) report.Date__c;
                        String dayOfWeek = dt.format('u');
                        formattedWeekday = weekdayMap.get(Integer.valueOf(dayOfWeek)); //曜日
                        TotalBalance = report.TotalSales_F__c - report.TotalSubcontractorSales_F__c; //全体合計(差額)

                        GeneralBalance = report.GeneralSales_F__c - report.GeneralSalesSubcontractorSales_F__c; //一般(差額)
                        ChateraiseBalance = report.ChateraiseSales__c - report.ChateraiseSubcontractorSales__c; //シャトレーゼ(差額)
                        FujiEchoBalance = report.FujiEchoSales_F__c - report.FujiEchoCharteredVehicleSubcontractSales__c; //富士エコー・ローソン(差額)

                        GeneralSalesPercent = calculatePercentage(report.GeneralSales_F__c, report.TotalSales_F__c); //占有率(一般)(売上細目)
                        ChateraiseSalesPercent = calculatePercentage(report.ChateraiseSales__c, report.TotalSales_F__c); //占有率(シャトレーゼ)(売上細目)
                        FujiEchoSalesPercent = calculatePercentage(report.FujiEchoSales_F__c, report.TotalSales_F__c); //占有率(富士エコー・ローソン)(売上細目)
                        TotalSalesPercent = GeneralSalesPercent + ChateraiseSalesPercent + FujiEchoSalesPercent; //占有率(全体合計)(売上細目)

                        GeneralPaymentPercent = calculatePercentage(
                            report.GeneralSalesSubcontractorSales_F__c,
                            report.TotalSubcontractorSales_F__c
                        ); //占有率(一般)(下払い金額)
                        ChateraisePaymentPercent = calculatePercentage(
                            report.ChateraiseSubcontractorSales__c,
                            report.TotalSubcontractorSales_F__c
                        ); //占有率(シャトレーゼ)(下払い金額)
                        FujiEchoPaymentPercent = calculatePercentage(
                            report.FujiEchoCharteredVehicleSubcontractSales__c,
                            report.TotalSubcontractorSales_F__c
                        ); //占有率(富士エコー・ローソン)(下払い金額)
                        TotalPaymentPercent = GeneralPaymentPercent + ChateraisePaymentPercent + FujiEchoPaymentPercent; //占有率(全体合計)(下払い金額)

                        GeneralBalancePercent = calculatePercentage(GeneralBalance, TotalBalance); //占有率(一般)(差額)
                        ChateraiseBalancePercent = calculatePercentage(ChateraiseBalance, TotalBalance); //占有率(シャトレーゼ)(差額)
                        FujiEchoBalancePercent = calculatePercentage(FujiEchoBalance, TotalBalance); //占有率(富士エコー・ローソン)(差額)
                        TotalBalancePercent = GeneralBalancePercent + ChateraiseBalancePercent + FujiEchoBalancePercent; //占有率(全体合計)(差額)

                        phase1Actual = getPhaseActual(1, year, month); //1期実績
                        phase2Actual = getPhaseActual(2, year, month); //2期実績
                        phase3Actual = getPhaseActual(3, year, month); //3期実績
                        monthActual = getPhaseActual(0, year, month); //今月売上実績
                        monthTarget =
                            report.ObjectiveManagement__r.FirstTermSalesTarget__c +
                            report.ObjectiveManagement__r.SecondTermSalesTarget__c +
                            report.ObjectiveManagement__r.ThirdTermSalesTarget__c;
                        phase1AchievementRate = calculatePercentage(
                            phase1Actual,
                            report.ObjectiveManagement__r.FirstTermSalesTarget__c
                        );
                        phase2AchievementRate = calculatePercentage(
                            phase2Actual,
                            report.ObjectiveManagement__r.SecondTermSalesTarget__c
                        );
                        phase3AchievementRate = calculatePercentage(
                            phase3Actual,
                            report.ObjectiveManagement__r.ThirdTermSalesTarget__c
                        );
                        monthAchievementRate = calculatePercentage(monthActual, monthTarget);
                        lastYearSameMonthRate = calculatePercentage(
                            monthActual,
                            report.ObjectiveManagement__r.SameMonthLastYearTotalSales_F__c
                        );
                    }
                }
            }
        } catch (Exception ex) {
            this.hasError = true;
            BulkProcessLog__c processLog = new BulkProcessLog__c(
                ProcessSubject__c = '運送売上実績表PDF出力時エラー発生通知',
                ProcessDetails__c = ex.getMessage() + ' ' + ex.getStackTraceString(),
                ProcessStatus__c = 'Error',
                ProcessType__c = 'ShippingSalesReportOutputCtrl',
                ToEmailGroupAddresses__c = 'SystemGroup'
            );
            errorMessage = '処理中に予期しないエラーが発生しました。<br/>お手数ですが、システム管理者までご連絡をお願いいたします。';
            insert processLog;
        }
        return null;
    }

    private static Map<Integer, String> weekdayMap = new Map<Integer, String>{
        1 => '月曜日',
        2 => '火曜日',
        3 => '水曜日',
        4 => '木曜日',
        5 => '金曜日',
        6 => '土曜日',
        7 => '日曜日'
    };

    /**
     * 期を取得
     * @param 日付
     * @return 期のNo.
     */
    public static Integer getPhase(Date reportDate) {
        Integer day = reportDate.day();

        Date firstOfNextMonth = reportDate.addMonths(1).toStartOfMonth();
        Date lastOfCurrentMonth = firstOfNextMonth.addDays(-1);
        Integer daysInMonth = lastOfCurrentMonth.day();

        if (day >= 1 && day <= 10) {
            return 1;
        } else if (day >= 11 && day <= 20) {
            return 2;
        } else if (day >= 21 && day <= daysInMonth) {
            return 3;
        }

        return null;
    }

    /**
     * 実績を取得
     * 対象オブジェクト：運送売上日報
     * @param phaseNumber:〇期実績
     * @param year:対象年
     * @param month:対象月
     * @return 実績
     */

    public static Decimal getPhaseActual(Integer phaseNumber, Integer year, Integer month) {
        Date startDate;
        Date endDate;

        Date lastDayOfMonth = Date.newInstance(year, month, 1).toStartOfMonth().addMonths(1).addDays(-1);

        if (phaseNumber == 1) {
            startDate = Date.newInstance(year, month, 1);
            endDate = Date.newInstance(year, month, 10);
        } else if (phaseNumber == 2) {
            startDate = Date.newInstance(year, month, 11);
            endDate = Date.newInstance(year, month, 20);
        } else if (phaseNumber == 3) {
            startDate = Date.newInstance(year, month, 21);
            endDate = lastDayOfMonth;
        } else if (phaseNumber == 0) {
            startDate = Date.newInstance(year, month, 1);
            endDate = lastDayOfMonth;
        } else {
            return 0;
        }

        AggregateResult[] results = [
            SELECT SUM(TotalSales_F__c) TotalSales
            FROM ShippingSalesReport__c
            WHERE Date__c >= :startDate AND Date__c <= :endDate
        ];
        Decimal totalActual = (results.size() > 0 &&
            results[0].get('TotalSales') != null)
            ? (Decimal) results[0].get('TotalSales')
            : 0;
        return totalActual != null ? totalActual : 0;
    }

    //パーセント計算
    public static Decimal calculatePercentage(Decimal numerator, Decimal denominator) {
        if (denominator == null || denominator == 0) {
            return 0;
        }

        Decimal percentage = (numerator / denominator) * 100;

        return percentage.setScale(1, RoundingMode.HALF_UP);
    }

    @AuraEnabled
    public static String getPdfPreviewUrl(Id recordId) {
        try {
            PageReference pdfPage = Page.ShippingSalesReportOutput;
            pdfPage.getParameters().put('id', recordId);
            return pdfPage.getUrl();
        } catch (Exception ex) {
            BulkProcessLog__c processLog = new BulkProcessLog__c(
                ProcessSubject__c = '運送売上実績表PDF出力時エラー発生通知',
                ProcessDetails__c = ex.getMessage() + ' ' + ex.getStackTraceString(),
                ProcessStatus__c = 'Error',
                ProcessType__c = 'ShippingSalesReportOutputCtrl',
                ToEmailGroupAddresses__c = 'SystemGroup'
            );

            insert processLog;
            throw new AuraHandledException(
                '処理中に予期しないエラーが発生しました。<br/>お手数ですが、システム管理者までご連絡をお願いいたします。'
            );
        }
    }

    @AuraEnabled
    public static void uploadPdfToRecord(Id recordId, String pdfUrl) {
        try {
            PageReference pdfPage = Page.ShippingSalesReportOutput;
            pdfPage.getParameters().put('id', recordId);

            Blob pdfBlob;
            if (Test.isRunningTest()) {
                pdfBlob = Blob.valueOf('Dummy PDF Content');
            } else {
                pdfBlob = pdfPage.getContentAsPDF();
            }

            Date outputDay = Date.today();
            if (String.isNotBlank(recordId)) {
                List<ShippingSalesReport__c> report = [
                    SELECT Id, Date__c
                    FROM ShippingSalesReport__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                if (!report.isEmpty()) {
                    outputDay = report[0].Date__c;
                }
            }
            String formattedDate = String.valueOf(outputDay).replace('-', '') + '_' + System.now().format('yyyyMMddHHmmss');
            String fileName = '日報売上実績表_' + formattedDate + '.pdf';

            ContentVersion cv = new ContentVersion();
            cv.Title = filename;
            cv.PathOnClient = filename;
            cv.VersionData = pdfBlob;
            cv.IsMajorVersion = true;
            insert cv;

            cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = recordId;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
        } catch (Exception ex) {
            BulkProcessLog__c processLog = new BulkProcessLog__c(
                ProcessSubject__c = '運送売上実績表PDF出力時エラー発生通知',
                ProcessDetails__c = ex.getMessage() + ' ' + ex.getStackTraceString(),
                ProcessStatus__c = 'Error',
                ProcessType__c = 'ShippingSalesReportOutputCtrl',
                ToEmailGroupAddresses__c = 'SystemGroup'
            );

            insert processLog;
            throw new AuraHandledException(
                '処理中に予期しないエラーが発生しました。<br/>お手数ですが、システム管理者までご連絡をお願いいたします。'
            );
        }
    }
}