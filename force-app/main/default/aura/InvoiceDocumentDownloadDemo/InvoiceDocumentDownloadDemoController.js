({
  invoke: function (component, event, helper) {
          if (component.get('v.isCooldown')) {
      return; // Exit the function if cooldown is active
    }
      component.set('v.isCooldown', true);

    let staticResourceName = 'InvoiceDocumentSamplePDF';
    let filename = '請求書';

    let staticResourceURL = $A.get('$Resource.' + staticResourceName);
    //let url = 'https://dga000009kouu2ai--dev--c.sandbox.vf.force.com/resource/1741771818000/InvoiceDocumentSamplePDF?';

    let downloadLink = document.createElement('a');
    downloadLink.href = staticResourceURL;
    downloadLink.download = filename;
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
    setTimeout(function () {
      component.set('v.isCooldown', false);
    }, 1000);
  }
});