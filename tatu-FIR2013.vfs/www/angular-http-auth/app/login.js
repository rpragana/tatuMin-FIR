angular.module('angular-auth-demo').controller({
  LoginController: function ($scope, $http, authService) {
    $scope.submit = function() {
      $http({
		  method: 'POST',
		  url: '/auth/login',
		  withCredentials: true})      
      .success(function() {
        authService.loginConfirmed();
      });
    }
  }
  
});

//Cookie functions

function createCookie(name, value) {
	//All cookies are session cookies that expire as soon as the browser is closed.
    document.cookie = name + "=" + value + "; path=/";
}

function readCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
    }
    return null;
}

function eraseCookie(name) {
	//Since all cookies are session cookies, we only need to remove the data.
    createCookie(name, "");
}
