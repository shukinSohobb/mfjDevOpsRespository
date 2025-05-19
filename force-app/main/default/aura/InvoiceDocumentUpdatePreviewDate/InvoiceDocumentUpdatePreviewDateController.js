({
    handleInit : function(component, event, helper) {
		let flow = component.find("flow");
        // フローの入力
        let flowInputVariables = [
            { name: "recordId", type: "String", value: component.get("v.recordId") }
        ];
        // フロー実行
        // フロー：請求書のプレビュー日更新
		flow.startFlow("InvoiceDocumentUpdatePreviewDate", flowInputVariables);
        // SVFのURL
        let url = "/apex/svfcloud__PreviewPage?appId=InvoiceDocument__c&id="+component.get("v.recordId")+"&buttonFullName=SVFInvoiceDocumentcButton20250407054604461Rcn";
        // SVFのPDFプレビュー
        window.location.href = url;
    }    
})