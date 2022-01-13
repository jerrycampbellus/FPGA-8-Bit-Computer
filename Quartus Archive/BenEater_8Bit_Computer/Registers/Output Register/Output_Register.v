module Output_Register

	(
		input		wire				CLK,							// Clock to synchronize Databus reads
		input		wire				OUTPUT_READ_EN,			// Enable output read of databus
		input		wire				TWOS_COMPLIMENT_FLAG,	// Zero Flag from ALU set high
		input		wire				HEXADECIMAL_FLAG,			// Display Hexadecimal
		input		wire				CLR,							// Clear Acive High
		input		wire	[7:0]		OUtPUT_DB_IN,				// Databus connection
		output	reg	[16:0]	OUTPUT_DISP					// Display output using signed BCD - 3 digits with leading negative sign for negative numbers :> - x x x
	);
	
	reg		[9:0]		bcd_out;
	reg		[6:0]		sign_bcd;
	reg					twos_compliment_ALU;

	always @(TWOS_COMPLIMENT_FLAG)
		begin
			if (TWOS_COMPLIMENT_FLAG == 1'b1)
				twos_compliment_ALU <= 1'b1;
			else if (TWOS_COMPLIMENT_FLAG == 1'b0)
				twos_compliment_ALU <= 1'b0;
		end
	
	always @(posedge CLK)
		begin 
			
			if (CLR == 1'b1)
				begin
					sign_bcd 	<= 7'b1010100;
					bcd_out		<= 10'b0000000000;
				end
			else if (OUTPUT_READ_EN == 1'b1)
				begin
					if(twos_compliment_ALU == 1'b1)
						begin
							sign_bcd 	<= 7'b1011000;
							if (HEXADECIMAL_FLAG)
								bcd_out 	<= {2'b00, (~OUtPUT_DB_IN[7:0] + 1'b1)};
							else
								bcd_out	<= bcd(~OUtPUT_DB_IN[7:0] + 1'b1);
						end
					else
						begin
							sign_bcd 	<= 7'b1010100;
							if (HEXADECIMAL_FLAG)
								bcd_out 	<= {2'b00, OUtPUT_DB_IN[7:0]};
							else
								bcd_out	<= bcd(OUtPUT_DB_IN[7:0]);
						end
				end
			
			OUTPUT_DISP	<= {sign_bcd, bcd_out};
		end	
	
	function [9:0] bcd (input [7:0] bin);
	
		integer i,j;
		
		begin
		
			for(i = 0; i <= 9; i = i + 1) bcd[i] = 0;						// initialize with zeros
			
			bcd[7:0] = bin;                                  			// initialize with input vector
			 
			for(i = 0; i <= 4; i = i + 1)                      			// iterate on structure depth
				for(j = 0; j <= i/3; j = j + 1)                     		// iterate on structure width
					
					if (bcd[8-i+4*j -: 4] > 4)                      	// if > 4
						bcd[8-i+4*j -: 4] = bcd[8-i+4*j -: 4] + 4'd3; 	// add 3
		end
	
	endfunction

endmodule
