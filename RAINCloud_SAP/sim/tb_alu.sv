// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
`timescale 1ns/1ps
module tb_alu;
  reg clk=0,reset=0,subtract=0,enable=1,bus_enable=1;
  reg [7:0] a=0,b=0;
  wire [7:0] result,bus,flags;
  integer x,y,s,expected;
  reg [7:0] saved;
  ALU dut(.CLK(clk),.CLR(reset),.SUBTRACT(subtract),.ALU_OUT(bus_enable),
    .ALU_FLAGS_OUT(enable),.A_REGISTER_IN(a),.B_REGISTER_IN(b),
    .ALU_DB(bus),.ALU_DISPLAY(result),.CPU_Flags(flags));
  initial begin
    #1; reset=1; #1; reset=0;
    for(s=0;s<2;s=s+1) for(x=0;x<256;x=x+1) for(y=0;y<256;y=y+1) begin
      a=x; b=y; subtract=s; expected=s ? x-y : x+y;
      #1; clk=1; #1;
      if(result!==expected[7:0] || bus!==expected[7:0])
        $fatal(1,"ALU arithmetic A=%d B=%d subtract=%d",x,y,s);
      if(flags[0] !== (expected[7:0]==0) || flags[1] !== (s ? (x<y) : (expected>255)))
        $fatal(1,"ALU flags A=%d B=%d subtract=%d flags=%h",x,y,s,flags);
      if(flags[7:2]!==0) $fatal(1,"Unexpected upper flag bits");
      bus_enable=0; #1;
      if(bus!==0 || result!==expected[7:0])
        $fatal(1,"Disabled ALU bus must be zero without changing displayed result");
      bus_enable=1; clk=0; #1;
    end
    saved=flags; enable=0; a=8'h17; b=8'h23; subtract=0;
    #1; clk=1; #1;
    if(flags!==saved) $fatal(1,"Flags changed without write enable");
    reset=1; #1;
    if(flags!==0) $fatal(1,"Flags did not reset asynchronously");
    $display("PASS tb_alu: 131072 arithmetic/flag combinations, bus gating, retention, reset");
    $finish;
  end
endmodule
