/**************************************************************************
* RAINCloud / SDRAM_Tester / tb_performance.sv
* Verification target: controller 1.2.1 / release 26101404 (October 14, 2026)
* Maintainer: J.CAMPBELL
*
* Cycle profiler plus data checker: unstalled client -> real controller ->
* ISSI model, using a 50 MHz core and +8 ns memory clock. Ten request sizes x
* three locality patterns x two directions produce 60 records of 16 requests
* each. Writes initialize address-derived data before the corresponding reads.
*
* Output: one PERF JSON record per case, then PASS performance with 98,160
* comparisons. A 100 ms simulated-time watchdog bounds deadlocks. No waveform
* dump is enabled by default. See docs/TESTBENCH.md for record field meanings
* and docs/PERFORMANCE.md for the measured results and optimization estimates.
**************************************************************************/
`timescale 1ns/1ps
// Baseline profiler, not an optimized controller. All rates use 50 MHz and
// count accepted request through accepted completion, inclusive, without stalls.
module tb_performance;
  reg clk=0,reset=1;
  always #10 clk=~clk;
  reg req_valid=0,req_write=0,w_valid=0,r_ready=0,done_ready=1;
  wire req_ready,w_ready,r_valid,r_last,done_valid,initialized;
  reg [25:0] req_addr=0; reg [10:0] req_words=0;
  reg [15:0] w_data=0; reg [1:0] w_be=3;
  wire [15:0] r_data,dq;
  wire [1:0] done_error,ba,dqm;
  wire [12:0] addr;
  wire cke,cs,ras,cas,we;
  wire [31:0] refresh_count;
  sdram_controller dut(.*,.sdram_addr(addr),.sdram_ba(ba),.sdram_dqm(dqm),.sdram_dq(dq),
    .sdram_cke(cke),.sdram_cs_n(cs),.sdram_ras_n(ras),.sdram_cas_n(cas),.sdram_we_n(we));
  // Forwarded SDRAM clock matches the +8 ns board profile.
  wire memclk;
  assign #8 memclk=clk;
  IS42S16320F model(.Clk(memclk),.Cke(cke),.Cs_n(cs),.Ras_n(ras),.Cas_n(cas),.We_n(we),.Addr(addr),.Ba(ba),.Dqm(dqm),.Dq(dq));

  bit measuring=0, previous_row_valid=0;
  reg [14:0] previous_row;
  integer cycles=0,client_beats=0,physical_beats=0,activates=0,precharges=0,refreshes=0,reuse_candidates=0;
  integer clock_count=0,last_refresh=0,mode_loads=0,checks=0;
  // Deadline and MODE monitoring run even outside timed requests. A refresh
  // invalidates the remembered row, including refreshes in inter-request gaps.
  // Physical-beat accounting below intentionally observes controller internals;
  // keep it synchronized with the capture pipeline when changing the RTL.
  always @(posedge clk) begin
    clock_count=clock_count+1;
    if(!cs && !ras && !cas && !we) mode_loads=mode_loads+1;
    if(!cs && !ras && !cas && we) begin
      last_refresh=clock_count; previous_row_valid=0;
    end
    if(initialized && clock_count-last_refresh>380) $fatal(1,"Profile refresh deadline");
    if(measuring) begin
      cycles=cycles+1;
      if((w_valid && w_ready) || (r_valid && r_ready)) client_beats=client_beats+1;
      if(dut.dq_enable || (dut.state==dut.RBURST && dut.burst_cycle>=dut.CAS)) physical_beats=physical_beats+1;
      if(!cs && !ras && cas && we) begin
        // A candidate means the previous ACTIVE selected this bank/row without
        // intervening refresh. The current design still closes every segment.
        activates=activates+1;
        if(previous_row_valid && previous_row=={ba,addr}) reuse_candidates=reuse_candidates+1;
        previous_row_valid=1; previous_row={ba,addr};
      end
      if(!cs && !ras && cas && !we) precharges=precharges+1;
      if(!cs && !ras && !cas && we) refreshes=refreshes+1;
    end
  end
  // Address-derived expected data remains valid when workload writes overlap.
  function [15:0] pattern(input [25:0] a);
    pattern=16'h5ac3 ^ a[16:1] ^ {7'd0,a[25:17]};
  endfunction
  // Timing includes the accepted request and accepted completion edges, but
  // excludes idle edges between requests. Every client/data beat is checked.
  // No tester-engine, Python or JTAG latency is present in these measurements.
  task transfer(input bit writing,input [25:0] a,input integer n);
    integer j;
    begin
      @(negedge clk); wait(req_ready);
      req_valid=1; req_write=writing; req_addr=a; req_words=n; measuring=1;
      @(negedge clk); req_valid=0;
      if(writing) begin
        for(j=0;j<n;j=j+1) begin
          w_valid=1; w_data=pattern(a+2*j);
          do @(posedge clk); while(!w_ready);
          @(negedge clk);
        end
        w_valid=0;
      end else begin
        r_ready=1;
        for(j=0;j<n;j=j+1) begin
          do @(posedge clk); while(!r_valid);
          if(r_data!==pattern(a+2*j) || r_last!==(j==n-1))
            $fatal(1,"Profile data mismatch %h/%0d",a,j);
          checks=checks+1;
          @(negedge clk);
        end
        r_ready=0;
      end
      do @(posedge clk); while(!done_valid);
      if(done_error!==0) $fatal(1,"Profile completion error");
      @(negedge clk); measuring=0;
    end
  endtask
  integer sizes[0:9];
  integer size_index,workload,direction,request_index,n;
  reg [25:0] a;
  initial begin
    sizes[0]=1; sizes[1]=4; sizes[2]=8; sizes[3]=16; sizes[4]=32;
    sizes[5]=64; sizes[6]=128; sizes[7]=256; sizes[8]=512; sizes[9]=1024;
    repeat(5) @(negedge clk); reset=0; wait(initialized);
    for(size_index=0;size_index<10;size_index=size_index+1) begin
      n=sizes[size_index];
      for(workload=0;workload<3;workload=workload+1) begin
        // 0: same row, sequential aligned addresses; 1: alternating rows;
        // 2: repeated row-crossing request at the row's final word.
        for(direction=0;direction<2;direction=direction+1) begin
          @(negedge clk);
          cycles=0; client_beats=0; physical_beats=0; activates=0;
          precharges=0; refreshes=0; reuse_candidates=0; previous_row_valid=0;
          for(request_index=0;request_index<16;request_index=request_index+1) begin
            case(workload)
              0:a=2*((request_index*n)%1024);
              1:a=(request_index%2)*2048;
              2:a=2046;
            endcase
            transfer(direction==0,a,n);
          end
          // Exactly N client and N physical beats per request; equal ACTIVE/
          // PRECHARGE counts check this closed-row baseline. The overhead
          // subtraction assumes client and physical data phases do not overlap.
          // An overlap implementation needs new accounting before reusing it.
          if(client_beats!=16*n || physical_beats!=16*n)
            $fatal(1,"Profiler beat accounting: %0d/%0d expected %0d",client_beats,physical_beats,16*n);
          if(activates!=precharges) $fatal(1,"Profile left bank open");
          $display("PERF {\"words\":%0d,\"workload\":%0d,\"read\":%0d,\"requests\":16,\"cycles\":%0d,\"client_beats\":%0d,\"physical_beats\":%0d,\"overhead_cycles\":%0d,\"activates\":%0d,\"precharges\":%0d,\"refreshes\":%0d,\"reuse_candidates\":%0d}",n,workload,direction,cycles,client_beats,physical_beats,cycles-client_beats-physical_beats,activates,precharges,refreshes,reuse_candidates);
        end
      end
    end
    if(mode_loads!=1) $fatal(1,"Application requests reloaded MODE");
    $display("PASS performance: 60 measured cases, %0d comparisons, one MODE load, refresh checked",checks);
    $finish;
  end
  initial begin #100000000; $fatal(1,"Performance timeout"); end
endmodule
