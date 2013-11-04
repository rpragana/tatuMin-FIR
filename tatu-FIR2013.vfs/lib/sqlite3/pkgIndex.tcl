if {$::tcl_platform(platform) == "unix"} {
#package ifneeded sqlite3 3.6.6.2 [list load [file join $dir libtclsqlite3.so]]
package ifneeded sqlite3 3.7.6.3 [list load [file join $dir libsqlite3.7.6.3.so]]
} else {
package ifneeded sqlite3 3.7.4 \
    [list load [file join $dir sqlite374.dll] Sqlite3]
}

