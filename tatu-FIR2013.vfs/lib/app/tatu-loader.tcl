package provide tatu-loader 0.1

package require tatu
package require json

set localcfgf [file join $starkit::topdir localhost.json]
if {[file exists $localcfgf]} {
	set f [open $localcfgf r]
	set json [read $f]
	close $f
}
foreach {k v} [json::json2dict $json] {
	set tatu::server($k) $v
}
### read local label from command line arguments
if {[llength $argv] > 0} {
	set tatu::server(label) [lindex $argv 0]
}

#tatu::startServer 0.0.0.0 8000 {allwaysModified 1}
tatu::startServer "" "" $tatu::options

proc loadPlugins {} {
set plugdir [file join $::starkit::topdir plugins]
foreach plugin [glob -directory $plugdir *.tcl] {
	set plugfn [file rootname [file tail $plugin]]
	if {[catch "source $plugin" err]} {
		tatu::log "Error loading plugin $plugfn: $err\nDETAIL: $::errorInfo" error
	} else {
		tatu::log "Loaded plugin $plugfn"
	}
}
}
loadPlugins
vwait forever

