`timescale 1ns/1ps
// Compare generated and prepared adapter outputs. The test runner supplies raw
// copies renamed with _original; no model or license-dependent JTAG core needed.
module tb_jtag_adapters;
  reg clk=0,reset_n=0,in_valid=0,out_ready=1,in_startofpacket=0,in_endofpacket=0;
  reg [7:0] in_data=0,in_channel=0;
  wire a_ready,a_valid,a_sop,a_eop,b_ready,b_valid,b_sop,b_eop;
  wire [7:0] a_data,b_data,c_data,d_data;
  wire c_valid,d_valid;
  jtag_bridge_master_b2p_adapter a(.clk(clk),.reset_n(reset_n),.in_valid(in_valid),.out_ready(out_ready),
    .in_data(in_data),.in_channel(in_channel),.in_startofpacket(in_startofpacket),.in_endofpacket(in_endofpacket),
    .in_ready(a_ready),.out_valid(a_valid),.out_data(a_data),.out_startofpacket(a_sop),.out_endofpacket(a_eop));
  jtag_bridge_master_b2p_adapter_original b(.clk(clk),.reset_n(reset_n),.in_valid(in_valid),.out_ready(out_ready),
    .in_data(in_data),.in_channel(in_channel),.in_startofpacket(in_startofpacket),.in_endofpacket(in_endofpacket),
    .in_ready(b_ready),.out_valid(b_valid),.out_data(b_data),.out_startofpacket(b_sop),.out_endofpacket(b_eop));
  jtag_bridge_master_timing_adt c(.clk(clk),.reset_n(reset_n),.in_valid(in_valid),.out_ready(out_ready),
    .in_data(in_data),.out_valid(c_valid),.out_data(c_data));
  jtag_bridge_master_timing_adt_original d(.clk(clk),.reset_n(reset_n),.in_valid(in_valid),.out_ready(out_ready),
    .in_data(in_data),.out_valid(d_valid),.out_data(d_data));
  integer control,channel,data,checks=0;
  initial begin
    // All channel/data values and valid/ready/packet-flag combinations. Clock
    // and reset also vary; these adapters are purely combinational at the ports.
    for(control=0;control<16;control=control+1) begin
      {in_valid,out_ready,in_startofpacket,in_endofpacket}=control[3:0];
      reset_n=control[0]; clk=control[1];
      for(channel=0;channel<256;channel=channel+1) begin
        in_channel=channel[7:0];
        for(data=0;data<256;data=data+1) begin
          in_data=data[7:0]; #1;
          if({a_ready,a_valid,a_data,a_sop,a_eop,c_valid,c_data} !==
             {b_ready,b_valid,b_data,b_sop,b_eop,d_valid,d_data}) $fatal(1,"Adapter port mismatch");
          checks=checks+1;
        end
      end
    end
    $display("PASS jtag_adapters: %0d generated/prepared port comparisons",checks);
    $finish;
  end
  initial begin #2000000; $fatal(1,"Adapter timeout"); end
endmodule
