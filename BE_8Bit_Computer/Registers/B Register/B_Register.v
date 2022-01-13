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

wire	[7:0] B_REG_DISPLAY_ALTERA_SYNTHESIZED;
wire	[7:0] B_REG_IN_DB;
wire	[7:0] BR_IN;
wire	[7:0] BR_OUT_DB;
wire	SYNTHESIZED_WIRE_6;
wire	SYNTHESIZED_WIRE_4;





IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(SYNTHESIZED_WIRE_6),
	.bG2(SYNTHESIZED_WIRE_6),
	.D_1(B_REG_IN_DB[7]),
	.D_2(B_REG_IN_DB[6]),
	.D_3(B_REG_IN_DB[5]),
	.D_4(B_REG_IN_DB[4]),
	.CLR(CLR),
	.Q_1(B_REG_DISPLAY_ALTERA_SYNTHESIZED[7]),
	.Q_2(B_REG_DISPLAY_ALTERA_SYNTHESIZED[6]),
	.Q_3(B_REG_DISPLAY_ALTERA_SYNTHESIZED[5]),
	.Q_4(B_REG_DISPLAY_ALTERA_SYNTHESIZED[4]));


IC_74LS173_RTL	b2v_173_2(
	.CLK(CLK),
	.bG1(SYNTHESIZED_WIRE_6),
	.bG2(SYNTHESIZED_WIRE_6),
	.D_1(B_REG_IN_DB[3]),
	.D_2(B_REG_IN_DB[2]),
	.D_3(B_REG_IN_DB[1]),
	.D_4(B_REG_IN_DB[0]),
	.CLR(CLR),
	.Q_1(B_REG_DISPLAY_ALTERA_SYNTHESIZED[3]),
	.Q_2(B_REG_DISPLAY_ALTERA_SYNTHESIZED[2]),
	.Q_3(B_REG_DISPLAY_ALTERA_SYNTHESIZED[1]),
	.Q_4(B_REG_DISPLAY_ALTERA_SYNTHESIZED[0]));


IC_74LS245AB_RTL	b2v_HEX_1(
	.bOE(SYNTHESIZED_WIRE_4),
	.A1(B_REG_DISPLAY_ALTERA_SYNTHESIZED[7]),
	.A2(B_REG_DISPLAY_ALTERA_SYNTHESIZED[6]),
	.A3(B_REG_DISPLAY_ALTERA_SYNTHESIZED[5]),
	.A4(B_REG_DISPLAY_ALTERA_SYNTHESIZED[4]),
	.A5(B_REG_DISPLAY_ALTERA_SYNTHESIZED[3]),
	.A6(B_REG_DISPLAY_ALTERA_SYNTHESIZED[2]),
	.A7(B_REG_DISPLAY_ALTERA_SYNTHESIZED[1]),
	.A8(B_REG_DISPLAY_ALTERA_SYNTHESIZED[0]),
	.B1(BR_OUT_DB[7]),
	.B2(BR_OUT_DB[6]),
	.B3(BR_OUT_DB[5]),
	.B4(BR_OUT_DB[4]),
	.B5(BR_OUT_DB[3]),
	.B6(BR_OUT_DB[2]),
	.B7(BR_OUT_DB[1]),
	.B8(BR_OUT_DB[0]));


IC_74LS245AB_RTL	b2v_inst2(
	.bOE(SYNTHESIZED_WIRE_6),
	.A1(BR_IN[7]),
	.A2(BR_IN[6]),
	.A3(BR_IN[5]),
	.A4(BR_IN[4]),
	.A5(BR_IN[3]),
	.A6(BR_IN[2]),
	.A7(BR_IN[1]),
	.A8(BR_IN[0]),
	.B1(B_REG_IN_DB[7]),
	.B2(B_REG_IN_DB[6]),
	.B3(B_REG_IN_DB[5]),
	.B4(B_REG_IN_DB[4]),
	.B5(B_REG_IN_DB[3]),
	.B6(B_REG_IN_DB[2]),
	.B7(B_REG_IN_DB[1]),
	.B8(B_REG_IN_DB[0]));

assign	SYNTHESIZED_WIRE_4 =  ~B_REG_OUT_EN;

assign	SYNTHESIZED_WIRE_6 =  ~B_REG_IN_EN;

assign	B_REG_ALU = B_REG_DISPLAY_ALTERA_SYNTHESIZED;
assign	BR_IN = B_REG_IN;
assign	B_REG_DISPLAY = B_REG_DISPLAY_ALTERA_SYNTHESIZED;
assign	B_REG_OUT_DB = BR_OUT_DB;

endmodule
