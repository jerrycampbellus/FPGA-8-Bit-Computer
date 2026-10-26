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

wire	[7:0] instruction_value;
wire	[7:0] instruction_input;
wire	[7:0] instruction_load_data;
wire	[7:0] instruction_bus_output;
wire	instruction_load_enable_n;
wire	instruction_output_enable_n;
wire	logic_zero;

assign	logic_zero = 0;




IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(instruction_load_enable_n),
	.bG2(instruction_load_enable_n),
	.D_1(instruction_load_data[7]),
	.D_2(instruction_load_data[6]),
	.D_3(instruction_load_data[5]),
	.D_4(instruction_load_data[4]),
	.CLR(CLR),
	.Q_1(instruction_value[7]),
	.Q_2(instruction_value[6]),
	.Q_3(instruction_value[5]),
	.Q_4(instruction_value[4]));


IC_74LS173_RTL	b2v_173_2(
	.CLK(CLK),
	.bG1(instruction_load_enable_n),
	.bG2(instruction_load_enable_n),
	.D_1(instruction_load_data[3]),
	.D_2(instruction_load_data[2]),
	.D_3(instruction_load_data[1]),
	.D_4(instruction_load_data[0]),
	.CLR(CLR),
	.Q_1(instruction_value[3]),
	.Q_2(instruction_value[2]),
	.Q_3(instruction_value[1]),
	.Q_4(instruction_value[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_245AB_1(
	.bOE(instruction_output_enable_n),
	.A1(logic_zero),
	.A2(logic_zero),
	.A3(logic_zero),
	.A4(logic_zero),
	.A5(instruction_value[3]),
	.A6(instruction_value[2]),
	.A7(instruction_value[1]),
	.A8(instruction_value[0]),
	.B1(instruction_bus_output[7]),
	.B2(instruction_bus_output[6]),
	.B3(instruction_bus_output[5]),
	.B4(instruction_bus_output[4]),
	.B5(instruction_bus_output[3]),
	.B6(instruction_bus_output[2]),
	.B7(instruction_bus_output[1]),
	.B8(instruction_bus_output[0]));


IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_245AB_2(
	.bOE(instruction_load_enable_n),
	.A1(instruction_input[7]),
	.A2(instruction_input[6]),
	.A3(instruction_input[5]),
	.A4(instruction_input[4]),
	.A5(instruction_input[3]),
	.A6(instruction_input[2]),
	.A7(instruction_input[1]),
	.A8(instruction_input[0]),
	.B1(instruction_load_data[7]),
	.B2(instruction_load_data[6]),
	.B3(instruction_load_data[5]),
	.B4(instruction_load_data[4]),
	.B5(instruction_load_data[3]),
	.B6(instruction_load_data[2]),
	.B7(instruction_load_data[1]),
	.B8(instruction_load_data[0]));


assign	instruction_output_enable_n =  ~INST_REG_OUT;

assign	instruction_load_enable_n =  ~INST_REG_IN;

assign	INST_OPCODE[3:0] = instruction_value[7:4];
assign	instruction_input = INST_REG_IN_DB;
assign	INST_OPERAND[3:0] = instruction_value[3:0];
assign	INST_REG_DISPLAY = instruction_value;
assign	INST_REG_OUT_DB = instruction_bus_output;

endmodule
