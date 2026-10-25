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

// Bit 0 is Q_A (the least significant counter bit). Each JK excitation
// pair loads DATA_A..DATA_D when load_enable is high, otherwise toggles
// when its lower-bit carry is active. preset_n is tied inactive.
reg	count_bit1;
reg	count_bit0;
wire	count_enable;
reg	count_bit2;
wire	bit0_j_mask;
wire	bit0_update_enable;
wire	preset_n;
reg	count_bit3;
wire	bit0_k_mask;
wire	bit1_j_mask;
wire	bit1_update_enable;
wire	bit1_k_mask;
wire	bit2_j_mask;
wire	bit2_update_enable;
wire	bit2_k_mask;
wire	bit3_j_mask;
wire	bit3_update_enable;
wire	bit3_k_mask;
wire	bit0_k;
wire	bit0_j;
wire	bit1_k;
wire	bit1_j;
wire	bit2_k;
wire	bit2_j;
wire	bit3_k;
wire	bit3_j;
wire	load_enable;
wire	carry_into_bit1;
wire	carry_into_bit2;
wire	carry_into_bit3;

assign	Q_B = count_bit1;
assign	Q_C = count_bit2;
assign	Q_D = count_bit3;
assign	Q_A = count_bit0;
assign	preset_n = 1;



assign	carry_into_bit2 = count_bit1 & count_bit0 & count_enable;

assign	carry_into_bit3 = count_bit2 & count_bit1 & count_bit0 & count_enable;

assign	bit0_j = bit0_j_mask & bit0_update_enable;

assign	count_enable = ENP & ENT;

assign	RCO = count_bit2 & preset_n & count_bit3 & count_bit1 & count_bit0 & ENT;

assign	bit0_k = bit0_update_enable & bit0_k_mask;

assign	bit1_j = bit1_j_mask & bit1_update_enable;

assign	bit1_k = bit1_update_enable & bit1_k_mask;

assign	bit2_j = bit2_j_mask & bit2_update_enable;

assign	bit2_k = bit2_update_enable & bit2_k_mask;

assign	bit3_j = bit3_j_mask & bit3_update_enable;

assign	bit3_k = bit3_update_enable & bit3_k_mask;

assign	carry_into_bit1 = count_bit0 & count_enable;



always@(posedge CLK or negedge bCLR or negedge preset_n)
begin
if (!bCLR)
	begin
	count_bit0 <= 0;
	end
else
	begin
if (!preset_n)
	begin
	count_bit0 <= 1;
	end
else
	begin
	count_bit0 <= ~count_bit0 & bit0_j | count_bit0 & ~bit0_k;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge preset_n)
begin
if (!bCLR)
	begin
	count_bit1 <= 0;
	end
else
	begin
if (!preset_n)
	begin
	count_bit1 <= 1;
	end
else
	begin
	count_bit1 <= ~count_bit1 & bit1_j | count_bit1 & ~bit1_k;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge preset_n)
begin
if (!bCLR)
	begin
	count_bit2 <= 0;
	end
else
	begin
if (!preset_n)
	begin
	count_bit2 <= 1;
	end
else
	begin
	count_bit2 <= ~count_bit2 & bit2_j | count_bit2 & ~bit2_k;
	end
	end
end


always@(posedge CLK or negedge bCLR or negedge preset_n)
begin
if (!bCLR)
	begin
	count_bit3 <= 0;
	end
else
	begin
if (!preset_n)
	begin
	count_bit3 <= 1;
	end
else
	begin
	count_bit3 <= ~count_bit3 & bit3_j | count_bit3 & ~bit3_k;
	end
	end
end

assign	bit0_j_mask = ~(bit0_k_mask & load_enable);

assign	bit0_k_mask = ~(load_enable & DATA_A);

assign	bit1_j_mask = ~(bit1_k_mask & load_enable);

assign	bit1_k_mask = ~(load_enable & DATA_B);

assign	bit2_j_mask = ~(bit2_k_mask & load_enable);

assign	bit2_k_mask = ~(load_enable & DATA_C);

assign	bit3_j_mask = ~(bit3_k_mask & load_enable);

assign	bit3_k_mask = ~(load_enable & DATA_D);

assign	load_enable =  ~bLOAD;

assign	bit0_update_enable = load_enable | count_enable;

assign	bit1_update_enable = load_enable | carry_into_bit1;

assign	bit2_update_enable = load_enable | carry_into_bit2;

assign	bit3_update_enable = load_enable | carry_into_bit3;


endmodule
