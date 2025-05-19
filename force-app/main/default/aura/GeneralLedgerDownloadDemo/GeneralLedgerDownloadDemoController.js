({
  invoke: function (component, event, helper) {
          if (component.get('v.isCooldown')) {
      return; // Exit the function if cooldown is active
    }
      component.set('v.isCooldown', true);

    let staticResourceName = 'GeneralLedgerSamplePDF';
    let filename = '元帳';

    let staticResourceURL = $A.get('$Resource.' + staticResourceName);
    //let url = 'https://dga000009kouu2ai--dev--c.sandbox.vf.force.com/resource/1741756229000/GeneralLedgerSamplePDF';

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