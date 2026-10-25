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
// CREATED		"Sat Jan 08 21:24:16 2022"

module ALU(
	CLR,
	CLK,
	SUBTRACT,
	ALU_OUT,
	ALU_FLAGS_OUT,
	A_REGISTER_IN,
	B_REGISTER_IN,
	ALU_DB,
	ALU_DISPLAY,
	CPU_Flags
);


input wire	CLK;
input wire CLR;
input wire	SUBTRACT;
input wire	ALU_OUT;
input wire	ALU_FLAGS_OUT;
input wire	[7:0] A_REGISTER_IN;
input wire	[7:0] B_REGISTER_IN;
output wire	[7:0] ALU_DB;
output wire	[7:0] ALU_DISPLAY;
output wire	[7:0] CPU_Flags;

// B is conditionally complemented for subtraction; SUBTRACT supplies the
// low-nibble carry-in. carry_borrow_next converts the final adder carry to
// the ISA's carry-on-ADD / borrow-on-SUB flag. The zero/carry flags are held.
wire	[7:0] a_operand;
wire	[7:0] alu_bus_output;
wire	[7:0] alu_result;
wire	[7:0] b_operand;
wire	[7:0] flags_value;
wire	logic_zero;
wire	carry_borrow_next;
wire	zero_next;
wire	b_addend_bit7;
wire	b_addend_bit6;
wire	b_addend_bit5;
wire	b_addend_bit4;
wire	carry_into_high_nibble;
wire	b_addend_bit3;
wire	b_addend_bit2;
wire	b_addend_bit1;
wire	b_addend_bit0;
wire	zero_bits_7_6;
wire	zero_bits_5_4;
wire	zero_bits_3_2;
wire	zero_bits_1_0;
wire	zero_high_nibble;
wire	zero_low_nibble;
wire	alu_output_enable_n;
wire	unused_flag_bit3;
wire	unused_flag_bit2;
wire	zero_flag;
wire	carry_borrow_flag;
wire	adder_carry_out;

assign	logic_zero = 0;




IC_74LS173_RTL	b2v_173_1(
	.CLK(CLK),
	.bG1(~ALU_FLAGS_OUT),
	.bG2(~ALU_FLAGS_OUT),
	.D_1(carry_borrow_next),
	.D_2(zero_next),
	.D_3(logic_zero),
	.D_4(logic_zero),
	.CLR(CLR),
	.Q_1(carry_borrow_flag),
	.Q_2(zero_flag),
	.Q_3(unused_flag_bit2),
	.Q_4(unused_flag_bit3));


IC_74LS283_RTL	b2v_283_1(
	.B4(b_addend_bit7),
	.A4(a_operand[7]),
	.B3(b_addend_bit6),
	.A3(a_operand[6]),
	.B2(b_addend_bit5),
	.A2(a_operand[5]),
	.B1(b_addend_bit4),
	.A1(a_operand[4]),
	.C_IN(carry_into_high_nibble),
	.C_OUT(adder_carry_out),
	.SUM_4(alu_result[7]),
	.SUM_3(alu_result[6]),
	.SUM_2(alu_result[5]),
	.SUM_1(alu_result[4]));


IC_74LS283_RTL	b2v_283_2(
	.B4(b_addend_bit3),
	.A4(a_operand[3]),
	.B3(b_addend_bit2),
	.A3(a_operand[2]),
	.B2(b_addend_bit1),
	.A2(a_operand[1]),
	.B1(b_addend_bit0),
	.A1(a_operand[0]),
	.C_IN(SUBTRACT),
	.C_OUT(carry_into_high_nibble),
	.SUM_4(alu_result[3]),
	.SUM_3(alu_result[2]),
	.SUM_2(alu_result[1]),
	.SUM_1(alu_result[0]));

assign	zero_high_nibble = zero_bits_7_6 & zero_bits_5_4;

assign	zero_low_nibble = zero_bits_3_2 & zero_bits_1_0;

assign	zero_next = zero_high_nibble & zero_low_nibble;



IC_74LS245AB_RTL #(.FPGA_MODE(1))	b2v_HEX_BUF_1(
	.bOE(alu_output_enable_n),
	.A1(alu_result[7]),
	.A2(alu_result[6]),
	.A3(alu_result[5]),
	.A4(alu_result[4]),
	.A5(alu_result[3]),
	.A6(alu_result[2]),
	.A7(alu_result[1]),
	.A8(alu_result[0]),
	.B1(alu_bus_output[7]),
	.B2(alu_bus_output[6]),
	.B3(alu_bus_output[5]),
	.B4(alu_bus_output[4]),
	.B5(alu_bus_output[3]),
	.B6(alu_bus_output[2]),
	.B7(alu_bus_output[1]),
	.B8(alu_bus_output[0]));


// Flags are persistent state, continuously visible to control and display.
assign flags_value = {6'b0, carry_borrow_flag, zero_flag};

assign	zero_bits_7_6 = ~(alu_result[6] | alu_result[7]);

assign	zero_bits_5_4 = ~(alu_result[4] | alu_result[5]);

assign	zero_bits_3_2 = ~(alu_result[2] | alu_result[3]);

assign	zero_bits_1_0 = ~(alu_result[0] | alu_result[1]);

assign	alu_output_enable_n =  ~ALU_OUT;


assign	b_addend_bit7 = SUBTRACT ^ b_operand[7];

assign	b_addend_bit6 = SUBTRACT ^ b_operand[6];

assign	b_addend_bit5 = SUBTRACT ^ b_operand[5];

assign	b_addend_bit4 = SUBTRACT ^ b_operand[4];

assign	b_addend_bit3 = SUBTRACT ^ b_operand[3];

assign	b_addend_bit2 = SUBTRACT ^ b_operand[2];

assign	b_addend_bit1 = SUBTRACT ^ b_operand[1];

assign	b_addend_bit0 = SUBTRACT ^ b_operand[0];

assign	carry_borrow_next = adder_carry_out ^ SUBTRACT;

assign	ALU_DB = alu_bus_output;
assign	b_operand = B_REGISTER_IN;
assign	a_operand = A_REGISTER_IN;
assign	ALU_DISPLAY = alu_result;
assign	CPU_Flags = flags_value;

endmodule
