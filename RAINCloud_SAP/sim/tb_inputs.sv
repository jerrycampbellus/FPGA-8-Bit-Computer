// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
`timescale 1ns/1ps
module tb_inputs;
  reg clk=0;
  reg [1:0] keys=2'b11;
  reg [9:0] switches=0;
  wire reset,step;
  wire [9:0] synced;
  input_conditioner #(.DEBOUNCE_CYCLES(4)) dut(.clk(clk),.keys(keys),
    .switches(switches),.reset(reset),.step_key(step),.switches_sync(synced));
  always #10 clk=~clk;
  initial begin
    repeat(4) @(negedge clk);
    if(reset!==0) $fatal(1,"Power-up reset failed to release");
    switches=10'h235; repeat(3) @(negedge clk);
    if(synced!==switches) $fatal(1,"Switch synchronization failed");
    keys[1]=0; repeat(2) @(negedge clk); keys[1]=1;
    repeat(8) @(negedge clk);
    if(step!==1) $fatal(1,"Short key bounce passed debounce");
    keys[1]=0; repeat(8) @(negedge clk);
    if(step!==0) $fatal(1,"Stable press not accepted");
    keys[1]=1; repeat(8) @(negedge clk);
    if(step!==1) $fatal(1,"Stable release not accepted");
    #2; keys[0]=0; #1;
    if(reset!==1) $fatal(1,"Reset did not assert asynchronously");
    keys[0]=1; @(posedge clk); #1;
    if(reset!==1) $fatal(1,"Reset released before two clock edges");
    @(posedge clk); #1;
    if(reset!==0) $fatal(1,"Reset release failed");
    $display("PASS tb_inputs: switch sync, bounce rejection, async reset/sync release");
    $finish;
  end
endmodule
