######################################################################
###                                                                ###
###  Copyright (c) 2009 Taylor Christopher Venable                 ###
###  Made available under the Simplified BSD License.              ###
###                                                                ###
######################################################################

# CVS Path: /Programs/Libraries/Tcl/tcvJSON/tcvJSON.tcl
# Last Change: $Date$
# Revision: $Revision$

## The parser part of this code is derived from that found in Tcllib, and which
## bears this copyright information:
##
## Copyright 2006 ActiveState Software Inc.
##
## See also the accompanying license.terms file which describes the rules for
## licensing and distributing Tcllib code.

package provide tcvJSON 1.0

namespace eval tcvJSON {}

# This namespace is called tcvJSON because json is already in tcllib and other
# programs which use this module may need to access that alternative json.  The
# problem with tcllib's json is that it doesn't offer a way to write JSON, only
# to read it.  The inherent difficulty here is that most Tcl values can be
# simultaneously representable by more than one type: most values can be shown
# as strings.  Examples: "quick brown fox" is both a string and a list of three
# elements.  Similarly, "true" is both a boolean (as interpreted by [expr]) and
# a string.  So how do we encode such things?  Well we punt on it and force
# data to be added to JSON via a special interface.  This produces an internal
# representation of tuples {TYPE VALUE} where TYPE indicates how to show the
# data.  For example, a list could be
#
# {list {str "quick brown fox"} {list {num 1} {num 2}}}
#
# --> ["quick brown fox", [1, 2]]
#
# In this scheme, objects are represented as follows:
#
# {obj "foo" {str "bar"} "tcl" {num 8.6}}
#
# --> {"foo" : "bar",
#      "tcl" : 8.6}
#
# Because keys in objects can only be strings, there's no need to tag them as
# such.  Thus, an object is a list of key-value pairs.

proc tcvJSON::create {type} {
    switch -- $type {
        {list} {
            return {list}
        }

        {obj} -
        {object} {
            return {obj}
        }
    }
}

# Synopsis: add! ?-type TYPE? JSONNAME VALUE
# Appends the VALUE (possibly explicitly qualified to be of the given TYPE) to
# the end of a JSON list stored in the caller in the variable JSONNAME.
# Signals an error if the value of JSONNAME is not a JSON list.

proc tcvJSON::add! {args} {
    set location ""
    set value ""

    set offset 0

    if {[lindex $args 0] eq "-type"} {
        set type [lindex $args 1]
        set offset 2
    }

    set location [lindex $args [expr {$offset + 0}]]
    set value [lindex $args [expr {$offset + 1}]]

    if {![info exists type]} {
        if {[string is double -strict $value]} {
            set type "num"
        } elseif {$value eq "true" || $value eq "false"} {
            set type "bool"
        } elseif {$value eq "null"} {
            set type "null"
        } else {
            set type "str"
        }
    } elseif {$type eq "auto"} {
        set type [lindex $value 0]
        if {$type ne "list" && $type ne "obj"} {
            set value [lindex $value 1]
        } else {
            set value [lrange $value 1 end]
        }
    }

    upvar $location json

    if {[lindex $json 0] ne "list"} {
        error "can only \"add\" to lists: received $json"
    }

    if {$type eq "null"} {
        lappend json "null"
    } else {
        if {$type eq "list" || $type eq "obj"} {
            lappend json [list $type {*}$value]
        } else {
            lappend json [list $type $value]
        }
    }
}

# Synopsis: put! ?-type TYPE? JSONNAME KEY VALUE
# Adds the relationship KEY → VALUE (possibly explicitly qualified to be of the
# given TYPE) into the JSON object stored in the caller in the variable
# JSONNAME.  Signals an error if the value of JSONNAME is not a JSON object.
# KEY is treated as a string, both internally and for encoding.

proc tcvJSON::put! {args} {
    set location ""

    set key ""
    set value ""

    set offset 0

    if {[lindex $args 0] eq "-type"} {
        set type [lindex $args 1]
        set offset 2
    }

    set location [lindex $args [expr {$offset + 0}]]
    set key [lindex $args [expr {$offset + 1}]]
    set value [lindex $args [expr {$offset + 2}]]

    if {![info exists type]} {
        if {[string is double -strict $value]} {
            set type "num"
        } elseif {$value eq "true" || $value eq "false"} {
            set type "bool"
        } elseif {$value eq "null"} {
            set type "null"
        } else {
            set type "str"
        }
    } elseif {$type eq "auto"} {
        set type [lindex $value 0]
        if {$type ne "list" && $type ne "obj"} {
            set value [lindex $value 1]
        } else {
            set value [lrange $value 1 end]
        }
    }

    upvar $location json

    if {[lindex $json 0] ne "obj"} {
        error "can only \"put\" to objects: received $json"
    }

    for {set i 1} {$i < [llength $json]} {incr i 2} {
        if {[lindex $json $i] eq $key} {
            set json [lreplace $json $i $i+1]
        }
    }

    lappend json $key
    if {$type eq "null"} {
        lappend json null
    } else {
        if {$type eq "list" || $type eq "obj"} {
            lappend json [list $type {*}$value]
        } else {
            lappend json [list $type $value]
        }
    }
}

# Synopsis: unparse JSONTHING
# Encodes / writes / prints / unparses some kind of JSON composite or scalar
# value JSONTHING into a string representation which can be sent over the wire
# or written to a file.

proc tcvJSON::unparse {thing args} {
    set output ""
    set type [lindex $thing 0]
    set indent 2
    set indentIncr 2

    if {[llength $args] > 0} {
        set indent [lindex $args 0]
    }

    switch -- $type {
        {list} {
            append output "\[\n[string repeat " " $indent]"
            set tmp {}
            foreach element [lrange $thing 1 end] {
                lappend tmp [unparse $element [expr {$indent + $indentIncr}]]
            }
            append output [join $tmp ",\n[string repeat " " $indent]"]
            append output "\n[string repeat " " [expr {$indent - $indentIncr}]]\]"
        }

        {obj} {
            append output "\{\n[string repeat " " $indent]"
            set tmp {}
            for {set i 1} {$i < [llength $thing]} {incr i} {
                set key [lindex $thing $i]
                set value [lindex $thing [incr i]]
                lappend tmp "\"$key\": [unparse $value [expr {$indent + $indentIncr}]]"
            }
            append output [join $tmp ",\n[string repeat " " $indent]"]
            append output "\n[string repeat " " [expr {$indent - $indentIncr}]]\}"
        }

        {str} {
            append output "\"[lindex $thing 1]\""
        }

        {bool} -
        {num} {
            append output "[lindex $thing 1]"
        }

        {null} {
            append output "null"
        }

        {default} {
            error "unknown type \"$type\""
        }
    }
    return $output
}

proc tcvJSON::write {args} {
    if {[llength $args] == 1} {
        set channel stdout
        set jsonName [lindex $args 0]
    } elseif {[llength $args] == 2} {
        set channel [lindex $args 0]
        set jsonName [lindex $args 1]
    } else {
        error "wrong # args: expected \"write ?channel? jsonName\""
    }

    upvar $jsonName json
    puts $channel [unparse $json]
}

# Shamelessly lifted from Tcllib's json::getc proc.

proc tcvJSON::getc {{txtvar txt}} {
    # pop single char off the front of the text
    upvar 1 $txtvar txt
    if {$txt eq ""} {
        return -code error "unexpected end of text"
    }

    set c [string index $txt 0]
    set txt [string range $txt 1 end]
    return $c
}

proc tcvJSON::parse {txt} {
    return [Parse]
}

# Modified from Tcllib's json::_json2dict proc.

proc tcvJSON::Parse {{txtvar txt}} {
    upvar 1 $txtvar txt

    set state TOP
    set current {}

    set txt [string trimleft $txt]
    while {$txt ne ""} {
        set c [string index $txt 0]

        # skip whitespace
        while {[string is space $c]} {
            getc
            set c [string index $txt 0]
        }

        if {$c eq "\{"} {
            # object
            switch -- $state {
                TOP {
                    # This is the toplevel object.
                    getc
                    set state OBJECT
                    set current [create obj]
                }
                VALUE {
                    # We are inside an object looking at the value, which is another object.
                    put! -type auto current $name [Parse]
                    set state COMMA
                }
                LIST {
                    # We are inside a list and the next element is an object.
                    add! -type auto current [Parse]
                    set state COMMA
                }
                default {
                    return -code error "unexpected open brace in $state mode"
                }
            }
        } elseif {$c eq "\}"} {
            getc
            if {$state ne "OBJECT" && $state ne "COMMA"} {
                return -code error "unexpected close brace in $state mode"
            }
            return $current
        } elseif {$c eq ":"} {
            # name separator
            getc

            if {$state eq "COLON"} {
                set state VALUE
            } else {
                return -code error "unexpected colon in $state mode"
            }
        } elseif {$c eq ","} {
            # element separator
            if {$state eq "COMMA"} {
                getc
                if {[lindex $current 0] eq "list"} {
                    set state LIST
                } elseif {[lindex $current 0] eq "obj"} {
                    set state OBJECT
                }
            } else {
                return -code error "unexpected comma in $state mode"
            }
        } elseif {$c eq "\""} {
            # string
            # capture quoted string with backslash sequences
            set reStr {(?:(?:\")(?:[^\\\"]*(?:\\.[^\\\"]*)*)(?:\"))}
            set string ""
            if {![regexp $reStr $txt string]} {
                set txt [string replace $txt 32 end ...]
                return -code error "invalid formatted string in $txt"
            }
            set txt [string range $txt [string length $string] end]
            # chop off outer ""s and substitute backslashes
            # This does more than the RFC-specified backslash sequences,
            # but it does cover them all
            set string [subst -nocommand -novariable \
                            [string range $string 1 end-1]]

            switch -- $state {
                TOP {
                    return $string
                }
                OBJECT {
                    set name $string
                    set state COLON
                }
                LIST {
                    add! -type str current $string
                    set state COMMA
                }
                VALUE {
                    put! -type str current $name $string
                    unset name
                    set state COMMA
                }
            }
        } elseif {$c eq "\["} {
            # JSON array == Tcl list
            switch -- $state {
                TOP {
                    getc
                    set current [create list]
                    set state LIST
                }
                LIST {
                    add! -type auto current [Parse]
                    set state COMMA
                }
                VALUE {
                    put! -type auto current $name [Parse]
                    set state COMMA
                }
                default {
                    return -code error "unexpected open bracket in $state mode"
                }
            }
        } elseif {$c eq "\]"} {
            # end of list
            getc
            return $current
        } elseif {[string match {[-0-9]} $c]} {
            # one last check for a number, no leading zeros allowed,
            # but it may be 0.xxx
            string is double -failindex last $txt
            if {$last > 0} {
                set num [string range $txt 0 [expr {$last - 1}]]
                set txt [string range $txt $last end]

                switch -- $state {
                    TOP {
                        return $num
                    }
                    LIST {
                        add! -type num current $num
                        set state COMMA
                    }
                    VALUE {
                        put! -type num current $name $num
                        set state COMMA
                    }
                    default {
                        getc
                        return -code error "unexpected number '$c' in $state mode"
                    }
                }
            } else {
                getc
                return -code error "unexpected '$c' in $state mode"
            }
        } elseif {[string match {[ftn]} $c]
                  && [regexp {^(true|false|null)} $txt val]} {
            # bare word value: true | false | null
            set txt [string range $txt [string length $val] end]

            switch -- $state {
                TOP {
                    return $val
                }
                LIST {
                    add! current $val
                    set state COMMA
                }
                VALUE {
                    put! current $name $val
                    set state COMMA
                }
                default {
                    getc
                    return -code error "unexpected '$c' in $state mode"
                }
            }
        } else {
            # error, incorrect format or unexpected end of text
            return -code error "unexpected '$c' in $state mode"
        }
    }
}

# Synopsis: objForEach KEY VALUE OBJ SCRIPT
# Iterates through the key/value pairs in the supplied JSON object OBJ and sets
# KEY and VALUE in the environment of SCRIPT, then running SCRIPT at the
# caller's level.

proc tcvJSON::objForEach {k v obj script} {
    if {[lindex $obj 0] ne "obj"} {
        error "this is not an object"
    }

    for {set i 1} {$i < [llength $obj]} {incr i 2} {
        uplevel [list set $k [lindex $obj $i]]
        uplevel [list set $v [lindex $obj $i+1]]
        uplevel $script
    }

    if {[llength $obj] > 1} {
        # Clean up after ourselves.
        uplevel [list unset $k]
        uplevel [list unset $v]
    }
}

# Synopsis: exists? JSON THING
# Indicates whether THING exists within JSON.  If JSON is an object, then we
# treat THING like a key.  If JSON is a list, we treat THING like an element.
# It is an error for the value of JSON to be a non-composite type.

proc tcvJSON::exists? {json thing} {
    if {[lindex $json 0] eq "obj"} {
        set increment 2
    } elseif {[lindex $json 0] eq "list"} {
        set increment 1
    } else {
        error "not a composite type"
    }
    for {set i 1} {$i < [llength $json]} {incr i $increment} {
        if {[lindex $json $i] == $thing} {
            return 1
        }
    }
    return 0
}

# Synopsis: listForEach ELT LIST SCRIPT
# Iterates through all the elements in the supplied JSON list LIST and sets ELT
# appropriately in the environment of SCRIPT, then running SCRIPT at the
# caller's level.

proc tcvJSON::listForEach {e lst script} {
    if {[lindex $lst 0] ne "list"} {
        error "this is not a list"
    }

    for {set i 1} {$i < [llength $lst]} {incr i} {
        uplevel [list set $e [lindex $obj $i]]
        uplevel $script
    }

    # Don't leave the variables set.
    uplevel [list unset $e]
}
