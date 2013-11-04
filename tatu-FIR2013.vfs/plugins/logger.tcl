############ logger
package require tcvJSON
package require json
package require json::write

namespace eval logger { }

proc logger::dumpProc {p} {
	set as {}
	foreach a [info args $p] {
	    if {[info default $p $a tmp]} {
		lappend as [list $a $tmp]
	    } else {
		lappend as $a
	    }
	}
	return [list proc $p $as [info body $p]]\n
}

proc logger::logger {conn params} {
	set cmd [$conn queryData cmd]
	if {[$conn reqCmd] eq "POST"} {
		set cmd "eval"
	}
	if {$cmd eq ""} { 
		set cmd "debug"
	}
	switch -- $cmd {
	"info" {
		$conn configure -setlength 0
		set s {}
		lappend s time [json::write string \
			"[clock format [clock seconds] -format %H:%M:%S]"]
		lappend s events [json::write string "[llength [after info]]"]
		lappend s channels [json::write string "[llength [file chan]]"]
		$conn outHeader 200 {Content-Type {application/json; charset=UTF-8}} 0
		$conn out "[eval json::write object $s]\n"
		return
	}
	"readlog" {	
		set start [$conn queryData start]
		if {$start eq ""} {
			set start 1
		}
		if {[set n [lsearch -index 0 $tatu::logbuf $start]] < 0} {
			 set n -1
		}
		$conn configure -setlength 0
		set j [tcvJSON::create list]
		foreach item [lrange $::tatu::logbuf [expr $n+1] end] {
			set i [tcvJSON::create obj]
			tcvJSON::put! -type num i line [lindex $item 0]
			tcvJSON::put! -type str i msg [tatu::escapeChars [lindex $item 1]]
			tcvJSON::add! -type auto j $i
		}
		$conn outHeader 200 {Content-Type application/json}
		$conn out [tcvJSON::unparse $j]
	}
	"toggleHeaders" {
		set tatu::showHeaders [expr !$tatu::showHeaders]
		$conn outHeader 200 {Content-Type application/json}
		$conn out "{}"
	}
	"toggleModified" {
		set tatu::allwaysModified [expr !$tatu::allwaysModified]
		$conn outHeader 200 {Content-Type application/json}
		$conn out "{}"
	}
	"eval" {
		if {$::tcl_platform(platform) eq "unix"} {
			set input [encoding convertfrom utf-8 [$conn queryData input]]
		} else {
			set input [$conn queryData input]
		}
		$conn configure -setlength 0
		#puts "EVAL: input=$input"
		set e [catch {uplevel #0 [tatu::unescapeChars $input]} result]
		set i [tcvJSON::create obj]
		tcvJSON::put! -type str i answer [tatu::escapeChars $result]
		if {$e} {
			tcvJSON::put! -type str i error [tatu::escapeChars $::errorInfo]
		}
		$conn outHeader 200 {Content-Type application/json}
		$conn out [tcvJSON::unparse $i]
	}
	"flags" {
		$conn outHeader 200 {Content-Type application/json}
		set sh [expr $tatu::showHeaders ? "true" : "false"]
		set am [expr $tatu::allwaysModified ? "true" : "false"]
		$conn out "{\"showHeaders\": $sh, \"allwaysModified\": $am}"
	}
	"debug" {
		$conn outHeader 200 {Content-Type text/html}
		$conn out \
{<!DOCTYPE html>
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<link href="/css/debug.css" type="text/css" rel="stylesheet" />
<script src="/js/jquery.js"></script>
<script src="/js/debug.js"></script>
<style>.error { color: #c00; }</style>
<title>Tatu logger/debugger</title>
</head>
<body>
<h1>Tatu Logger/Debugger</h1>
<span id="kainfo">
	Updated: <span id="katime"></span>
	Events: <span id="kaevents"></span>
	Channels: <span id="kachannels"></span>
</span>
<button class="skip" id="btn_exit">exit server</button>
<button class="skip" id="btn_reload">reload plug</button>
<button class="skip" id="btn_toggleHeaders">req headers</button>
<button class="skip" id="btn_toggleModified">don't cache</button>
<button class="skip" id="btn_clear">clear</button>
<div id="cmd">
<textarea></textarea>
</div>
<div id="logger">
</div>
<div id="log">
<pre></pre>
</div>
</body>
</html>}
	}
	}
}

tatu::addRoute "/log" logger::logger 0 {http https}

