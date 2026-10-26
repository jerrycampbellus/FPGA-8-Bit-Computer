// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Reset asserts asynchronously, releases through two 50 MHz registers.
// Switches and step input are synchronized; the step key is also debounced.
module input_conditioner #(parameter integer DEBOUNCE_CYCLES=250000)(
    input wire clk, input wire [1:0] keys, input wire [9:0] switches,
    output wire reset, output reg step_key=1,
    output wire [9:0] switches_sync
);
    (* preserve *) reg [1:0] reset_pipe=2'b11;
    (* preserve *) reg [9:0] switch_meta=0, switch_sync=0;
    (* preserve *) reg step_meta=1, step_sync=1;
    reg [19:0] debounce_count=0;
    assign reset=reset_pipe[1];
    assign switches_sync=switch_sync;
    always @(posedge clk or negedge keys[0])
        if(!keys[0]) reset_pipe<=2'b11;
        else reset_pipe<={reset_pipe[0],1'b0};
    always @(posedge clk) begin
        switch_meta<=switches; switch_sync<=switch_meta;
        step_meta<=keys[1]; step_sync<=step_meta;
    end
    always @(posedge clk or posedge reset)
        if(reset) begin step_key<=1; debounce_count<=0; end
        else if(step_sync==step_key) debounce_count<=0;
        else if(debounce_count==DEBOUNCE_CYCLES-1) begin
            step_key<=step_sync; debounce_count<=0;
        end else debounce_count<=debounce_count+1'b1;
endmodule
