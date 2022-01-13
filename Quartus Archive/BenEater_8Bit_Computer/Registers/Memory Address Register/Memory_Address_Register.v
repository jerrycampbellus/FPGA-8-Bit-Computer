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

wire	[7:0] AD_B;
wire	[3:0] MA;
wire	[3:0] MA_O;
wire	SYNTHESIZED_WIRE_0;
wire	SYNTHESIZED_WIRE_3;


IC_74LS245AB_RTL	b2v_HEX_1(
	.bOE(SYNTHESIZED_WIRE_0),
	.A5(MA[0]),
	.A6(MA[1]),
	.A7(MA[2]),
	.A8(MA[3]),	
	.B5(MA_O[0]),
	.B6(MA_O[1]),
	.B7(MA_O[2]),
	.B8(MA_O[3]));

IC_74LS173_RTL	b2v_inst(
	.CLK(CLK),
	.bG1(SYNTHESIZED_WIRE_3),
	.bG2(SYNTHESIZED_WIRE_3),
	.D_1(AD_B[3]),
	.D_2(AD_B[2]),
	.D_3(AD_B[1]),
	.D_4(AD_B[0]),
	.CLR(CLR),
	.Q_1(MA[3]),
	.Q_2(MA[2]),
	.Q_3(MA[1]),
	.Q_4(MA[0]));

assign	SYNTHESIZED_WIRE_3 =  ~MEMORY_ADDRESS_IN;

assign	SYNTHESIZED_WIRE_0 =  ~MEMORY_ADDRESS_ENABLE;

assign	MEMORY_ADDRESS_DISP = MA;
assign	AD_B = ADDRESS_BUS;
assign	MEMORY_ADDRESS_OUT = MA_O;
assign	AD_B[4] = 0;
assign	AD_B[5] = 0;
assign	AD_B[6] = 0;
assign	AD_B[7] = 0;

endmodule
