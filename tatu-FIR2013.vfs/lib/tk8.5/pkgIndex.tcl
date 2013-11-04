if {[catch {package present Tcl	8.5.1}]} { return }
package ifneeded Tk 8.5.1 \
  [list load [file join $dir libtk8.5[info sharedlibext]] Tk]
