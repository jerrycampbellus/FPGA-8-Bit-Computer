// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Samples the shared CPU bus for diagnostic display. No reset input or initializer.
module Bus_Display_Register

	(
		input		wire			CLK,					// CPU capture clock
		input		wire			DB_Enable,			// Capture bus when high; capture zero otherwise
		input		wire	[7:0]	DB,					// Shared CPU bus input
		output	reg	[7:0]	DB_Display			// Registered sample sent to JC_Display
	);


	always @(posedge CLK)
		begin
			if (DB_Enable == 1'b1)
				DB_Display <= DB;
			else
				DB_Display <= 8'b0; // defined idle diagnostic value in FPGA fabric
		end
endmodule
