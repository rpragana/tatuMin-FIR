
$(document).ready(function(){
	/*var auction = {};
	auction.title = "Exemplo de leilão"
	auction.endingSoon = true;
	auction.currentBid = 123.45;
	auction.remaining = 15;

	rivets.configure({
  		adapter: {
    		subscribe: function(obj, keypath, callback) {
      			//obj.on('change:' + keypath, callback);
    		},
    		unsubscribe: function(obj, keypath, callback) {
      			//obj.off('change:' + keypath, callback);
    		},
    		read: function(obj, keypath) {
      			//return obj.get(keypath);
    		},
    		publish: function(obj, keypath, value) {
      			//obj.set(keypath, value);
    		}
  		}
	});
	rivets.bind($('#auction'), {auction: auction})
*/

	var book = {
		title:'Awesome Book Title',
		available: true,
		cost:'$5.15'
	};

    rivets.bind(document.getElementById('book'), {book: book})

// -------------------------------------------------------------

// CONFIGURE RIVETS.JS WITH BACKBONE.JS

rivets.configure({
  adapter: {
    subscribe: function(obj, keypath, callback) {
      callback.wrapped = function(m, v) { callback(v) };
      obj.on('change:' + keypath, callback.wrapped);
    },
    unsubscribe: function(obj, keypath, callback) {
      obj.off('change:' + keypath, callback.wrapped);
    },
    read: function(obj, keypath) {
      return obj.get(keypath);
    },
    publish: function(obj, keypath, value) {
      obj.set(keypath, value);
    }
  }
});

// BINDING BACKBONE.JS MODEL(S) TO A VIEW

var user = new Backbone.Model({name: 'Joe'});
var el = document.getElementById('user-view');

rivets.bind(el, {user: user});

});

// ----------- dermis js tests

// var example = (function() {
//   var User, todd,
//     __hasProp = {}.hasOwnProperty,
//     __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };
// 
//   User = (function(_super) {
// 
//     __extends(User, _super);
// 
//     function User() {
//       return User.__super__.constructor.apply(this, arguments);
//     }
// 
//     User.prototype.urls = {
//       create: function() {
//         return "/users";
//       },
//       read: function() {
//         return "/users/" + (this.get('id'));
//       },
//       update: function() {
//         return "/users/" + (this.get('id'));
//       },
//       destroy: function() {
//         return "/users/" + (this.get('id'));
//       }
//     };
// 
//     User.prototype.run = function() {
//       return console.log("Running!");
//     };
// 
//     User.prototype.walk = function() {
//       return console.log("Walking...");
//     };
// 
//     User.prototype.move = function() {
//       if (this.get('indoors')) {
//         return this.walk();
//       } else {
//         return this.run();
//       }
//     };
// 
//     return User;
// 
//   })(dermis.Model);
// 
//   todd = new User({
//     nome: 'Todd',
//     id: 1
//   });
// 
//   todd.set('indoors', true);
// 
//   todd.move();
// 
//   todd.set('indoors', false);
// 
//   todd.move();
// 
//   return {User: User, todd: todd};
// }).call(this);



// ---- TESTS with AngularJS ----
 
var app = angular.module("rpApp",['ui.bootstrap'])
	.controller("ListCtrl",function($scope){
		$scope.val = 1234567.89;
		$scope.people = [
			{nome: "Rildo", idade:"62"},
			{nome: "Daniel", idade:"12"},
			{nome: "Julius", idade:"35"}
		];
		$scope.add = function(){
			$scope.people.push({
				nome: $scope.novo_nome,
				idade: $scope.nova_idade
			});
			$scope.novo_nome = "";
			$scope.nova_idade = "";
		};
		$scope.delete = function($index){
			$scope.people.splice($index,1);	
		};
	});

var MyCtrl = function ($scope) {
	$scope.clear = function(){
		$scope.name = "";
	};
};


var Filetree = function($scope, $http){
	$http.get('/filetree?type=json')
		.success(function(data,status,headers,config){
			//alert(data);
			$scope.files = data;
	});
//	$http({
//		url: '/filetree',
//		method: 'GET'
//		params: {}
//	}).success(function(data,status,headers,config){
//		alert(data);
//		$scope.files = data;
//	});
};

var GithubController = function($scope, $http) {
//    $http.get('https://api.github.com/repos/rpragana/tatu/commits')
    $http.get('https://api.github.com/repos/angular/angular.js/commits')
      .success(function(commits) {
//        $scope.commits = commits;
        $scope.commits = commits.slice(0,8); /* 8 first elements */
//		$scope.project = "Tatu";
		$scope.project = "AngularJS";
//		$scope.baseLink = "https://github.com/rpragana/Tatu/commit/";
		$scope.baseLink = "https://github.com/angular/angular.js/commit/";

      });
};

var AccordionDemoCtrl = function($scope) {
  $scope.oneAtATime = true;

  $scope.groups = [
    {
      title: "Dynamic Group Header - 1",
      content: "Dynamic Group Body - 1"
    },
    {
      title: "Dynamic Group Header - 2",
      content: "Dynamic Group Body - 2"
    }
  ];

  $scope.items = ['Item 1', 'Item 2', 'Item 3'];

  $scope.addItem = function() {
    var newItemNo = $scope.items.length + 1;
    $scope.items.push('Item ' + newItemNo);
  };
}

/* tabs directive */

app.directive('tabs', function() {
    return {
        restrict: 'E',
        transclude: true,
        scope: {},
        controller: function($scope, $element) {
            var panes = $scope.panes = [];

            $scope.select = function(pane) {
                angular.forEach(panes, function(pane) {
                    pane.selected = false;
                });

                pane.selected = true;
            }

            this.addPane = function(pane) {
                if (panes.length == 0)
                    $scope.select(pane);

                panes.push(pane);
            }
        },
        template:
        '<div class="tabbable">' +
        '<ul class="nav nav-tabs">' +
        '<li ng-repeat="pane in panes" ng-class="{active:pane.selected}">'+
        '<a href="" ng-click="select(pane)">{{pane.title}}</a>' +
        '</li>' +
        '</ul>' +
        '<div class="tab-content" ng-transclude></div>' +
        '</div>',
        replace: true
    };
});

app.directive('pane', function() {
    return {
        require: '^tabs',
        restrict: 'E',
        transclude: true,
        scope: { title: '@' },
        link: function(scope, element, attrs, tabsCtrl) {
            tabsCtrl.addPane(scope);
        },
        template:
        '<div class="tab-pane" ng-class="{active: selected}" ng-transclude>' +
        '</div>',
        replace: true
    };
});

/****** simple directive for testing *****/
app.directive('angular', function() {
  return {
    restrict: 'A',
    link: function(scope, element, attrs) {
      var img = document.createElement('img');
      img.src = 'http://goo.gl/ceZGf';
      element[0].appendChild(img);           
    }
  };
});

app.controller('tdirecCtrl',function($scope){
	$scope.tname = "Rildo";
});

app.directive('tdirec',function($http,$scope){
	return {
		restrict: 'AE',
		template: '<p></p>',
		link: function(scope,elem,attrs){
			alert('tdirec:');
			//scope.msg = $scope.tname;
		}
	}
});


app.directive('whoiam', function($http,$log) {
  return {
    restrict: 'A',
	templateUrl: "partials/whoiam.html",
    link: function(scope, element, attrs) {
      $http.get('https://api.github.com/repos/angular/angular.js').success(function(data) {
//      $http.get('https://api.github.com/repos/rpragana/tatu').success(function(data) {
        scope.data = data;
        $log.log(JSON.stringify(data));
      });
    }
  };
});


/*
app.directive('whoiam', function($http,$log) {
  return {
    restrict: 'A',
    template: '{{header}}<div class="thumbnail" style="width: 80px;"><div><img ng-src="{{data.owner.avatar_url}}"/></div><div class="caption"><p>{{data.name}}</p></div></div>{{footer}}',
    link: function(scope, element, attrs) {
//      $http.get('https://api.github.com/repos/angular/angular.js').success(function(data) {
      $http.get('https://api.github.com/repos/rpragana/tatu').success(function(data) {
        scope.data = data;
        $log.log(JSON.stringify(data));
      });
    }
  };
});
*/


/*
app.controller('direc2testCtrl',function($scope){
	$scope.name = "";
});
app.directive('direc2testDirective',function(){
	return {
		require: 'ngModel',
		link: function(scope,elem,attrs,ngModel){
			scope.$watch(function(){
				return ngModel.$modelValue;
			}, function(v) {
				elem.parent().append('<pre>'+v+'</pre>');
			});
		}
	}
});
*/

app.controller("widgetCtrl",function($scope){
	$scope.visible = true;
});
app.directive("myWidget", function() {
	return {
		/*template: "<p>{{text}}</p>",*/
		templateUrl: "partials/widget1.html",
		/*replace: true,*/
		link: function(scope, element, attributes) {
			scope.$watch(attributes.show, function(value){
				element.css('display', value ? '' : 'none');
			});
			scope.text = attributes["myWidget"];
		}
	};
});

//service style, probably the simplest one
app.service('helloWorldFromService', function() {
    this.sayHello = function() {
        return "Hello, World!"
    };
});

//factory style, more involved but more sophisticated
app.factory('helloWorldFromFactory', function() {
    return {
        sayHello: function() {
            return "Hello, World!"
        }
    };
});
    
//provider style, full blown, configurable version     
app.provider('helloWorld', function() {

    this.name = 'Default';

    this.$get = function() {
        var name = this.name;
        return {
            sayHello: function() {
                return "Hello, " + name + "!"
            }
        }
    };

    this.setName = function(name) {
        this.name = name;
    };
});

//hey, we can configure a provider!            
app.config(function(helloWorldProvider){
    helloWorldProvider.setName('World');
});
        

app.controller('ComparingCtrl',function ($scope, helloWorld, helloWorldFromFactory, helloWorldFromService) {
    $scope.hellos = [
        helloWorld.sayHello(),
        helloWorldFromFactory.sayHello(),
        helloWorldFromService.sayHello()];
});


app.directive('fileUpload', function () {
	return {
		restrict: 'EA',
		template: '<span>' +
			'<label>Upload file</label>' +
			'<input type="file" onchange="angular.element(this).scope().setFile(this)">' +
			'<button class="btn btn-primary" ng-click="uploadFile()">Send</button>'+
			'</span>',
		replace: true,
		controller: function ($scope) { 
			$scope.setFile = function (elem) {
					$scope.inputField = elem;
					$scope.file = elem.files[0];
				}; 
			$scope.uploadFile = function () {
					var fd = new FormData(), xhr = new XMLHttpRequest();
					fd.append("sentFile", $scope.file);
					xhr.open("POST", "/testUpload");
					xhr.send(fd);
					xhr.addEventListener("load",function(){
						alert(xhr.response);
					},false);
					$scope.inputField.value = "";
				};
		}
	};
});

app.directive('testDraggable', function($document) {
    return function(scope, element, attr) {
      var startX = 0, startY = 0, x = 0, y = 0;
 
      element.css({
	   width: '30%',
	   padding: '10px',
       position: 'relative',
       border: '2px dotted red',
       backgroundColor: '#cfc',
       cursor: 'pointer'
      });
 
      element.on('mousedown', function(event) {
        // Prevent default dragging of selected content
        event.preventDefault();
        startX = event.pageX - x;
        startY = event.pageY - y;
        $document.on('mousemove', mousemove);
        $document.on('mouseup', mouseup);
      });
 
      function mousemove(event) {
        y = event.pageY - startY;
        x = event.pageX - startX;
        element.css({
          top: y + 'px',
          left:  x + 'px'
        });
      }
 
      function mouseup() {
        $document.unbind('mousemove', mousemove);
        $document.unbind('mouseup', mouseup);
      }
    }
});
