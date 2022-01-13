module JC_Display

	(
		input wire				Display_CLK,					// Display Clock for LED Ouptut Toggle
		
		input wire	[7:0]		A_Register,						// 1)		8 bit Output from A Register
		input wire	[7:0]		B_Register,						// 2) 	8 bit Output from B Register
		input wire	[7:0]		ALU,								// 3) 	8 bit Output from ALU Results
		input wire	[7:0]		CPU_Flags,						// 4) 	8 bit Output from CPU
		input	wire	[3:0]		Memory_Address_Register,	// 5) 	4 bit Output from Memory Address Register (MAR)
		input	wire	[7:0]		RAM,								// 6) 	8 bit Output from RAM Contents
		input	wire	[3:0]		Program_Counter,				// 7) 	4 bit Output from Program Counter
		input wire	[16:0]	CPU_Output,						// 8) 	17 bit Output for CPU based on a 3 BCD digits and sign
		input	wire	[7:0]		Data_Bus,						// 9) 	8 bit Output for Data Bus
		input	wire	[15:0]	Control_Flags,					// 10)	16 bit Output for Control Flags
		input wire	[7:0]		Instruction_Register,		//	11)	8 bit Output for Instruction Register
		
		input wire	[3:0]		JC_OUPUT_SELECT,				// 4 bit Selector Determines which Output to Display ( 1 - 10)
		
		output reg	[7:0]		JC_LED_OUTPUT,					// 8 bit LED Output on FPGA Board
		
		output reg	[7:0]		JC_7SEG_OUPUT_0,				// HEX0 Seven Segment Output of FPGA Board
		output reg	[7:0]		JC_7SEG_OUPUT_1,				// HEX1 Seven Segment Output of FPGA Board
		output reg	[7:0]		JC_7SEG_OUPUT_2,				// HEX2 Seven Segment Output of FPGA Board
		output reg	[7:0]		JC_7SEG_OUPUT_3,				// HEX3 Seven Segment Output of FPGA Board
		output reg	[7:0]		JC_7SEG_OUPUT_4,				// HEX4 Seven Segment Output of FPGA Board
		output reg	[7:0]		JC_7SEG_OUPUT_5				// HEX5 Seven Segment Output of FPGA Board
	);
	
	reg			toggle_LED 		= 1'b0;
	reg	[7:0]	first_row_LED 	= 8'b00000000;
	reg	[7:0]	second_row_LED = 8'b00000000;

		
	always @(*)
		begin
			
			case (JC_OUPUT_SELECT)
			
				4'b0000	:					// Blank Seven Segment Display and LED
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_0 <= Segment_Decode (5'h15);
						
						JC_LED_OUTPUT <= 8'b00000000;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
				
				4'b0001	:					// A Register - Ar__XX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0A);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h13);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, A_Register[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, A_Register[3:0]});
						
						JC_LED_OUTPUT <= A_Register;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				4'b0010	:					// B Register - Br__XX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0B);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h13);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, B_Register[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, B_Register[3:0]});
						
						JC_LED_OUTPUT <= B_Register;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end

				4'b0011	:					// ALU - ALU_XX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0A);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h10);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h14);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, ALU[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, ALU[3:0]});
						
						JC_LED_OUTPUT <= ALU;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;						
					end
					
				4'b0100	:					// CPU Flags - CPF_XX 
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0C);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h12);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h0F);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, CPU_Flags[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, CPU_Flags[3:0]});
						
						JC_LED_OUTPUT <= CPU_Flags;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				4'b0101	:					// Memory Address Register - MAr__X
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h11);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h0A);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h13);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, Memory_Address_Register[3:0]});
						
						JC_LED_OUTPUT <= Memory_Address_Register;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				4'b0110	:					// RAM Contents - rAM_XX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h13);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h0A);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h11);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, RAM[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, RAM[3:0]});
						
						JC_LED_OUTPUT <= RAM;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				4'b0111	:					// Program Counter - PC___X
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h12);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h0C);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, Program_Counter[3:0]});
						
						JC_LED_OUTPUT <= Program_Counter;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
				
				4'b1000	:					// CPU Output - C_SXXX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0C);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_3 <= Segment_Decode (CPU_Output[16:12]);
						JC_7SEG_OUPUT_2 <= Segment_Decode ({1'b0, CPU_Output[11:8]});
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, CPU_Output[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, CPU_Output[3:0]});
						
						JC_LED_OUTPUT <= 8'b00000000;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				4'b1001	:					// Data Bus - db__XX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0D);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h0B);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, Data_Bus[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, Data_Bus[3:0]});
						
						JC_LED_OUTPUT <= Data_Bus;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;						
					end
					
				4'b1010	:					// Control Flags - F_XXXX
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h0F);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_3 <= Segment_Decode ({1'b0, Control_Flags[15:12]});
						JC_7SEG_OUPUT_2 <= Segment_Decode ({1'b0, Control_Flags[11:8]});
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, Control_Flags[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, Control_Flags[3:0]});
						
						toggle_LED 	<= 1'b1;
						JC_LED_OUTPUT 	<= 8'b00000000;
						first_row_LED 	<= Control_Flags[15:8];
						second_row_LED <= Control_Flags[7:0];						
					end
					
				4'b1011	:					// Instruction_Register - 1R__XX 
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h01);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h13);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode ({1'b0, Instruction_Register[7:4]});
						JC_7SEG_OUPUT_0 <= Segment_Decode ({1'b0, Instruction_Register[3:0]});
						
						JC_LED_OUTPUT <= Instruction_Register;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 	<= 1'b0;
					end
					
				default	:					// Blank Seven Segment Display and LED
					begin
						JC_7SEG_OUPUT_5 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_4 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_3 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_2 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_1 <= Segment_Decode (5'h15);
						JC_7SEG_OUPUT_0 <= Segment_Decode (5'h15);
						
						JC_LED_OUTPUT 	<= 8'b00000000;
						first_row_LED 	<= 8'b00000000;
						second_row_LED <= 8'b00000000;
						toggle_LED 		<= 1'b0;
					end
			endcase
			
			if (toggle_LED == 1'b1)
					JC_LED_OUTPUT <= (Display_CLK == 1) ? first_row_LED : second_row_LED;
			
		end
		
		function [7:0] Segment_Decode (input [4:0] iDIG);
			begin
				case(iDIG)
					5'h0		: Segment_Decode = 8'b11000000;	// 0 
					5'h1		: Segment_Decode = 8'b11111001;	// 1	
					5'h2		: Segment_Decode = 8'b10100100; 	// 2
					5'h3		: Segment_Decode = 8'b10110000; 	// 3
					5'h4		: Segment_Decode = 8'b10011001; 	// 4
					5'h5		: Segment_Decode = 8'b10010010; 	// 5
					5'h6		: Segment_Decode = 8'b10000010; 	// 6
					5'h7		: Segment_Decode = 8'b11111000; 	// 7
					5'h8		: Segment_Decode = 8'b10000000; 	// 8
					5'h9		: Segment_Decode = 8'b10011000;	// 9
					5'ha		: Segment_Decode = 8'b10001000;	// A
					5'hb		: Segment_Decode = 8'b10000011;	// b
					5'hc		: Segment_Decode = 8'b11000110;	// C
					5'hd		: Segment_Decode = 8'b10100001;	// D
					5'he		: Segment_Decode = 8'b10000110;	// E
					5'hf		: Segment_Decode = 8'b10001110;	// F
					5'h10		: Segment_Decode = 8'b11000111;	// L
					5'h11		: Segment_Decode = 8'b11101010;	// M
					5'h12		: Segment_Decode = 8'b10001100;	// P
					5'h13		: Segment_Decode = 8'b10101111;	// r
					5'h14		: Segment_Decode = 8'b11000001;	// U
					5'h15		: Segment_Decode = 8'b11111111;	// blank
					5'h16		: Segment_Decode = 8'b10111111;	// negative sign
					default	: Segment_Decode = 8'b00000000;	// all segments on
				endcase
			end
		
			//		COMMON ANNODE 7 SEGMENT
			//
			//			---a---
			//			|		|
			//			f		b
			//			|--g--|
			//			e		c
			//			|		|
			//			---d---DP
			//
			//		oSEG is an 8 bit number starting with DP (Decimal Point) -> DP g f e d c b a
			//																						 7 6 5 4 3 2 1 0 
			//			1 = turn off segment
			//			0 - turn on segment
		
		endfunction 

endmodule
