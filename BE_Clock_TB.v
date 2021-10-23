`timescale 1 ns / 100 ps

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

reg [2:0] i_div = 3'b000;

always
	#10 iCLK_tb = ~ iCLK_tb;

initial
	begin 
		$display($time, " << Starting the Simulation >>");
		iCLK_tb = 1'b0;

 	// Set Initial Conditions
		HLT_tb = 1'b1;
		CLK_SELECT_tb = 1'b0;
		DIV_CLK_tb = 3'b0;
		CLK_STEP_tb = 1'b1;
	
	// Step through the 8 clock frequencies
		$display($time, " << Initial Conditions Set for Continuous Clock >>");
			repeat(8)							
				begin
					@(negedge CLK_tb)
					@(posedge CLK_tb)
					$display($time, " << Clock Period Complete>>");
					#1
					i_div = i_div + 1'b1;
					inc_div(i_div);
				end
	
	// Set Clock to 128 Hz and Halt Clock for 100000000 ns
		DIV_CLK_tb = 3'b111;
		$display($time, " << Halt Continuous Clock for 100000000 ns >>");			//Issue Halt for 30 ns
		HLT_tb = 1'b0;
		wait (HLT_tb == 1'b0); 
		#100000000;
		HLT_tb = 1'b1;
		wait (HLT_tb == 1'b1);
	
	// Set Clock to Manual Input and Send 3 Manual Clock Periods of 100000000 ns
		$display($time, " << Set Manual Clock >>");
		CLK_SELECT_tb = 1'b1;
		wait (CLK_SELECT_tb == 1'b1);
		$display($time, " << Pulse Manual Clock 3 times separated by 100000000 ns >>");	//Pulse Manual Clock 3 times
		repeat (3)
			begin
				CLK_STEP_tb = 1'b1;
				#100000000;
				CLK_STEP_tb = 1'b0;
				#100000000;
			end
 	// Simulation End
		$display($time, " << Simulation Complete >>");	
		$stop;
	end

	// Task to Increment Clock Frequency
	task inc_div;
		input [2:0] inc_value;
		begin
			DIV_CLK_tb = inc_value;
		end
	endtask

endmodule
