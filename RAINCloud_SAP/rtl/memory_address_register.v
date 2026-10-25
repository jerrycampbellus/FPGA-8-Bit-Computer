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
// CREATED		"Sat Dec 11 20:39:03 2021"

module Memory_Address_Register(
	CLR,
	CLK,
	MEMORY_ADDRESS_IN,
	MEMORY_ADDRESS_ENABLE,
	ADDRESS_BUS,
	MEMORY_ADDRESS_DISP,
	MEMORY_ADDRESS_OUT
);


input wire	CLR;
input wire	CLK;
input wire	MEMORY_ADDRESS_IN;
input wire	MEMORY_ADDRESS_ENABLE;
input wire	[7:0] ADDRESS_BUS;
output wire	[3:0] MEMORY_ADDRESS_DISP;
output wire	[3:0] MEMORY_ADDRESS_OUT;

wire	[7:0] address_input;
wire	[3:0] address_value;
wire	[3:0] address_output;
wire	address_output_enable_n;
wire	address_load_enable_n;


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_1(
	.bOE(address_output_enable_n),
	.A1(1'b0), .A2(1'b0), .A3(1'b0), .A4(1'b0),
	.B1(), .B2(), .B3(), .B4(), // unused half of the 8-bit buffer
	.A5(address_value[0]),
	.A6(address_value[1]),
	.A7(address_value[2]),
	.A8(address_value[3]),	
	.B5(address_output[0]),
	.B6(address_output[1]),
	.B7(address_output[2]),
	.B8(address_output[3]));

IC_74LS173_RTL	b2v_inst(
	.CLK(CLK),
	.bG1(address_load_enable_n),
	.bG2(address_load_enable_n),
	.D_1(address_input[3]),
	.D_2(address_input[2]),
	.D_3(address_input[1]),
	.D_4(address_input[0]),
	.CLR(CLR),
	.Q_1(address_value[3]),
	.Q_2(address_value[2]),
	.Q_3(address_value[1]),
	.Q_4(address_value[0]));

assign	address_load_enable_n =  ~MEMORY_ADDRESS_IN;

assign	address_output_enable_n =  ~MEMORY_ADDRESS_ENABLE;

assign	MEMORY_ADDRESS_DISP = address_value;
assign	address_input = ADDRESS_BUS;
assign	MEMORY_ADDRESS_OUT = address_output;

endmodule
