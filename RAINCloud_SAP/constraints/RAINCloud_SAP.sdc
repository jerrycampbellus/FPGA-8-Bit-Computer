# RAINCloud Digital | RAINCloud_SAP
# Original SAP design and codebase: J. Campbell.
#
# 50 MHz board oscillator and fastest possible registered CPU clock (25 MHz).
# Slow and manual modes only lengthen intervals; no data transfer is enabled
# by an asynchronous board input. Both CPU phases are timed at this bound.
proc sap_require {collection expected label} {
    if {[get_collection_size $collection] != $expected} {
        error "RAINCloud_SAP: unexpected object count for $label; fix the constraint target"
    }
    return $collection
}
set board_clock_pin [sap_require [get_ports {MAX10_CLK1_50}] 1 board_clock]
set cpu_clock_reg [sap_require [get_registers {*b2v_CLK|CLK}] 1 cpu_clock]
create_clock -name board_clk -period 20.000 $board_clock_pin
create_generated_clock -name cpu_clk -source [get_ports {MAX10_CLK1_50}] \
    -divide_by 2 $cpu_clock_reg
derive_clock_uncertainty

# Buttons and switches are asynchronous. Cut only the first synchronizer
# stages, never the downstream synchronous paths.
set reset_sync_regs [sap_require [get_registers {*inputs|reset_pipe[*]}] 2 reset_sync]
set step_first_reg [sap_require [get_registers {*inputs|step_meta}] 1 step_sync]
set switch_first_regs [sap_require [get_registers {*inputs|switch_meta[*]}] 10 switch_sync]
set_false_path -from [get_ports {KEY[0]}] -to $reset_sync_regs
set_false_path -from [get_ports {KEY[1]}] -to $step_first_reg
set_false_path -from [get_ports {SW[*]}] -to $switch_first_regs

# LEDs/seven-segment outputs are human indicators without a capture clock.
# Their internal launch/control paths remain timed; external setup/hold
# requirements do not apply to these output-only display loads.
set display_pins [sap_require [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}] 58 display_pins]
set_false_path -to $display_pins
