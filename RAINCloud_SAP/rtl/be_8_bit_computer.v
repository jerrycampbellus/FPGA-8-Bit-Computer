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
// CREATED		"Tue Jan 11 14:25:48 2022"

module BE_8_BIT_Computer(
	FPGA_CLK_SOURCE,
	CLK_SELECT,
	CLK_STEP,
	CLR,
	TWOS_COMPLEMENT,
	HEXADECIMAL_FLAG,
	CLK_DIVIDER,
	DISPLAY_SELECT,
	HLT_LED,
	CLK_LED,
	LED,
	SEVEN_SEG_0,
	SEVEN_SEG_1,
	SEVEN_SEG_2,
	SEVEN_SEG_3,
	SEVEN_SEG_4,
	SEVEN_SEG_5
);


input wire	FPGA_CLK_SOURCE;
input wire	CLK_SELECT;
input wire	CLK_STEP;
input wire	CLR;
input wire	TWOS_COMPLEMENT;
input wire	HEXADECIMAL_FLAG;
input wire	[2:0] CLK_DIVIDER;
input wire	[3:0] DISPLAY_SELECT;
output wire	HLT_LED;
output wire	CLK_LED;
output wire	[7:0] LED;
output wire	[7:0] SEVEN_SEG_0;
output wire	[7:0] SEVEN_SEG_1;
output wire	[7:0] SEVEN_SEG_2;
output wire	[7:0] SEVEN_SEG_3;
output wire	[7:0] SEVEN_SEG_4;
output wire	[7:0] SEVEN_SEG_5;

wire	[7:0] cpu_flags;
wire	[7:0] data_bus;
wire [7:0] alu_bus, a_bus, b_bus, instruction_bus, pc_bus, ram_bus;

// Each FPGA-mode source drives zero when disabled. Microcode must enable
// at most one source; tb_cpu checks this invariant on every capture edge.
// A single fabric driver replaces the educational shared tri-state net.
assign data_bus = alu_bus | a_bus | b_bus | instruction_bus | pc_bus | ram_bus;
wire	alu_output_enable;
wire	alu_subtract;
wire	flags_write_enable;
wire	cpu_clock;
wire	[7:0] a_value;
wire	[7:0] b_value;
wire	a_output_enable;
wire	a_load_enable;
wire	b_output_enable;
wire	b_load_enable;
wire	cpu_clock_n;
wire	[3:0] instruction_opcode;
wire	[3:0] instruction_operand;
wire	cpu_halt;
wire	bus_display_enable;
wire	display_clock;
wire	[7:0] a_display;
wire	[7:0] alu_result;
wire	[7:0] b_display;
wire	[15:0] control_word;
wire	[16:0] output_display;
wire	[7:0] bus_display;
wire	[7:0] instruction_display;
wire	[3:0] mar_display;
wire	[3:0] pc_value;
wire	[7:0] ram_display;
wire	instruction_output_enable;
wire	instruction_load_enable;
wire	mar_load_enable;
wire	mar_output_enable;
wire	output_load_enable;
wire	pc_jump_enable;
wire	pc_count_enable;
wire	pc_output_enable;
wire	ram_read_enable;
wire	ram_write_enable;
wire	[3:0] ram_address;

assign	HLT_LED = cpu_halt;
assign	CLK_LED = cpu_clock;




ALU	b2v_ALU(
	.CLR(CLR),
	.ALU_OUT(alu_output_enable),
	.SUBTRACT(alu_subtract),
	.ALU_FLAGS_OUT(flags_write_enable),
	.CLK(cpu_clock),
	.A_REGISTER_IN(a_value),
	.B_REGISTER_IN(b_value),
	.ALU_DB(alu_bus),
	.ALU_DISPLAY(alu_result),
	.CPU_Flags(cpu_flags));


A_Register	b2v_AR(
	.A_REG_OUT_EN(a_output_enable),
	.A_REG_IN_EN(a_load_enable),
	.CLK(cpu_clock),
	.CLR(CLR),
	.A_REG_IN(data_bus),
	.A_REG_ALU(a_value),
	.A_REG_DISPLAY(a_display),
	.A_REG_OUT_DB(a_bus));


B_Register	b2v_BR(
	.B_REG_OUT_EN(b_output_enable),
	.B_REG_IN_EN(b_load_enable),
	.CLK(cpu_clock),
	.CLR(CLR),
	.B_REG_IN(data_bus),
	.B_REG_ALU(b_value),
	.B_REG_DISPLAY(b_display),
	.B_REG_OUT_DB(b_bus));


Control_Logic	b2v_CL(
	.CLR(CLR),
	.NOT_CLK(cpu_clock_n),
	.ALU_FLGS(cpu_flags),
	.OPCODE(instruction_opcode),
	.OPERAND(instruction_operand),
	.HALT(cpu_halt),
	.JUMP(pc_jump_enable),
	.PRGM_COUNT_ENBL(pc_count_enable),
	.PRGM_COUNT_OUT(pc_output_enable),
	.A_REG_OUT(a_output_enable),
	.A_REG_IN(a_load_enable),
	.ALU_OUT(alu_output_enable),
	.SUBTRACT(alu_subtract),
	.ALU_FLGS_OUT(flags_write_enable),
	.B_REG_OUT(b_output_enable),
	.B_REG_IN(b_load_enable),
	.RAM_READ_ENABLE(ram_read_enable),
	.RAM_WRITE_ENABLE(ram_write_enable),
	.INST_REG_OUT(instruction_output_enable),
	.INST_REG_IN(instruction_load_enable),
	.MEMORY_ADDRESS_IN(mar_load_enable),
	.MAR_ENABLE(mar_output_enable),
	.DB_ENABLE(bus_display_enable),
	.OUTPUT_IN(output_load_enable),
	.CONTROL_FLAGS_OUT(control_word));


BE_Clock	b2v_CLK(
	.iCLK(FPGA_CLK_SOURCE),
	.CLK_SELECT(CLK_SELECT),
	.CLK_STEP(CLK_STEP),
	.HLT(cpu_halt),
	.CLR(CLR),
	.DIV_CLK(CLK_DIVIDER),
	.CLK(cpu_clock),
	.NOT_CLK(cpu_clock_n),
	.DISPLAY_CLK(display_clock));


Bus_Display_Register	bus_display_register(
	.CLK(cpu_clock),
	.DB_Enable(bus_display_enable),
	.DB(data_bus),
	.DB_Display(bus_display));


JC_Display	b2v_DISP(
	.Display_CLK(display_clock),
	.CPU_Output_Hexadecimal(HEXADECIMAL_FLAG),
	.A_Register(a_display),
	.ALU(alu_result),
	.B_Register(b_display),
	.Control_Flags(control_word),
	.CPU_Flags(cpu_flags),
	.CPU_Output(output_display),
	.Bus_Display_Sample(bus_display),
	.Instruction_Register(instruction_display),
	.JC_OUPUT_SELECT(DISPLAY_SELECT),
	.Memory_Address_Register(mar_display),
	.Program_Counter(pc_value),
	.RAM(ram_display),
	.JC_7SEG_OUPUT_0(SEVEN_SEG_0),
	.JC_7SEG_OUPUT_1(SEVEN_SEG_1),
	.JC_7SEG_OUPUT_2(SEVEN_SEG_2),
	.JC_7SEG_OUPUT_3(SEVEN_SEG_3),
	.JC_7SEG_OUPUT_4(SEVEN_SEG_4),
	.JC_7SEG_OUPUT_5(SEVEN_SEG_5),
	.JC_LED_OUTPUT(LED));


Instruction_Register	b2v_IR(
	.INST_REG_OUT(instruction_output_enable),
	.INST_REG_IN(instruction_load_enable),
	.CLK(cpu_clock),
	.CLR(CLR),
	.INST_REG_IN_DB(data_bus),
	.INST_OPCODE(instruction_opcode),
	.INST_OPERAND(instruction_operand),
	.INST_REG_DISPLAY(instruction_display),
	.INST_REG_OUT_DB(instruction_bus));


Memory_Address_Register	b2v_MAR(
	.CLK(cpu_clock),
	.MEMORY_ADDRESS_IN(mar_load_enable),
	.CLR(CLR),
	.MEMORY_ADDRESS_ENABLE(mar_output_enable),
	.ADDRESS_BUS(data_bus),
	.MEMORY_ADDRESS_DISP(mar_display),
	.MEMORY_ADDRESS_OUT(ram_address));


Output_Register	b2v_OR(
	.CLK(cpu_clock),
	.OUTPUT_READ_EN(output_load_enable),
	.TWOS_COMPLIMENT_FLAG(TWOS_COMPLEMENT),
	.HEXADECIMAL_FLAG(HEXADECIMAL_FLAG),
	.CLR(CLR),
	.OUtPUT_DB_IN(data_bus),
	.OUTPUT_DISP(output_display));


Program_Counter	b2v_PC(
	.JMP(pc_jump_enable),
	.CLR(CLR),
	.CLK(cpu_clock),
	.CE(pc_count_enable),
	.COUNT_OUT(pc_output_enable),
	.PC_IN_DB(data_bus),
	.PC_DISP(pc_value),
	.PC_OUT_DB(pc_bus));


RAM #(.FPGA_MODE(1))	b2v_RAM(
	.CLK(cpu_clock),
	.Read_Enable(ram_read_enable),
	.Write_Enable(ram_write_enable),
	.Address(ram_address),
	.Data_In_DB(data_bus),
	.Data_DISP(ram_display),
	.Data_Out_DB(ram_bus));


endmodule
