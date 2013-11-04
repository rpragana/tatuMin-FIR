angular.module('angular-auth-demo')
  .config(function ($routeProvider, $httpProvider) {
    $httpProvider.defaults.withCredentials = true;
  })
  .controller({
  ContentController: function ($scope, $http) {

    $scope.publicContent = [];
    $scope.restrictedContent = [];

    $scope.publicAction = function() {
      $http.post('/data/public', $scope.publicData).success(function(response) {
        $scope.publicContent.push(response);
      });
    }

    $scope.restrictedAction = function() {
      $http({
		  method: 'POST', 
		  url:'/data/protected', 
		  data: $scope.restrictedData,
		  withCredentials: true}).success(function(response) {
        // this piece of code will not be executed until user is authenticated
        $scope.restrictedContent.push(response);
      });
    }

    $scope.logout = function() {
      $http.post('/auth/logout').success(function() {
        $scope.restrictedContent = [];
      });
    }
  }
  
});

