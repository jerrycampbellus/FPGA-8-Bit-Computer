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

// Bit 0 corresponds to A1/B1/SUM_1. generate = A & B; kill = ~(A | B).
// carryN_block_* terms indicate why carry into bit N is absent. Their NOR
// forms the carry; the original gate-level adder topology is preserved.
// Suffix _n denotes the complement / active-low form of a signal.
wire	kill_bit2;
wire	generate_bit3_n;
wire	generate_bit0_n;
wire	carry_in_n;
wire	kill_bit1;
wire	generate_bit2_n;
wire	kill_bit0;
wire	generate_bit1_n;
wire	logic_one;
wire	generate_bit3;
wire	kill_bit3;
wire	generate_bit2;
wire	generate_bit1;
wire	generate_bit0;
wire	logic_zero;
wire	carry4_block_bit2;
wire	carry4_block_bit3;
wire	carry4_block_bit1;
wire	carry4_block_carry_in;
wire	carry4_block_bit0;
wire	carry3_block_bit2;
wire	carry3_block_bit0;
wire	carry3_block_bit1;
wire	carry3_block_carry_in;
wire	carry2_block_bit1;
wire	carry2_block_bit0;
wire	carry2_block_carry_in;
wire	carry1_block_carry_in;
wire	carry1_block_bit0;
wire	xor_bit3;
wire	carry_into_bit3;
wire	xor_bit2;
wire	carry_into_bit2;
wire	xor_bit1;
wire	carry_into_bit1;
wire	xor_bit0;
wire	carry_into_bit0;

assign	logic_one = 1;
assign	logic_zero = 0;



assign	carry4_block_bit2 = kill_bit2 & generate_bit3_n;

assign	carry1_block_carry_in = generate_bit0_n & carry_in_n;

assign	carry4_block_bit1 = kill_bit1 & generate_bit3_n & generate_bit2_n;

assign	carry4_block_bit0 = kill_bit0 & generate_bit3_n & generate_bit2_n & generate_bit1_n;

assign	carry4_block_carry_in = generate_bit2_n & logic_one & generate_bit3_n & generate_bit1_n & generate_bit0_n & carry_in_n;

assign	carry3_block_bit1 = kill_bit1 & generate_bit2_n;

assign	carry3_block_bit0 = kill_bit0 & generate_bit2_n & generate_bit1_n;

assign	carry3_block_carry_in = generate_bit2_n & generate_bit1_n & generate_bit0_n & carry_in_n;

assign	carry2_block_bit0 = kill_bit0 & generate_bit1_n;

assign	carry2_block_carry_in = generate_bit1_n & generate_bit0_n & carry_in_n;

assign	xor_bit3 = ~(generate_bit3 | kill_bit3);

assign	xor_bit2 = ~(generate_bit2 | kill_bit2);

assign	xor_bit1 = ~(generate_bit1 | kill_bit1);

assign	xor_bit0 = ~(generate_bit0 | kill_bit0);

assign	generate_bit3 =  ~generate_bit3_n;

assign	generate_bit2 =  ~generate_bit2_n;

assign	generate_bit1 =  ~generate_bit1_n;

assign	generate_bit0 =  ~generate_bit0_n;

assign	carry_into_bit0 =  ~carry_in_n;

assign	carry_in_n =  ~C_IN;



assign	generate_bit3_n = ~(A4 & B4);

assign	generate_bit2_n = ~(A3 & B3);

assign	generate_bit1_n = ~(A2 & B2);

assign	generate_bit0_n = ~(A1 & B1);

assign	kill_bit3 = ~(A4 | B4);

assign	kill_bit2 = ~(A3 | B3);

assign	kill_bit1 = ~(A2 | B2);

assign	kill_bit0 = ~(A1 | B1);

assign	C_OUT = ~(logic_zero | carry4_block_bit2 | carry4_block_bit3 | carry4_block_bit1 | carry4_block_carry_in | carry4_block_bit0);

assign	carry_into_bit3 = ~(carry3_block_bit2 | carry3_block_bit0 | carry3_block_bit1 | carry3_block_carry_in);

assign	carry_into_bit2 = ~(carry2_block_bit1 | carry2_block_bit0 | carry2_block_carry_in);

assign	carry_into_bit1 = ~(carry1_block_carry_in | carry1_block_bit0);

assign	carry4_block_bit3 = kill_bit3;


assign	carry3_block_bit2 = kill_bit2;


assign	carry2_block_bit1 = kill_bit1;


assign	carry1_block_bit0 = kill_bit0;


assign	SUM_4 = xor_bit3 ^ carry_into_bit3;

assign	SUM_3 = xor_bit2 ^ carry_into_bit2;

assign	SUM_2 = xor_bit1 ^ carry_into_bit1;

assign	SUM_1 = xor_bit0 ^ carry_into_bit0;


endmodule
