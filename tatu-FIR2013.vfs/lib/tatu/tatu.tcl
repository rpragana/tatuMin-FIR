# 
# Tatu - a simple http 1.1 embedded web server
# 
# Release to the public domain, (C) Copyfree 2001
# Author: Rildo Pragana <rildo@pragana.net>
# Homepage: http://pragana.net/
# Version: 0.6
# vim: set ts=4
#
# 2012-03-23 - added TLS transport (https)
# 2011-01-28 - remade with snit

package provide tatu 0.6

### use Tk send mechanism to debug via tkcon
if {[string tolower [lindex $argv 0]] eq "gui" } {
set ::GUI 1
set argv [lrange $argv 1 end]
package require Tk
#wm withdraw .
tk appname tatu
wm geometry . +0-50
proc topblink {} {
	if {[. cget -bg] eq "#c0c0a0"} {
		. config -bg #a0a0c0
	} else {
		. config -bg #c0c0a0
	}
	after 300 topblink
}
topblink

### an advanced debug engine... (tkcon!)
namespace eval ::tkcon {}
set ::tkcon::OPT(exec) ""
package require app-tkcon
set tkcon::PRIV(showOnStartup) 0
set tkcon::PRIV(root) .console
set tkcon::PRIV(protocol) {tkcon hide}
set tkcon::OPT(exec) ""
set tkcon::OPT(cols) 60
set tkcon::OPT(rows) 15
tkcon::Init
tkcon title "Console"
proc toggle_console {} {
    if {[winfo ismapped .console]} {
        tkcon hide
    } else {
        tkcon show
    }
}
wm geometry .console -10-40
wm protocol .console WM_DELETE_WINDOW {wm withdraw .console}
#wm overrideredirect .console 1
bind all <Shift-Control-D> toggle_console

pack [button .b -text "exit Tatu" -command exit] \
	[button .b1 -text "console" -command toggle_console] \
	[button .b2 -text "restart server" -command tatu::startServer]
}

package require ncgi
package require md5
package require snit
#package require uuid
package require tls

snit::type httpConn {
	option -sock -readonly yes 
	option -setlength 1
	variable C -array {
		encoding "utf-8"
		content_length 0
		reqtmp {}
		rawquery ""
		busy 0
		headers {}
		body ""
		hostip 127.0.0.1
		hostport 8000
		tls 0
		bin 0
		delayed 0
		rawData ""
	}
	variable R -array {}

	method queueReq {} {
		variable C
		lappend C(req) $C(reqtmp)
		set C(reqtmp) {}
		set C(rawquery) ""
		$self reqHandle
	}
	method processQuery {} {
		variable C
		set lst {}
		foreach e [split $C(rawquery) &] {
			foreach {a b} [split $e =] break
			lappend lst [ncgi::decode $a] [ncgi::decode $b]
		}
		return $lst
	}
	method queryValue {name var {multiple 0}} {
		variable R
		if $multiple {
			set r {}
			foreach {ix val} $R(parsed_query) {
				if {$ix eq $name} {
					array set v [lindex $val 0]
 					if {![info exists v($var)]} {
						return ""
					}
					lappend r $v($var)
				}
			}
			return $r
		}
		if {![dict exists $R(parsed_query) $name]} {
			return ""
		}
		array set v [lindex [dict get $R(parsed_query) $name] 0]
 		if {![info exists v($var)]} {
			return ""
		}
		return $v($var)
	}
	method rawData {} {
		variable C
		return $C(rawData)
	}
	method queryData {name {multiple 0} {index -1}} {
		variable R
		if {[info exists R(content_type)] &&
				[string match multipart/* $R(content_type)]} {
			if $multiple {
				if {$index < 0} {
					error "multipart content with multiple \
equal keys must be indexed"
					return
				}
				set n 0
				foreach {ix val} $R(parsed_query) {
					if {$ix eq $name} {
						if {$n == $index} {
							return [lindex $val 1]
						}
						incr n
					}
				}
			} else {
				if {![dict exists $R(parsed_query) $name]} {
					return ""
				}
				return [lindex [dict get $R(parsed_query) $name] 1]
			}
		} else {
			array set v $R(query_array)
			if {![info exists v($name)]} {
				return ""
			}
			if {$multiple && $index<0} {
				set r {}
				foreach {ix val} $R(query_array) {
					if {$ix eq $name} {
						lappend r $val
					}
				}
				return $r
			} else {
				return $v($name)
			}
		}
	}
	method queryNames {} {
		variable R
		if {[info exists R(content_type)] &&
				[string match multipart/* $R(content_type)]} {
			return [dict keys $R(parsed_query)]
		} else {
			return [dict keys $R(query_array)]
		}
	}
	method getQueryArray {} {
		variable R
		return $R(query_array)
	}
	method getParsedQuery {} {
		variable R
		return $R(parsed_query)
	}
	method headers {} {
		variable C
		return $C(clientHeaders)
	}
	method headersDict {} {
		variable C
		set hdrs [$self headers]
		set dh {}
		foreach h $hdrs {
			dict set dh [lindex $h 0] [lrange $h 1 end]
		}
		return $dh
	}
	method cliHeaders {} {
		variable R
		return [array get R]
	}
	method rdquery {} {
		variable C
		set sock [$self cget -sock]
		if {[eof $sock]} {
			catch {close $sock}
			$self destroy
			return
		}
		append C(rawquery) [read $sock $C(content_length)]
		if {[string length $C(rawquery)] >= $C(content_length)} {
			chan configure $sock -translation auto
			chan event $sock readable [namespace code [list $self serve]]
			if {[info exists C(content_type)] &&
					[string match multipart/* $C(content_type)]} {
				lappend C(reqtmp) parsed_query \
					[ncgi::multipart $C(content_type) $C(rawquery)]
			} else {
				lappend C(reqtmp) query_array "[$self processQuery]"
			}
			set C(rawData) $C(rawquery)
			$self queueReq
		}
	}
	
	method hostip {{ip ""}} {
		variable C
		if {$ip ne ""} {
			set C(hostip) $ip	
		}
		return $C(hostip)
	}

	method hostport {{port ""}} {
		variable C
		if {$port ne ""} {
			set C(hostport) $port
			if {$port == $tatu::server(tlsport)} {
				set C(tls) 1
			} else {
				set C(tls) 0
			}
		}
		return $C(hostport)
	}

	method tls {} {
		variable C
		return $C(tls)
	}

	method serve {} {
		variable C
		set sock [$self cget -sock]
		if [eof $sock] {
			catch {close $sock}
			$self destroy
			return
		}
		gets $sock line
		### end of header, save request
		if {[string trim $line] == ""} {
			if {$C(reqtmp) != {}} {
				if {$C(method) == "POST" || $C(method) == "PUT"} {
					if {[info exists C(content_length)] &&
							$C(content_length) != "" && $C(content_length) > 0} {
						set C(rawquery) ""
						chan configure $sock -translation binary 
						chan event $sock readable [list $self rdquery]
					} elseif {$C(content_length) == 0} {
						$self queueReq
						$self queueReq
					}
				} else {
					$self queueReq
				}
			}
		} else {
			### if first line of request, extract query, methods
			if {$C(reqtmp) == {}} {
				set C(clientHeaders) {}
				lappend C(reqtmp) request $line
				set C(method) [string range $line 0 \
					[string wordend $line 0]-1]
				set tail /
				regexp {(/[^ ?]*)(\?[^ ]*)?} $line -> path rest
				if {![info exists rest]} return
				set C(rawquery) [string range $rest 1 end]
				lappend C(reqtmp) method $C(method) rawquery $C(rawquery) \
					path $path
				lappend C(reqtmp) query_array "[$self processQuery]"
			}
			lappend C(clientHeaders) $line	
			set opt [regexp -inline {(.*?):\s*(.*)$} $line]
			if {[llength $opt]} {
				set key [string map {- _} [string tolower [lindex $opt 1]]]
				set C($key) [lindex $opt 2]
				lappend C(reqtmp) $key $C($key)
			}
		}
		return
	}
	method done {file keepalive {bytes 0} {msg {}}} {
		variable C
		set sock [$self cget -sock]
		if {$file != ""} {
			close $file
		}
		if {!$keepalive} {
			#puts "CLOSE $sock"
			close $sock
			$self destroy
		} else {
			chan configure $sock -translation auto
			#flush $sock
			puts $sock ""
			incr C(busy) -1
			$self reqHandle 
		}
	}
	method putsHdr {h} {
		set sock [$self cget -sock]
		if {$tatu::showHeaders} {
			tatu::log $h status
		}
		puts $sock $h
	}
	method reqHandle {} {
		variable C
		variable R
		set sock [$self cget -sock]
		if {$C(busy)} {
			return
		}
		if {[llength $C(req)] == 0} return ;# no requests queued
		incr C(busy)
		array unset R
		array set R [lindex $C(req) 0]
		#tatu::log "TATU REQUEST: [array get R]"	
		set C(req) [lrange $C(req) 1 end]
		if {![info exists R(encoding)]} {
			set R(encoding) "utf-8"
		}
		set keepalive 0
		if {[info exists R(connection)] && 
				$R(connection) eq "keep-alive"} {
			incr keepalive
		}
		### try a registered route first
		set match [tatu::matchRoute $R(path) $C(hostport)]
		if {$C(tls)} {
			set sr "TLS "
		} else {
			set sr ""
		}
		if {$match ne ""} {
			chan configure $sock -translation crlf
			set C(body) ""
			set C(headers) {}
			set cmd [lindex $match 0]
			set parms [lindex $match 1]
			set log [lindex $match 2]
			if $log {
				tatu::log \
				"[clock format [clock seconds] -format %H:%M:%S]:$R(request)"
				if {$tatu::showHeaders} {
					tatu::log "$sr SERVER REQUEST HEADERS <<<<<<<<<" request
					foreach {ix val} [array get R] {
						tatu::log [tatu::escapeHTML "${ix}:\t$val"] request
					}
					tatu::log ">>>>>>>>>> $sr SERVER REQUEST HEADERS" request
				}
			}
			uplevel #0 [list $cmd $self $parms]
			if $log {
				if {$tatu::showHeaders} {
					tatu::log "$sr RESPONSE HEADERS <<<<<" status
					dict for {key value} $C(headers) {
						tatu::log "$key: $value" status
					}
					tatu::log ">>>>> $sr RESPONSE HEADERS" status
				}
			}
			if {[info exists C(delayed)] && !$C(delayed)} {
				$self respond
			}
			return
		}
		tatu::log "[clock format [clock seconds] -format %H:%M:%S]:$R(request)"
		if {$tatu::showHeaders} {
			tatu::log "$sr SERVER REQUEST HEADERS <<<<<<<<<" request
			foreach {ix val} [array get R] {
				tatu::log [tatu::escapeHTML "${ix}:\t$val"] request
			}
			tatu::log ">>>>>>>>>> $sr SERVER REQUEST HEADERS" request
		}
		### serve static files
		#if {[string match */ $R(path)]} {append R(path) $tatu::default}
		if {$C(tls)} {
			set root $tatu::tlsroot
		} else {
			set root $tatu::root
		}
		set name [string map {%20 " "} $root$R(path)]
		if {[file isdirectory $name]} {
			set ix [file join $name index.html]	
			if {[file exists $ix]} {
				set name $ix
			} else {
				# what to do with directories (return listing?)	
			}
		}
		#tatu::log "SERVER name=$name"
		if {[file readable $name]} {
			set ck [file mtime $name]
			set etag [md5::md5 -hex "$name$ck"]
			set cliEtag ""
			set status304 0
			if {!$::tatu::allwaysModified} {
				if {[info exists R(if_none_match)]} {
					set cliEtag $R(if_none_match)
					#tatu::log "ETAG: \"$etag\" ==== $cliEtag"
					if { "\"$etag\"" eq $cliEtag} {
						set status304 1
					}
				} elseif {[info exists R(if_modified_since)]} {
					if {$ck < [clock scan $R(if_modified_since)]} {
						set status304 1
					}
				}
			}
			if { $status304 } {
				if {$tatu::showHeaders} {
					tatu::log "HTTP/1.1 304 Not Modified" status
				}
				puts $sock "HTTP/1.1 304 Not Modified"
				puts $sock "\n"
				$self done "" 0
			} else {
				if {$tatu::showHeaders} {
					tatu::log "HTTP/1.1 200 OK" status
				}
				puts $sock "HTTP/1.1 200 OK"
		#	if {[file extension $name] eq ".tcl"} {
		#		puts $sock "Connection: close"
		#		eval [$self cache_source $name]
		#		incr C(busy) -1
		#		close $sock
		#		array unset R
		#	} else {
				set ext [file extension $name]
				set type [tatu::mimeType $ext]
				if {$ext eq ".html"} {
					append type "; charset=$R(encoding)"
				}
				set size [file size $name]
				set now [clock seconds]
				set expires [expr $now + 2592000] ;# 30 days
				#set expires [expr $now + 10] 
				set ckfmt "%a, %d %h %Y %H:%M:%S GMT"
				set lastMod [clock format $ck -format $ckfmt]
				set currDate [clock format $now -format $ckfmt]
				set expDate [clock format $expires -format $ckfmt]
				$self putsHdr "Server: Tatu/0.6"
				$self putsHdr "Date: $currDate"
				$self putsHdr "Last-Modified: $lastMod"
				if {!$::tatu::allwaysModified} {
					$self putsHdr "Expires: $expDate"
					$self putsHdr "Cache-Control: max-age=5184000" ;# 60 days
					#$self putsHdr "Cache-Control: max-age=10" 
					$self putsHdr "ETag: \"$etag\""
				} else {
					$self putsHdr "Expires: $currDate"
					$self putsHdr "Cache-Control: no-cache"
				}
				$self putsHdr "Content-length: $size"
				$self putsHdr "Content-Type: $type\n"
				set inchan [open $name]
				chan configure $inchan -translation binary
				chan configure $sock   -translation binary
				#puts "SERVING $size $name $inchan"
				### fcopy bug -- avoid files channels "mkNNN"
				#if {[string first mk $inchan] < 0} { }
				if {$size > 0} {
					fcopy $inchan $sock -size $size -command \
						[list $self done $inchan $keepalive]
				#} elseif {$size > 0} {
				#	set data [read $inchan]
				#	puts -nonewline $sock $data
				#	flush $sock
				#	$self done $inchan $keepalive	
				} else {
					puts $sock "\n"
					close $inchan
					$self done "" 0
				}
		#	}
			}
		} else {
			#tatu::log "HTTP/1.1 404 Not Found"
			$self putsHdr "HTTP/1.1 404 Not Found"
			set name $root/404.html
			set size [file size $name]
			$self putsHdr "Content-length: $size"
			$self putsHdr "Content-Type: text/html\n"
			set inchan [open $name]
			chan configure $inchan -translation binary
			chan configure $sock   -translation binary
			fcopy $inchan $sock -size $size -command \
				[list $self done $inchan $keepalive]
		}
	}
	method cache_source {name} {
		variable C
		if {![info exists C(cache,$name)]} {
			set f [open $name r]
			set C(cache,$name) [read $f]
			close $f
		}
		return $C(cache,$name)
	}
	method reqCmd {} {
		return $R(method)
	}
	method outHeader {{status 200} {headers {}} {delayed 0}} {
		variable C
		if {$status > 0} {
			dict set C(headers) status $status
		}
		foreach {key value} $headers {
			dict set C(headers) $key $value
		}
		if {$delayed} {
			set C(delayed) 1
		}
	}
	method out {s {bin 0}} {
		variable C
		append C(body) $s
		set C(bin) $bin
	}
	method respond {{log 0}} {
		variable C
		set r ""
		if {![dict exists $C(headers) status]} {
			dict set C(headers) status 500 ;# internal server error
		}
		set sock [$self cget -sock]
		if {[eof $sock]} {
			catch {close $sock}
			$self destroy
			return
		}
		set status [dict get $C(headers) status]
		set msg [dict get $tatu::STATUS $status]
		puts $sock "HTTP/1.1 $status $msg"
		if {[$self cget -setlength]} {
			if {$C(bin)} {
				set len [string length $C(body)]
			} else {
#				set C(body) [string map {\n \r\n} $C(body)]
#				set len [string bytelength $C(body)]

				set len [string bytelength \
					[string map {\n \r\n} $C(body)]]
			}
			#tatu::log "Content-length: $len"
			puts $sock "Content-length: $len"
		}
		#puts $sock "Connection: close"
		dict for {key value} $C(headers) {
			if {$key eq "status"} continue
			#tatu::log "$key: $value"
			puts $sock "$key: $value"
		}
		puts $sock ""
		if {$C(bin)} {
			chan configure $sock -translation binary 
		}
		puts -nonewline $sock $C(body)
		flush $sock
		$self done "" 0
	}
	method respond_new {{log 0}} {
		variable C
		set r ""
		if {![dict exists $C(headers) status]} {
			dict set C(headers) status 500 ;# internal server error
		}
		set sock [$self cget -sock]
		if {[eof $sock]} {
			catch {close $sock}
			$self destroy
			return
		}
		### write everything in a mem file first
		set memfn [tatu::tmpfile]
		#puts "MEM FILE = $memfn"
		set memf [open $memfn w+]
		set status [dict get $C(headers) status]
		set msg [dict get $tatu::STATUS $status]
		puts $memf "HTTP/1.1 $status $msg"
		if {[$self cget -setlength]} {
			if {$C(bin)} {
				set len [string length $C(body)]
			} else {
				set len [string bytelength \
					[string map {\n \r\n} $C(body)]]
			}
			puts $memf "Content-length: $len"
		}
		dict for {key value} $C(headers) {
			if {$key eq "status"} continue
			puts $memf "$key: $value"
		}
		puts $memf ""
		if {$C(bin)} {
			chan configure $sock -translation binary 
			chan configure $memf -translation binary
		}
		puts -nonewline $memf $C(body)
		flush $memf
		#set size [tell $memf]
		seek $memf 0
		
		#set f [open $memfn r]
		#puts [read $f]
		#close $f

		fcopy $memf $sock -command [list $self respondEnd $memf $memfn]
	}
	
	method respondEnd {mf mfname {keepalive 0}} {
		variable C
		set sock [$self cget -sock]
		close $mf
		file delete -force $mfname
		if {!$keepalive} {
			close $sock
			$self destroy
		} else {
			chan configure $sock -translation auto
			#puts $sock ""
			incr C(busy) -1
			$self reqHandle 
		}
	}

}

######## http server ###############
namespace eval tatu {
	variable server 
	array set server {
		host 0.0.0.0
		port 8000
		sock ""
		tlsport 8001
		socktls ""
		ready 0
	}
	variable default "index.html"
	variable root [file join $::starkit::topdir www]
	#variable tlsroot [file join $::starkit::topdir https]
	variable tlsroot [file join $::starkit::topdir www]
  	variable STATUS {
	100 "Continue" 						410 "Gone" 
	101 "Switching Protocols"           411 "Length Required"
	200 "OK"                            412 "Precondition Failed"
	201 "Created"                       413 "Request Entity Too Large"
	202 "Accepted"                      414 "Request-URI Too Large"
	203 "Non-Authoritative Information" 415 "Unsupported Media Type"
	204 "No Content"                    416 "Requested Range Not Satisfiable"
	205 "Reset Content"                 417 "Expectation Failed"
	206 "Partial Content"               418 "I'm a teapot"
	207 "Multi-Status"                  422 "Unprocessable Entity"
	300 "Multiple Choices"              423 "Locked"
	301 "Moved Permanently"             424 "Failed Dependency"
	302 "Moved Temporarily"             425 "Unordered Collection"
	303 "See Other"                     426 "Upgrade Required"
	304 "Not Modified"                  500 "Internal Server Error"
	305 "Use Proxy"                     501 "Not Implemented"
	307 "Temporary Redirect"            502 "Bad Gateway"
	400 "Bad Request"                   503 "Service Unavailable"
	401 "Unauthorized"                  504 "Gateway Time-out"
	402 "Payment Required"              505 "HTTP Version not supported"
	403 "Forbidden"                     506 "Variant Also Negotiates"
	404 "Not Found"                     507 "Insufficient Storage"
	405 "Method Not Allowed"            509 "Bandwidth Limit Exceeded"
	406 "Not Acceptable"                510 "Not Extended" 
	407 "Proxy Authentication Required"
	408 "Request Time-out"
	409 "Conflict"
	}
	variable MIMETYPE {
	"image/jpeg" jpeg jpg
	"image/gif" gif
	"image/png" png
	"image/x-ico" ico
	"application/javascript" js
	"application/json" json
	"text/css" css
	"text/html" htm html
	"text/rss+xml" rss
	"text/xml" xml
	"application/pdf" pdf
	"application/postscript" ps eps
	"image/svg+xml" svg
	"text/x-tcl" tcl
	}
	variable routes {}
	variable logbuf {}
	variable logline 0
	variable showHeaders 0
	variable allwaysModified 0
	variable options {}

	### url encoder vars
	variable map
    variable alphanumeric a-zA-Z0-9
	variable memfs
	variable memdir
	variable memcnt 0
}

proc tatu::escapeChars {s} {
    set map [list \\ \\\\ \" \\" \n \\n \b \\b \r \\r \t \\t]
		#set map {\\ \\\\ \" \\\" 
		#\n \\n \t \\t \f \\f \r \\r \b \\b} 
	set s [string map $map $s]
	set r ""
	for {set i 0} {$i < [string length $s]} {incr i} {
		set c [string index $s $i]
		set d [scan $c %c]
		#if {$d > 127 || $d < 32} 
		if {$d > 127 || $d < 32} {
			append r "\\u[format %04x $d]"
		} else {
			append r $c
		}
	}
	return $r
}

proc tatu::unescapeChars {s} {
    set map [list \\ \\ \\" \" \\n \n \\b \b \\r \r \\t \t]
	#set map {\\\\ \\ \\\" \"  
	#	\\n \n \\t \t \\f \f \\r \r \\b \b} 
	return [string map $map $s]
}

proc tatu::escapeHTML {s} {
	set map [list & "&amp;" < "&lt;" > "&gt;"]
	return [string map $map $s]
}

proc tatu::mimeType {ext} {
	variable MIMETYPE
	### remove "." from extension and lowercase it
	set e [string tolower [string range $ext 1 end]]
	foreach m [split $MIMETYPE \n] {
		if {$e in [lrange $m 1 end]} {
			return [lindex $m 0]
		}
	}
	## we return text/plain for unknown (?)
	return "text/plain"
}

proc tatu::log {msg {type "warn"}} {
	variable logbuf
	variable logline
	set fmsg $msg
	switch $type {
	error {
		set fmsg "<span class='error'>$msg</span>"
	}
	default {
		set fmsg "<span class='$type'>[escapeHTML $msg]</span>"
	}
	}
	lappend logbuf [list [incr logline] $fmsg]
	set logbuf [lrange $logbuf end-2000 end]
	#puts "[format %07d $logline]: $fmsg"
}

proc tatu::setupEnv {} {
array set ::env {
PATH "/bin:/usr/bin:/sbin:/usr/sbin"
SERVER_ADDR "127.0.0.1"
SERVER_PORT "8000"
SERVER_PROTOCOL "HTTP/1.1"
SERVER_SOFTWARE "Embedded Tcl Server"
}
set ::env(DOCUMENT_ROOT) "[file join $::starkit::topdir html]"
}

proc bgerror {trouble} {::tatu::log "bgerror: $trouble\n$::errorInfo" error}

proc tatu::addRoute {route cmd {log 1} {protocols {http https}}} {
	variable routes
	set r [split $route /]
	### strip first component (absolute path, begin with "/")
	if {[lindex $r 0] == {}} {
		set r [lrange $r 1 end]
	}
	set vars {}
	set re "^"
	foreach item $r {	
		if {[string index $item 0] eq ":"} {
			append re {/([^/]*)}
			lappend vars [string range $item 1 end]
		} else {
			append re "/$item"
		}
	}
	append re \$
	lappend routes [list $re $vars $cmd $log $protocols]
}

proc tatu::matchRoute {path {port 0}} {
	variable routes
	variable server
	foreach route $routes {
		lassign $route re vars cmd log protocols
		set r [regexp -inline $re $path]
		if {$r ne ""} {
			### check if protocol match
			set proto ""
			if {$port == $server(port)} {
				set proto "http"
			}
			if {$port == $server(tlsport)} {
				set proto "https"
			}
			if {[lsearch $protocols $proto] < 0} {
				return ""
			}	
			set values {}
			foreach v $vars val [lrange $r 1 end] {
				lappend values $v [ncgi::decode $val]
			}
			return [list $cmd $values $log]
		}
	}
	return ""
}

proc tatu::answer {sk host port} {
	#puts "CONNECTION - $sk $host $port"
	chan configure $sk -blocking 0
	set handler [httpConn %AUTO% -sock $sk]
	set sockname [chan configure $sk -sockname]
	$handler hostip [lindex $sockname 0]
	$handler hostport [lindex $sockname 2]
	chan event $sk readable [namespace code [list $handler serve]]
}

proc tatu::changeRoot {newroot} {
	variable root
	set root $newroot
}

proc tatu::closeSock {port} {
	foreach c [file chan sock*] {
		if {[lindex [chan config $c -sockname] end] == $port} {
			close $c
			break
		}
	}
}

proc ::tatu::urlEncoderInit {} {
    variable map
    variable alphanumeric a-zA-Z0-9
    for {set i 0} {$i <= 256} {incr i} { 
        set c [format %c $i]
        if {![string match \[$alphanumeric\] $c]} {
            set map($c) %[format %.2x $i]
        }
    }
    # These are handled specially
    array set map { " " + \n %0d%0a }
}
::tatu::urlEncoderInit

proc tatu::urlEncode {string} {
    variable map
    variable alphanumeric
    # The spec says: "non-alphanumeric characters are replaced by '%HH'"
    # 1 leave alphanumerics characters alone
    # 2 Convert every other character to an array lookup
    # 3 Escape constructs that are "special" to the tcl parser
    # 4 "subst" the result, doing all the array substitutions
    regsub -all \[^$alphanumeric\] $string {$map(&)} string
    # This quotes cases like $map([) or $map($) => $map(\[) ...
    regsub -all {[][{})\\]\)} $string {\\&} string
    return [subst -nocommand $string]
}

proc tatu::urlDecode str {
    # rewrite " " back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\"] $str]
    # prepare to process all %-escapes
    regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str
    # process \u unicode mapped chars
    return [subst -novar -nocommand $str]
}

proc tatu::tmpfile {} {
	variable memcnt
	variable memdir
	return [file join $memdir M[incr memcnt]]
}

#proc tatu::restart_server {} {
#	variable server
#	close $server(sock)	
#	set server(sock) [socket -server tatu::answer -myaddr \
#		$server(host) $server(port)]
#}

proc tatu::startServer {{host ""} {port ""} {options {}}} {
	variable server
	setupEnv
	if {$host == ""} {set host $server(host)}
	if {$port == ""} {set port $server(port)}
	if {$options != {}} {
		foreach {opt val} $options {
			if {[lsearch {host port tlsport} $opt] >= 0} {
				set server($opt) $val
			} else {
				variable $opt
				set $opt $val
			}
		}
	}
	tatu::closeSock $server(port)
	set tatu::server(sock) [socket -server tatu::answer \
		-myaddr $server(host) $server(port)]
	log "Tatu started on host: $server(host) port: $server(port)!"

   	if {$server(tlsport) != 0} {	
		set kdir $::starkit::topdir
		set pdir [file dirname $kdir]
		set cert [file join $pdir cert]
		set certfile [file join $cert server.pem]
		set keyfile [file join $cert server.key]
		
		if {![file exists $keyfile] || ![file exists $certfile]} {
			#file mkdir $cert
			#tls::misc req 2048 $keyfile $certfile \
			#	[list CN "localhost" days 7300]
			file delete $cert
			file copy -force [file join $kdir cert] $pdir
		}		
		
		::tls::init -certfile $certfile -keyfile  $keyfile \
			-ssl2 1 -ssl3 1 -tls1 0 -require 0 -request 0
		tatu::closeSock $server(tlsport)
		set server(socktls) [::tls::socket \
			-server tatu::answer $server(tlsport)]
	}
}

package require vfs::mk4
### fcopy bug -- avoid files channels "mkNNN"
package require Mk4tcl
set ::mk4vfs::direct 1

set ::tatu::memdir [file join [pwd] tatuMem]
set ::tatu::memfs [vfs::mk4::Mount "" $::tatu::memdir]


