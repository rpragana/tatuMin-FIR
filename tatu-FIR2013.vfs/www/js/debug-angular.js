//
// debug.js - tatu debugger/logger
//
$(function(){
	var srvflags = { sh: false, am: false };
	$('#btn_exit').click(function(){
		$('#log').prepend('<pre class="error">Server exited!</pre>');
		$.getJSON('/log?cmd=eval&input=exit');
	});
	
	$('#btn_reload').click(function(){
		$('#log').prepend('<pre class="error">Reloading plugins</pre>');
		$.getJSON('/log?cmd=eval&input=loadPlugins');
	});
	
	$('#btn_toggleHeaders').click(function(){
		srvflags.sh=!srvflags.sh;
		$(this).toggleClass('active');
		$.getJSON('/log?cmd=toggleHeaders');
	});
	
	$('#btn_toggleModified').click(function(){
		srvflags.am=!srvflags.am;
		$(this).toggleClass('active');
		$.getJSON('/log?cmd=toggleModified');
	});
	
	$('#btn_clear').click(function(){
		$('#logger').html('');
		$('#log').html('');
	});
	
	$('h1:first').click(function(){
		var ed;
		var winH = $(window).height();
		var winW = $(window).width();
		$('#editor').remove();
		$('body').append('<div id="editor"></div>');
		var menuHtml = '<ul id="nav">'+
                '<li><a class="hsubs" href="#">procs 1</a>'+
                    '<ul class="subs">'+
                        '<li><a href="">tefxfer::postBuf</a></li>'+
                        '<li><a href="">tefxfer::ccardRead</a></li>'+
                        '<li><a href="">tefxfer::sendGateway</a></li>'+
                        '<li><a href="">tefxfer::tefxfer</a></li>'+
                        '<li><a href="">tefxfer::connect</a></li>'+
                        '<li><a href="">tefxfer::connectDone</a></li>'+
                    '</ul>'+
                '</li>'+
                '<li><a class="hsubs" href="">procs 2</a>'+
                    '<ul class="subs">'+
                        '<li><a href="">trdata::trdata</a></li>'+
                        '<li><a href="">trdata::tock</a></li>'+
                        '<li><a href="">trdata::tick</a></li>'+
                        '<li><a href="">trdata::tickAnswer</a></li>'+
                        '<li><a href="">trdata::retrieve</a></li>'+
                        '<li><a href="">trdata::putfile</a></li>'+
                        '<li><a href="">trdata::init</a></li>'+
                    '</ul>'+
                '</li>'+
                '<li><a href="">procs 3</a>'+
                    '<ul class="subs">'+
                        '<li><a href="">tefxfer::ccaut</a></li>'+
                        '<li><a href="">tefxfer::ccautRemove</a></li>'+
                        '<li><a href="">trdataToggle</a></li>'+
                        '<li><a href="">chkmemf</a></li>'+
                        '<li><a href="">putbuf</a></li>'+
                    '</ul>'+
                '</li>'+
                '<div id="lavalamp"></div>'+
            '</ul>';
		
		ed=$('#editor').
			html( menuHtml +
					'Proc: <input id="editorProc"></input>'+
					'<button id="editorB0">edita</button><br>'+
					'<textarea contenteditable="true"></textarea>'+
					'<input id="enableInfo" type="password"></input>'+
					'<button id="editorB3">enable info</button>'+
					'<button id="editorB1">salva</button>'+
					'<button id="editorB2">desiste</button>');
		ed.css('top',  winH/2-ed.height()/2);
		ed.css('left', winW/2-ed.width()/2);
		ed.fadeIn(2000);
	});

	$(document).on('click','#nav a',function(){
		var t = $(this).text();
		$('#editorProc').val(t);
		return false;
	});


	$(document).on('click','#editorB0',function(){
		var cmd;
		var pr;
		console.log("click editorB0");
		pr = $('#editorProc').val();
		//cmd = 'set s "proc '+pr+' {[info args '+pr+']} {[info body '+pr+']}"';
		cmd = '::logger::dumpProc '+pr;
		console.log("command:"+cmd);
//		$.getJSON('/log?cmd=eval&format=raw&input='+encodeURIComponent(cmd),
		$.getJSON('/log?cmd=eval&input='+encodeURIComponent(cmd),
						"",function(data,textStatus,xhr){
//			$('#editor textarea').val(decodeURIComponent(data.answer));	
//			$('#editor textarea').val(data);	
			$('#editor textarea').val(data.answer);	
//			$('#editor textarea').val(data.answer);	
		});
	});
	$(document).on('click','#editorB1',function(){
		var cmd;
		cmd = $('#editor textarea').val();	
		$.getJSON('/log?cmd=eval&input='+encodeURIComponent(cmd),
						"",function(data,textStatus,xhr){
			$('#editor').fadeOut(2000);	
		});
	});
	$(document).on('click','#editorB2',function(){
		$('#editor').remove();	
	});
	$(document).on('click','#editorB3',function(){
		var pw=$('#enableInfo').val();
		$.getJSON('/log?cmd=eval&input=reenableInfo+'+pw);
		var pw=$('#enableInfo').val('');
	});

/*	
	var start=0;
	window.setInterval(function() {
		$.getJSON('/log?cmd=readlog&start='+start,"",
			function(data,textStatus,xhr) {
				var log=$('#logger');
				$.each(data, function(index,v){
					log.prepend('<pre class="logger">'+
						v.line+": "+v.msg+'</pre>');
				});
				if (data.length > 0) {
					start=data.pop().line;
				}});
	},500);
*/

	// update counters of events and channels
	window.setInterval(function(){
		$.getJSON('/log?cmd=info',"",
			function(data,textStatus,xhr) {
				$("#katime").text(data.time);
				$("#kaevents").text(data.events);
				$("#kachannels").text(data.channels);
			});
		},997);

	// keep flags on the server the same as local settings
	window.setInterval(function(){
		$.getJSON('/log?cmd=flags',"",
			function(data,textStatus,xhr) {
				if (data.allwaysModified != srvflags.am) {
					$.getJSON('/log?cmd=toggleModified');
				}	
				if (data.showHeaders != srvflags.sh) {
					$.getJSON('/log?cmd=toggleHeaders');
				}	
			});
	},3000);

	var wd = $('body').width();
	var history=[null];
	$('#log pre').css('width',wd);	
	$('#cmd').keydown(function(ev){
		//console.log("shift:"+ev.shiftKey+" which:"+ev.which);
		if (!ev.shiftKey && ev.which == 13) {
			var log=$('#log');
			var cmd=$('#cmd textarea').val();
			if (cmd.length > 0) {
				$.getJSON('/log?cmd=eval&input='+
						encodeURIComponent(cmd),
						"",function(data,textStatus,xhr){
					if (!data.error) {
						history.unshift(cmd);
						log.prepend('<pre class="answer">'+
							data.answer+'</pre>');
						$('#cmd textarea').val("");
					} else {
						log.prepend('<pre class="error">'+
							data.error+'</pre>');
					}
					log.prepend('<pre class="input">'+
						cmd+'</pre>');	
				});
			}
			return false;
		} else if (ev.which == 38) {
			//if (history[0] != null) {
				$('#cmd textarea').val(history[0]);
				history.push(history.shift());
			//}
			return false;
		} else if (ev.which == 40) {
			//if (history[0] != null) {
				$('#cmd textarea').val(history[0]);
				history.unshift(history.pop());
			//}
			return false;
		}
		return true;
	});
}); 

var ngapp = angular.module('debugApp',['ui.bootstrap','http-auth-interceptor']);

ngapp.directive('authApplication', function() {
    return {
      restrict: 'C',
      link: function(scope, elem, attrs) {
        
        var login = elem.find('#login-holder');
        var main = elem.find('#content');
        
        login.hide();
        
        scope.$on('event:auth-loginRequired', function() {
          login.slideDown('slow', function() {
            main.hide();
          });
        });
        scope.$on('event:auth-loginConfirmed', function() {
          login.hide();
          main.show();
        });
      }
    }
  });

/*
ngapp.controller({
	loggerCtrl: function($scope, $timeout, $http, authService) {
		var start=0;
		$scope.log = [];
		var countUp = function() {
			$http.get('/log?cmd=readlog&start='+start)
			.success(function(data){
				//console.log("logCTRL GOT:"+JSON.stringify(data));
				angular.forEach(data,function(item, key){
					$scope.log.unshift(item);
					$scope.log = $scope.log.slice(0,500);
					//console.log("ITEM: "+JSON.stringify(item));
					start++;
				});
				$timeout(countUp, 1000);
			});
		}
		$timeout(countUp, 1000);
	}
});
*/

ngapp.controller('loggerCtrl',function($scope,$timeout,$http){
	var start=0;
	$scope.log = [];
	$scope.name = "";
	var countUp = function() {
		$http.get('/log?cmd=readlog&start='+start)
		.success(function(data){
			$scope.log = data;
			start += data.length;
			$timeout(countUp, 100);
		});
	}
	$timeout(countUp, 100);
});


ngapp.directive('prepender',function(){
	return {
		require: 'ngModel',
		link: function(scope,elem,attrs,ngModel){
			scope.$watch(function(){
				return ngModel.$modelValue;
			}, function(va) {
				angular.forEach(va,function(v,key) {
					elem.prepend('<pre class="logger">'+v.line+': '+v.msg+'</pre>');
				});
			});
		}
	}
});



  
ngapp.filter('reverse', function() {
  return function(items) {
    return items.slice().reverse();
  };
});

ngapp.controller({
  LoginController: function ($scope, $http, authService) {
	$scope.submit = function() {

	var credentials = {
		username: $scope.username,
		password: $scope.password
	};
	var xcred = $.param(credentials);
	// cleanup old cookies
	document.cookie = document.cookie + ";expires=Thu, 01 Jan 1970 00:00:00 GMT";
	$http({
		  method: 'POST',
		  url: '/auth/login',
		  data: xcred,
		  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
		  withCredentials: true})      
	.success(function() {
		 $scope.username = $scope.password = "";
		 authService.loginConfirmed();
	});
	}
	}
});
  
ngapp.config(function ($routeProvider, $httpProvider) {
    $httpProvider.defaults.withCredentials = true;
    //document.cookie = document.cookie + ";expires=Thu, 01 Jan 1970 00:00:00 GMT";
});

ngapp.controller({
	debugCtrl: function ($scope, $http) {
		$scope.logout = function() {
		  $http.post('/auth/logout').success(function() {
			document.cookie = document.cookie + ";expires=Thu, 01 Jan 1970 00:00:00 GMT";
		  });
		}
	 }  
});
