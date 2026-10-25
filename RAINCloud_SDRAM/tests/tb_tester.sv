/**************************************************************************
* RAINCloud / SDRAM_Tester / tb_tester.sv
* Verification target: controller 1.2.1 / release 26101404 / register API 1.1
* Date: October 14, 2026; Maintainer: J.CAMPBELL
*
* Register-level integration: Avalon/local-control driver -> tester_regs ->
* sdram_controller -> ISSI model. Core is 50 MHz, memory model clock is +10 ns.
* Avalon accesses are driven directly; this does not simulate JTAG transport.
*
* Checks seven patterns, latched configuration, nonce/ack errors, ownership,
* stop/drain, frozen snapshots, staging byte masks/aliases and one-request page
* operations. Deliberate read corruption verifies first-error reporting and
* the bounded log. The controller supplies real modeled SDRAM transactions.
*
* Expected: PASS tester; $fatal on a failed assertion or 30 ms watchdog.
* Run through scripts/test.ps1; see docs/TESTBENCH.md for sequence and limits.
**************************************************************************/
`timescale 1ns/1ps
module tb_tester;
  reg clk=0,reset=1;
  always #10 clk=~clk;
  reg [31:0] av_address=0,av_writedata=0;
  reg av_read=0,av_write=0;
  reg [3:0] av_byteenable=15;
  wire [31:0] av_readdata;
  wire av_readdatavalid,av_waitrequest;
  reg local_start=0,local_stop=0,local_release=0,local_edit=0,local_edit_mode=0,edit_down=0;
  reg [2:0] edit_field=0,edit_digit=0;
  reg [3:0] display_page=0;
  wire [19:0] display_value;
  wire busy,done,stopped,owner,failed,stop_pending,initialized;
  wire req_valid,req_ready,req_write,w_valid,w_ready,r_valid,r_ready,r_last,done_valid,done_ready;
  wire [25:0] req_addr;
  wire [10:0] req_words;
  wire [15:0] w_data,r_data,raw_read;
  wire [1:0] w_be,done_error,dqm,ba;
  wire [31:0] refresh_count;
  wire [12:0] addr; wire [15:0] dq;
  wire cke,cs,ras,cas,we;
  reg inject=0;
  // Flip one returned data bit before the checker, without modifying model RAM.
  // This exercises diagnostics, not an electrical SDRAM fault or ECC mechanism.
  assign r_data=raw_read ^ (inject ? 16'h0001 : 0);
  tester_regs dut(.*);
  sdram_controller memory(.*,.r_data(raw_read),.sdram_addr(addr),.sdram_ba(ba),.sdram_dqm(dqm),.sdram_dq(dq),
    .sdram_cke(cke),.sdram_cs_n(cs),.sdram_ras_n(ras),.sdram_cas_n(cas),.sdram_we_n(we));
  IS42S16320F model(.Clk(~clk),.Cke(cke),.Cs_n(cs),.Ras_n(ras),.Cas_n(cas),.We_n(we),.Addr(addr),.Ba(ba),.Dqm(dqm),.Dq(dq));
  integer seq=0, p, i, requests=0, saved_requests;
  always @(posedge clk) if(req_valid && req_ready) requests<=requests+1;
  reg [31:0] value, saved, old_id;
  // Minimal Avalon BFM: byte addresses, one-cycle commands, no wait states.
  // rd samples the registered response on the following falling edge.
  task wr(input [31:0] a,v);
    begin @(negedge clk); av_address=a; av_writedata=v; av_write=1; @(negedge clk); av_write=0; end
  endtask
  task rd(input [31:0] a,output [31:0] v);
    begin @(negedge clk); av_address=a; av_read=1; @(negedge clk); if(!av_readdatavalid) $fatal(1,"Missing Avalon response"); v=av_readdata; av_read=0; end
  endtask
  // Every normal command gets a new nonce; verify acknowledgement and status.
  // The duplicate-delivery test below deliberately bypasses this helper.
  task command(input [7:0] op,input [31:0] err);
    begin
      seq=seq+1; wr('h14,(seq<<8)|op); rd('h14,value);
      if(value!==((seq<<8)|op)) $fatal(1,"Bad command acknowledgement");
      rd('h18,value); if(value!==err) $fatal(1,"Command %d error %d expected %d",op,value,err);
    end
  endtask
  // Freeze results only after idle, then compare operation/byte/error counts.
  // Counts here fit 32 bits; Python tests separately exercise 64-bit decoding.
  task finish_run(input [31:0] expected_ops,input [31:0] expected_errors);
    begin
      wait(!busy); command(3,0);
      rd('h88,value); if(value!==expected_ops) $fatal(1,"Operation count %d expected %d",value,expected_ops);
      rd('h8c,value); if(value!==expected_ops*2) $fatal(1,"Byte count");
      rd('h9c,value); if(value!==expected_errors) $fatal(1,"Errors %d expected %d",value,expected_errors);
      if(!done) $fatal(1,"Engine did not leave RUN");
    end
  endtask
  initial begin
    // Initialization/ownership, then short runs with both stall flags and a
    // 500-clock phase gap. Mask pattern 6 has seven operations per word/repeat;
    // the other patterns have two (write/read).
    repeat(5) @(negedge clk); reset=0; wait(initialized);
    rd(0,value); if(value!==32'h5344524d) $fatal(1,"Build identity");
    command(1,3); command(6,0);
    // Narrow register selectors must preserve full-address rejection, including
    // unaligned accesses. Upper address bits cannot alias a writable register.
    wr('h10000020,'hface); rd('h10000020,value);
    if(value!==32'hdeadbeef) $fatal(1,"Upper address aliased scalar read");
    wr('h220,'hface); rd('h220,value);
    if(value!==32'hdeadbeef) $fatal(1,"Unknown page aliased scalar read");
    wr('h21,'hface); rd('h21,value);
    if(value!==32'hdeadbeef) $fatal(1,"Unaligned register read accepted");
    rd('h20,value); if(value!==0) $fatal(1,"Invalid register write changed start");
    rd('h10000080,value); if(value!==32'hdeadbeef) $fatal(1,"Upper address aliased snapshot");
    // Independent constants check intentional modulo-16-bit arithmetic and
    // ensure unsupported pattern IDs do not alias low three-bit selections.
    if(dut.pattern_word(32'h3fffffe,32'hffff,32'd1,32'hffff)!==16'hfffd)
      $fatal(1,"Incrementing pattern wrap changed");
    if(dut.pattern_word(0,0,32'd8,0)!==16'ha55a ||
       dut.pattern_word(0,0,32'hfffffff8,0)!==16'ha55a)
      $fatal(1,"High pattern bits aliased valid pattern");
    wr('h2c,8); command(1,2);
    wr('h20,'h7f0); wr('h24,33); wr('h28,2); wr('h34,16); wr('h38,3); wr('h3c,500);
    for(p=0;p<7;p=p+1) begin
      wr('h2c,p); command(1,0);
      // Host config and local edits cannot perturb the latched run.
      wr('h24,99); @(negedge clk); local_edit=1; local_start=1;
      @(negedge clk); local_edit=0; local_start=0;
      rd('h24,value); if(value!==33) $fatal(1,"Configuration changed while active");
      finish_run(p==6 ? 462 : 132,0);
    end
    // Inject 33 failures: bounded log (8), full first address/data, total count.
    wr('h20,'h10007f0); wr('h28,1); wr('h2c,0); wr('h30,'h1234);
    inject=1; command(1,0); finish_run(66,33); inject=0;
    rd('ha0,value); if(value!=='h10007f0) $fatal(1,"Full failure address lost");
    rd('ha4,value); if(value!==32'h12341235) $fatal(1,"Expected/actual mismatch");
    rd('ha8,value); if(value!==8) $fatal(1,"Error log bound");
    display_page=9; #1; if(display_value!==16) $fatal(1,"High failure address display page");
    display_page=10; #1; if(display_value!=='h1234) $fatal(1,"Expected display page");
    display_page=11; #1; if(display_value!=='h1235) $fatal(1,"Actual display page");
    // Snapshot remains immutable throughout next run until explicitly replaced.
    rd('h80,saved); command(1,0); rd('h80,value); if(value!==saved) $fatal(1,"Snapshot mutated");
    command(1,1); command(7,1);
    @(negedge clk); local_release=1; local_stop=1;
    @(negedge clk); local_release=0; local_stop=0;
    wait(!busy); if(!stopped || !owner) $fatal(1,"Controlled local stop / ownership");
    command(3,0); rd('h88,value); if(value>16) $fatal(1,"Stop did not drain only current transaction");
    // Bounded staging operations and byte enables.
    wr('h40,'h7fe); wr('h44,2); wr('h100,'h31234); wr('h104,'h3abcd);
    command(5,0); finish_run(2,0);
    wr('h100,'h1ffff); wr('h104,'h1ffff); command(5,0); finish_run(2,0);
    command(4,0); finish_run(2,0);
    rd('h100,value); if(value!=='h312ff) $fatal(1,"Staging low-byte mask");
    rd('h104,value); if(value!=='h3abff) $fatal(1,"Staging row crossing");
    // Page staging is a single 1024-word controller request, not 64 small requests.
    wr('h40,'hfffffe); wr('h44,1024);
    for(i=0;i<1024;i=i+1) wr('h1000+4*i,18'h30000 | ((i*71)^16'h1234)&16'hffff);
    saved_requests=requests; command(5,0); finish_run(1024,0);
    if(requests!=saved_requests+1) $fatal(1,"Page write was split into client requests");
    saved_requests=requests; command(4,0); finish_run(1024,0);
    if(requests!=saved_requests+1) $fatal(1,"Page read was split into client requests");
    // Back-to-back Avalon reads exercise the synchronous RAM response pipeline.
    @(negedge clk); av_read=1; av_address='h1000;
    for(i=0;i<1024;i=i+1) begin
      @(negedge clk);
      if(!av_readdatavalid || av_readdata!==(18'h30000 | (((i*71)^16'h1234)&16'hffff)))
        $fatal(1,"Page staging beat %d got %h",i,av_readdata);
      av_address='h1000+4*(i+1);
    end
    av_read=0;
    rd('h100,value); if(value!=='h31234) $fatal(1,"Legacy staging alias");
    av_byteenable=1; wr('h100,'h000000ff); av_byteenable=15;
    rd('h1000,value); if(value!=='h312ff) $fatal(1,"Partial host byte write");
    // Update low bytes only across the whole page.
    for(i=0;i<1024;i=i+1) wr('h1000+4*i,'h1ffff);
    command(5,0); finish_run(1024,0); command(4,0); finish_run(1024,0);
    for(i=0;i<1024;i=i+1) begin
      rd('h1000+4*i,value);
      if(value!==(18'h300ff | (((i*71)^16'h1234)&16'hff00))) $fatal(1,"Page mask beat %d",i);
    end
    wr('h44,1025); command(4,2);
    wr('h44,1024); wr('h40,'h3fff802); command(5,2);
    // Page-size generator/checker chunks, including a final one-word tail.
    wr('h20,'h1fffffe); wr('h24,1025); wr('h28,2); wr('h34,1024);
    for(p=0;p<7;p=p+1) begin
      wr('h2c,p); command(1,0); finish_run(p==6 ? 14350 : 4100,0);
    end
    // Stop drains one complete page request and preserves ownership.
    wr('h24,8192); wr('h2c,2); wr('h38,0); command(1,0);
    wait(w_valid && w_ready); @(negedge clk); local_stop=1;
    @(negedge clk); local_stop=0; wait(!busy);
    if(!stopped || !owner) $fatal(1,"Page stop / ownership");
    finish_run(1024,0);
    // Invalid commands and duplicate command delivery never rerun a request.
    wr('h40,1); command(4,2); command(255,4);
    rd('h50,old_id); wr('h14,(seq<<8)|255); rd('h50,value); if(value!==old_id) $fatal(1,"Duplicate command reran");
    wr('h20,1); command(1,2); wr('h20,0);
    // Ownership release permits standalone run with shared engine and 1024-word preset.
    command(7,0); @(negedge clk); local_edit=1; edit_field=0; edit_digit=0;
    @(negedge clk); local_edit=0; rd('h24,value); if(value!==1024) $fatal(1,"Full-page preset truncated");
    @(negedge clk); local_start=1; @(negedge clk); local_start=0;
    command(6,1); finish_run(2048,0);
    saved=refresh_count; repeat(1000) @(negedge clk);
    if(refresh_count<=saved) $fatal(1,"Idle refresh stopped");
    $display("PASS tester: patterns 0..6, repeats, stalls, retention gap, ownership, local stop, counters, coherent snapshots, error log, single-request pages, pipelined staging/legacy alias, standalone 1024 words");
    $finish;
  end
  initial begin #30000000; $fatal(1,"Tester timeout"); end
endmodule
