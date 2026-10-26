// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
`timescale 1ns/1ps
module tb_clock;
  reg master=0,manual=0,step=1,halt=0,reset=0;
  reg [2:0] rate=0;
  wire clk,nclk,display;
  integer r,half_period,edges=0,before_edges;
  BE_Clock #(.BASE_HALF_PERIOD(128),.DISPLAY_HALF_PERIOD(8)) dut(
    .iCLK(master),.CLK_SELECT(manual),.CLK_STEP(step),.HLT(halt),
    .CLR(reset),.DIV_CLK(rate),.CLK(clk),.NOT_CLK(nclk),.DISPLAY_CLK(display));
  always #10 master=~master;
  always @(posedge clk) edges=edges+1;
  always @(negedge master) if(nclk!==~clk) $fatal(1,"Clock phases are not complementary");
  task do_reset;
    begin @(negedge master); reset=1; #1; reset=0; end
  endtask
  initial begin
    for(r=0;r<8;r=r+1) begin
      rate=r; do_reset(); half_period=(r==7)?1:(128>>r);
      repeat(half_period) @(posedge master); #1;
      if(clk!==1) $fatal(1,"Wrong divider rise at rate %0d",r);
      repeat(half_period) @(posedge master); #1;
      if(clk!==0) $fatal(1,"Wrong divider fall at rate %0d",r);
    end
    manual=1; step=1; do_reset(); repeat(3) @(negedge master);
    before_edges=edges;
    repeat(3) begin
      step=0; repeat(5) @(negedge master);
      if(clk!==1) $fatal(1,"Manual press failed");
      step=1; repeat(5) @(negedge master);
      if(clk!==0) $fatal(1,"Manual release failed");
    end
    if(edges-before_edges!=3) $fatal(1,"Manual key produced extra/missing steps");
    halt=1; step=0; repeat(4) @(negedge master);
    if(clk!==0) $fatal(1,"HALT allowed a CPU edge");
    #1; reset=1; #1;
    if(clk!==0 || dut.counter!==0) $fatal(1,"Stopped clock reset failed");
    reset=0; halt=0;
    // Reset with manual selected and the key held must not create a step.
    before_edges=edges;
    repeat(5) @(negedge master);
    if(clk!==0 || edges!=before_edges) $fatal(1,"Held key stepped after reset");
    step=1; repeat(3) @(negedge master);
    step=0; repeat(3) @(negedge master);
    if(clk!==1 || edges!=before_edges+1) $fatal(1,"Fresh key press failed after reset");
    $display("PASS tb_clock: eight dividers, phase complement, manual, HALT/reset, held key");
    $finish;
  end
  initial begin #100000; $fatal(1,"Clock test timeout"); end
endmodule
