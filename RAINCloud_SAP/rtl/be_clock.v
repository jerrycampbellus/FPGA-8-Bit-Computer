// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Registered source-clock transitions. Inputs are conditioned at board level.
module BE_Clock #(
    parameter integer BASE_HALF_PERIOD=25000000,
    parameter integer DISPLAY_HALF_PERIOD=125000000
)(
    input wire iCLK, CLK_SELECT, CLK_STEP, HLT, CLR,
    input wire [2:0] DIV_CLK,
    output reg CLK=0,
    output wire NOT_CLK,
    output reg DISPLAY_CLK=0
);
    reg [26:0] counter=0;
    reg [27:0] display_counter=0;
    reg manual_mode=0, step_armed=0;
    wire [26:0] shifted_period=BASE_HALF_PERIOD[26:0] >> DIV_CLK;
    wire [26:0] half_period=(DIV_CLK==7) ? 27'd1 :
                           ((shifted_period==0) ? 27'd1 : shifted_period);
    assign NOT_CLK=~CLK;
    always @(posedge iCLK or posedge CLR) begin
        if(CLR) begin
            counter<=0; display_counter<=0; CLK<=0; DISPLAY_CLK<=0;
            // A fixed asynchronous reset maps to a flip-flop on MAX 10.
            // Sample the selected mode at the first low boundary after reset.
            manual_mode<=0; step_armed<=0;
        end else begin
            // Display inspection continues during HALT.
            if(display_counter==DISPLAY_HALF_PERIOD-1) begin
                display_counter<=0; DISPLAY_CLK<=~DISPLAY_CLK;
            end else display_counter<=display_counter+1'b1;
            // Change mode at a low boundary. Require a fresh manual press.
            if(!CLK && manual_mode!=CLK_SELECT) begin
                manual_mode<=CLK_SELECT; step_armed<=0; counter<=0;
            end else if(!HLT) begin
                if(manual_mode) begin
                    counter<=0;
                    if(CLK_STEP) begin CLK<=0; step_armed<=1; end
                    else if(step_armed) begin CLK<=1; step_armed<=0; end
                end else if(counter>=half_period-1) begin
                    CLK<=~CLK; counter<=0;
                end else counter<=counter+1'b1;
            end
        end
    end
endmodule
