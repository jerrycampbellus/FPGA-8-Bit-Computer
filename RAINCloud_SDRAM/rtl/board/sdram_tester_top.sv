/**************************************************************************
* RAINCloud / SDRAM_Tester / sdram_tester_top.sv
* Release: 26101404, controller 1.2.1 (October 14, 2026)
* Maintainer: J.CAMPBELL
*
* DE10-Lite integration boundary: PLL/reset, asynchronous switch/key inputs,
* debounce, generated JTAG bridge, shared tester engine, portable memory
* controller and active-low seven-segment displays. Pin assignments and I/O
* timing live in the Quartus project/SDC, not in the portable memory library.
*
* KEY is active low at the pins and active high after synchronization. SW0
* selects browse/run or edit. Hold both debounced keys for three seconds to
* reset. See docs/BOARD.md for the complete control/display mapping.
* tests/tb_board.sv replaces PLL/JTAG IP for local-control simulation only;
* see docs/TESTBENCH.md for what that model can and cannot establish.
**************************************************************************/
module sdram_tester_top #(
  parameter integer DEBOUNCE_BITS=19
)(
  input wire MAX10_CLK1_50,
  input wire [9:0] SW, input wire [1:0] KEY,
  output wire [9:0] LEDR,
  output wire [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
  output wire [12:0] DRAM_ADDR, output wire [1:0] DRAM_BA,
  output wire DRAM_CLK, DRAM_CKE, DRAM_CS_N, DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N,
  output wire DRAM_LDQM, DRAM_UDQM, inout wire [15:0] DRAM_DQ
);
  wire clk,locked;
  de10_clock clocks(.ref_clk(MAX10_CLK1_50),.core_clk(clk),.sdram_clk(DRAM_CLK),.locked(locked));
  // Wait for PLL lock and 255 core edges before releasing power-on reset.
  reg [7:0] power_count=0;
  always @(posedge clk) if(!locked) power_count<=0; else if(!(&power_count)) power_count<=power_count+1'b1;
  wire power_reset=!locked || !(&power_count);
  // First-stage synchronizers isolate asynchronous pins. Keys then need a
  // stable level through the debounce counter before generating a press pulse.
  (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *) reg [9:0] sw_meta, sw_sync;
  (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED" *) reg [1:0] key_meta, key_sync;
  reg [1:0] key_db, key_prev;
  reg [DEBOUNCE_BITS-1:0] debounce0, debounce1;
  reg [27:0] hold_count;
  wire reset=power_reset || hold_count==150000000;
  wire [1:0] press=key_db & ~key_prev;
  always @(posedge clk) begin
    if(power_reset) begin
      sw_meta<=0; sw_sync<=0; key_meta<=0; key_sync<=0;
      key_db<=0; key_prev<=0; debounce0<=0; debounce1<=0; hold_count<=0;
    end else begin
      sw_meta<=SW; sw_sync<=sw_meta; key_meta<=~KEY; key_sync<=key_meta; key_prev<=key_db;
      if(key_sync[0]==key_db[0]) debounce0<=0;
      else if(&debounce0) begin key_db[0]<=key_sync[0]; debounce0<=0; end
      else debounce0<=debounce0+1'b1;
      if(key_sync[1]==key_db[1]) debounce1<=0;
      else if(&debounce1) begin key_db[1]<=key_sync[1]; debounce1<=0; end
      else debounce1<=debounce1+1'b1;
      if(&key_db) begin if(hold_count<150000000) hold_count<=hold_count+1'b1; end
      else hold_count<=0;
    end
  end
  reg [3:0] page;
  wire busy,done,stopped,owner,failed,stop_pending,initialized;
  always @(posedge clk) begin
    if(reset) page<=0;
    else if(press[0] && !sw_sync[0]) page<=page+1'b1;
  end
  wire [19:0] value;
  wire [3:0] display_tag=sw_sync[0] ? {1'b0,sw_sync[3:1]} : page;
  // Intel-generated JTAG-to-Avalon bridge is confined to this board wrapper.
  wire [31:0] av_address,av_writedata,av_readdata;
  wire av_read,av_write,av_readdatavalid,av_waitrequest;
  wire [3:0] av_byteenable;
  jtag_bridge bridge(
    .clk_clk(clk),.reset_reset(reset),.master_reset_reset(),
    .avalon_address(av_address),.avalon_writedata(av_writedata),
    .avalon_read(av_read),.avalon_write(av_write),.avalon_byteenable(av_byteenable),
    .avalon_readdata(av_readdata),.avalon_readdatavalid(av_readdatavalid),.avalon_waitrequest(av_waitrequest)
  );
  wire req_valid,req_ready,req_write,w_valid,w_ready,r_valid,r_ready,r_last,done_valid,done_ready;
  wire [25:0] req_addr;
  wire [10:0] req_words;
  wire [15:0] w_data,r_data;
  wire [1:0] w_be,done_error,dqm;
  wire [31:0] refresh_count;
  tester_regs regs(
    .clk(clk),.reset(reset),.initialized(initialized),
    .av_address(av_address),.av_writedata(av_writedata),.av_read(av_read),.av_write(av_write),
    .av_byteenable(av_byteenable),.av_readdata(av_readdata),.av_readdatavalid(av_readdatavalid),.av_waitrequest(av_waitrequest),
    .local_start(press[1] && !sw_sync[0] && !busy && !key_db[0]),
    .local_stop(press[1] && busy),.local_release(press[0] && sw_sync[9] && !sw_sync[0]),
    .local_edit(sw_sync[0] && (|press) && !(&key_db)),
    .local_edit_mode(sw_sync[0]),
    .edit_field(sw_sync[3:1]),.edit_digit(sw_sync[6:4]),.edit_down(press[1]),
    .display_page(display_tag),.display_value(value),.busy(busy),.done(done),.stopped(stopped),.owner(owner),.failed(failed),.stop_pending(stop_pending),
    .req_valid(req_valid),.req_ready(req_ready),.req_write(req_write),.req_addr(req_addr),.req_words(req_words),
    .w_valid(w_valid),.w_ready(w_ready),.w_data(w_data),.w_be(w_be),
    .r_valid(r_valid),.r_ready(r_ready),.r_data(r_data),.r_last(r_last),
    .done_valid(done_valid),.done_ready(done_ready),.done_error(done_error),.refresh_count(refresh_count)
  );
  sdram_controller memory(
    .clk(clk),.reset(reset),.req_valid(req_valid),.req_ready(req_ready),.req_write(req_write),.req_addr(req_addr),.req_words(req_words),
    .w_valid(w_valid),.w_ready(w_ready),.w_data(w_data),.w_be(w_be),
    .r_valid(r_valid),.r_ready(r_ready),.r_data(r_data),.r_last(r_last),
    .done_valid(done_valid),.done_ready(done_ready),.done_error(done_error),.initialized(initialized),.refresh_count(refresh_count),
    .sdram_cke(DRAM_CKE),.sdram_cs_n(DRAM_CS_N),.sdram_ras_n(DRAM_RAS_N),.sdram_cas_n(DRAM_CAS_N),.sdram_we_n(DRAM_WE_N),
    .sdram_addr(DRAM_ADDR),.sdram_ba(DRAM_BA),.sdram_dqm(dqm),.sdram_dq(DRAM_DQ)
  );
  assign {DRAM_UDQM,DRAM_LDQM}=dqm;
  // Status order matches docs/BOARD.md; LED7/8 are reserved, LED9 is edit mode.
  assign LEDR={sw_sync[0],2'b00,stop_pending,initialized,owner,stopped,failed,done,busy};
  function [7:0] hex;
    // Active-low segment encoding; bit 7 controls the decimal point.
    input [3:0] n;
    begin
      case(n)
        0:hex=8'hc0; 1:hex=8'hf9; 2:hex=8'ha4; 3:hex=8'hb0;
        4:hex=8'h99; 5:hex=8'h92; 6:hex=8'h82; 7:hex=8'hf8;
        8:hex=8'h80; 9:hex=8'h90; 10:hex=8'h88; 11:hex=8'h83;
        12:hex=8'hc6; 13:hex=8'ha1; 14:hex=8'h86; 15:hex=8'h8e;
      endcase
    end
  endfunction
  assign HEX0=hex(value[3:0]); assign HEX1=hex(value[7:4]); assign HEX2=hex(value[11:8]);
  assign HEX3=hex(value[15:12]); assign HEX4=hex(value[19:16]); assign HEX5=hex(display_tag)&(sw_sync[0] ? 8'hff : 8'h7f);
endmodule
