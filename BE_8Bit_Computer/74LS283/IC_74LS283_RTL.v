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
// CREATED		"Sat Nov 06 15:42:54 2021"

module IC_74LS283_RTL(
	B4,
	A4,
	B3,
	A3,
	B2,
	A2,
	B1,
	A1,
	C_IN,
	C_OUT,
	SUM_4,
	SUM_3,
	SUM_2,
	SUM_1
);


input wire	B4;
input wire	A4;
input wire	B3;
input wire	A3;
input wire	B2;
input wire	A2;
input wire	B1;
input wire	A1;
input wire	C_IN;
output wire	C_OUT;
output wire	SUM_4;
output wire	SUM_3;
output wire	SUM_2;
output wire	SUM_1;

wire	SYNTHESIZED_WIRE_71;
wire	SYNTHESIZED_WIRE_72;
wire	SYNTHESIZED_WIRE_73;
wire	SYNTHESIZED_WIRE_74;
wire	SYNTHESIZED_WIRE_75;
wire	SYNTHESIZED_WIRE_76;
wire	SYNTHESIZED_WIRE_77;
wire	SYNTHESIZED_WIRE_78;
wire	SYNTHESIZED_WIRE_12;
wire	SYNTHESIZED_WIRE_31;
wire	SYNTHESIZED_WIRE_79;
wire	SYNTHESIZED_WIRE_33;
wire	SYNTHESIZED_WIRE_35;
wire	SYNTHESIZED_WIRE_37;
wire	SYNTHESIZED_WIRE_44;
wire	SYNTHESIZED_WIRE_45;
wire	SYNTHESIZED_WIRE_46;
wire	SYNTHESIZED_WIRE_47;
wire	SYNTHESIZED_WIRE_48;
wire	SYNTHESIZED_WIRE_49;
wire	SYNTHESIZED_WIRE_50;
wire	SYNTHESIZED_WIRE_51;
wire	SYNTHESIZED_WIRE_52;
wire	SYNTHESIZED_WIRE_53;
wire	SYNTHESIZED_WIRE_54;
wire	SYNTHESIZED_WIRE_55;
wire	SYNTHESIZED_WIRE_56;
wire	SYNTHESIZED_WIRE_57;
wire	SYNTHESIZED_WIRE_58;
wire	SYNTHESIZED_WIRE_63;
wire	SYNTHESIZED_WIRE_64;
wire	SYNTHESIZED_WIRE_65;
wire	SYNTHESIZED_WIRE_66;
wire	SYNTHESIZED_WIRE_67;
wire	SYNTHESIZED_WIRE_68;
wire	SYNTHESIZED_WIRE_69;
wire	SYNTHESIZED_WIRE_70;

assign	SYNTHESIZED_WIRE_12 = 1;
assign	SYNTHESIZED_WIRE_44 = 0;



assign	SYNTHESIZED_WIRE_45 = SYNTHESIZED_WIRE_71 & SYNTHESIZED_WIRE_72;

assign	SYNTHESIZED_WIRE_57 = SYNTHESIZED_WIRE_73 & SYNTHESIZED_WIRE_74;

assign	SYNTHESIZED_WIRE_47 = SYNTHESIZED_WIRE_75 & SYNTHESIZED_WIRE_72 & SYNTHESIZED_WIRE_76;

assign	SYNTHESIZED_WIRE_49 = SYNTHESIZED_WIRE_77 & SYNTHESIZED_WIRE_72 & SYNTHESIZED_WIRE_76 & SYNTHESIZED_WIRE_78;

assign	SYNTHESIZED_WIRE_48 = SYNTHESIZED_WIRE_76 & SYNTHESIZED_WIRE_12 & SYNTHESIZED_WIRE_72 & SYNTHESIZED_WIRE_78 & SYNTHESIZED_WIRE_73 & SYNTHESIZED_WIRE_74;

assign	SYNTHESIZED_WIRE_52 = SYNTHESIZED_WIRE_75 & SYNTHESIZED_WIRE_76;

assign	SYNTHESIZED_WIRE_51 = SYNTHESIZED_WIRE_77 & SYNTHESIZED_WIRE_76 & SYNTHESIZED_WIRE_78;

assign	SYNTHESIZED_WIRE_53 = SYNTHESIZED_WIRE_76 & SYNTHESIZED_WIRE_78 & SYNTHESIZED_WIRE_73 & SYNTHESIZED_WIRE_74;

assign	SYNTHESIZED_WIRE_55 = SYNTHESIZED_WIRE_77 & SYNTHESIZED_WIRE_78;

assign	SYNTHESIZED_WIRE_56 = SYNTHESIZED_WIRE_78 & SYNTHESIZED_WIRE_73 & SYNTHESIZED_WIRE_74;

assign	SYNTHESIZED_WIRE_63 = ~(SYNTHESIZED_WIRE_31 | SYNTHESIZED_WIRE_79);

assign	SYNTHESIZED_WIRE_65 = ~(SYNTHESIZED_WIRE_33 | SYNTHESIZED_WIRE_71);

assign	SYNTHESIZED_WIRE_67 = ~(SYNTHESIZED_WIRE_35 | SYNTHESIZED_WIRE_75);

assign	SYNTHESIZED_WIRE_69 = ~(SYNTHESIZED_WIRE_37 | SYNTHESIZED_WIRE_77);

assign	SYNTHESIZED_WIRE_31 =  ~SYNTHESIZED_WIRE_72;

assign	SYNTHESIZED_WIRE_33 =  ~SYNTHESIZED_WIRE_76;

assign	SYNTHESIZED_WIRE_35 =  ~SYNTHESIZED_WIRE_78;

assign	SYNTHESIZED_WIRE_37 =  ~SYNTHESIZED_WIRE_73;

assign	SYNTHESIZED_WIRE_70 =  ~SYNTHESIZED_WIRE_74;

assign	SYNTHESIZED_WIRE_74 =  ~C_IN;



assign	SYNTHESIZED_WIRE_72 = ~(A4 & B4);

assign	SYNTHESIZED_WIRE_76 = ~(A3 & B3);

assign	SYNTHESIZED_WIRE_78 = ~(A2 & B2);

assign	SYNTHESIZED_WIRE_73 = ~(A1 & B1);

assign	SYNTHESIZED_WIRE_79 = ~(A4 | B4);

assign	SYNTHESIZED_WIRE_71 = ~(A3 | B3);

assign	SYNTHESIZED_WIRE_75 = ~(A2 | B2);

assign	SYNTHESIZED_WIRE_77 = ~(A1 | B1);

assign	C_OUT = ~(SYNTHESIZED_WIRE_44 | SYNTHESIZED_WIRE_45 | SYNTHESIZED_WIRE_46 | SYNTHESIZED_WIRE_47 | SYNTHESIZED_WIRE_48 | SYNTHESIZED_WIRE_49);

assign	SYNTHESIZED_WIRE_64 = ~(SYNTHESIZED_WIRE_50 | SYNTHESIZED_WIRE_51 | SYNTHESIZED_WIRE_52 | SYNTHESIZED_WIRE_53);

assign	SYNTHESIZED_WIRE_66 = ~(SYNTHESIZED_WIRE_54 | SYNTHESIZED_WIRE_55 | SYNTHESIZED_WIRE_56);

assign	SYNTHESIZED_WIRE_68 = ~(SYNTHESIZED_WIRE_57 | SYNTHESIZED_WIRE_58);

assign	SYNTHESIZED_WIRE_46 = SYNTHESIZED_WIRE_79;


assign	SYNTHESIZED_WIRE_50 = SYNTHESIZED_WIRE_71;


assign	SYNTHESIZED_WIRE_54 = SYNTHESIZED_WIRE_75;


assign	SYNTHESIZED_WIRE_58 = SYNTHESIZED_WIRE_77;


assign	SUM_4 = SYNTHESIZED_WIRE_63 ^ SYNTHESIZED_WIRE_64;

assign	SUM_3 = SYNTHESIZED_WIRE_65 ^ SYNTHESIZED_WIRE_66;

assign	SUM_2 = SYNTHESIZED_WIRE_67 ^ SYNTHESIZED_WIRE_68;

assign	SUM_1 = SYNTHESIZED_WIRE_69 ^ SYNTHESIZED_WIRE_70;


endmodule