# IS42S16320F-7, 3.3V, CL3, board 50 MHz profile. See docs/TIMING.md.
create_clock -name ref_clk -period 20.000 [get_ports MAX10_CLK1_50]
derive_pll_clocks
create_generated_clock -name sdram_clk -source [get_pins {clocks|pll|auto_generated|pll1|clk[1]}] -divide_by 1 [get_ports DRAM_CLK]
derive_clock_uncertainty
# Conservative +/-0.5ns board trace skew allowance (not measured board flight times).
# tAC(max)=5.4ns; tOH(min)=2.5ns; setup=1.5ns; hold=0.8ns.
set_input_delay -clock sdram_clk -max 5.900 [get_ports {DRAM_DQ[*]}]
set_input_delay -clock sdram_clk -min 2.000 [get_ports {DRAM_DQ[*]}]
set_output_delay -clock sdram_clk -max 2.000 [get_ports {DRAM_ADDR[*] DRAM_BA[*] DRAM_DQ[*] DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N DRAM_LDQM DRAM_UDQM}]
set_output_delay -clock sdram_clk -min -1.300 [get_ports {DRAM_ADDR[*] DRAM_BA[*] DRAM_DQ[*] DRAM_RAS_N DRAM_CAS_N DRAM_WE_N DRAM_CKE DRAM_CS_N DRAM_LDQM DRAM_UDQM}]
# Human controls are asynchronous; only first synchronizer stages are excluded.
set_false_path -from [get_ports {SW[*] KEY[*]}] -to [get_registers {*sw_meta* *key_meta*}]
# Static human indicators have no external synchronous capture clock.
set_false_path -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]
# USB-Blaster JTAG profile: 10 MHz or slower; 20ns external arrival/setup
# allowance. Keep these paths timed instead of blanket-cutting the JTAG domain.
if {[get_collection_size [get_ports -nowarn altera_reserved_tck]] > 0} {
    if {[get_collection_size [get_clocks -nowarn altera_reserved_tck]] == 0} {
        create_clock -name altera_reserved_tck -period 100.0 [get_ports altera_reserved_tck]
    }
    set_input_delay -clock altera_reserved_tck -clock_fall -max 20.0 [get_ports {altera_reserved_tdi altera_reserved_tms}]
    set_input_delay -clock altera_reserved_tck -clock_fall -min 0.0 [get_ports {altera_reserved_tdi altera_reserved_tms}]
    set_output_delay -clock altera_reserved_tck -max 20.0 [get_ports altera_reserved_tdo]
    set_output_delay -clock altera_reserved_tck -min 0.0 [get_ports altera_reserved_tdo]
}
