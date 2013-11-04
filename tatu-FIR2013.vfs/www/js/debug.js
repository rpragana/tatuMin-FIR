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
	});
	
	$('h1:first').click(function(){
		var ed;
		var winH = $(window).height();
		var winW = $(window).width();
		$('#editor').remove();
		$('body').append('<div id="editor"></div>');
		ed=$('#editor').
			html('Proc: <input id="editorProc"></input>'+
					'<button id="editorB0">edita</button><br>'+
					'<textarea contenteditable="true"></textarea>'+
					'<button id="editorB1">salva</button>'+
					'<button id="editorB2">desiste</button>');
		ed.css('top',  winH/2-ed.height()/2);
		ed.css('left', winW/2-ed.width()/2);
		ed.fadeIn(2000);
	});

	$(document).on('click','#editorB0',function(){
		var cmd;
		var pr;
		//console.log("click editorB0");
		pr = $('#editorProc').val();
		//cmd = 'set s "proc '+pr+' {[info args '+pr+']} {[info body '+pr+']}"';
		cmd = '::logger::dumpProc '+pr;
		//console.log("command:"+cmd);
		$.getJSON('/log?cmd=eval&input='+encodeURIComponent(cmd),
						"",function(data,textStatus,xhr){
			$('#editor textarea').val(data.answer);	
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
	},2000);

	var wd = $('body').width();
	var history=[null];
	$('#log pre').css('width',wd);	
	$('#cmd').keydown(function(ev){
		//console.log("shift:"+ev.shiftKey+" which:"+ev.which);
		if (!ev.shiftKey && (ev.which == 13)) {
			var log=$('#log');
			var cmd=$('#cmd textarea').val();
			if (cmd.length > 0) {
				var url = '/log?cmd=eval&input='+encodeURIComponent(cmd);
				//console.log('getJSON('+url+')');
				$.getJSON(url)
					.done(function(data){
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



