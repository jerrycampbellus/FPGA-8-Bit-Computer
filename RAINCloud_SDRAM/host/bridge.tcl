# Persistent stdin/stdout adapter. Only numeric register operations are accepted.
# No eval of host input. USB-Blaster is a JTAG service, not a COM port.
set service ""
# System Console owns stdin as a Tcl REPL. Define a numeric RPC command in that
# interpreter instead of racing it with a second gets-stdin loop.
proc sdram_rpc {id op args} {
    global service
    set fields [linsert $args 0 $id $op]
    if {![string is integer -strict $id] || $id < 1} {return}
    set result ""
    if {[catch {
        switch -- $op {
            C {
                if {$service ne ""} {catch {close_service master $service}; set service ""}
                set paths [get_service_paths master]
                for {set n 0} {$n<50 && [llength $paths]==0} {incr n} {
                    after 100; update; set paths [get_service_paths master]
                }
                set index [lindex $fields 2]
                if {$index eq "auto"} {
                    if {[llength $paths]!=1} {error "Expected exactly one JTAG master; specify service index (found [llength $paths])"}
                    set index 0
                }
                if {![string is integer -strict $index] || $index<0 || $index>=[llength $paths]} {error "Invalid master index"}
                set service [lindex $paths $index]
                open_service master $service
                set result connected
            }
            R - W {
                if {$service eq ""} {error "Not connected"}
                set address [lindex $fields 2]
                set count [lindex $fields 3]
                if {![string is integer -strict $address] || ![string is integer -strict $count]} {error "Expected integers"}
                if {$address<0 || ($address%4)!=0 || $count<1 || $count>128 || !(($address>=0 && $address+4*$count<=512) || ($address>=4096 && $address+4*$count<=8192))} {error "Register access out of range"}
                if {$op eq "R"} {
                    set result [master_read_32 $service $address $count]
                } else {
                    set words [lrange $fields 4 end]
                    if {[llength $words]!=$count} {error "Length mismatch"}
                    foreach word $words {
                        if {![string is wideinteger -strict $word] || $word<0 || $word>4294967295} {error "Invalid word"}
                    }
                    master_write_32 $service $address $words
                    set result written
                }
            }
            Q {if {$service ne ""} {catch {close_service master $service}; set service ""}; set result bye}
            default {error "Unknown operation"}
        }
    } detail]} {
        puts "@$id ERR [string map [list \n { } \r { }] $detail]"
    } else {puts "@$id OK $result"}
    flush stdout
}
puts "@0 OK ready"
flush stdout
