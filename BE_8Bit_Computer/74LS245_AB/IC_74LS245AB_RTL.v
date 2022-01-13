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
// CREATED		"Mon Dec 06 17:21:07 2021"

module IC_74LS245AB_RTL(
	bOE,
	A1,
	A2,
	A3,
	A4,
	A5,
	A6,
	A7,
	A8,
	B1,
	B2,
	B3,
	B4,
	B5,
	B6,
	B7,
	B8
);


input wire	bOE;
input wire	A1;
input wire	A2;
input wire	A3;
input wire	A4;
input wire	A5;
input wire	A6;
input wire	A7;
input wire	A8;
output wire	B1;
output wire	B2;
output wire	B3;
output wire	B4;
output wire	B5;
output wire	B6;
output wire	B7;
output wire	B8;



assign	B1 = !bOE ? A1 : 1'bz;

assign	B2 = !bOE ? A2 : 1'bz;

assign	B3 = !bOE ? A3 : 1'bz;

assign	B4 = !bOE ? A4 : 1'bz;

assign	B5 = !bOE ? A5 : 1'bz;

assign	B6 = !bOE ? A6 : 1'bz;

assign	B7 = !bOE ? A7 : 1'bz;

assign	B8 = !bOE ? A8 : 1'bz;



endmodule
