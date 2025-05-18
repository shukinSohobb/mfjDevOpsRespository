@isTest
private class ShippingSalesReportOutputCtrl_T {
    @TestSetup
    static void createData() {
        ObjectiveManagement__c objectiveManagement = new ObjectiveManagement__c();
        objectiveManagement.Name = 'test';
        objectiveManagement.TargetMonth__c = Date.today().toStartOfMonth();
        objectiveManagement.FirstTermSalesTarget__c = 100000;
        objectiveManagement.SecondTermSalesTarget__c = 200000;
        objectiveManagement.ThirdTermSalesTarget__c = 300000;
        objectiveManagement.SameMonthLastYearTotalSales__c = 200000;
        objectiveManagement.SameMonthLastYearTotalSubcontractorSales__c = 100000;

        insert objectiveManagement;

        ShippingSalesReport__c report = new ShippingSalesReport__c();
        report.Date__c = Date.today();
        report.MARUSMfjVehicleSales__c = 300000;
        report.ChateraiseSales__c = 100000;
        report.FujiEchoMfjVehicleSales__c = 100000;
        report.CharteredVehicleSales__c = 100000;
        report.FujiEchoCharteredVehicleSales__c = 50000;
        report.ChateraiseSubcontractorSales__c = 50000;
        report.CharteredVehicleSubcontractorSales__c = 100000;
        report.FujiEchoCharteredVehicleSubcontractSales__c = 50000;
        report.ObjectiveManagement__c = objectiveManagement.Id;

        insert report;
    }

    @isTest
    static void testMethod1() {
        Test.startTest();

        ShippingSalesReport__c report = [SELECT Id FROM ShippingSalesReport__c WHERE Date__c = :Date.today() LIMIT 1];

        PageReference pageRef = Page.ShippingSalesReportOutput;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', report.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(new ShippingSalesReport__c());

        ShippingSalesReportOutputCtrl controller = new ShippingSalesReportOutputCtrl(sc);
        controller.Init();
        String pdfUrl = ShippingSalesReportOutputCtrl.getPdfPreviewUrl(report.Id);
        ShippingSalesReportOutputCtrl.uploadPdfToRecord(report.Id, pdfUrl);

        Test.stopTest();
    }

    @isTest
    static void testMethod2() {
        Test.startTest();

        ObjectiveManagement__c objectiveManagement = [
            SELECT Id, FirstTermSalesTarget__c
            FROM ObjectiveManagement__c
            WHERE TargetMonth__c = :Date.today().toStartOfMonth()
            LIMIT 1
        ];
        objectiveManagement.FirstTermSalesTarget__c = null;
        update objectiveManagement;

        ShippingSalesReport__c report = [SELECT Id FROM ShippingSalesReport__c WHERE Date__c = :Date.today() LIMIT 1];

        PageReference pageRef = Page.ShippingSalesReportOutput;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', report.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(new ShippingSalesReport__c());

        ShippingSalesReportOutputCtrl controller = new ShippingSalesReportOutputCtrl(sc);
        controller.Init();
        String pdfUrl = ShippingSalesReportOutputCtrl.getPdfPreviewUrl(report.Id);
        ShippingSalesReportOutputCtrl.uploadPdfToRecord(report.Id, pdfUrl);

        Test.stopTest();
    }
}