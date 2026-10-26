/**************************************************************************
* RAINCloud / SDRAM_Tester / tester_regs.sv
* Release: 26101404, controller 1.2.1, register API 1.1 (October 14, 2026)
* Maintainer: J.CAMPBELL
*
* Shared local/JTAG register bank, pattern generator and read checker. Host
* and board controls use one engine; owner=1 grants host configuration rights.
* A start latches configuration, then issues 1..1024-word logical requests to
* the memory library. Physical MODE, row commands and refresh stay in memory.
*
* Direct operations use a 1024-entry staging RAM with per-word byte enables.
* Test operations generate/check patterns in the FPGA. Each accepted start or
* direct-memory command increments run_id once; data counters retire on completion.
* Stop drains the current logical request. Snapshot command 3 freezes results
* and the first eight errors so host block reads cannot tear live counters.
*
* Contract: docs/API.md; local controls: docs/BOARD.md.
* Verification: tests/tb_tester.sv and docs/TESTBENCH.md.
**************************************************************************/
`timescale 1ns/1ps
module tester_regs #(
  parameter [31:0] BUILD_ID=32'h26101404,
  parameter integer CLOCK_HZ=50000000
)(
  input wire clk, reset, initialized,
  // Avalon-MM uses byte addresses, one-cycle read responses and no wait states.
  // Byte enables merge ordinary writes; command writes require all four lanes.
  input wire [31:0] av_address, av_writedata,
  input wire av_read, av_write, input wire [3:0] av_byteenable,
  output wire [31:0] av_readdata, output reg av_readdatavalid,
  output wire av_waitrequest,
  // Local inputs are already synchronized/debounced; start/stop/edit are pulses.
  input wire local_start, local_stop, local_release, local_edit, local_edit_mode,
  input wire [2:0] edit_field, edit_digit, input wire edit_down,
  input wire [3:0] display_page,
  output reg [19:0] display_value,
  output reg busy, done, stopped, owner,
  output wire failed, output reg stop_pending,
  // One outstanding memory request, owned through its completion handshake.
  output wire req_valid, input wire req_ready,
  output wire req_write, output wire [25:0] req_addr,
  output wire [10:0] req_words,
  output wire w_valid, input wire w_ready,
  output wire [15:0] w_data, output wire [1:0] w_be,
  input wire r_valid, output wire r_ready,
  input wire [15:0] r_data, input wire r_last,
  input wire done_valid, output wire done_ready, input wire [1:0] done_error,
  input wire [31:0] refresh_count
);
  // Configuration is always readable; writes/edits require idle and ownership.
  // Separate run parameters latch at start so a running pass stays consistent.
  reg [31:0] cfg_start, cfg_words, cfg_repeats, cfg_pattern, cfg_seed, cfg_burst, cfg_flags, cfg_gap;
  reg [31:0] start_addr, total_words, repeats, pattern, seed, burst_words, flags, gap;
  reg [31:0] run_id, errors, first_addr, first_data;
  reg [63:0] cycles, bytes_done, operations;
  reg [31:0] cmd_ack, cmd_error;
  reg [31:0] stage_addr, stage_count;
  reg [17:0] stage_host_data, stage_engine_data;
  reg [7:0] staging_low[0:1023], staging_high[0:1023];
  reg [1:0] staging_mask[0:1023]; // bit 0 enables low lane
  reg [31:0] log_addr[0:7], log_data[0:7];
  reg [3:0] log_count;
  reg [31:0] snapshot[0:15], snap_log_addr[0:7], snap_log_data[0:7];
  reg [31:0] snapshot_id;
  // PREP sizes the next chunk; REQUEST holds valid until accepted; WRITE/READ
  // transfer all beats; COMPLETE retires the request. GAP and WSTALL deliberately
  // exercise retention and backpressure without taking over SDRAM refresh.
  localparam IDLE=0, PREP=1, REQUEST=2, WRITE=3, READ=4, COMPLETE=5, GAP=6, WSTALL=7;
  reg [3:0] state;
  reg [2:0] phase;
  reg [31:0] offset_words, iteration, gap_left;
  reg [10:0] chunk, beat;
  reg direct_mode, direct_write;
  // Only the low register page has scalar registers. Preserve full-address
  // rejection before narrowing the case selector; 0xff is an unmapped offset.
  // Snapshot/log/staging arrays still decode the full Avalon address below.
  wire [7:0] register_offset=av_address[31:8]==0 ? av_address[7:0] : 8'hff;
  wire [31:0] remaining_words=total_words-offset_words;
  wire phase_write = direct_mode ? direct_write : (pattern==6 ? (phase==0 || phase==1 || phase==3 || phase==5) : phase==0);
  wire [31:0] beat_addr = start_addr + ((offset_words + beat)<<1);
  wire [31:0] status_word={24'd0,stop_pending,failed,owner,initialized,stopped,done,busy,1'b0};
  wire config_ok=cfg_start[0]==0 && cfg_start<32'h4000000 && cfg_words>0 && cfg_words<=32'h2000000 &&
    ({1'b0,cfg_start}+({1'b0,cfg_words}<<1))<=33'h4000000 && cfg_repeats>0 &&
    cfg_pattern<=6 && cfg_burst>0 && cfg_burst<=1024 && cfg_flags<=3;
  wire stage_ok=stage_addr[0]==0 && stage_addr<32'h4000000 && stage_count>0 && stage_count<=1024 &&
    ({1'b0,stage_addr}+({1'b0,stage_count}<<1))<=33'h4000000;
  wire command_write=av_write && av_address==32'h14 && av_byteenable==4'hf;
  // Deduplicate only the identical most recently acknowledged command word.
  // A new nonce is a new command, even when the opcode is unchanged.
  wire command_new=command_write && av_writedata!=cmd_ack;
  wire host_start=command_new && av_writedata[7:0]==1 && owner && !busy && initialized && config_ok;
  wire board_start=local_start && !owner && !busy && initialized && config_ok;
  wire host_direct=command_new && (av_writedata[7:0]==4 || av_writedata[7:0]==5) && owner && !busy && initialized && stage_ok;
  assign av_waitrequest=0;
  assign failed=errors!=0;
  assign req_valid=state==REQUEST;
  assign req_write=phase_write;
  // The validated run fits 64 MiB. Explicit low bits implement the same
  // byte-address arithmetic without an implicit 32-to-26-bit truncation.
  assign req_addr=start_addr[25:0]+{offset_words[24:0],1'b0};
  assign req_words=chunk;
  assign w_valid=state==WRITE;
  assign w_be=direct_mode ? stage_engine_data[17:16] : pattern==6 ? (phase==1 ? 2'b01 : phase==3 ? 2'b10 : phase==5 ? 2'b00 : 2'b11) : 2'b11;
  assign r_ready=state==READ && (!flags[1] || cycles[2:0]==0);
  assign done_ready=state==COMPLETE;

  // Address/iteration-derived patterns need no mutable PRNG state. Pattern 6
  // is handled by the seven-phase byte-mask sequence around this function.
  function [15:0] pattern_word;
    input [31:0] addr, iter, p, s;
    reg [31:0] x;
    begin
      x=(addr>>1)^s^(iter*32'h9e3779b9);
      x=x^(x<<13); x=x^(x>>17); x=x^(x<<5);
      // Select only supported IDs; high bits must not alias a valid pattern.
      case(p<=32'd6 ? p[2:0] : 3'd7)
        0: pattern_word=s[15:0];
        // Incrementing data intentionally wraps modulo 2^16.
        1: pattern_word=s[15:0]+addr[16:1]+iter[15:0];
        2: pattern_word=addr[16:1]^addr[25:17]^s[15:0]^iter[15:0];
        3: pattern_word=16'h1<<((addr[4:1]+iter[3:0])&15);
        4: pattern_word=~(16'h1<<((addr[4:1]+iter[3:0])&15));
        5: pattern_word=x[15:0]^x[31:16];
        default: pattern_word=16'ha55a;
      endcase
    end
  endfunction
  wire [15:0] expected=pattern==6 ? (phase==2 ? 16'ha5a5 : 16'h5aa5) : pattern_word(beat_addr,iteration,pattern,seed);
  assign w_data=direct_mode ? stage_engine_data[15:0] : pattern==6 && phase!=0 && phase!=5 ? 16'h5aa5 : pattern_word(beat_addr,iteration,pattern,seed);
  function [31:0] merge_bytes;
    input [31:0] old_value, new_value; input [3:0] be;
    integer b;
    begin
      merge_bytes=old_value;
      for(b=0;b<4;b=b+1) if(be[b]) merge_bytes[b*8+:8]=new_value[b*8+:8];
    end
  endfunction
  function [31:0] edit_value;
    input [31:0] value; input [2:0] digit; input down;
    begin
      edit_value=value;
      edit_value[digit*4+:4]=down ? value[digit*4+:4]-4'd1 : value[digit*4+:4]+4'd1;
    end
  endfunction
  // Page RAM with a shared write port and synchronous host/engine read ports. Legacy 0x100..0x13c aliases its first sixteen words.
  // No reset/clear of RAM: software fills every requested write word first.
  wire stage_selected=av_address[1:0]==0 &&
    ((av_address>=32'h1000 && av_address<32'h2000) ||
     (av_address>=32'h100 && av_address<32'h140));
  wire [9:0] stage_host_index=av_address[12] ? av_address[11:2] : {6'd0,av_address[5:2]};
  wire [9:0] stage_engine_index=(state==WRITE && w_ready && beat!=chunk-1) ?
    beat[9:0]+10'd1 : beat[9:0];
  reg stage_read_response;
  // Register reads and synchronous RAM reads share the same one-cycle response.
  // Read staged results after completion; live RAM writes are not a snapshot.
  reg [31:0] register_read_data;
  assign av_readdata=stage_read_response ? {14'd0,stage_host_data} : register_read_data;
  wire stage_capture=state==READ && r_valid && r_ready && direct_mode && !reset;
  wire stage_host_write=av_write && stage_selected && owner && !busy && !reset;
  wire [9:0] stage_write_index=stage_capture ? beat[9:0] : stage_host_index;
  wire [17:0] stage_write_data=stage_capture ? {2'b11,r_data} : av_writedata[17:0];
  wire [2:0] stage_write_enable=stage_capture ? 3'b111 : stage_host_write ? av_byteenable[2:0] : 3'b000;
  always @(posedge clk) begin
    if(stage_write_enable[0]) staging_low[stage_write_index]<=stage_write_data[7:0];
    if(stage_write_enable[1]) staging_high[stage_write_index]<=stage_write_data[15:8];
    if(stage_write_enable[2]) staging_mask[stage_write_index]<=stage_write_data[17:16];
    if(av_read) stage_host_data<={staging_mask[stage_host_index],staging_high[stage_host_index],staging_low[stage_host_index]};
    stage_engine_data<={staging_mask[stage_engine_index],staging_high[stage_engine_index],staging_low[stage_engine_index]};
  end
  integer i;
  always @* begin
    // Five value digits; the board top supplies the sixth page/field digit.
    case(display_page)
      0: display_value=busy ? operations[19:0] : cfg_words[19:0];
      1: display_value=cfg_start[19:0];
      2: display_value={14'd0,cfg_start[25:20]};
      3: display_value={4'd0,cfg_seed[15:0]};
      4: display_value={cfg_pattern[3:0],cfg_burst[11:0],cfg_repeats[3:0]};
      5: display_value=operations[19:0];
      6: display_value={8'd0,operations[31:20]};
      7: display_value=errors[19:0];
      8: display_value=first_addr[19:0];
      9: display_value={8'd0,first_addr[31:20]};
      10: display_value={4'd0,first_data[31:16]};
      11: display_value={4'd0,first_data[15:0]};
      12: display_value=cycles[19:0];
      13: display_value=cycles[39:20];
      14: display_value=cycles[59:40];
      default: display_value={16'd0,cycles[63:60]};
    endcase
    if(local_edit_mode) begin
      case(edit_field)
        0: display_value={17'd0,edit_digit};
        1: display_value=cfg_burst[19:0];
        2: display_value=edit_digit>=5 ? {14'd0,cfg_start[25:20]} : cfg_start[19:0];
        3: display_value=edit_digit>=5 ? {8'd0,cfg_seed[31:20]} : cfg_seed[19:0];
        4: display_value=edit_digit>=5 ? {8'd0,cfg_words[31:20]} : cfg_words[19:0];
        5: display_value=cfg_pattern[19:0];
        6: display_value=edit_digit>=5 ? {8'd0,cfg_repeats[31:20]} : cfg_repeats[19:0];
        7: display_value=cfg_flags[19:0];
      endcase
    end
  end
  always @(posedge clk) begin
    if(reset) begin
      cfg_start<=0; cfg_words<=1024; cfg_repeats<=1; cfg_pattern<=2; cfg_seed<=32'h12345678;
      cfg_burst<=1024; cfg_flags<=0; cfg_gap<=0; owner<=0;
      start_addr<=0; total_words<=0; repeats<=0; pattern<=0; seed<=0; burst_words<=0; flags<=0; gap<=0;
      busy<=0; done<=0; stopped<=0; stop_pending<=0;
      run_id<=0; operations<=0; errors<=0; first_addr<=0; first_data<=0; cycles<=0; bytes_done<=0;
      cmd_ack<=0; cmd_error<=0; snapshot_id<=0; stage_addr<=0; stage_count<=1;
      stage_read_response<=0;
      state<=IDLE; phase<=0; offset_words<=0; iteration<=0; chunk<=0; beat<=0; gap_left<=0;
      direct_mode<=0; direct_write<=0; log_count<=0; register_read_data<=0; av_readdatavalid<=0;
      for(i=0;i<16;i=i+1) snapshot[i]<=0;
      for(i=0;i<8;i=i+1) begin log_addr[i]<=0; log_data[i]<=0; snap_log_addr[i]<=0; snap_log_data[i]<=0; end
    end else begin
      av_readdatavalid<=av_read;
      if(av_read) stage_read_response<=stage_selected;
      if(av_read) begin
        case(register_offset)
          'h00: register_read_data<=32'h5344524d;
          'h04: register_read_data<=32'h00010001;
          'h08: register_read_data<=BUILD_ID;
          'h0c: register_read_data<=32'h000000ff;
          'h10: register_read_data<=status_word;
          'h14: register_read_data<=cmd_ack;
          'h18: register_read_data<=cmd_error;
          'h1c: register_read_data<=CLOCK_HZ;
          'h20: register_read_data<=cfg_start;
          'h24: register_read_data<=cfg_words;
          'h28: register_read_data<=cfg_repeats;
          'h2c: register_read_data<=cfg_pattern;
          'h30: register_read_data<=cfg_seed;
          'h34: register_read_data<=cfg_burst;
          'h38: register_read_data<=cfg_flags;
          'h3c: register_read_data<=cfg_gap;
          'h40: register_read_data<=stage_addr;
          'h44: register_read_data<=stage_count;
          'h48: register_read_data<=refresh_count;
          'h4c: register_read_data<=snapshot_id;
          'h50: register_read_data<=run_id;
          'h54: register_read_data<={8'd0,display_page,display_value};
          'h58: register_read_data<=1024;
          'h5c: register_read_data<=32'h1000;
          default: begin
            if(av_address>='h80 && av_address<'hc0 && av_address[1:0]==0) register_read_data<=snapshot[av_address[5:2]];
            
            else if(av_address>='h180 && av_address<'h1c0 && av_address[1:0]==0)
              register_read_data<=av_address[2] ? snap_log_data[av_address[5:3]] : snap_log_addr[av_address[5:3]];
            else register_read_data<=32'hdeadbeef;
          end
        endcase
      end
      if(av_write && owner && !busy) begin
        case(register_offset)
          'h20: cfg_start<=merge_bytes(cfg_start,av_writedata,av_byteenable);
          'h24: cfg_words<=merge_bytes(cfg_words,av_writedata,av_byteenable);
          'h28: cfg_repeats<=merge_bytes(cfg_repeats,av_writedata,av_byteenable);
          'h2c: cfg_pattern<=merge_bytes(cfg_pattern,av_writedata,av_byteenable);
          'h30: cfg_seed<=merge_bytes(cfg_seed,av_writedata,av_byteenable);
          'h34: cfg_burst<=merge_bytes(cfg_burst,av_writedata,av_byteenable);
          'h38: cfg_flags<=merge_bytes(cfg_flags,av_writedata,av_byteenable);
          'h3c: cfg_gap<=merge_bytes(cfg_gap,av_writedata,av_byteenable);
          'h40: stage_addr<=merge_bytes(stage_addr,av_writedata,av_byteenable);
          'h44: stage_count<=merge_bytes(stage_count,av_writedata,av_byteenable);
          default: begin end // Staging RAM is written on its dedicated host port.
        endcase
      end
      if(local_release && !busy) owner<=0;
      if(local_edit && !owner && !busy) begin
        case(edit_field)
          0: begin // Presets: 1 Kiword smoke / 64 MiB full / boundary / retention
            cfg_start<=edit_digit==2 ? 32'h7f0 : 0;
            cfg_words<=edit_digit==1 ? 32'h2000000 : edit_digit==2 ? 32'd32 : 32'd1024;
            cfg_pattern<=2; cfg_burst<=1024; cfg_repeats<=1; cfg_flags<=0;
            cfg_gap<=edit_digit==3 ? CLOCK_HZ/10 : 0;
          end
          1: cfg_burst<=cfg_burst==1024 ? 1 : cfg_burst<<1;
          2: cfg_start<=edit_value(cfg_start,edit_digit,edit_down)&32'h03fffffe;
          3: cfg_seed<=edit_value(cfg_seed,edit_digit,edit_down);
          4: cfg_words<=edit_value(cfg_words,edit_digit,edit_down);
          5: cfg_pattern<=cfg_pattern==6 ? 0 : cfg_pattern+1'b1;
          6: cfg_repeats<=edit_value(cfg_repeats,edit_digit,edit_down);
          7: cfg_flags<=cfg_flags==3 ? 0 : cfg_flags+1'b1;
        endcase
      end
      // Acknowledgement records acceptance/rejection, not operation completion.
      if(command_new) begin
        cmd_ack<=av_writedata; cmd_error<=0;
        case(av_writedata[7:0])
          1: if(!host_start) cmd_error<=!owner ? 3 : busy ? 1 : 2;
          2: if(busy) stop_pending<=1;
          3: begin // Freeze counters, status and bounded log on one FPGA edge.
            snapshot_id<=snapshot_id+1'b1;
            snapshot[0]<=run_id; snapshot[1]<=status_word; snapshot[2]<=operations[31:0];
            snapshot[3]<=bytes_done[31:0]; snapshot[4]<=bytes_done[63:32];
            snapshot[5]<=cycles[31:0]; snapshot[6]<=cycles[63:32]; snapshot[7]<=errors;
            snapshot[8]<=first_addr; snapshot[9]<=first_data; snapshot[10]<={28'd0,log_count};
            snapshot[11]<=operations[63:32]; snapshot[12]<=refresh_count; snapshot[13]<=start_addr;
            snapshot[14]<=total_words; snapshot[15]<=pattern;
            for(i=0;i<8;i=i+1) begin snap_log_addr[i]<=log_addr[i]; snap_log_data[i]<=log_data[i]; end
          end
          4,5: if(!host_direct) cmd_error<=!owner ? 3 : busy ? 1 : 2;
          6: if(busy && !owner) cmd_error<=1; else owner<=1;
          7: if(busy) cmd_error<=1; else owner<=0;
          default: cmd_error<=4;
        endcase
      end
      if(local_stop && busy) stop_pending<=1;
      if(busy) cycles<=cycles+1'b1;
      // A direct page operation and a generator/checker run share this start path.
      // Neither path changes the controller's SDRAM mode configuration.
      if(host_start || board_start || host_direct) begin
        start_addr<=host_direct ? stage_addr : cfg_start;
        total_words<=host_direct ? stage_count : cfg_words;
        repeats<=host_direct ? 1 : cfg_repeats; pattern<=cfg_pattern; seed<=cfg_seed;
        burst_words<=host_direct ? stage_count : cfg_burst;
        flags<=host_direct ? 0 : cfg_flags; gap<=host_direct ? 0 : cfg_gap;
        direct_mode<=host_direct; direct_write<=av_writedata[7:0]==5;
        busy<=1; done<=0; stopped<=0; stop_pending<=0; run_id<=run_id+1'b1;
        operations<=0; bytes_done<=0; cycles<=0; errors<=0; first_addr<=0; first_data<=0; log_count<=0;
        phase<=0; offset_words<=0; iteration<=0; state<=PREP;
      end else case(state)
        PREP: begin
          if(stop_pending) begin busy<=0; stopped<=1; done<=1; state<=IDLE; end
          // Compare the full remaining count before selecting low bits. The
          // chosen count is bounded by the validated 1..1024-word burst size.
          else begin chunk<=remaining_words<burst_words ? remaining_words[10:0] : burst_words[10:0]; beat<=0; state<=REQUEST; end
        end
        REQUEST: if(req_ready) state<=phase_write ? (flags[0] ? WSTALL : WRITE) : READ;
        WSTALL: if(cycles[2:0]==0) state<=WRITE;
        WRITE: if(w_valid && w_ready) begin
          if(beat==chunk-1) state<=COMPLETE;
          else begin beat<=beat+1'b1; if(flags[0]) state<=WSTALL; end
        end
        READ: if(r_valid && r_ready) begin
          if(!direct_mode && (r_data!=expected || r_last!=(beat==chunk-1))) begin
            if(errors!=32'hffffffff) errors<=errors+1'b1;
            if(errors==0) begin first_addr<=beat_addr; first_data<={expected,r_data}; end
            if(log_count<8) begin log_addr[log_count]<=beat_addr; log_data[log_count]<={expected,r_data}; log_count<=log_count+1'b1; end
          end
          if(beat==chunk-1) state<=COMPLETE; else beat<=beat+1'b1;
        end
        // Count full words, including masked writes: bytes_done=2*operations.
        // Retire a stop only here (or before the next request/in a phase gap).
        COMPLETE: if(done_valid) begin
          operations<=operations+chunk; bytes_done<=bytes_done+({53'd0,chunk}<<1);
          if(done_error!=0) begin errors<=errors+1'b1; busy<=0; done<=1; state<=IDLE; end
          else if(stop_pending) begin busy<=0; done<=1; stopped<=1; state<=IDLE; end
          else if(offset_words+chunk<total_words) begin offset_words<=offset_words+chunk; state<=PREP; end
          else if(direct_mode) begin busy<=0; done<=1; state<=IDLE; end
          else if(phase==(pattern==6 ? 6 : 1)) begin
            if(iteration==repeats-1) begin busy<=0; done<=1; state<=IDLE; end
            else begin iteration<=iteration+1'b1; phase<=0; offset_words<=0; state<=PREP; end
          end else begin phase<=phase+1'b1; offset_words<=0; gap_left<=gap; state<=GAP; end
        end
        GAP: if(stop_pending) begin busy<=0; done<=1; stopped<=1; state<=IDLE; end
          else if(gap_left==0) state<=PREP; else gap_left<=gap_left-1'b1;
        default: state<=IDLE;
      endcase
    end
  end
endmodule
