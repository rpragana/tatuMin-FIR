//
// main.js - funcoes para o programa principal (index.html)
//
$(function(){			
	//----- links for applications inside the starkit server --------
/*	$.getJSON('/links.json',"",function(data,textStatus,xhr){
		data.forEach(function(d){
			if (d.charAt(0) == '*') {
				$('#links').append(
						'<a class="ausente" href="#">AUSENTE '+d+'</a><br>')
			} else {
				$('#links').append('<a href="'+d+'">'+d+'</a><br>')
			}
		});
	});
*/
	//--------------- queries sql --------------
//	$('#respclear').click(function(ev) {
//		ev.preventDefault();
//		$('#resposta').html("");
//	});
//	$('#sqlquery').keypress(function(ev){
//		if (ev.which == 13) /* Return KEY */ {
//			var sql=$(this).val();
//			var db=$('#sqldb').val();
//			$('#resposta').append("<p><em>SQL:</em>"+sql+"</p>");
//			$.post('/sqlservice',{db: db, sql: sql},function(data){
//				var resp=$('#resposta');
//				//console.log('RESPOSTA='+JSON.stringify(data));
//				for (var i=0;i < data.length; i++) {
//					var dt=data[i];
//					var line="<p>"+i+": { ";
//					for (c in dt) {
//							line+=(c+":\""+dt[c]+"\", ");
//					}
//					line+=(" }</p>");
//					resp.append(line);
//				}
//			});
//			return false;	
//		}
//		return true;
//	});
//	$('#sql li').click(function(ev) {
//		var sql=$(this).text();
//		var db=$('#sqldb').val();
//		var c;
//		ev.preventDefault();
//		$('#resposta').append("<p><em>SQL:</em>"+sql+"</p>");
//		//$.ajax({
//   		//	type: "POST",
//   		//	url:  'tcl/sql.tcl',
//   		//	data: 'query='+sql, 
//   		//	success: function(data){
//		//		var resp=$('#resposta');
//		//		for (var i=0;i < data.length; i++) {
//	 	//			var dt=data[i];
//		//			var line="<p>"+i+":";
//		//			for (c in dt) {
//		//					line+=(dt[c]+" ");
//		//			}
//		//			line+=("</p>");
//		//			resp.append(line);
//		//		}	
//   		//	}
//		//});
//		
//		$.post('/sqlservice',{sql: sql, db: db},function(data){
//			var resp=$('#resposta');
//			for (var i=0;i < data.length; i++) {
//	 			var dt=data[i];
//				var line="<p>"+i+":";
//				for (c in dt) {
//						line+=(dt[c]+" ");
//				}
//				line+=("</p>");
//				resp.append(line);
//			}
//		});
//	});	
//	$('#put').click(function(ev) {
//		var c;
//		ev.preventDefault();
//		$.ajax({
//   			type: "PUT",
//   			url:  'query',
//   			data: 'n=RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR', 
//   			success: function(data){
//   				console.log("PUT request sent\n"+data);
//			}
//		});	
//	});	
//	
//	$('#sqldb').val('chinook.sqlite');
//	$('#sqlquery').val('select * from Customer limit 10');
}); 



