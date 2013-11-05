############ File Manager (jquery filetree connector)

package require json
package require json::write

######  URI encoding/decoding
#
# Encode all except "unreserved" characters; use UTF-8 for extended chars.
# See http://tools.ietf.org/html/rfc3986
proc urlEncode {str} {
    #set uStr [encoding convertto utf-8 $str]
    set chRE {[^-A-Za-z0-9._~\n]};		# Newline is special case!
    set replacement {%[format "%02X" [scan "\\\0" "%c"]]}
    return [string map {"\n" "%0A"} [subst \
		[regsub -all $chRE $uStr $replacement]]]
}

proc urlDecode {str} {
    set specialMap {"[" "[" "]" "]"}
    set seqRE {%([0-9a-fA-F]{2})}
    set replacement {[format "%c" [scan "\1" "%2x"]]}
    set modStr [regsub -all $seqRE [string map $specialMap $str] $replacement]
    #return [encoding convertfrom utf-8 [subst -nobackslash -novariable $modStr]]
    return [subst -nobackslash -novariable $modStr]
}
######  END ----  URI encoding/decoding

namespace eval filetree { }

proc filetree::filetree {conn params} {
	set dir [$conn queryData dir]
	if {$dir eq ""} {
		set dir $::starkit::topdir
	}
	set jsonData 0
	if {[$conn queryData type] eq "json"} {
		set jsonData 1
	}
	#if {[$conn reqCmd] ne "POST"} {
	#	close $conn
	#	return
	#}
	tatu::log "filetree dir=$dir"

	if {$jsonData} {
		set s {}
	} else {	
		set s {<ul class="jqueryFileTree" style="display: none;">}
	}
	foreach f [glob -directory $dir *] {
		if {![file isdirectory $f]} continue
    	if {$jsonData} {
			lappend s [json::write string [file tail $f]/]
		} else {
			append s {<li class="directory collapsed">}
			append s "<a href=\"#\" rel=\"$f/\">"
			append s "[file tail $f]</a></li>"
		}
	}
	foreach f [glob -directory $dir *] {
		if {[file isdirectory $f]} continue
    	if {$jsonData} {
			lappend s [json::write string [file tail $f]]
		} else {
			set ext [string range [file extension $f] 1 end]
			append s "<li class=\"file ext_$ext\">"
			append s "<a href=\"#\" rel=\"$f"
			append s "\">[file tail $f]</a></li>"
		}
	}
	if {$jsonData} {
		set headers {Content-Type {application/json; charset=UTF-8}
			Cache-control no-cache}
		$conn outHeader 200 $headers
		$conn out [json::write array {*}$s]
	} else {
		append s "</ul>"
		$conn outHeader 200 {Content-Type text/html}
		$conn out $s
	}
}

proc filetree::single {conn params} {
	set path [tatu::urlDecode [$conn queryData path]]
	set method [$conn reqCmd]
	tatu::log "filetree::single path=$path, method=$method"
	switch -- $method {
	"GET" {
		$conn configure -setlength 0
		set f [open $path r]
		#chan configure $f -translation binary
		set msg [read $f]
		puts "GET CONTENTS=[string trim $msg]"		
		close $f
	}
	"PUT" {
		if {![file isfile $path]} {
			$conn outHeader 400 {Content-Type text/plain; charset=utf-8}
			$conn out "File not found"
		}
#		set contents [tatu::urlDecode [$conn queryData contents]]
		set contents [encoding convertfrom utf-8 [$conn queryData contents]]
		puts "PUT CONTENTS=[string trim $contents]"
		set f [open $path w]
		puts -nonewline $f $contents
		close $f
		set msg "Saved [string length $contents] bytes into $path"
	}
	"POST" {
		set n 0
		set fname [$conn queryData fname]
		if {$fname eq ""} {
			set tail [file tail $path]
			set dir [file dirname $path]
		} else {
			set tail $fname
			set dir $path
		}
		set path [file join $dir $tail]
		while {[file exists $path]} {
			set path [file join $dir ${tail}_[incr n]]
		}
		#set contents [tatu::urlDecode [$conn queryData contents]]
		set contents [encoding convertfrom utf-8 [$conn queryData contents]]
		#set contents [$conn rawData]
		set f [open $path w]
		puts -nonewline $f $contents
		close $f
		set msg "Created $path with [string length $contents] bytes"
	}
	"DELETE" {
		file delete -force $path
	}
	}
	$conn outHeader 200 {Content-Type text/plain; charset=utf-8}
	$conn out $msg
}

tatu::addRoute "/filetree" filetree::filetree 0 {http}
tatu::addRoute "/filetr" filetree::single 0 {http}


