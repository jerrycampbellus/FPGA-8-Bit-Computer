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
// CREATED		"Mon Dec 06 17:36:45 2021"

module IC_74LS245BA_RTL(
	bOE,
	B1,
	B2,
	B3,
	B4,
	B5,
	B6,
	B7,
	B8,
	A1,
	A2,
	A3,
	A4,
	A5,
	A6,
	A7,
	A8
);


input wire	bOE;
input wire	B1;
input wire	B2;
input wire	B3;
input wire	B4;
input wire	B5;
input wire	B6;
input wire	B7;
input wire	B8;
output wire	A1;
output wire	A2;
output wire	A3;
output wire	A4;
output wire	A5;
output wire	A6;
output wire	A7;
output wire	A8;



assign	A1 = !bOE ? B1 : 1'bz;

assign	A2 = !bOE ? B2 : 1'bz;

assign	A3 = !bOE ? B3 : 1'bz;

assign	A4 = !bOE ? B4 : 1'bz;

assign	A5 = !bOE ? B5 : 1'bz;

assign	A6 = !bOE ? B6 : 1'bz;

assign	A7 = !bOE ? B7 : 1'bz;

assign	A8 = !bOE ? B8 : 1'bz;

endmodule
