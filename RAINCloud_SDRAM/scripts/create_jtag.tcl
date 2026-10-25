package require -exact qsys 23.1
create_system jtag_bridge
set_project_property DEVICE_FAMILY "MAX 10"
set_project_property DEVICE 10M50DAF484C7G
add_instance master altera_jtag_avalon_master
set_instance_parameter_value master USE_PLI 0
set_instance_parameter_value master FAST_VER 0
add_interface clk clock sink
set_interface_property clk EXPORT_OF master.clk
add_interface reset reset sink
set_interface_property reset EXPORT_OF master.clk_reset
add_interface avalon avalon master
set_interface_property avalon EXPORT_OF master.master
add_interface master_reset reset source
set_interface_property master_reset EXPORT_OF master.master_reset
save_system src/ip/jtag_bridge.qsys
