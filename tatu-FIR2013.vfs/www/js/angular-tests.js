  //console.log('Output from a script...');
    var myapp = angular.module('myApp',[])
    .controller('ExampCtrl',function($scope){
        $scope.name = "Rildo Pragana";
        $scope.inputvar = "conteúdo";
        $scope.agenda = [{
            nome: "Rildo Pragana",
            fone: "9517-4422"
        },
        {
            nome: "Daniel Pragana",
            fone: "9835-4167"
        },
        {
            nome: "Fernanda W. Pragana",
            fone: "9772-9650"
        }
        ]
    })
    .controller('funcsCtrl',function($scope,$http){
		var url = "/log?cmd=eval&input=concat "
			+" [info procs logger::*] [info procs ::tatu::*]";
		$scope.url = url;
		$http.get(url).success(function(data){
			$scope.data = data;
			$scope.procList = data.answer.split(" ");
			//console.log($scope.procList);
		})
		.error(function(){
			console.log("error http");
		});
		$scope.$watch('watchedvar', function(newVal, oldVal) {
			console.log("|"+oldVal+"|-->|"+newVal+"|");
		});
	})
	.directive('compileCheck', function() {
		return {
			restrict: 'A',
			compile: function(tElement, tAttrs) {
			tElement.append('Added during compilation phase!');
		}
	};
	})
	// Similar to $(document).ready() in jQuery
	.run(function($rootScope) {
		$rootScope.header = 'I am bound to rootScope';
	})
	.controller('DemoCtrl', function($scope) {
		$scope.footer = 'I am bound to DemoCtrl';
	})
	.directive('whoiam', function($http) {
		return {
			restrict: 'A',
			template: '{{header}}<div class="thumbnail" style="width: 80px;"><div><img ng-src="{{data.owner.avatar_url}}"/></div><div class="caption"><p>{{data.name}}</p></div></div>{{footer}}',
			link: function(scope, element, attrs) {
				$http.get('https://api.github.com/repos/angular/angular.js').success(function(data) {
					scope.data = data;
				});
			}
		};
	})
	.filter('reverse',function(){
		return function(text) {
			return "["+text.split("").reverse().join("")+"]";
		}
	})
	.controller('FirstCtrl',function($scope,SharedData){
		// first controller
		$scope.data = SharedData;
	})
	.controller('SecondCtrl',function($scope,SharedData){
		// second controller
		$scope.data = SharedData;
		$scope.reversedMessage = function(){
			return $scope.data.msg.split("").reverse().join("");
		}
	})
	.factory('SharedData',function(){
		return {msg: "I'm shared data"};
	});
	
