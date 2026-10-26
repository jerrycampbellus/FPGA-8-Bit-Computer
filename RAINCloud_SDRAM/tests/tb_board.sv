/**************************************************************************
* RAINCloud / SDRAM_Tester / tb_board.sv
* Verification target: controller 1.2.1 / release 26101404 (October 14, 2026)
* Maintainer: J.CAMPBELL
*
* Board integration test with the production top/tester/controller and ISSI
* model. This file also defines simulation replacements named de10_clock and
* jtag_bridge. Do not compile the real PLL or generated JTAG IP into this run.
* The replacement clock is 50 MHz, forwards +8 ns and asserts lock at 200 ns.
*
* DEBOUNCE_BITS=2 shortens key qualification. Checks local smoke run/count,
* LEDs, HEX5 page encoding, controlled key stop and idle burst editing.
* It does not emulate contact bounce, active JTAG, PLL analog behavior, the
* three-second reset hold or every display/edit field. Those require separate
* evidence; see docs/TESTBENCH.md, docs/BOARD.md and docs/VALIDATION.md.
*
* Expected: PASS board; $fatal on assertion failure or 5 ms watchdog.
**************************************************************************/
`timescale 1ns/1ps
// Behavioral PLL substitute checks reset sequencing and nominal +8 ns phase.
module de10_clock(input ref_clk,output core_clk,output sdram_clk,output locked);
  assign core_clk=ref_clk; assign #8 sdram_clk=ref_clk;
  reg ready=0; initial begin #200; ready=1; end
  assign locked=ready;
endmodule
// Simulation stand-in ONLY for inactive JTAG. Production uses generated Intel IP.
module jtag_bridge(input clk_clk,reset_reset, output master_reset_reset,
  output [31:0] avalon_address,avalon_writedata, output avalon_read,avalon_write,
  output [3:0] avalon_byteenable, input [31:0] avalon_readdata,
  input avalon_readdatavalid,avalon_waitrequest);
  assign master_reset_reset=0; assign avalon_address=0; assign avalon_writedata=0;
  assign avalon_read=0; assign avalon_write=0; assign avalon_byteenable=0;
endmodule
module tb_board;
  reg MAX10_CLK1_50=0; always #10 MAX10_CLK1_50=~MAX10_CLK1_50;
  reg [9:0] SW=0; reg [1:0] KEY=3;
  wire [9:0] LEDR; wire [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5;
  wire [12:0] DRAM_ADDR; wire [1:0] DRAM_BA; wire [15:0] DRAM_DQ;
  wire DRAM_CLK,DRAM_CKE,DRAM_CS_N,DRAM_RAS_N,DRAM_CAS_N,DRAM_WE_N,DRAM_LDQM,DRAM_UDQM;
  sdram_tester_top #(.DEBOUNCE_BITS(2)) dut(.*);
  IS42S16320F model(.Clk(DRAM_CLK),.Cke(DRAM_CKE),.Cs_n(DRAM_CS_N),.Ras_n(DRAM_RAS_N),.Cas_n(DRAM_CAS_N),.We_n(DRAM_WE_N),.Addr(DRAM_ADDR),.Ba(DRAM_BA),.Dqm({DRAM_UDQM,DRAM_LDQM}),.Dq(DRAM_DQ));
  // KEY pins are active low. Twelve clocks pressed/released allow the two
  // synchronizer stages and the shortened debounce counters to settle.
  task press(input integer button);
    begin
      @(negedge MAX10_CLK1_50); KEY[button]=0;
      repeat(12) @(negedge MAX10_CLK1_50); KEY[button]=1;
      repeat(12) @(negedge MAX10_CLK1_50);
    end
  endtask
  initial begin
    // LED5 gates start until memory initialization. The default 1024-word
    // address-pattern smoke test completes 2048 write+read word operations.
    wait(LEDR[5]); press(1); wait(LEDR[1]);
    if(LEDR[0] || LEDR[2] || LEDR[3]) $fatal(1,"Standalone did not pass");
    if(dut.regs.operations!=2048) $fatal(1,"Standalone count");
    // KEY0 advances page 0 to 1; 0x79 encodes active-low '1' with decimal point.
    press(0); if(HEX5!==8'h79) $fatal(1,"Page indicator");
    press(1); wait(LEDR[0]); press(1); wait(!LEDR[0]);
    if(!LEDR[3]) $fatal(1,"Physical key controlled stop");
    // Configuration edit uses switches only while idle.
    SW=10'b0000000011; repeat(4) @(negedge MAX10_CLK1_50); press(0);
    if(dut.regs.cfg_burst!=1) $fatal(1,"Burst editing");
    SW=0;
    $display("PASS board: power-on reset, debounced keys, standalone run/pass, progress LEDs, page selection, controlled stop, parameter edit");
    $finish;
  end
  initial begin #5000000; $fatal(1,"Board timeout"); end
endmodule
