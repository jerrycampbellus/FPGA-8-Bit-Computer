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
// CREATED		"Sat Dec 11 20:46:54 2021"

module B_Register(
	CLR,
	CLK,
	B_REG_IN_EN,
	B_REG_OUT_EN,
	B_REG_IN,
	B_REG_ALU,
	B_REG_DISPLAY,
	B_REG_OUT_DB
);


input wire	CLR;
input wire	CLK;
input wire	B_REG_IN_EN;
input wire	B_REG_OUT_EN;
input wire	[7:0] B_REG_IN;
output wire	[7:0] B_REG_ALU;
output wire	[7:0] B_REG_DISPLAY;
output wire	[7:0] B_REG_OUT_DB;

wire	[7:0] b_value;
wire	[7:0] b_load_data;
wire	[7:0] b_input;
wire	[7:0] b_bus_output;
wire	b_load_enable_n;
wire	b_output_enable_n;





IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(b_load_enable_n),
	.bG2(b_load_enable_n),
	.D_1(b_load_data[7]),
	.D_2(b_load_data[6]),
	.D_3(b_load_data[5]),
	.D_4(b_load_data[4]),
	.CLR(CLR),
	.Q_1(b_value[7]),
	.Q_2(b_value[6]),
	.Q_3(b_value[5]),
	.Q_4(b_value[4]));


IC_74LS173_RTL	b2v_173_2(
	.CLK(CLK),
	.bG1(b_load_enable_n),
	.bG2(b_load_enable_n),
	.D_1(b_load_data[3]),
	.D_2(b_load_data[2]),
	.D_3(b_load_data[1]),
	.D_4(b_load_data[0]),
	.CLR(CLR),
	.Q_1(b_value[3]),
	.Q_2(b_value[2]),
	.Q_3(b_value[1]),
	.Q_4(b_value[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_1(
	.bOE(b_output_enable_n),
	.A1(b_value[7]),
	.A2(b_value[6]),
	.A3(b_value[5]),
	.A4(b_value[4]),
	.A5(b_value[3]),
	.A6(b_value[2]),
	.A7(b_value[1]),
	.A8(b_value[0]),
	.B1(b_bus_output[7]),
	.B2(b_bus_output[6]),
	.B3(b_bus_output[5]),
	.B4(b_bus_output[4]),
	.B5(b_bus_output[3]),
	.B6(b_bus_output[2]),
	.B7(b_bus_output[1]),
	.B8(b_bus_output[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_inst2(
	.bOE(b_load_enable_n),
	.A1(b_input[7]),
	.A2(b_input[6]),
	.A3(b_input[5]),
	.A4(b_input[4]),
	.A5(b_input[3]),
	.A6(b_input[2]),
	.A7(b_input[1]),
	.A8(b_input[0]),
	.B1(b_load_data[7]),
	.B2(b_load_data[6]),
	.B3(b_load_data[5]),
	.B4(b_load_data[4]),
	.B5(b_load_data[3]),
	.B6(b_load_data[2]),
	.B7(b_load_data[1]),
	.B8(b_load_data[0]));

assign	b_output_enable_n =  ~B_REG_OUT_EN;

assign	b_load_enable_n =  ~B_REG_IN_EN;

assign	B_REG_ALU = b_value;
assign	b_input = B_REG_IN;
assign	B_REG_DISPLAY = b_value;
assign	B_REG_OUT_DB = b_bus_output;

endmodule
