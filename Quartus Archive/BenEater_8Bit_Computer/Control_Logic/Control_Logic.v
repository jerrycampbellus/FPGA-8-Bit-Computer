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
// CREATED		"Sun Jan 09 16:15:53 2022"

module Control_Logic(
	NOT_CLK,
	CLR,
	ALU_FLGS,
	OPCODE,
	OPERAND,
	DB_ENABLE,
	MAR_ENABLE,
	MEMORY_ADDRESS_IN,
	INST_REG_IN,
	INST_REG_OUT,
	RAM_READ_ENABLE,
	HALT,
	JUMP,
	PRGM_COUNT_ENBL,
	PRGM_COUNT_OUT,
	A_REG_OUT,
	A_REG_IN,
	ALU_OUT,
	SUBTRACT,
	ALU_FLGS_OUT,
	B_REG_OUT,
	B_REG_IN,
	OUTPUT_IN,
	RAM_WRITE_ENABLE,
	CONTROL_FLAGS_OUT
);


input wire	NOT_CLK;
input wire	CLR;
input wire	[7:0] ALU_FLGS;
input wire	[3:0] OPCODE;
input wire	[3:0] OPERAND;
output wire	DB_ENABLE;
output wire	MAR_ENABLE;
output wire	MEMORY_ADDRESS_IN;
output wire	INST_REG_IN;
output wire	INST_REG_OUT;
output wire	RAM_READ_ENABLE;
output wire	HALT;
output wire	JUMP;
output wire	PRGM_COUNT_ENBL;
output wire	PRGM_COUNT_OUT;
output wire	A_REG_OUT;
output wire	A_REG_IN;
output wire	ALU_OUT;
output wire	SUBTRACT;
output wire	ALU_FLGS_OUT;
output wire	B_REG_OUT;
output wire	B_REG_IN;
output wire	OUTPUT_IN;
output wire	RAM_WRITE_ENABLE;
output wire	[15:0] CONTROL_FLAGS_OUT;

wire	[15:0] CF;
wire	[2:0] MICRO_CNT;
wire	SYNTHESIZED_WIRE_11;
wire	SYNTHESIZED_WIRE_1;
wire	SYNTHESIZED_WIRE_12;
wire	SYNTHESIZED_WIRE_8;
wire	SYNTHESIZED_WIRE_9;
wire	SYNTHESIZED_WIRE_10;

assign	SYNTHESIZED_WIRE_11 = 1;
assign	SYNTHESIZED_WIRE_12 = 0;




IC_74LS161_RTL	b2v_161_1(
	.bLOAD(SYNTHESIZED_WIRE_11),
	.bCLR(SYNTHESIZED_WIRE_1),
	.DATA_A(SYNTHESIZED_WIRE_12),
	.DATA_B(SYNTHESIZED_WIRE_12),
	.CLK(NOT_CLK),
	.DATA_C(SYNTHESIZED_WIRE_12),
	.DATA_D(SYNTHESIZED_WIRE_12),
	.ENP(SYNTHESIZED_WIRE_11),
	.ENT(SYNTHESIZED_WIRE_11),
	.Q_A(MICRO_CNT[0]),
	.Q_B(MICRO_CNT[1]),
	.Q_C(MICRO_CNT[2])
	
	);

assign	SYNTHESIZED_WIRE_10 = MICRO_CNT[2] & MICRO_CNT[0] & SYNTHESIZED_WIRE_8;




MicroCode_StateMachine	b2v_MSM(
	.CLK(NOT_CLK),
	.ALU_Flags(ALU_FLGS),
	.Instruction_OpCode(OPCODE),
	.Instruction_Operand(OPERAND),
	.Micro_Count(MICRO_CNT),
	.Halt_Signal(HALT),
	.Jump_Signal(JUMP),
	.Program_Count_Enable(CF[0]),
	.Program_Count_Out(CF[1]),
	.A_Reg_Out(CF[2]),
	.A_Reg_In(CF[3]),
	.ALU_Out(CF[4]),
	.Subtract(CF[5]),
	.ALU_Flags_Out(CF[6]),
	.B_Reg_Out(CF[7]),
	.B_Reg_In(CF[8]),
	.RAM_Read_Enable(CF[9]),
	.RAM_Write_Enable(CF[10]),
	.Instruction_Reg_Out(CF[11]),
	.Instruction_Reg_In(CF[12]),
	.Memory_Address_In(CF[13]),
	.Memory_Address_Enable(CF[14]),
	.DB_Enable(DB_ENABLE),
	.Output_Enable(CF[15]));

assign	SYNTHESIZED_WIRE_8 =  ~MICRO_CNT[1];

assign	SYNTHESIZED_WIRE_1 =  ~SYNTHESIZED_WIRE_9;

assign	SYNTHESIZED_WIRE_9 = CLR | SYNTHESIZED_WIRE_10;

assign	MAR_ENABLE = CF[14];
assign	MEMORY_ADDRESS_IN = CF[13];
assign	INST_REG_IN = CF[12];
assign	INST_REG_OUT = CF[11];
assign	RAM_READ_ENABLE = CF[9];
assign	PRGM_COUNT_ENBL = CF[0];
assign	PRGM_COUNT_OUT = CF[1];
assign	A_REG_OUT = CF[2];
assign	A_REG_IN = CF[3];
assign	ALU_OUT = CF[4];
assign	SUBTRACT = CF[5];
assign	ALU_FLGS_OUT = CF[6];
assign	B_REG_OUT = CF[7];
assign	B_REG_IN = CF[8];
assign	OUTPUT_IN = CF[15];
assign	RAM_WRITE_ENABLE = CF[10];
assign	CONTROL_FLAGS_OUT = CF;

endmodule
