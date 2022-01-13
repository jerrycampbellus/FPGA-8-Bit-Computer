module BE_Clock

	(
		input			wire			iCLK,				//	FPGA Board Supplied Clock
		input			wire			CLK_SELECT,		//	Select CLock Type - Manual or Continuous
		input			wire	  		CLK_STEP,		//	Clock Single Step Pulse Output - One Clock Period, Active High	
		input			wire    		HLT,				//	Halt Signal,
		input 		wire			CLR,				// Reset Signal

		input			wire	[2:0]	DIV_CLK,			//	Divisor for Clock - 3'b000 is a 1Hz clock, 3b'001 is a 2 Hz clock, up to 3'b111 a 128 Hz clock
															//	Ben Eater's variable clock used a 555 timer with a 1 kOhm resistor  
																// in series with a 1Mohm potentiometer in series with a 1uF capacitor
																// giving a period of 1.43 Hz to 1430 Hz.
		output		wire		CLK,					//	Clock Output
		output		wire		NOT_CLK,				//	Inverted Clock Output
		output		reg		DISPLAY_CLK			//	Dedicated 1 Hz. Display Clock
	);

	reg	[25:0] 		counter	= 0;							//	Counter to track number of positive edge transitions of FPGA clock
	reg	[25:0]	 	DIVISOR 	= 25000000;					//	Frequency to Divide FPGA Clock to Produce CLK and NOT_CLK Output
																		//	25,000,000 will provide a 1 Hz Clock if the FPGA Clock is 50 MHz (50% Duty Cycle)
	
	reg	[29:0]		display_Counter	=	0;				//	Dedicated counter for display
	reg	[29:0]		display_Divisor	=	125000000;	// 5 Second Delay for Display
	
	reg			cont_CLK	=	1'b1;								//	Continuous Clock temporary variable
	reg			step_CLK	=	1'b1;								//	Push buton CLock temporary variable
	
	always @(DIV_CLK)
		begin
			case(DIV_CLK)
				3'b000	:	DIVISOR = 25000000;
				3'b001	:	DIVISOR = 12500000;
				3'b010	:	DIVISOR =  6250000;
				3'b011	:	DIVISOR =  3125000;
				3'b100	:	DIVISOR =  1562500;
				3'b101	:	DIVISOR =   781250;
				3'b110	:	DIVISOR =	390625;
				3'b111	:	DIVISOR = 	0;
				default	:	DIVISOR = 25000000;
			endcase
		end
	
	
	always @(posedge iCLK)
		begin
				
			if (~HLT || CLR)
				begin
					counter	<= counter + 1'b1;
					display_Counter <= display_Counter + 1;
					
					if(counter >= DIVISOR)
						begin
							cont_CLK 	<= (cont_CLK == 1'b0) ? 1'b1 : 1'b0;					
							counter 		<= 0;
						end
					
					if(display_Counter >= display_Divisor)
						begin
							DISPLAY_CLK 		<= (DISPLAY_CLK == 1'b0) ? 1'b1 : 1'b0;					
							display_Counter 	<= 0;
						end
					
					
					if (CLK_STEP == 1'b1)
						step_CLK <= 1'b0;
					else
						step_CLK <= 1'b1;
				end
		end
		
		
		assign 	CLK = (~CLK_SELECT & cont_CLK) | (CLK_SELECT & step_CLK);
		assign	NOT_CLK = ~(~CLK_SELECT & cont_CLK) | (CLK_SELECT & step_CLK);	
endmodule
