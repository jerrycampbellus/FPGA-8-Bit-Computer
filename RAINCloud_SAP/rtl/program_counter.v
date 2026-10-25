// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Lite Edition"
// CREATED		"Mon Dec 27 16:03:17 2021"

module Program_Counter(
	CE,
	CLK,
	JMP,
	CLR,
	COUNT_OUT,
	PC_IN_DB,
	PC_DISP,
	PC_OUT_DB
);


input wire	CE;
input wire	CLK;
input wire	JMP;
input wire	CLR;
input wire	COUNT_OUT;
input wire	[7:0] PC_IN_DB;
output wire	[3:0] PC_DISP;
output wire	[7:0] PC_OUT_DB;

wire	[3:0] pc_value;
wire	[7:0] pc_bus_output;
wire	pc_load_n;
wire	pc_clear_n;
wire	pc_load_bit0;
wire	pc_load_bit1;
wire	pc_load_bit2;
wire	pc_load_bit3;
wire	pc_output_enable_n;
wire	logic_zero;
wire	pc_jump_n;

assign	logic_zero = 0;


IC_74LS161_RTL	b2v_161_1(
	.bLOAD(pc_load_n),
	.bCLR(pc_clear_n),
	.DATA_A(pc_load_bit0),
	.DATA_B(pc_load_bit1),
	.CLK(CLK),
	.DATA_C(pc_load_bit2),
	.DATA_D(pc_load_bit3),
	.ENP(CE),
	.ENT(CE),
	.Q_A(pc_value[0]),
	.Q_B(pc_value[1]),
	.Q_C(pc_value[2]),
	.Q_D(pc_value[3]),
	.RCO() // standalone 4-bit counter; no carry cascade
	);


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_1(
	.bOE(pc_output_enable_n),
	.A1(pc_value[0]),
	.A2(pc_value[1]),
	.A3(pc_value[2]),
	.A4(pc_value[3]),
	.A5(logic_zero),
	.A6(logic_zero),
	.A7(logic_zero),
	.A8(logic_zero),
	.B1(pc_bus_output[0]),
	.B2(pc_bus_output[1]),
	.B3(pc_bus_output[2]),
	.B4(pc_bus_output[3]),
	.B5(pc_bus_output[4]),
	.B6(pc_bus_output[5]),
	.B7(pc_bus_output[6]),
	.B8(pc_bus_output[7]));


IC_74LS245BA_RTL #(.FPGA_MODE(1))	b2v_HEX_2(
	.bOE(pc_jump_n),
	.B1(PC_IN_DB[0]),
	.B2(PC_IN_DB[1]),
	.B3(PC_IN_DB[2]),
	.B4(PC_IN_DB[3]),
	.B5(PC_IN_DB[4]),
	.B6(PC_IN_DB[5]),
	.B7(PC_IN_DB[6]),
	.B8(PC_IN_DB[7]),
	.A1(pc_load_bit0),
	.A2(pc_load_bit1),
	.A3(pc_load_bit2),
	.A4(pc_load_bit3),
	.A5(), .A6(), .A7(), .A8() // PC loads only the low nibble
	
	
	
	);



assign	pc_jump_n =  ~JMP;

assign	pc_clear_n =  ~CLR;

assign	pc_output_enable_n =  ~COUNT_OUT;

assign	pc_load_n = pc_jump_n ~^ pc_clear_n;

assign	PC_DISP = pc_value;
assign	PC_OUT_DB = pc_bus_output;

endmodule
