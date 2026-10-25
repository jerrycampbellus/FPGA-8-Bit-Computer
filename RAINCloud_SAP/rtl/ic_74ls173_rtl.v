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

// Bit 0 corresponds to D_1/Q_1. The load/hold terms select each next bit.
// clear_n is active low; preset_n is tied inactive in this 74LS173 model.
reg	stored_bit0;
wire	hold_enable;
wire	load_enable;
reg	stored_bit1;
reg	stored_bit2;
reg	stored_bit3;
wire	clear_n;
wire	next_bit1;
wire	preset_n;
wire	next_bit2;
wire	next_bit3;
wire	next_bit0;
wire	load_data_bit0;
wire	hold_data_bit0;
wire	load_data_bit1;
wire	hold_data_bit1;
wire	load_data_bit2;
wire	hold_data_bit2;
wire	load_data_bit3;
wire	hold_data_bit3;

assign	Q_1 = stored_bit0;
assign	Q_2 = stored_bit1;
assign	Q_3 = stored_bit2;
assign	Q_4 = stored_bit3;
assign	preset_n = 1;



assign	hold_data_bit0 = stored_bit0 & hold_enable;

assign	load_data_bit0 = D_1 & load_enable;

assign	hold_data_bit1 = stored_bit1 & hold_enable;

assign	load_data_bit1 = D_2 & load_enable;

assign	hold_data_bit2 = stored_bit2 & hold_enable;

assign	load_data_bit2 = D_3 & load_enable;

assign	hold_data_bit3 = stored_bit3 & hold_enable;

assign	load_data_bit3 = D_4 & load_enable;

assign	load_enable = ~(bG1 | bG2);


always@(posedge CLK or negedge clear_n or negedge preset_n)
begin
if (!clear_n)
	begin
	stored_bit1 <= 0;
	end
else
if (!preset_n)
	begin
	stored_bit1 <= 1;
	end
else
	begin
	stored_bit1 <= next_bit1;
	end
end


always@(posedge CLK or negedge clear_n or negedge preset_n)
begin
if (!clear_n)
	begin
	stored_bit2 <= 0;
	end
else
if (!preset_n)
	begin
	stored_bit2 <= 1;
	end
else
	begin
	stored_bit2 <= next_bit2;
	end
end


always@(posedge CLK or negedge clear_n or negedge preset_n)
begin
if (!clear_n)
	begin
	stored_bit3 <= 0;
	end
else
if (!preset_n)
	begin
	stored_bit3 <= 1;
	end
else
	begin
	stored_bit3 <= next_bit3;
	end
end


always@(posedge CLK or negedge clear_n or negedge preset_n)
begin
if (!clear_n)
	begin
	stored_bit0 <= 0;
	end
else
if (!preset_n)
	begin
	stored_bit0 <= 1;
	end
else
	begin
	stored_bit0 <= next_bit0;
	end
end


assign	hold_enable =  ~load_enable;

assign	clear_n =  ~CLR;

assign	next_bit0 = load_data_bit0 | hold_data_bit0;

assign	next_bit1 = load_data_bit1 | hold_data_bit1;

assign	next_bit2 = load_data_bit2 | hold_data_bit2;

assign	next_bit3 = load_data_bit3 | hold_data_bit3;


endmodule
