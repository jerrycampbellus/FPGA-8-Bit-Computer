/**************************************************************************
*
*    File Name:  sdram_controller.sv
*      Version:  1.2.1 - Explicit widths and warning cleanup
*         Date:  October 14, 2026
*   Maintainer:  J.CAMPBELL
*      Company:  RAINCloud
*      Project:  SDRAM_Tester
*       Module:  sdram_controller
*     Instance:  sdram_tester_top|memory (Quartus: sdram_controller:memory)
*      Release:  26101404 / host register API 1.1
*    Simulator:  Icarus Verilog 13.0 with the ISSI IS42S16320F model
*
*    Description:
*      Reusable, vendor-independent SDRAM controller for the DE10-Lite's
*      64 MiB IS42S16320F: four banks, 8192 rows/bank, 1024 columns/row,
*      and a 16-bit data bus. Addresses presented by clients are BYTE
*      addresses; all requests start on an even address.
*
*      Accepts one outstanding read or write request containing 1..1024
*      words (2..2048 bytes). Ready/valid handshakes carry the request,
*      write data, read data and completion. A complete write is buffered
*      before accessing SDRAM; a complete read is captured before it is
*      exposed to the client. Client stalls therefore cannot interrupt a
*      physical SDRAM burst or postpone refresh indefinitely.
*
*      Defaults to CL3 and sequential full-page burst mode. Each logical
*      request is split into physical bursts of at most 256 words and
*      further split at row/bank boundaries. Every burst is explicitly
*      terminated and precharged. An aligned page is four physical bursts
*      under one client request and one completion.
*
*      Initialization, refresh, address decoding, byte masks, SDRAM bus
*      direction and command timing are owned by this module. Board pins,
*      PLL generation, test patterns and JTAG registers are separate.
*
*    Qualified Clock / Timing Profile:
*      Core clock: 50 MHz (20 ns). The board supplies a forwarded SDRAM
*      clock nominally shifted +8 ns; this module does not generate it.
*      Power-up wait: 200 us plus initialization-command overhead.
*      Refresh: scheduled early enough to meet a 380-cycle maximum spacing.
*      Segment admission reserves 280 clocks with the default parameters.
*      Defaults are qualified as a set; changing clock rate, CAS, geometry
*      or MAX_WORDS requires controller/timing review and revalidation.
*
*    Interface Rules:
*      - A transfer occurs on a rising clk edge with valid && ready.
*      - Producers hold valid and payload stable until acceptance.
*      - req_words is the actual count, not count-minus-one.
*      - req_write=1 writes; req_write=0 reads.
*      - w_be[0] enables the low byte; w_be[1] enables the high byte.
*      - r_last accompanies the final accepted read word.
*      - done_error=0 succeeds; 1 rejects an invalid address/count.
*        Invalid requests consume no write data and return no read data.
*      - Completion remains valid until accepted. Read completion follows
*        delivery of the last word; write completion follows recovery and
*        precharge. Accept completion before submitting the next request.
*      - Synchronous active-high reset cancels pending work and restarts
*        initialization. Buffer/memory contents are not valid across reset.
*
*    RAINCloud Revision History:
*      1.0 / 26101401 - Buffered 1..16-word requests, physical BL1 accesses.
*      1.1 / 26101402 - Buffered 1..1024-word requests, terminated sequential
*                       bursts, row splitting and refresh-aware admission.
*      2026-10-14    - Added this header and implementation descriptions;
*                       executable RTL and programmed release unchanged.
*      1.2 / 26101403 - Generate MODE from named fields and the same CAS used
*                       by capture timing; reject unsupported parameters.
*                       Request length/masks vary without reloading MODE.
*      1.2.1 / 26101404 - Explicit segment-count width; physical timing,
*                       buffering and the request contract are unchanged.
*
*    References:
*      docs/INTERFACE.md  - Handshake, addressing and integration contract.
*      docs/TIMING.md     - Datasheet limits and board timing assumptions.
*      docs/VALIDATION.md - Simulation, timing and connected-board evidence.
*      docs/TESTBENCH.md  - Test hierarchy, scoreboards, coverage and debug.
*      Release/API registers are implemented in rtl/tester/tester_regs.sv.
*
**************************************************************************/

`timescale 1ns/1ps
module sdram_controller #(
  // Timing parameters are core-clock counts. FSM states can add conservative
  // overhead; these values are not a direct latency/throughput specification.
  // MAX_WORDS=1024 matches the fixed 11-bit count and 10-bit RAM address widths.
  parameter integer MAX_WORDS=1024,       // Complete logical transfer capacity.
  parameter integer POWERUP_CYCLES=10000, // 200 us before PRECHARGE ALL.
  parameter integer REFRESH_CYCLES=380,   // 7.6 us refresh-spacing budget.
  // tRP: precharge; tRCD: ACT-to-access; tRFC: refresh recovery;
  // TWR: final-write recovery; tRAS: minimum active-row duration.
  parameter integer TRP=2, TRCD=2, TRFC=4, TWR=2, TRAS=3,
  parameter integer CAS=3,               // CL2/CL3 supported; board qualified at CL3.
  parameter integer TMRD=2               // Mode-register recovery, >=2 clocks.
)(
  // Client interface: all signals below are synchronous to clk.
  input wire clk, reset,
  // Request channel: aligned byte address and actual word count, one in flight.
  input wire req_valid, output wire req_ready,
  input wire req_write, input wire [25:0] req_addr,
  input wire [10:0] req_words,
  // Write channel: exactly req_words beats; active-high per-byte enables.
  input wire w_valid, output wire w_ready,
  input wire [15:0] w_data, input wire [1:0] w_be,
  // Read channel: buffered data and final-beat indication; stable under stalls.
  output wire r_valid, input wire r_ready,
  output wire [15:0] r_data, output wire r_last,
  // Completion channel and status. initialized gates new requests;
  // refresh_count counts runtime refresh commands (wraps at 32 bits).
  output wire done_valid, input wire done_ready,
  output reg [1:0] done_error, output reg initialized,
  output reg [31:0] refresh_count,
  // Physical SDRAM pins: active-low command strobes, multiplexed row/column
  // address, bank, active-high DQM masks and bidirectional 16-bit DQ.
  output wire sdram_cke, output wire sdram_cs_n,
  output reg sdram_ras_n, sdram_cas_n, sdram_we_n,
  output reg [12:0] sdram_addr, output reg [1:0] sdram_ba,
  output reg [1:0] sdram_dqm, inout wire [15:0] sdram_dq
);
  // Mode-register fields (ISSI datasheet p24). Physical burst format is a
  // scheduler invariant, not an application request option. Finite/interleaved
  // bursts and single-location writes would require a different scheduler.
  // CAS is the single source for both SDRAM programming and the read pipeline.
  // Address-bit layout: [12:10] reserved, [9] single-write flag,
  // [8:7] operation, [6:4] CAS, [3] order, [2:0] burst length; BA must be zero.
  // This profile is loaded only at initialization. req_words and w_be may vary
  // on every logical request without changing any of these physical fields.
  localparam [2:0] MODE_BURST_LENGTH=3'b111; // Full page, explicitly terminated.
  localparam MODE_BURST_INTERLEAVED=1'b0;  // Sequential columns.
  localparam [1:0] MODE_OPERATION=2'b00;   // Normal operation.
  localparam MODE_WRITE_SINGLE=1'b0;      // Writes use the programmed burst.
  localparam [12:0] MODE_REGISTER={3'b000, MODE_WRITE_SINGLE, MODE_OPERATION,
    CAS[2:0], MODE_BURST_INTERLEAVED, MODE_BURST_LENGTH};

  // ----------------------------------------------------------------------
  // Physical command scheduler
  // Init: PWR -> IPRE -> eight IREF cycles -> MODE -> IDLE (via WAIT).
  // Access: IDLE -> ACT -> ACCESS -> WBURST/RBURST -> PRE -> ADVANCE.
  // REF is entered only with all banks precharged; WAIT handles recovery.
  // ----------------------------------------------------------------------
  localparam PWR=0, IPRE=1, IREF=2, MODE=3, WAIT=4, IDLE=5,
    ACT=6, ACCESS=7, RBURST=8, PRE=9, ADVANCE=10, REF=11, WBURST=12;
  localparam [10:0] SEGMENT_MAX=11'd256; // Leaves room for refresh at 50 MHz.
  // Includes activate, burst pipeline/termination, recovery, precharge and FSM overhead.
  localparam ACCESS_BUDGET=SEGMENT_MAX+TRCD+TRAS+CAS+TWR+TRP+12;
  // Invalid generate branches deliberately name missing modules: FPGA tools
  // and simulators must reject an unsupported profile at elaboration,
  // rather than silently truncate a parameter or program a mismatched mode.
  generate
    if(CAS!=2 && CAS!=3) begin : invalid_cas
      SDRAM_CONFIG_ERROR__CAS_must_be_2_or_3 invalid();
    end
    if(MAX_WORDS<1 || MAX_WORDS>1024) begin : invalid_capacity
      SDRAM_CONFIG_ERROR__MAX_WORDS_must_be_1_to_1024 invalid();
    end
    if(POWERUP_CYCLES<1 || TRP<1 || TRCD<1 || TRFC<1 || TWR<1 || TRAS<1 || TMRD<2) begin : invalid_timing
      SDRAM_CONFIG_ERROR__timing_counts_invalid invalid();
    end
    if(REFRESH_CYCLES<=ACCESS_BUDGET || REFRESH_CYCLES>65535) begin : invalid_refresh
      SDRAM_CONFIG_ERROR__refresh_budget_invalid invalid();
    end
  endgenerate
  reg [3:0] state, resume_state;
  reg [31:0] delay_count;
  reg [15:0] refresh_age;
  reg [3:0] init_refs;
  // Logical transaction state is independent of the physical scheduler.
  // collected: all write beats buffered (immediately true for a read).
  // delivered: full read buffer captured; complete: completion may be accepted.
  reg busy, writing, collected, delivered, complete;
  // word_addr is the next physical segment's start:
  // [24:23] bank, [22:10] row, [9:0] column. Client byte bit 0 is checked.
  reg [24:0] word_addr;
  // Count/index roles: requested total, write collection, physical segment
  // offset, and client read response. Counts must represent 1024 itself.
  reg [10:0] count, fill_index, exec_index, read_index;
  reg [10:0] segment_words, burst_cycle;
  reg [9:0] capture_index;
  // Write entries contain {active-high SDRAM DQM mask, 16-bit data}.
  reg [17:0] write_buffer[0:MAX_WORDS-1];
  reg [15:0] read_buffer[0:MAX_WORDS-1];
  reg [17:0] write_prefetch;
  reg [15:0] read_output;
  reg dq_enable;
  reg [15:0] dq_out;
  // Unconditional I/O capture, followed by RAM capture on the next core edge.
  reg [15:0] dq_sample;
  always @(posedge clk) dq_sample<=sdram_dq;

  // Segment sizing prevents full-page mode from wrapping within a row.
  // Recompute the bank/row from word_addr after each segment.
  wire [10:0] remaining=count-exec_index;
  wire [10:0] row_remaining=11'd1024-{1'b0,word_addr[9:0]};
  wire [10:0] row_chunk=remaining<row_remaining ? remaining : row_remaining;
  wire [10:0] next_segment=row_chunk<SEGMENT_MAX ? row_chunk : SEGMENT_MAX;
  // Use the worst-case segment budget even for short requests and idle time.
  // With defaults this asserts at age 100; IDLE services REF before ACT.
  // Refresh continues while client input/output/completion channels are stalled.
  wire refresh_due=refresh_age>=REFRESH_CYCLES-ACCESS_BUDGET;
  // Widen the exclusive end address so a 64 MiB overflow cannot wrap away.
  wire [26:0] end_addr={1'b0,req_addr}+{15'd0,req_words,1'b0};
  // Synchronous RAM needs the next beat's address one core edge early.
  // ACCESS consumes the prefetched first write word; WBURST streams the rest.
  // Read prefetch advances only on acceptance, preserving stalled payloads.
  wire [9:0] write_fetch_index=state==ACCESS ? exec_index[9:0]+10'd1 :
    state==WBURST ? exec_index[9:0]+burst_cycle[9:0]+10'd1 : exec_index[9:0];
  wire [9:0] read_fetch_index=(r_valid && r_ready && !r_last) ? read_index[9:0]+10'd1 : read_index[9:0];
  // Neither array is reset: validity is controlled separately and requests fully
  // populate their data before use. This permits embedded RAM implementation.
  always @(posedge clk) begin
    if(w_valid && w_ready) write_buffer[fill_index[9:0]]<={~w_be,w_data};
    write_prefetch<=write_buffer[write_fetch_index];
    if(state==RBURST && burst_cycle>=CAS && !reset)
      read_buffer[capture_index]<=dq_sample;
    read_output<=read_buffer[read_fetch_index];
  end

  // ----------------------------------------------------------------------
  // Ready/valid contract and DQ ownership
  // ----------------------------------------------------------------------
  assign req_ready=initialized && !busy && !reset;
  assign w_ready=busy && writing && !collected && done_error==0 && !reset;
  assign r_valid=busy && !writing && delivered && !complete && !reset;
  assign r_data=read_output;
  assign r_last=read_index==count-1;
  assign done_valid=busy && complete && !reset;
  // CKE stays high: this release uses runtime AUTO REFRESH, not self-refresh.
  assign sdram_cke=1'b1;
  assign sdram_cs_n=1'b0;
  assign sdram_dq=dq_enable ? dq_out : 16'hzzzz;

  // ----------------------------------------------------------------------
  // Transaction bookkeeping and registered SDRAM commands
  // ----------------------------------------------------------------------
  always @(posedge clk) begin
    if(reset) begin
      // Drop all validity/ownership state; RAM contents need no reset hardware.
      state<=PWR; resume_state<=IDLE; delay_count<=POWERUP_CYCLES;
      initialized<=0; refresh_age<=0; refresh_count<=0; init_refs<=0;
      busy<=0; writing<=0; collected<=0; delivered<=0; complete<=0;
      done_error<=0; word_addr<=0; count<=0; fill_index<=0;
      exec_index<=0; read_index<=0; segment_words<=0; burst_cycle<=0; capture_index<=0;
      sdram_ras_n<=1; sdram_cas_n<=1; sdram_we_n<=1;
      sdram_addr<=0; sdram_ba<=0; sdram_dqm<=3; dq_enable<=0; dq_out<=0;
    end else begin
      // Default command is NOP, with DQ released. Access states override it.
      sdram_ras_n<=1; sdram_cas_n<=1; sdram_we_n<=1;
      sdram_dqm<=initialized ? 2'b00 : 2'b11; dq_enable<=0;
      if(initialized && refresh_age!=16'hffff) refresh_age<=refresh_age+1'b1;
      // Latch one request. Reject before any write-data handshake or SDRAM access.
      if(req_valid && req_ready) begin
        busy<=1; writing<=req_write; word_addr<=req_addr[25:1];
        count<=req_words; fill_index<=0; exec_index<=0; read_index<=0;
        collected<=!req_write; delivered<=0; complete<=0; done_error<=0;
        if(req_addr[0] || req_words==0 || req_words>MAX_WORDS || end_addr>27'h4000000) begin
          done_error<=1; complete<=1;
        end
      end
      // These handshakes progress independently of refresh/command timing.
      if(w_valid && w_ready) begin
        if(fill_index==count-1) collected<=1;
        else fill_index<=fill_index+1'b1;
      end
      if(r_valid && r_ready) begin
        if(r_last) complete<=1;
        else read_index<=read_index+1'b1;
      end
      if(done_valid && done_ready) busy<=0;
      case(state)
        // Initialization: wait with NOPs, close every bank, refresh eight times,
        // then load the compile-time profile. No requests are accepted until IDLE.
        PWR: if(delay_count==0) state<=IPRE; else delay_count<=delay_count-1'b1;
        IPRE: begin
          sdram_ras_n<=0; sdram_we_n<=0; sdram_addr<=13'h400;
          delay_count<=TRP-1; resume_state<=IREF; state<=WAIT;
        end
        IREF: begin
          sdram_ras_n<=0; sdram_cas_n<=0; init_refs<=init_refs+1'b1;
          delay_count<=TRFC-1; resume_state<=init_refs==7 ? MODE : IREF; state<=WAIT;
        end
        MODE: begin
          sdram_ras_n<=0; sdram_cas_n<=0; sdram_we_n<=0;
          sdram_addr<=MODE_REGISTER; sdram_ba<=0; // Default CL3=0x037; CL2=0x027.
          // WAIT includes its state-transition overhead; TMRD is a minimum
          // recovery setting, not an exact request-ready latency specification.
          delay_count<=TMRD; resume_state<=IDLE; state<=WAIT;
        end
        // Shared recovery counter resumes the state saved by the last command.
        WAIT: if(delay_count==0) state<=resume_state; else delay_count<=delay_count-1'b1;
        // Refresh has priority over a buffered transfer. A stalled client leaves
        // this scheduler free to refresh even while the logical request is busy.
        IDLE: begin
          if(!initialized) begin initialized<=1; refresh_age<=0; end
          else if(refresh_due) state<=REF;
          else if(busy && collected && !delivered && !complete) begin
            segment_words<=next_segment; state<=ACT;
          end
        end
        // Runtime AUTO REFRESH with all banks closed; restart the age counter.
        REF: begin
          sdram_ras_n<=0; sdram_cas_n<=0; refresh_age<=0;
          refresh_count<=refresh_count+1'b1;
          delay_count<=TRFC-1; resume_state<=IDLE; state<=WAIT;
        end
        // Open the selected row. Waiting max(tRAS,tRCD) here also makes the
        // later explicit precharge safe for very short (one-word) segments.
        ACT: begin
          sdram_ras_n<=0; sdram_ba<=word_addr[24:23]; sdram_addr<=word_addr[22:10];
          delay_count<=((TRAS>TRCD)?TRAS:TRCD)-1; resume_state<=ACCESS; state<=WAIT;
        end
        // Launch one column command for the whole segment. Writes drive their
        // first word with WRITE; reads begin a separate CAS/capture pipeline.
        ACCESS: begin
          sdram_cas_n<=0; sdram_we_n<=!writing;
          sdram_addr<={3'b000,word_addr[9:0]}; // Auto-precharge disabled in full-page mode.
          if(writing) begin
            dq_enable<=1; dq_out<=write_prefetch[15:0]; sdram_dqm<=write_prefetch[17:16];
            burst_cycle<=1; state<=WBURST;
          end else begin
            burst_cycle<=0; capture_index<=exec_index[9:0]; state<=RBURST;
          end
        end
        // Stream consecutive prefetched words and masks without client stalls.
        // Termination occupies the first clock after the last data word;
        // write recovery is then observed before closing the row.
        WBURST: begin
          if(burst_cycle==segment_words) begin
            sdram_we_n<=0; sdram_dqm<=3; // BURST TERMINATE; no extra write beat.
            delay_count<=TWR-1; resume_state<=PRE; state<=WAIT;
          end else begin
            dq_enable<=1; dq_out<=write_prefetch[15:0]; sdram_dqm<=write_prefetch[17:16];
            burst_cycle<=burst_cycle+1'b1;
          end
        end
        // The read command/termination pipeline and the I/O-to-RAM pipeline
        // overlap. Keep capturing after BURST TERMINATE until the last sampled
        // word reaches RAM; capture_index addresses the complete logical page.
        RBURST: begin
          // At command+N terminate the SDRAM pipeline after exactly N words.
          // The registered I/O sample reaches RAM CAS+1 clocks after READ.
          if(burst_cycle==segment_words-1) sdram_we_n<=0;
          if(burst_cycle>=CAS) capture_index<=capture_index+1'b1;
          if(burst_cycle==segment_words+CAS-1) state<=PRE;
          else burst_cycle<=burst_cycle+1'b1;
        end
        // A10=1 selects PRECHARGE ALL. Only one bank is opened at a time.
        PRE: begin
          sdram_ras_n<=0; sdram_we_n<=0; sdram_addr<=13'h400;
          delay_count<=TRP-1; resume_state<=ADVANCE; state<=WAIT;
        end
        // After precharge recovery, either finish the entire logical request
        // or move to its next segment. Return through IDLE to recheck refresh.
        ADVANCE: begin
          if(exec_index+segment_words==count) begin
            if(writing) complete<=1; else delivered<=1;
          end else begin
            exec_index<=exec_index+segment_words; word_addr<=word_addr+segment_words;
          end
          state<=IDLE;
        end
        default: state<=PWR;
      endcase
    end
  end
endmodule
