# Run after IP generation/preparation with quartus_sh -t tests/test_prepare_jtag.tcl.
# Verify the real saved generator output, idempotence, and fail-closed shape guards.
set root [file dirname [file dirname [file normalize [info script]]]]
set ::raincloud_prepare_jtag_library_only 1
source [file join $root scripts prepare_jtag.tcl]
foreach name {jtag_bridge_master_timing_adt.sv jtag_bridge_master_b2p_adapter.sv} {
    set channel [open [file join $root build jtag-raw $name] r]
    set raw [read $channel]
    close $channel
    set once [raincloud_adapter_text $name $raw]
    if {[raincloud_adapter_text $name $once] ne $once} {error "Not idempotent: $name"}
    set channel [open [file join $root src ip jtag_bridge synthesis submodules $name] r]
    set actual [read $channel]
    close $channel
    if {$actual ne $once} {error "Prepared output mismatch: $name"}
    if {$name eq "jtag_bridge_master_timing_adt.sv"} {
        set bad [string map {{in_use_ready:       false} {in_use_ready:       true}} $raw]
    } else {
        set bad [string map {{out_channel = in_channel;} {out_channel = in_channel[0];}} $raw]
    }
    if {![catch {raincloud_adapter_text $name $bad}]} {error "Generator drift accepted: $name"}
    puts "PASS adapter preparation: $name, raw/prepared match, idempotent, generator drift rejected"
}
