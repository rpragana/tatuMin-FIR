proc users::login {conn parms} {
	variable ssid
#	tatu::log "users::login"
puts "HEADERS: [$conn headers]\n"
	set headers {Content-Type {text/plain; charset=UTF-8}
		Cache-control no-cache}
	set id [::uuid::uuid generate]
	set ssid($id) 1
#	set expd [clock format [expr [clock seconds]+100000] -format "%a, %d %b %Y %H:%M:%S GMT"]
#	lappend headers Set-Cookie "sessid=$id; Path=/; Expires=$expd"
	lappend headers Set-Cookie "$id; Path=/"
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
