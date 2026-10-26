/**************************************************************************
* RAINCloud / SDRAM_Tester / tb_controller.sv
* Verification target: controller 1.2.1 / release 26101404 (October 14, 2026)
* Maintainer: J.CAMPBELL
*
* Self-checking library test: ready/valid driver -> sdram_controller -> ISSI
* IS42S16320F model. No tester, JTAG or Intel primitives are involved. Core
* period is 20 ns; the model samples the inverted core clock (+10 ns phase).
* scripts/test.ps1 runs TEST_CAS=3 and TEST_CAS=2 as separate simulations.
*
* The scoreboard changes only on accepted write beats and honors each byte
* mask. Reads check both data and r_last; independent command monitors check
* MODE, burst termination and refresh spacing. Long stalls exceed one refresh
* interval to expose any dependency between client progress and refresh.
*
* Expected: PASS controller, 17,191 comparisons per CAS run; $fatal on mismatch
* or a 20 ms simulated-time watchdog. See docs/TESTBENCH.md for the case matrix,
* commands, limitations and waveform signals. This bench is simulation-only.
**************************************************************************/
`timescale 1ns/1ps
module tb_controller #(parameter integer TEST_CAS=3);
  reg clk=0,reset=1;
  always #10 clk=~clk;
  reg req_valid=0,req_write=0,w_valid=0,r_ready=0,done_ready=0;
  wire req_ready,w_ready,r_valid,r_last,done_valid,initialized;
  reg [25:0] req_addr=0; reg [10:0] req_words=0;
  reg [15:0] w_data=0; reg [1:0] w_be=3;
  wire [15:0] r_data,dq;
  wire [1:0] done_error,ba,dqm;
  wire [12:0] addr;
  wire cke,cs,ras,cas,we;
  wire [31:0] refresh_count;
  sdram_controller #(.CAS(TEST_CAS)) dut(.*,.sdram_addr(addr),.sdram_ba(ba),.sdram_dqm(dqm),.sdram_dq(dq),
    .sdram_cke(cke),.sdram_cs_n(cs),.sdram_ras_n(ras),.sdram_cas_n(cas),.sdram_we_n(we));
  IS42S16320F model(.Clk(~clk),.Cke(cke),.Cs_n(cs),.Ras_n(ras),.Cas_n(cas),.We_n(we),.Addr(addr),.Ba(ba),.Dqm(dqm),.Dq(dq));
  // Reference scoreboard is independent of model storage and controller internals.
  reg [15:0] expected[0:1023];
  // Request-local expected data, not a full-memory mirror. Every checked range
  // is initialized by a full-mask write before partial/no-op mask updates.
  integer i,j,k,checks=0;
  integer last_refresh=0, cycle=0, access_commands=0, terminate_commands=0, saved_accesses=0;
  integer mode_commands=0,mode_cycle=0;
  // Check the pins, not the implementation's MODE_REGISTER constant. One init
  // load must serve all byte/cache/page-sized requests and mixed byte masks.
  always @(posedge clk) begin
    if(!cs && !ras && !cas && !we) begin
      if(addr !== (TEST_CAS==3 ? 13'h037 : 13'h027) || ba!==0)
        $fatal(1,"MODE does not match CAS/profile: %h bank %h",addr,ba);
      mode_commands=mode_commands+1; mode_cycle=cycle;
    end
    if(initialized && (mode_commands!=1 || cycle-mode_cycle<2))
      $fatal(1,"Initialization MODE count/recovery invalid");
  end
  always @(posedge clk) begin
    if(initialized && !cs && ras && !cas) access_commands<=access_commands+1;
    if(initialized && !cs && ras && cas && !we) terminate_commands<=terminate_commands+1;
  end
  always @(posedge clk) begin
    cycle<=cycle+1;
    if(!cs && !ras && !cas && we) last_refresh<=cycle;
    if(initialized && cycle-last_refresh>380) $fatal(1,"Refresh deadline missed");
  end
  // Drive on falling edges; hold the request until a rising-edge handshake.
  // n is the actual word count; a is a byte address, including invalid cases.
  task request(input bit writing,input [25:0] a,input [10:0] n);
    begin
      @(negedge clk); req_addr=a; req_words=n; req_write=writing; req_valid=1;
      do @(posedge clk); while(!req_ready);
      @(negedge clk); req_valid=0;
    end
  endtask
  // Completion must remain asserted, with stable error status, during a
  // 420-clock stall. The global refresh monitor remains active throughout.
  task completion(input [1:0] err);
    begin
      wait(done_valid);
      if(done_error!==err) $fatal(1,"Completion error %d expected %d",done_error,err);
      repeat(420) @(negedge clk); // refresh must continue while completion blocked
      if(!done_valid || done_error!==err) $fatal(1,"Completion lost under stall");
      done_ready=1; @(negedge clk); done_ready=0;
    end
  endtask
  // Start with a 430-clock producer stall. Large writes then supply one beat
  // per clock; short writes insert patterned gaps. Scoreboard uses handshakes.
  task write_words(input [25:0] a,input integer n,input [1:0] mask,input [15:0] value);
    begin
      request(1,a,n);
      for(j=0;j<n;j=j+1) begin
        repeat(j==0 ? 430 : n>=256 ? 0 : (j%4)+1) @(negedge clk);
        w_valid=1; w_data=value+j; w_be=mask;
        do @(posedge clk); while(!w_ready);
        if(mask[0]) expected[j][7:0]=w_data[7:0];
        if(mask[1]) expected[j][15:8]=w_data[15:8];
        @(negedge clk); w_valid=0;
      end
      completion(0);
    end
  endtask
  // Backpressure checks valid/data/last stability before accepting each beat.
  task read_words(input [25:0] a,input integer n);
    reg [15:0] held; reg last;
    begin
      request(0,a,n);
      for(j=0;j<n;j=j+1) begin
        wait(r_valid); held=r_data; last=r_last;
        repeat(j==0 ? 420 : 3) begin
          @(negedge clk);
          if(!r_valid || r_data!==held || r_last!==last) $fatal(1,"Read changed under stall");
        end
        r_ready=1; @(posedge clk);
        if(r_data!==expected[j] || r_last!==(j==n-1)) $fatal(1,"Mismatch addr %h beat %d got %h expected %h last %b",a,j,r_data,expected[j],r_last);
        checks=checks+1;
        @(negedge clk); r_ready=0;
      end
      completion(0);
    end
  endtask
  // Continuously ready consumer checks RAM prefetch at one word per clock.
  task read_continuous(input [25:0] a,input integer n);
    begin
      request(0,a,n); @(negedge clk); r_ready=1;
      for(j=0;j<n;j=j+1) begin
        do @(posedge clk); while(!r_valid);
        if(r_data!==expected[j] || r_last!==(j==n-1))
          $fatal(1,"Continuous page mismatch %h beat %d got %h expected %h",a,j,r_data,expected[j]);
        checks=checks+1;
        @(negedge clk);
      end
      r_ready=0; completion(0);
    end
  endtask
  // Guard words use a fixed sentinel, independent of the request scoreboard.
  task check_guard(input [25:0] a);
    begin
      request(0,a,1); wait(r_valid);
      if(r_data!==16'hcafe) $fatal(1,"Page write changed adjacent word at %h: %h",a,r_data);
      @(negedge clk); r_ready=1; @(negedge clk); r_ready=0; completion(0);
    end
  endtask
  // Cycle 00/01/10/11 on consecutive beats to check preserved byte lanes.
  task mixed_masks(input [25:0] a,input integer n);
    begin
      request(1,a,n);
      for(j=0;j<n;j=j+1) begin
        @(negedge clk); w_valid=1; w_data=16'h91b3^j; w_be=j%4;
        do @(posedge clk); while(!w_ready);
        if(w_be[0]) expected[j][7:0]=w_data[7:0];
        if(w_be[1]) expected[j][15:8]=w_data[15:8];
      end
      @(negedge clk); w_valid=0; completion(0);
    end
  endtask
  reg [25:0] bases[0:5];
  integer lengths[0:9];
  initial begin
    // Phase 1: small transfers around row/bank boundaries and memory end,
    // followed by every count 1..15. Count 16 is covered by the boundary loop.
    bases[0]=0; bases[1]='h7fa; bases[2]='hfffffa;
    bases[3]='h1fffffa; bases[4]='h2fffffa; bases[5]='h3ffffe0;
    repeat(5) @(negedge clk); reset=0; wait(initialized);
    for(k=0;k<6;k=k+1) begin
      write_words(bases[k],16,3,16'h1234+k); read_words(bases[k],16);
      write_words(bases[k],16,1,16'hfeed); read_words(bases[k],16);
      write_words(bases[k],16,2,16'h5678); read_words(bases[k],16);
      write_words(bases[k],16,0,16'h0000); read_words(bases[k],16);
    end
    for(i=1;i<16;i=i+1) begin
      write_words('h3fc,i,3,16'hbeef); read_words('h3fc,i);
    end
    // Phase 2: directed counts around segment and page boundaries; this is
    // boundary coverage, not an exhaustive sweep of every length up to 1024.
    lengths[0]=17; lengths[1]=31; lengths[2]=255; lengths[3]=256; lengths[4]=257;
    lengths[5]=511; lengths[6]=512; lengths[7]=513; lengths[8]=1023; lengths[9]=1024;
    for(i=0;i<10;i=i+1) begin
      write_words('h7fa,lengths[i],3,16'h3900+i); read_continuous('h7fa,lengths[i]);
    end
    // Phase 3: complete pages with adjacent sentinels. An aligned page needs
    // four physical accesses; a page beginning at a row's last word needs five.
    bases[0]='h800; bases[1]='h7fe; bases[2]='hfffffe;
    bases[3]='h1fffffe; bases[4]='h2fffffe; bases[5]='h3fff800;
    for(k=0;k<6;k=k+1) begin
      write_words(bases[k]-2,1,3,16'hcafe);
      if(k!=5) write_words(bases[k]+2048,1,3,16'hcafe);
      saved_accesses=access_commands;
      write_words(bases[k],1024,3,16'h1200+k);
      if(access_commands-saved_accesses!=(k==0 || k==5 ? 4 : 5))
        $fatal(1,"Expected real segmented bursts for page, got %d commands",access_commands-saved_accesses);
      read_continuous(bases[k],1024);
      mixed_masks(bases[k],1024); read_words(bases[k],1024);
      check_guard(bases[k]-2); if(k!=5) check_guard(bases[k]+2048);
    end
    // Phase 4: odd address, zero/oversize count, and read/write end overflow.
    // No data is supplied for rejected writes; each must complete with error 1.
    request(0,1,1); completion(1);
    request(0,0,0); completion(1);
    request(0,0,1025); completion(1);
    request(0,'h3fffffe,2); completion(1);
    request(1,'h3fff802,1024); completion(1);
    if(access_commands!=terminate_commands) $fatal(1,"Unterminated physical burst");
    repeat(1000) @(negedge clk);
    $display("PASS controller: CAS=%0d, one MODE load, %0d comparisons, per-beat masks, lengths 1..1024, continuous pages, adjacent guards, row/bank/end boundaries, stalls, refresh, invalid requests",TEST_CAS,checks);
    $finish;
  end
  initial begin #20000000; $fatal(1,"Controller timeout"); end
endmodule
