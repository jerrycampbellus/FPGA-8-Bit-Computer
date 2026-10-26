# RAINCloud release 26101404: narrow cleanup for the Quartus 23.1 generated
# single-channel JTAG adapters. Run automatically by PRE_FLOW_SCRIPT_FILE.
# No warning suppression and no changes to the installed Intel IP templates.
# Repeated runs are idempotent; unexpected generator output fails explicitly.
# A raw copy is retained under build/jtag-raw for port-equivalence testing.

proc raincloud_replace_once {text before after} {
    set index [string first $before $text]
    if {$index < 0 || $index != [string last $before $text]} {
        error "JTAG generator shape changed; expected one occurrence of: $before"
    }
    return [string replace $text $index [expr {$index+[string length $before]-1}] $after]
}

proc raincloud_adapter_text {name text} {
    set marker "// RAINCloud 26101404: unused adapter bookkeeping removed."
    set prepared [expr {[string first $marker $text]>=0}]
    switch -- $name {
        jtag_bridge_master_timing_adt.sv {
            foreach expected {{in_use_ready:       false} {out_use_ready:      true} {in_ready_latency:   0} {out_ready_latency:  0}} {
                if {[string first $expected $text]<0} {error "Unsupported timing adapter: $expected"}
            }
            if {!$prepared} {
                set text [raincloud_replace_once $text {   reg [1-1:0]   ready;   } {}]
                set text [raincloud_replace_once $text {   reg           in_ready;} {}]
                # ready[0] and in_ready are aliases of out_ready used only by
                # the simulation diagnostic. Monitor that port directly.
                set text [raincloud_replace_once $text {always @(negedge in_ready)} {always @(negedge out_ready)}]
                set text [raincloud_replace_once $text {     ready[0]    = out_ready;} {}]
                set text [raincloud_replace_once $text {     in_ready    = ready[0];} {}]
            }
            set code [regsub -all {"(?:\\.|[^"\\])*"|//[^\n]*} $text {}]
            if {[regexp {\m(in_ready|ready)\M} $code] ||
                [string first {always @(negedge out_ready)} $text]<0} {
                error "Unexpected ready bookkeeping in prepared timing adapter"
            }
        }
        jtag_bridge_master_b2p_adapter.sv {
            foreach expected {{in_channel_width:    8} {out_channel_width:   0} {out_max_channel:     0}} {
                if {[string first $expected $text]<0} {error "Unsupported channel adapter: $expected"}
            }
            if {!$prepared} {
                set text [raincloud_replace_once $text {    reg out_channel;} {}]
                set text [raincloud_replace_once $text {      out_channel = in_channel; //TODO delete this to avoid Quartus warnings} {}]
            }
            # Keep the real channel-zero filter; only the unused local copy goes.
            if {[regexp {\mout_channel\M} $text] || [string first {if (in_channel > 0)} $text]<0} {
                error "Unexpected channel logic in prepared adapter"
            }
        }
        default {error "Unsupported adapter: $name"}
    }
    if {!$prepared} {append text "\n$marker\n"}
    return $text
}

proc raincloud_prepare_jtag {root} {
    set directory [file join $root src ip jtag_bridge synthesis submodules]
    set updates {}
    # Validate both complete transformations before writing either file.
    foreach name {jtag_bridge_master_timing_adt.sv jtag_bridge_master_b2p_adapter.sv} {
        set path [file join $directory $name]
        set channel [open $path r]
        set original [read $channel]
        close $channel
        set prepared [raincloud_adapter_text $name $original]
        if {$prepared ne $original} {lappend updates [list $path $name $original $prepared]}
    }
    foreach update $updates {
        lassign $update path name original prepared
        set raw_directory [file join $root build jtag-raw]
        file mkdir $raw_directory
        set channel [open [file join $raw_directory $name] w]
        fconfigure $channel -translation lf
        puts -nonewline $channel $original
        close $channel
        set channel [open "$path.raincloud-tmp" w]
        fconfigure $channel -translation lf
        puts -nonewline $channel $prepared
        close $channel
        file rename -force "$path.raincloud-tmp" $path
        puts "RAINCloud: prepared $name"
    }
    puts "RAINCloud: JTAG adapter check passed ([llength $updates] files updated)"
}

if {![info exists ::raincloud_prepare_jtag_library_only]} {
    raincloud_prepare_jtag [file dirname [file dirname [file normalize [info script]]]]
}
