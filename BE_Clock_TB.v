`timescale 10 ns / 1 ns

module BE_Clock_tb;

//Declaring Inputs
reg		iCLK_tb;		//FPGA Board Supplied Clock
reg		CLK_SELECT_tb;		//Select CLock Type - Manual or Continuous
reg	  	CLK_STEP_tb;		//Clock Single Step Pulse Output - One Clock Period, Active High	
reg    		HLT_tb;			//Halt Push Button, Active Low
reg	[2:0]	DIV_CLK_tb;		//Divisor for Clock - 3'b000 is a 1Hz clock, 3b'001 is a 2 Hz clock, 
					//up to 3'b111 a 128 Hz clock
//Declaring Outputs
wire		CLK_tb;			//Clock Output
wire		NOT_CLK_tb;		//Inverted Clock Output

//Instantiating Device Under Test (DUT)
BE_Clock DUT 
(
.iCLK(iCLK_tb),
.CLK_SELECT(CLK_SELECT_tb),
.CLK_STEP(CLK_STEP_tb),
.HLT(HLT_tb),
.DIV_CLK(DIV_CLK_tb),
.CLK(CLK_tb),
.NOT_CLK(NOT_CLK_tb)
);

initial
	begin: CLOCK_GENERATOR
 		iCLK_tb = 0;
 		forever
 			begin
 				#5 iCLK_tb = ~ iCLK_tb;
 			end
	end

// 	HLT_tb = 1'b1;
//	CLK_SELECT_tb = 1'b0;
//	DIV_CLK_tb = 3'b0;
//	CLK_STEP_tb = 1'b0;

endmodule
