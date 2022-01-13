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
// CREATED		"Sun Dec 26 23:37:13 2021"

module IC_74LS161_RTL(
	bLOAD,
	bCLR,
	CLK,
	ENP,
	ENT,
	DATA_A,
	DATA_B,
	DATA_C,
	DATA_D,
	Q_B,
	Q_C,
	Q_D,
	RCO,
	Q_A
);


input wire	bLOAD;
input wire	bCLR;
input wire	CLK;
input wire	ENP;
input wire	ENT;
input wire	DATA_A;
input wire	DATA_B;
input wire	DATA_C;
input wire	DATA_D;
output wire	Q_B;
output wire	Q_C;
output wire	Q_D;
output wire	RCO;
output wire	Q_A;

reg	SYNTHESIZED_WIRE_52;
reg	SYNTHESIZED_WIRE_53;
wire	SYNTHESIZED_WIRE_54;
reg	SYNTHESIZED_WIRE_55;
wire	SYNTHESIZED_WIRE_2;
wire	SYNTHESIZED_WIRE_56;
wire	SYNTHESIZED_WIRE_57;
reg	JKFF_JK_4;
wire	SYNTHESIZED_WIRE_58;
wire	SYNTHESIZED_WIRE_7;
wire	SYNTHESIZED_WIRE_59;
wire	SYNTHESIZED_WIRE_60;
wire	SYNTHESIZED_WIRE_11;
wire	SYNTHESIZED_WIRE_61;
wire	SYNTHESIZED_WIRE_62;
wire	SYNTHESIZED_WIRE_15;
wire	SYNTHESIZED_WIRE_63;
wire	SYNTHESIZED_WIRE_64;
wire	SYNTHESIZED_WIRE_21;
wire	SYNTHESIZED_WIRE_22;
wire	SYNTHESIZED_WIRE_24;
wire	SYNTHESIZED_WIRE_25;
wire	SYNTHESIZED_WIRE_27;
wire	SYNTHESIZED_WIRE_28;
wire	SYNTHESIZED_WIRE_30;
wire	SYNTHESIZED_WIRE_31;
wire	SYNTHESIZED_WIRE_65;
wire	SYNTHESIZED_WIRE_47;
wire	SYNTHESIZED_WIRE_49;
wire	SYNTHESIZED_WIRE_51;

assign	Q_B = SYNTHESIZED_WIRE_52;
assign	Q_C = SYNTHESIZED_WIRE_55;
assign	Q_D = JKFF_JK_4;
assign	Q_A = SYNTHESIZED_WIRE_53;
assign	SYNTHESIZED_WIRE_57 = 1;



assign	SYNTHESIZED_WIRE_49 = SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53 & SYNTHESIZED_WIRE_54;

assign	SYNTHESIZED_WIRE_51 = SYNTHESIZED_WIRE_55 & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53 & SYNTHESIZED_WIRE_54;

assign	SYNTHESIZED_WIRE_22 = SYNTHESIZED_WIRE_2 & SYNTHESIZED_WIRE_56;

assign	SYNTHESIZED_WIRE_54 = ENP & ENT;

assign	RCO = SYNTHESIZED_WIRE_55 & SYNTHESIZED_WIRE_57 & JKFF_JK_4 & SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_53 & ENT;

assign	SYNTHESIZED_WIRE_21 = SYNTHESIZED_WIRE_56 & SYNTHESIZED_WIRE_58;

assign	SYNTHESIZED_WIRE_25 = SYNTHESIZED_WIRE_7 & SYNTHESIZED_WIRE_59;

assign	SYNTHESIZED_WIRE_24 = SYNTHESIZED_WIRE_59 & SYNTHESIZED_WIRE_60;

assign	SYNTHESIZED_WIRE_28 = SYNTHESIZED_WIRE_11 & SYNTHESIZED_WIRE_61;

assign	SYNTHESIZED_WIRE_27 = SYNTHESIZED_WIRE_61 & SYNTHESIZED_WIRE_62;

assign	SYNTHESIZED_WIRE_31 = SYNTHESIZED_WIRE_15 & SYNTHESIZED_WIRE_63;

assign	SYNTHESIZED_WIRE_30 = SYNTHESIZED_WIRE_63 & SYNTHESIZED_WIRE_64;

assign	SYNTHESIZED_WIRE_47 = SYNTHESIZED_WIRE_53 & SYNTHESIZED_WIRE_54;



always@(posedge CLK or negedge bCLR or negedge SYNTHESIZED_WIRE_57)
begin
if (!bCLR)
	begin
	SYNTHESIZED_WIRE_53 <= 0;
	end
else
	begin
if (!SYNTHESIZED_WIRE_57)
	begin
	SYNTHESIZED_WIRE_53 <= 1;
	end
else
	begin
	SYNTHESIZED_WIRE_53 <= ~SYNTHESIZED_WIRE_53 & SYNTHESIZED_WIRE_22 | SYNTHESIZED_WIRE_53 & ~SYNTHESIZED_WIRE_21;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge SYNTHESIZED_WIRE_57)
begin
if (!bCLR)
	begin
	SYNTHESIZED_WIRE_52 <= 0;
	end
else
	begin
if (!SYNTHESIZED_WIRE_57)
	begin
	SYNTHESIZED_WIRE_52 <= 1;
	end
else
	begin
	SYNTHESIZED_WIRE_52 <= ~SYNTHESIZED_WIRE_52 & SYNTHESIZED_WIRE_25 | SYNTHESIZED_WIRE_52 & ~SYNTHESIZED_WIRE_24;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge SYNTHESIZED_WIRE_57)
begin
if (!bCLR)
	begin
	SYNTHESIZED_WIRE_55 <= 0;
	end
else
	begin
if (!SYNTHESIZED_WIRE_57)
	begin
	SYNTHESIZED_WIRE_55 <= 1;
	end
else
	begin
	SYNTHESIZED_WIRE_55 <= ~SYNTHESIZED_WIRE_55 & SYNTHESIZED_WIRE_28 | SYNTHESIZED_WIRE_55 & ~SYNTHESIZED_WIRE_27;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge SYNTHESIZED_WIRE_57)
begin
if (!bCLR)
	begin
	JKFF_JK_4 <= 0;
	end
else
	begin
if (!SYNTHESIZED_WIRE_57)
	begin
	JKFF_JK_4 <= 1;
	end
else
	begin
	JKFF_JK_4 <= ~JKFF_JK_4 & SYNTHESIZED_WIRE_31 | JKFF_JK_4 & ~SYNTHESIZED_WIRE_30;
	end
	end
end

assign	SYNTHESIZED_WIRE_2 = ~(SYNTHESIZED_WIRE_58 & SYNTHESIZED_WIRE_65);

assign	SYNTHESIZED_WIRE_58 = ~(SYNTHESIZED_WIRE_65 & DATA_A);

assign	SYNTHESIZED_WIRE_7 = ~(SYNTHESIZED_WIRE_60 & SYNTHESIZED_WIRE_65);

assign	SYNTHESIZED_WIRE_60 = ~(SYNTHESIZED_WIRE_65 & DATA_B);

assign	SYNTHESIZED_WIRE_11 = ~(SYNTHESIZED_WIRE_62 & SYNTHESIZED_WIRE_65);

assign	SYNTHESIZED_WIRE_62 = ~(SYNTHESIZED_WIRE_65 & DATA_C);

assign	SYNTHESIZED_WIRE_15 = ~(SYNTHESIZED_WIRE_64 & SYNTHESIZED_WIRE_65);

assign	SYNTHESIZED_WIRE_64 = ~(SYNTHESIZED_WIRE_65 & DATA_D);

assign	SYNTHESIZED_WIRE_65 =  ~bLOAD;

assign	SYNTHESIZED_WIRE_56 = SYNTHESIZED_WIRE_65 | SYNTHESIZED_WIRE_54;

assign	SYNTHESIZED_WIRE_59 = SYNTHESIZED_WIRE_65 | SYNTHESIZED_WIRE_47;

assign	SYNTHESIZED_WIRE_61 = SYNTHESIZED_WIRE_65 | SYNTHESIZED_WIRE_49;

assign	SYNTHESIZED_WIRE_63 = SYNTHESIZED_WIRE_65 | SYNTHESIZED_WIRE_51;


endmodule
