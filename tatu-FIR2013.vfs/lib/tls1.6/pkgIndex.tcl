if {![package vsatisfies [package provide Tcl] 8.3]} {return}
if {$::tcl_platform(platform) == "unix"} {
package ifneeded tls 1.6 \
    "[list source [file join $dir tls.tcl]] ; \
     [list tls::initlib $dir libtls1.6.so]"
} else {
package ifneeded tls 1.6 "source \[file join [list $dir] tls-Windows.tcl\] ; tls::initlib [list $dir] tls16.dll"
}

