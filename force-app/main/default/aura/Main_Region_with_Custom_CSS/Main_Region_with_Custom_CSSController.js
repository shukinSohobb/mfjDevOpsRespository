({
  doInit: function (component, event, helper) {
		window.setTimeout(function() {
			let pageHeader = document.querySelector('.flexipageHeader'); // pageHeaderがnullになって消せない
			console.log('pageHeader:', pageHeader);
			if (pageHeader) {
				pageHeader.style.display = 'none';
			}
		},1000);
	}
})