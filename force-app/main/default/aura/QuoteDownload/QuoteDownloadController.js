({
  invoke: function (component, event, helper) {
    //      if (component.get('v.isCooldown')) {
    //  return; // Exit the function if cooldown is active
    //}
      
    //  component.set('v.isCooldown', true);
    var downloadMode = component.get('v.downloadMode');
    let staticResourceName = '';
    let filename = '見積書';
    //let staticResourceURL = $A.get('$Resource.' + staticResourceName);
    let staticResourceURL = 'https://dga000009kouu2ai--demo.sandbox.file.force.com/sfc/servlet.shepherd/document/download/069H4000000NM5TIAW?operationContext=S1';      
    
    var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
      "url": staticResourceURL
    });
    urlEvent.fire();
    //$A.get('e.force:refreshView').fire();
    var recordId = component.get("v.recordId");
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
            "recordId": recordId,
            "slideDevName": "detail"
        });
        navEvt.fire();

      
    //let downloadLink = document.createElement('a');
    //downloadLink.href = staticResourceURL;
    //downloadLink.download = filename;
    //document.body.appendChild(downloadLink);
    //downloadLink.click();
    //document.body.removeChild(downloadLink);
    //setTimeout(function () {
    //  component.set('v.isCooldown', false);
    //}, 1000);
  }
});