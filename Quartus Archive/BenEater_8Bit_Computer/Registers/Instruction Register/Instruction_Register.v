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
// CREATED		"Sat Jan 01 15:01:17 2022"

module Instruction_Register(
	CLK,
	CLR,
	INST_REG_OUT,
	INST_REG_IN,
	INST_REG_IN_DB,
	INST_OPCODE,
	INST_OPERAND,
	INST_REG_DISPLAY,
	INST_REG_OUT_DB
);


input wire	CLK;
input wire	CLR;
input wire	INST_REG_OUT;
input wire	INST_REG_IN;
input wire	[7:0] INST_REG_IN_DB;
output wire	[3:0] INST_OPCODE;
output wire	[3:0] INST_OPERAND;
output wire	[7:0] INST_REG_DISPLAY;
output wire	[7:0] INST_REG_OUT_DB;

wire	[7:0] I_REG_DIS;
wire	[7:0] I_REG_IN;
wire	[7:0] I_REG_IN_DB;
wire	[7:0] I_REG_OUT;
wire	SYNTHESIZED_WIRE_10;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_11;

assign	SYNTHESIZED_WIRE_11 = 0;




IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(SYNTHESIZED_WIRE_10),
	.bG2(SYNTHESIZED_WIRE_10),
	.D_1(I_REG_IN_DB[7]),
	.D_2(I_REG_IN_DB[6]),
	.D_3(I_REG_IN_DB[5]),
	.D_4(I_REG_IN_DB[4]),
	.CLR(CLR),
	.Q_1(I_REG_DIS[7]),
	.Q_2(I_REG_DIS[6]),
	.Q_3(I_REG_DIS[5]),
	.Q_4(I_REG_DIS[4]));


IC_74LS173_RTL	b2v_173_2(
	.CLK(CLK),
	.bG1(SYNTHESIZED_WIRE_10),
	.bG2(SYNTHESIZED_WIRE_10),
	.D_1(I_REG_IN_DB[3]),
	.D_2(I_REG_IN_DB[2]),
	.D_3(I_REG_IN_DB[1]),
	.D_4(I_REG_IN_DB[0]),
	.CLR(CLR),
	.Q_1(I_REG_DIS[3]),
	.Q_2(I_REG_DIS[2]),
	.Q_3(I_REG_DIS[1]),
	.Q_4(I_REG_DIS[0]));


IC_74LS245AB_RTL	b2v_245AB_1(
	.bOE(SYNTHESIZED_WIRE_4),
	.A1(SYNTHESIZED_WIRE_11),
	.A2(SYNTHESIZED_WIRE_11),
	.A3(SYNTHESIZED_WIRE_11),
	.A4(SYNTHESIZED_WIRE_11),
	.A5(I_REG_DIS[3]),
	.A6(I_REG_DIS[2]),
	.A7(I_REG_DIS[1]),
	.A8(I_REG_DIS[0]),
	.B1(I_REG_OUT[7]),
	.B2(I_REG_OUT[6]),
	.B3(I_REG_OUT[5]),
	.B4(I_REG_OUT[4]),
	.B5(I_REG_OUT[3]),
	.B6(I_REG_OUT[2]),
	.B7(I_REG_OUT[1]),
	.B8(I_REG_OUT[0]));


IC_74LS245AB_RTL	b2v_245AB_2(
	.bOE(SYNTHESIZED_WIRE_10),
	.A1(I_REG_IN[7]),
	.A2(I_REG_IN[6]),
	.A3(I_REG_IN[5]),
	.A4(I_REG_IN[4]),
	.A5(I_REG_IN[3]),
	.A6(I_REG_IN[2]),
	.A7(I_REG_IN[1]),
	.A8(I_REG_IN[0]),
	.B1(I_REG_IN_DB[7]),
	.B2(I_REG_IN_DB[6]),
	.B3(I_REG_IN_DB[5]),
	.B4(I_REG_IN_DB[4]),
	.B5(I_REG_IN_DB[3]),
	.B6(I_REG_IN_DB[2]),
	.B7(I_REG_IN_DB[1]),
	.B8(I_REG_IN_DB[0]));


assign	SYNTHESIZED_WIRE_4 =  ~INST_REG_OUT;

assign	SYNTHESIZED_WIRE_10 =  ~INST_REG_IN;

assign	INST_OPCODE[3:0] = I_REG_DIS[7:4];
assign	I_REG_IN = INST_REG_IN_DB;
assign	INST_OPERAND[3:0] = I_REG_DIS[3:0];
assign	INST_REG_DISPLAY = I_REG_DIS;
assign	INST_REG_OUT_DB = I_REG_OUT;

endmodule
