module BE_Clock

	(
		input			wire			iCLK,				//FPGA Board Supplied Clock
		input			wire			CLK_SELECT,		//Select CLock Type - Manual or Continuous
		input			wire	  		CLK_STEP,		//Clock Single Step Pulse Output - One Clock Period, Active High	
		input			wire    		HLT,				//Halt Push Button, Active Low

		input			wire	[2:0]	DIV_CLK,			//Divisor for Clock - 3'b000 is a 1Hz clock, 3b'001 is a 2 Hz clock, up to 3'b111 a 128 Hz clock
															//Ben Eater's variable clock used a 555 timer with a 1 kOhm resistor  
																//in series with a 1Mohm potentiometer in series with a 1uF capacitor
																//giving a period of 1.43 Hz to 1430 Hz.
		output		reg		CLK,					//Clock Output
		output		reg		NOT_CLK				//Inverted Clock Output
	);

	reg	[25:0] 		counter	= 0;				//Counter to track number of positive edge transitions of FPGA clock
	reg	[25:0]	 	DIVISOR 	= 25000000;		//Frequency to Divide FPGA Clock to Produce CLK and NOT_CLK Output
															//25,000,000 will provide a 1 Hz Clock if the FPGA Clock is 50 MHz (50% Duty Cycle)
	
	reg			cont_CLK	=	1'b1;					//Continuous Clock temporary variable
	reg			step_CLK	=	1'b1;					//Push buton CLock temporary variable
	
	always @(DIV_CLK)
		begin
			case(DIV_CLK)
				4'b000	:	DIVISOR = 25000000;
				4'b001	:	DIVISOR = 12500000;
				4'b010	:	DIVISOR =  6250000;
				4'b011	:	DIVISOR =  3125000;
				4'b100	:	DIVISOR =  1562500;
				4'b101	:	DIVISOR =   781250;
				4'b110	:	DIVISOR =	390625;
				4'b111	:	DIVISOR = 	195312;
				default	:	DIVISOR = 25000000;
			endcase
		end
	
	always @(posedge iCLK)
		begin	
			if (HLT)
				begin
					counter	= counter + 1;
					
					if(counter >= DIVISOR)
						begin
							cont_CLK 	= (cont_CLK == 1'b0) ? 1'b1 : 1'b0;					
							counter 		= 0;
						end
					
					if (CLK_STEP == 1'b1)
						step_CLK = 1'b0;
					else
						step_CLK = 1'b1;

					CLK = (!CLK_SELECT & cont_CLK) | (CLK_SELECT & step_CLK);
					NOT_CLK = !CLK;
				end
		end
endmodule
