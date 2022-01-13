module MicroCode_StateMachine
	(
		input		wire	[2:0]	Micro_Count,					// Instruction state - 000 -> 100				
		input		wire	[3:0]	Instruction_OpCode,			// Current OpCode
		input		wire	[3:0]	Instruction_Operand,			// Current Operand
		input		wire	[7:0]	ALU_Flags,						//	Flags from ALU, ALU_FLAGS[0] -> Carry Flag, ALU_FLAGS[1] -> Zero Flag
		input		wire			CLK,								// Clock
		output	reg			Halt_Signal,
		output	reg			Jump_Signal,
		output	reg			Program_Count_Enable,
		output	reg			Program_Count_Out,
		output	reg			A_Reg_Out,
		output	reg			A_Reg_In,
		output	reg			ALU_Out,
		output	reg			Subtract,
		output	reg			ALU_Flags_Out,
		output	reg			B_Reg_Out,
		output	reg			B_Reg_In,
		output	reg			RAM_Read_Enable,
		output	reg			RAM_Write_Enable,
		output	reg			Instruction_Reg_Out,
		output	reg			Instruction_Reg_In,
		output	reg			Memory_Address_In,
		output	reg			Memory_Address_Enable,
		output	reg			DB_Enable,
		output	reg			Output_Enable
	);
	
	reg [0:0] Zero_Flag, Carry_Flag, Clear_Zero_Flag, Clear_Carry_Flag	=	0;
	
	always @(posedge CLK)
	
		begin

			DB_Enable 					<= 1'b1;
			Halt_Signal					<= 1'b0;
			Jump_Signal					<= 1'b0;
			Program_Count_Enable		<= 1'b0;
			Program_Count_Out			<= 1'b0;
			A_Reg_Out					<= 1'b0;
			A_Reg_In						<= 1'b0;
			ALU_Out						<= 1'b0;
			Subtract						<= 1'b0;
			ALU_Flags_Out				<= 1'b0;
			B_Reg_Out					<= 1'b0;
			B_Reg_In						<= 1'b0;
			RAM_Read_Enable			<= 1'b0;
			RAM_Write_Enable			<=	1'b0;
			Instruction_Reg_Out		<= 1'b0;
			Instruction_Reg_In		<= 1'b0;
			Memory_Address_In			<= 1'b0;
			Memory_Address_Enable	<= 1'b0;
			Output_Enable				<= 1'b0;
			
			if (ALU_Flags[1] == 1'b1)
					Carry_Flag[0] <= 1;
			else
					Carry_Flag[0] <= 0;
					
			if (ALU_Flags[0] == 1'b1)
					Zero_Flag[0] <= 1;
			else
					Zero_Flag[0] <= 0;
			
			if (Clear_Carry_Flag[0] == 1)
				begin
					Carry_Flag[0] 			<= 0;
					Clear_Carry_Flag[0]	<= 0;
				end
			
			if (Clear_Zero_Flag[0] == 1)
				begin
					Zero_Flag[0] 			<= 0;
					Clear_Zero_Flag[0]	<= 0;
				end
				
			case(Micro_Count)
				
				3'b000	:													// Fetch - Output Program Counter to MAR
					begin
						Memory_Address_Enable 	<= 1'b1;				// Enable MAR
						Memory_Address_In 		<= 1'b1;				// LOAD MAR with current Program Counter Value
						
						Program_Count_Out 		<= 1'b1; 			// Output current Program Counter value
						Program_Count_Enable 	<= 1'b1;				// Increment Program Counter
					end
				
				3'b001	:													//	Fetch - Output current instruction from RAM to IR
					begin
						Memory_Address_Enable 	<= 1'b1;				// MAR Emable - Current Address sent to RAM
						RAM_Read_Enable 			<= 1'b1;				// RAM READ - Output data value to DB for current Address
						Instruction_Reg_In 		<= 1'b1;				// Load current instruction into instruction register
					end
				
				3'b010	:													// Opcode specific control logic
					begin						
						case(Instruction_OpCode)
							4'b0000	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0001	:	// LD A 1X -> Load A register with value from memory location X in operand
								begin
									Instruction_Reg_Out		<= 1'b1;
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;	
								end
							4'b0010	:	// Add
								begin
									Instruction_Reg_Out		<= 1'b1;
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;	
								end
							4'b0011	:	// Subtract
								begin
									Instruction_Reg_Out		<= 1'b1;
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;
								end
							4'b0100	:	// OUT
								begin
									A_Reg_Out			 		<= 1'b1;
									Output_Enable				<= 1'b1;	// Send Output to Display
								end
							4'b0101	:	// JMP
								begin
									Instruction_Reg_Out 		<= 1'b1;
									Jump_Signal					<= 1'b1;	// Send Operand in Instrucion Register to Program Counter
								end
							4'b0110	:	// ST A
								begin
									Instruction_Reg_Out		<= 1'b1;
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;
								end
							4'b0111	:	// BNZ		
								begin
									if (Zero_Flag[0]	 == 1)		// Check Zero flag
										begin
											Instruction_Reg_Out 	<= 1'b1;
											Jump_Signal				<= 1'b1;	// Send Operand in Instrucion Register to Program Counter, if zero flag is set
											Clear_Zero_Flag[0]	<= 1;
										end
									else
										DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b1000	:	// BNC		
								begin
									if (Carry_Flag[0]	 == 1)		// Check Carry Flag
										begin
											Instruction_Reg_Out 		<= 1'b1;
											Jump_Signal					<= 1'b1;	// Send Operand in Instrucion Register to Program Counter, if carry flag is set
											Clear_Carry_Flag[0]		<= 1;
										end
									else
										DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b1111	:	// Halt - stop clock
								begin
									Halt_Signal			 		<= 1'b1; // Halt OpCode
								end
							default	:	Halt_Signal <= 1'b1;			// Halt if OpCode not found
						endcase
					end
					
				3'b011	:													// Opcode specific control logic
					begin
						case(Instruction_OpCode)
							4'b0000	:	// NOP - 00
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0001	:	// LD A - 1X				// LD A - Load A register with value from memory location X in operand
								begin
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;	
									RAM_Read_Enable		 	<= 1'b1;
									A_Reg_In				 		<= 1'b1;		
								end
							4'b0010	:	// ADD - 2X					// Add value stored in memory location X to the A register
								begin
									Memory_Address_In 		<= 1'b1; // Enable Memory output 
									Memory_Address_Enable 	<= 1'b1;	
									RAM_Read_Enable		 	<= 1'b1; // Load B register with value in memory, ALU adds value
									B_Reg_In						<= 1'b1;
									ALU_Flags_Out				<= 1'b1;
								end
							4'b0011	:	// SUBTRACT	- 3X				// Subtract value stored in meory location X from the A register
								begin
									Memory_Address_In 		<= 1'b1; // Enable Memory output 
									Memory_Address_Enable 	<= 1'b1;	
									RAM_Read_Enable		 	<= 1'b1; // Load B register with value in memory, ALU subtracts value
									B_Reg_In						<= 1'b1;
									Subtract						<= 1'b1;
									ALU_Flags_Out				<= 1'b1;
								end
							4'b0100	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0101	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0110	:	// ST A
								begin
									Memory_Address_In 		<= 1'b1; 
									Memory_Address_Enable 	<= 1'b1;	
									RAM_Write_Enable		 	<= 1'b1;
									A_Reg_Out			 		<= 1'b1;
								end
							4'b0111	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b1000	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							default	:	Halt_Signal <= 1'b1;			// Halt if OpCode not found
						endcase						
					end
					
				3'b100	:													// Opcode specific control logic
					begin
						case(Instruction_OpCode)
							4'b0000	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0001	:									
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP		
								end
							4'b0010	:	// ADD										// LD A with ALU
								begin
									ALU_Out		 				<= 1'b1;
									A_Reg_In					 	<= 1'b1;
								end
							4'b0011	:	// SUBTRACT									// LD A with ALU
								begin
									Subtract						<= 1'b1;
									ALU_Out		 				<= 1'b1;
									A_Reg_In					 	<= 1'b1;
								end
							4'b0100	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0101	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0110	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b0111	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							4'b1000	:	// NOP
								begin
									DB_Enable 					<= 1'b1;	// Enable DB = NOP
								end
							default	:	Halt_Signal <= 1'b1;			// Halt if OpCode not found
						endcase
					end
					
				default	:	DB_Enable <= 1'b0;			
			endcase	
		end
	
endmodule
