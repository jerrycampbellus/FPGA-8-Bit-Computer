module RAM 
  	(
			input		wire				CLK,				// Single Port RAM with CLK
			input		wire				Read_Enable,	//	Read Enable Active High
			input		wire				Write_Enable,	//	Write Enable Active High
    		input 	wire 	[3:0] 	Address,			// Address bus - 4 bit - 0 to F
			input		wire	[7:0]		Data_In_DB,		// Data Bus In Connection
    		output 	wire	[7:0] 	Data_Out_DB,	// Data Bus Out Connection
			output	wire	[7:0]		Data_DISP		// Display for RAM
 	);

	reg [7:0] RAM [15:0];
	
	initial 
		begin
			$readmemh("C:\\Users\\jcamp\\OneDrive\\Documents\\Projects\\BenEater_8Bit_Computer\\RAM\\RAM_INIT.txt", RAM);
		end
		
	assign Data_Out_DB = (Read_Enable) ? RAM[Address] : 8'bzzzzzzzz;
	assign Data_DISP	 = (Read_Enable) ? RAM[Address] : 8'bzzzzzzzz;
	
	always @(posedge CLK)
	
		begin
			if (Write_Enable)
				RAM[Address] <= Data_In_DB;
		end	
		
endmodule

