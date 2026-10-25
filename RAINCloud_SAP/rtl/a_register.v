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
// CREATED		"Sat Dec 11 20:51:07 2021"

module A_Register(
	CLK,
	CLR,
	A_REG_IN_EN,
	A_REG_OUT_EN,
	A_REG_IN,
	A_REG_ALU,
	A_REG_DISPLAY,
	A_REG_OUT_DB
);


input wire	CLK;
input wire	CLR;
input wire	A_REG_IN_EN;
input wire	A_REG_OUT_EN;
input wire	[7:0] A_REG_IN;
output wire	[7:0] A_REG_ALU;
output wire	[7:0] A_REG_DISPLAY;
output wire	[7:0] A_REG_OUT_DB;

wire	[7:0] a_value;
wire	[7:0] a_load_data;
wire	[7:0] a_input;
wire	[7:0] a_bus_output;
wire	a_load_enable_n;
wire	a_output_enable_n;





IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(a_load_enable_n),
	.bG2(a_load_enable_n),
	.D_1(a_load_data[7]),
	.D_2(a_load_data[6]),
	.D_3(a_load_data[5]),
	.D_4(a_load_data[4]),
	.CLR(CLR),
	.Q_1(a_value[7]),
	.Q_2(a_value[6]),
	.Q_3(a_value[5]),
	.Q_4(a_value[4]));


IC_74LS173_RTL	b2v_173_2(
	.CLK(CLK),
	.bG1(a_load_enable_n),
	.bG2(a_load_enable_n),
	.D_1(a_load_data[3]),
	.D_2(a_load_data[2]),
	.D_3(a_load_data[1]),
	.D_4(a_load_data[0]),
	.CLR(CLR),
	.Q_1(a_value[3]),
	.Q_2(a_value[2]),
	.Q_3(a_value[1]),
	.Q_4(a_value[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_1(
	.bOE(a_output_enable_n),
	.A1(a_value[7]),
	.A2(a_value[6]),
	.A3(a_value[5]),
	.A4(a_value[4]),
	.A5(a_value[3]),
	.A6(a_value[2]),
	.A7(a_value[1]),
	.A8(a_value[0]),
	.B1(a_bus_output[7]),
	.B2(a_bus_output[6]),
	.B3(a_bus_output[5]),
	.B4(a_bus_output[4]),
	.B5(a_bus_output[3]),
	.B6(a_bus_output[2]),
	.B7(a_bus_output[1]),
	.B8(a_bus_output[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_2(
	.bOE(a_load_enable_n),
	.A1(a_input[7]),
	.A2(a_input[6]),
	.A3(a_input[5]),
	.A4(a_input[4]),
	.A5(a_input[3]),
	.A6(a_input[2]),
	.A7(a_input[1]),
	.A8(a_input[0]),
	.B1(a_load_data[7]),
	.B2(a_load_data[6]),
	.B3(a_load_data[5]),
	.B4(a_load_data[4]),
	.B5(a_load_data[3]),
	.B6(a_load_data[2]),
	.B7(a_load_data[1]),
	.B8(a_load_data[0]));

assign	a_output_enable_n =  ~A_REG_OUT_EN;

assign	a_load_enable_n =  ~A_REG_IN_EN;

assign	A_REG_ALU = a_value;
assign	a_input = A_REG_IN;
assign	A_REG_DISPLAY = a_value;
assign	A_REG_OUT_DB = a_bus_output;

endmodule
