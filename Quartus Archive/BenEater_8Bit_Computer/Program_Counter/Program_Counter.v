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

wire	[3:0] PC_DISP_ALTERA_SYNTHESIZED;
wire	[7:0] PC_OUT_DB_ALTERA_SYNTHESIZED;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_14;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_3;
wire	SYNTHESIZED_WIRE_4;
wire	SYNTHESIZED_WIRE_5;
wire	SYNTHESIZED_WIRE_6;
wire	SYNTHESIZED_WIRE_15;
wire	SYNTHESIZED_WIRE_16;

assign	SYNTHESIZED_WIRE_15 = 0;


IC_74LS161_RTL	b2v_161_1(
	.bLOAD(SYNTHESIZED_WIRE_0),
	.bCLR(SYNTHESIZED_WIRE_14),
	.DATA_A(SYNTHESIZED_WIRE_2),
	.DATA_B(SYNTHESIZED_WIRE_3),
	.CLK(CLK),
	.DATA_C(SYNTHESIZED_WIRE_4),
	.DATA_D(SYNTHESIZED_WIRE_5),
	.ENP(CE),
	.ENT(CE),
	.Q_A(PC_DISP_ALTERA_SYNTHESIZED[0]),
	.Q_B(PC_DISP_ALTERA_SYNTHESIZED[1]),
	.Q_C(PC_DISP_ALTERA_SYNTHESIZED[2]),
	.Q_D(PC_DISP_ALTERA_SYNTHESIZED[3])
	);


IC_74LS245AB_RTL	b2v_HEX_1(
	.bOE(SYNTHESIZED_WIRE_6),
	.A1(PC_DISP_ALTERA_SYNTHESIZED[0]),
	.A2(PC_DISP_ALTERA_SYNTHESIZED[1]),
	.A3(PC_DISP_ALTERA_SYNTHESIZED[2]),
	.A4(PC_DISP_ALTERA_SYNTHESIZED[3]),
	.A5(SYNTHESIZED_WIRE_15),
	.A6(SYNTHESIZED_WIRE_15),
	.A7(SYNTHESIZED_WIRE_15),
	.A8(SYNTHESIZED_WIRE_15),
	.B1(PC_OUT_DB_ALTERA_SYNTHESIZED[0]),
	.B2(PC_OUT_DB_ALTERA_SYNTHESIZED[1]),
	.B3(PC_OUT_DB_ALTERA_SYNTHESIZED[2]),
	.B4(PC_OUT_DB_ALTERA_SYNTHESIZED[3]),
	.B5(PC_OUT_DB_ALTERA_SYNTHESIZED[4]),
	.B6(PC_OUT_DB_ALTERA_SYNTHESIZED[5]),
	.B7(PC_OUT_DB_ALTERA_SYNTHESIZED[6]),
	.B8(PC_OUT_DB_ALTERA_SYNTHESIZED[7]));


IC_74LS245BA_RTL	b2v_HEX_2(
	.bOE(SYNTHESIZED_WIRE_16),
	.B1(PC_IN_DB[0]),
	.B2(PC_IN_DB[1]),
	.B3(PC_IN_DB[2]),
	.B4(PC_IN_DB[3]),
	.B5(PC_IN_DB[4]),
	.B6(PC_IN_DB[5]),
	.B7(PC_IN_DB[6]),
	.B8(PC_IN_DB[7]),
	.A1(SYNTHESIZED_WIRE_2),
	.A2(SYNTHESIZED_WIRE_3),
	.A3(SYNTHESIZED_WIRE_4),
	.A4(SYNTHESIZED_WIRE_5)
	
	
	
	);



assign	SYNTHESIZED_WIRE_16 =  ~JMP;

assign	SYNTHESIZED_WIRE_14 =  ~CLR;

assign	SYNTHESIZED_WIRE_6 =  ~COUNT_OUT;

assign	SYNTHESIZED_WIRE_0 = SYNTHESIZED_WIRE_16 ~^ SYNTHESIZED_WIRE_14;

assign	PC_DISP = PC_DISP_ALTERA_SYNTHESIZED;
assign	PC_OUT_DB = PC_OUT_DB_ALTERA_SYNTHESIZED;

endmodule
