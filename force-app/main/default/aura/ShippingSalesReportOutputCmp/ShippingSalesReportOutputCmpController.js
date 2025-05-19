({
    doInit: function(component, event, helper) {
        try{
            var action = component.get("c.getPdfPreviewUrl");
            action.setParams({
                recordId: component.get("v.recordId")
            });

            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var pdfUrl = response.getReturnValue();
                    component.set("v.pdfUrl", pdfUrl);
                    component.set("v.hasError", false);
                } else {
                    let message = '処理中に予期しないエラーが発生しました。お手数ですが、システム管理者までご連絡をお願いいたします。';
                    component.set("v.hasError", true);
                    component.set("v.errorMessage", message);
                }
            });

            $A.enqueueAction(action);

        }catch(e){
            let message = '処理中に予期しないエラーが発生しました。お手数ですが、システム管理者までご連絡をお願いいたします。';
            component.set("v.hasError", true);
            component.set("v.errorMessage", message);
        }
        
    },

    uploadPdf: function(component, event, helper) {
        try{
                var action = component.get("c.uploadPdfToRecord");
                action.setParams({
                    recordId: component.get("v.recordId"),
                    pdfUrl: component.get("v.pdfUrl")
                });

                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        component.set("v.hasError", false);
                        alert('Salesforce Filesへのアップロード処理が完了しました。');
                    } else {
                        let message = '処理中に予期しないエラーが発生しました。お手数ですが、システム管理者までご連絡をお願いいたします。';
                        component.set("v.hasError", true);
                        component.set("v.errorMessage", message);
                    } 
                    });

                $A.enqueueAction(action);
            }
            catch(e){
                let message = '処理中に予期しないエラーが発生しました。お手数ですが、システム管理者までご連絡をお願いいたします。';
                component.set("v.hasError", true);
                component.set("v.errorMessage", message);
                }
        }
        
        
})