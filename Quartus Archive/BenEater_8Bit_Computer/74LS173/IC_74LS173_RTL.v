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
// CREATED		"Sat Dec 11 20:33:05 2021"

module IC_74LS173_RTL(
	bG1,
	bG2,
	CLK,
	CLR,
	D_1,
	D_2,
	D_3,
	D_4,
	Q_1,
	Q_2,
	Q_3,
	Q_4
);


input wire	bG1;
input wire	bG2;
input wire	CLK;
input wire	CLR;
input wire	D_1;
input wire	D_2;
input wire	D_3;
input wire	D_4;
output wire	Q_1;
output wire	Q_2;
output wire	Q_3;
output wire	Q_4;

reg	DFF_DFF_1;
wire	SYNTHESIZED_WIRE_29;
wire	SYNTHESIZED_WIRE_30;
reg	DFF_D_FF2;
reg	DFF_D_FF3;
reg	DFF_D_FF4;
wire	SYNTHESIZED_WIRE_31;
wire	SYNTHESIZED_WIRE_9;
wire	SYNTHESIZED_WIRE_32;
wire	SYNTHESIZED_WIRE_12;
wire	SYNTHESIZED_WIRE_15;
wire	SYNTHESIZED_WIRE_18;
wire	SYNTHESIZED_WIRE_21;
wire	SYNTHESIZED_WIRE_22;
wire	SYNTHESIZED_WIRE_23;
wire	SYNTHESIZED_WIRE_24;
wire	SYNTHESIZED_WIRE_25;
wire	SYNTHESIZED_WIRE_26;
wire	SYNTHESIZED_WIRE_27;
wire	SYNTHESIZED_WIRE_28;

assign	Q_1 = DFF_DFF_1;
assign	Q_2 = DFF_D_FF2;
assign	Q_3 = DFF_D_FF3;
assign	Q_4 = DFF_D_FF4;
assign	SYNTHESIZED_WIRE_32 = 1;



assign	SYNTHESIZED_WIRE_22 = DFF_DFF_1 & SYNTHESIZED_WIRE_29;

assign	SYNTHESIZED_WIRE_21 = D_1 & SYNTHESIZED_WIRE_30;

assign	SYNTHESIZED_WIRE_24 = DFF_D_FF2 & SYNTHESIZED_WIRE_29;

assign	SYNTHESIZED_WIRE_23 = D_2 & SYNTHESIZED_WIRE_30;

assign	SYNTHESIZED_WIRE_26 = DFF_D_FF3 & SYNTHESIZED_WIRE_29;

assign	SYNTHESIZED_WIRE_25 = D_3 & SYNTHESIZED_WIRE_30;

assign	SYNTHESIZED_WIRE_28 = DFF_D_FF4 & SYNTHESIZED_WIRE_29;

assign	SYNTHESIZED_WIRE_27 = D_4 & SYNTHESIZED_WIRE_30;

assign	SYNTHESIZED_WIRE_30 = ~(bG1 | bG2);


always@(posedge CLK or negedge SYNTHESIZED_WIRE_31 or negedge SYNTHESIZED_WIRE_32)
begin
if (!SYNTHESIZED_WIRE_31)
	begin
	DFF_D_FF2 <= 0;
	end
else
if (!SYNTHESIZED_WIRE_32)
	begin
	DFF_D_FF2 <= 1;
	end
else
	begin
	DFF_D_FF2 <= SYNTHESIZED_WIRE_9;
	end
end


always@(posedge CLK or negedge SYNTHESIZED_WIRE_31 or negedge SYNTHESIZED_WIRE_32)
begin
if (!SYNTHESIZED_WIRE_31)
	begin
	DFF_D_FF3 <= 0;
	end
else
if (!SYNTHESIZED_WIRE_32)
	begin
	DFF_D_FF3 <= 1;
	end
else
	begin
	DFF_D_FF3 <= SYNTHESIZED_WIRE_12;
	end
end


always@(posedge CLK or negedge SYNTHESIZED_WIRE_31 or negedge SYNTHESIZED_WIRE_32)
begin
if (!SYNTHESIZED_WIRE_31)
	begin
	DFF_D_FF4 <= 0;
	end
else
if (!SYNTHESIZED_WIRE_32)
	begin
	DFF_D_FF4 <= 1;
	end
else
	begin
	DFF_D_FF4 <= SYNTHESIZED_WIRE_15;
	end
end


always@(posedge CLK or negedge SYNTHESIZED_WIRE_31 or negedge SYNTHESIZED_WIRE_32)
begin
if (!SYNTHESIZED_WIRE_31)
	begin
	DFF_DFF_1 <= 0;
	end
else
if (!SYNTHESIZED_WIRE_32)
	begin
	DFF_DFF_1 <= 1;
	end
else
	begin
	DFF_DFF_1 <= SYNTHESIZED_WIRE_18;
	end
end


assign	SYNTHESIZED_WIRE_29 =  ~SYNTHESIZED_WIRE_30;

assign	SYNTHESIZED_WIRE_31 =  ~CLR;

assign	SYNTHESIZED_WIRE_18 = SYNTHESIZED_WIRE_21 | SYNTHESIZED_WIRE_22;

assign	SYNTHESIZED_WIRE_9 = SYNTHESIZED_WIRE_23 | SYNTHESIZED_WIRE_24;

assign	SYNTHESIZED_WIRE_12 = SYNTHESIZED_WIRE_25 | SYNTHESIZED_WIRE_26;

assign	SYNTHESIZED_WIRE_15 = SYNTHESIZED_WIRE_27 | SYNTHESIZED_WIRE_28;


endmodule
