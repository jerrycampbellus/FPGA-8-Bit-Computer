project_open SDRAM_Test_Harness
create_timing_netlist
read_sdc
update_timing_netlist
report_timing -setup -npaths 12 -detail full_path -file ../build/setup-paths.txt
report_timing -hold -npaths 6 -detail full_path -file ../build/hold-paths.txt
report_ucp -file ../build/unconstrained.txt
delete_timing_netlist
project_close
