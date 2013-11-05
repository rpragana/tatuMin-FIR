package require json
package require json::write
package require uuid
package require sqlite3
	
namespace eval users {
	variable memfs [vfs::mk4::Mount "" mem]
	variable memdir [file join [file dirname $::starkit::topdir] mem]
	variable authenticated 0
}

proc users::chencode {s} {
	return [string map {\n "" \\ \\\\ \" \\"} [string trimright $s]]
	# " to fix syntax highlight in editor
}

proc users::main {conn parms} {
	set id -1
	if {[info command ::users::usersdb] == ""} {
		set dir [file dirname $::starkit::topdir]
		sqlite3 ::users::usersdb [file join $dir users.db]
		set sql "begin transaction"
	   	append sql "; create table if not exists users (nome text, id int)"
		append sql "; commit"
		::users::usersdb eval $sql

	}
	if {[dict exists $parms id]} {
		set id [dict get $parms id]
	} 
	set method [$conn reqCmd]
	set json "{}"
	set d ""
	catch {json::json2dict [lindex [$conn queryNames] 0]} d
	switch -- $method {
	"GET" {
		if {$id >= 0} {
			set s {}
			set sql "select nome, id from users where id = $id"
			::users::usersdb eval $sql v {
				foreach ix $v(*) {
					lappend s $ix [json::write string $v($ix)]
				}
			}
			set json "[eval json::write object $s]"
		} else {
			set s {}
			set sql "select nome, id from users"
			::users::usersdb eval $sql v {
				set u {}
				foreach ix $v(*) {
					lappend u $ix [json::write string $v($ix)]
				}
				lappend s "[eval json::write object $u]"
			}
			set json "[eval json::write array $s]"			
		}
	}
	"POST" {		
		### TEST
#		set headers {Content-Type {application/json; charset=UTF-8}
#			Cache-control no-cache}
#		$conn outHeader 200 $headers
#		$conn out "CLI-HEADERS=[$conn cliHeaders]\n"
#		$conn out "\nQUERY-NAMES=[$conn queryNames]\n"
#		return
		
		set nome [dict get $d nome]
		set id [dict get $d id]
		set sql "insert into users (nome, id) values ('$nome', $id)"
		::users::usersdb eval $sql 
	}
	"DELETE" {
		set sql "delete from users where id = $id"
		::users::usersdb eval $sql 
	}
	"PUT" {
		set nome [dict get $d nome]
		set sql "update users  set nome = '$nome' where id = $id"
		::users::usersdb eval $sql 
	}
	default {
		$conn outHeader 405
		return
	}}
	set headers {Content-Type {application/json; charset=UTF-8}
		Cache-control no-cache}
	$conn outHeader 200 $headers
	$conn out $json
}

proc users::login {conn parms} {
	variable ssid
#	tatu::log "users::login"
puts "HEADERS: [$conn headers]\n"
	set headers {Content-Type {text/plain; charset=UTF-8}
		Cache-control no-cache}
	set id ""
	foreach ln [$conn headers] {
		set r [regexp -inline {(.*?):\s*(.*)$} $ln]
puts r=$r
		set key [string tolower [lindex $r 1]]
		set val [lindex $r 2]
		if {$key == "cookie"} {
			set id $val
		}
	}
	if {$id eq ""} {
		set id [::uuid::uuid generate]
		set ssid($id) 1
	#	set expd [clock format [expr [clock seconds]+100000] -format "%a, %d %b %Y %H:%M:%S GMT"]
	#	lappend headers Set-Cookie "sessid=$id; Path=/; Expires=$expd"
		lappend headers Set-Cookie "$id; Path=/"
	}
	$conn outHeader 200 $headers
	$conn out "ok\n"
}
proc users::logout {conn parms} {
	variable ssid
#	tatu::log "users::logout"
	set headers {Content-Type {text/plain; charset=UTF-8}
		Cache-control no-cache}
	foreach ln [$conn headers] {
		set r [regexp -inline {(.*?):\s*(.*)$} $ln]
puts r=$r
		set key [string tolower [lindex $r 1]]
		set val [lindex $r 2]
		if {$key == "cookie"} {
			unset ssid($val)
		}
	}
	$conn outHeader 200 $headers
	$conn out "ok\n"
}
proc users::authenticated {conn} {
	variable ssid
puts "HEADERS(authenticated): [$conn headers]\n"	
	foreach ln [$conn headers] {
		set r [regexp -inline {(.*?):\s*(.*)$} $ln]
		set key [string tolower [lindex $r 1]]
		set val [lindex $r 2]
		if {$key == "cookie"} {
			if {[info exists ssid($val)]} {
				return 1
			}
		}
	}
	return 0
}
proc users::dataprot {conn parms} {
	tatu::log "users::dataprot"
puts "HEADERS(data): [$conn headers]\n"
	if {![authenticated $conn]} {
		$conn outHeader 401 {}
		$conn out "ok"
		return
	}
	set headers {Content-Type {text/plain; charset=UTF-8}
		Cache-control no-cache}
	$conn outHeader 200 $headers
	$conn out "[$conn rawData]\n"
}

proc users::testUpload {conn parms} {
	$conn configure -setlength 0

	set headers {Content-Type {text/plain; charset=utf-8}
		Cache-control no-cache}	
	$conn outHeader 200 $headers

	set resultado [$conn queryData sentFile]
	set filename [$conn queryValue sentFile filename]
	
	### armazenamos o conteúdo com o mesmo nome de arquivo
	### no diretório "uploads" (criado se não existir)
	set uploadDir [file join [file dirname $::starkit::topdir] uploads]
	file mkdir $uploadDir
	set fnpath [file join $uploadDir $filename]
	set f [open $fnpath w]
	chan configure $f -translation binary
	puts $f $resultado 
	close $f
	
	$conn out "RESULTADO=$resultado"
	$conn out "\n\nCLI-HEADERS=[$conn cliHeaders]\n"

	tatu::log "CLI-HEADERS=[$conn cliHeaders]"
#	tatu::log "CONTENTS=$resultado"
#	catch {tatu::log "FILENAME=[$conn queryValue sentFile filename]"
#		tatu::log "CONTENT-TYPE=[$conn queryValue sentFile content-type]"}
}



proc users::test {conn parms} {
	$conn configure -setlength 0
#	$conn configure -preserve 1	
#	set ::Conn $conn
	
	set hdrData ""
#	set hdrData "HEADERS(data): [$conn headers]\n\n"
	append hdrData "\n\nR=[$conn cliHeaders]\n"
	foreach q [$conn queryNames] {
		append hdrData "qry($q)-->[$conn queryData $q]\n"
		#tatu::log "DATA: qry($q)-->[$conn queryData $q]"
	}

	set format [$conn queryData format]
	set f [open "content.dat" r]
	set content [read $f]
	puts "content length=[string length $content]"
	close $f

	if {$format eq "json"} {
		set headers {Content-Type {application/json; charset=utf-8}
			Cache-control no-cache}

#puts "set i {}"					
		set i {}
#		lappend i answer [json::write string [tatu::escapeChars $content]]
#puts		"lappend i answer [json::write string $content]"
		lappend i answer [json::write string $content]

#puts	"	$conn outHeader 200 $headers"
		$conn outHeader 200 $headers
#puts		"$conn out [eval json::write object $i]\n"

#	catch {
#		set dh [$conn headersDict]
#		foreach key [dict keys $dh] {
#			append hdrData "$key = [dict get $dh $key]\n"
#		}
#	}
		$conn out "[eval json::write object $i]\n$hdrData"
	} else {
		set headers {Content-Type {text/plain; charset=utf-8}
			Cache-control no-cache}
		
		$conn outHeader 200 $headers

		set resultado [$conn queryData sentFile]
		$conn out "RESULTADO=$resultado"
		$conn out "\nCLI-HEADERS=[$conn cliHeaders]\n"
		tatu::log "CLI-HEADERS=[$conn cliHeaders]"
		tatu::log "CONTENTS=$resultado"
		catch {tatu::log "FILENAME=[$conn queryValue sentFile filename]"
			tatu::log "CONTENT-TYPE=[$conn queryValue sentFile content-type]"}
		
		#$conn out "$content"
		#$conn out "\n$hdrData"
	}
}

tatu::addRoute "/test" users::test
tatu::addRoute "/testUpload" users::testUpload

tatu::addRoute "/users" users::main
tatu::addRoute "/users/:id" users::main

tatu::addRoute "/auth/login" users::login
tatu::addRoute "/auth/logout" users::logout
tatu::addRoute "/data/public" users::datapub
tatu::addRoute "/data/protected" users::dataprot

################  DEBUG & TEST  ################
proc fmtHex s {
	set r ""
	foreach c [split $s ""] {
		append r [format "%02X " [scan $c %c]]
	}
	return $r
}

proc headersCheck {conn parms} {
	set rstat [$conn queryData "rstat"]
	set rcmd [$conn queryData "rcmd"] 
	if {$rstat ne ""} {
		$conn outHeader $rstat {Content-Type {text/plain}}
	} else {
		$conn outHeader 200 {Content-Type {text/plain}}
	}
	foreach line [$conn headers] {
		$conn out $line\n
	}
	$conn out "--------------------------------------\n"
	foreach {k v} [$conn cliHeaders] {
		$conn out "$k --> $v\n"
	}
	$conn out "--------------------------------------\n"
	
	if {$rcmd ne ""} {
		set input [tatu::unescapeChars $rcmd]
		set e [catch {uplevel #0 $input} result]
		if {$e} {
			$conn out [tatu::escapeChars $::errorInfo]
		} else {
			$conn out $result
		}
	} else {
		foreach n [$conn queryNames] {
			$conn out "$n --> [$conn queryData $n]\n"
		}
		$conn out "--------------------------------------\n"
		$conn out "hostip=[$conn hostip]\nhostport=[$conn hostport]"
	}
}
tatu::addRoute "/chk" headersCheck

proc lssock {} {
	set r {}
	foreach sk [file chan sock*] {
		lappend r [list $sk [dict get [chan configure $sk] -sockname]]\n
	}
	return $r
}

proc ainfo {} {
	set r {}
	foreach a [after info] {
		lappend r [after info $a]\n
	}
	return $r
}

proc lsmem {{dir {}} {start 0}} {
	if {$dir eq ""} {
		set dir $::users::memdir
		set start [expr [string length $dir]+1]
	}
	set s ""
	foreach fn [glob -nocomplain $dir/*] {
		set fn1 [string range $fn $start end]
		if {[file isdirectory $fn]} {
			### discard if no file found
			if {$fn eq ""} continue
			append s "$fn1 \[DIR\]\n"
			append s [lsmem $fn $start]
		} else {
			### discard empty files (possibly directories)
			if {![file size $fn]} continue
			append s "$fn1\n"
		}
	}
	return $s
}

proc cat fn {
	set f [open $fn r]
	chan configure $f -encoding utf-8
	set d [read $f]
	close $f
	return $d
}

proc xcat fn {
	set f [open $fn r]
	chan configure $f -translation binary
	set d [read $f]
	close $f
	return [fmtHex $d]
}

#################################################

catch {
wm geometry . +0-50
wm geometry .console +120-50
}

