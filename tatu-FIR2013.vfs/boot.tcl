############ File Manager (jquery filetree connector)

######  URI encoding/decoding
#
# Encode all except "unreserved" characters; use UTF-8 for extended chars.
# See http://tools.ietf.org/html/rfc3986 §2.4 and §2.5
proc urlEncode {str} {
    set uStr [encoding convertto utf-8 $str]
    set chRE {[^-A-Za-z0-9._~\n]};		# Newline is special case!
    set replacement {%[format "X" [scan "\\\0" "%c"]]}
    return [string map {"\n" "
"} [subst \
		[regsub -all $chRE $uStr $replacement]]]
}

proc urlDecode {str} {
    set specialMap {"[" "[" "]" "]"}
    set seqRE {%([0-9a-fA-F]{2})}
    set replacement {[format "%c" [scan "\1" "%2x"]]}
    set modStr [regsub -all $seqRE [string map $specialMap $str] $replacement]
    return [encoding convertfrom utf-8 [subst -nobackslash -novariable $modStr]]
}
######  END ----  URI encoding/decoding

namespace eval filetree { }

proc filetree::filetree {conn params} {
	set dir [$conn queryData dir]
	if {$dir eq ""} {
		set dir $::starkit::topdir
	}
	#if {[$conn reqCmd] ne "POST"} {
	#	close $conn
	#	return
	#}
	tatu::log "filetree dir=$dir"
	
	set s {<ul class="jqueryFileTree" style="display: none;">}
	foreach f [glob -directory $dir *] {
		if {![file isdirectory $f]} continue
    	append s {<li class="directory collapsed">}
		append s "<a href=\"#\" rel=\"$f/\">"
		append s "[file tail $f]</a></li>"
	}
	foreach f [glob -directory $dir *] {
		if {[file isdirectory $f]} continue
		set ext [string range [file extension $f] 1 end]
    	append s "<li class=\"file ext_$ext\">"
		append s "<a href=\"#\" rel=\"$f"
		append s "\">[file tail $f]</a></li>"
	}
	append s "</ul>"
	$conn outHeader 200 {Content-Type text/html}
	$conn out $s
}

proc filetree::single {conn params} {
	set path [urlDecode [$conn queryData path]]
	set method [$conn reqCmd]
			tatu::log "filetree::single path=$path, method=$method"
	switch -- $method {
	"GET" {
		set f [open $path r]
		set msg [read $f]
		close $f
	}
	"PUT" {
		set contents [urlDecode [$conn queryData contents]]
		set f [open $path w]
		puts -nonewline $f $contents
		close $f
		set msg "Saved [string length $contents] bytes into $path"
	}
	"POST" {
		set n 0
		set tail [file tail $path]
		set dir [file dirname $path]
		while {[file exists $path]} {
			set path [file join $dir ${tail}_[incr n]]
		}
		set contents [urlDecode [$conn queryData contents]]
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
