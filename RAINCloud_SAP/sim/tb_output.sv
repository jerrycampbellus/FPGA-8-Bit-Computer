// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
`timescale 1ns/1ps
module tb_output;
  reg clk=0,reset=0,enable=1,signed_mode=0,hex_mode=0;
  reg [7:0] bus=0;
  reg [3:0] display_select=4'h8;
  wire [16:0] display;
  wire [7:0] hex0,hex1,hex2,hex3,hex4,hex5,leds;
  // Independent active-low numeral patterns, indexed by numeric digit.
  localparam [7:0] NUMERAL [0:15] = '{
    8'hc0,8'hf9,8'ha4,8'hb0,8'h99,8'h92,8'h82,8'hf8,
    8'h80,8'h98,8'h88,8'h83,8'hc6,8'ha1,8'h86,8'h8e};
  integer x,s,h,magnitude,expected_digits,selector;
  reg negative;
  reg [55:0] other_display;
  Output_Register dut(.CLK(clk),.CLR(reset),.OUTPUT_READ_EN(enable),
    .TWOS_COMPLIMENT_FLAG(signed_mode),.HEXADECIMAL_FLAG(hex_mode),
    .OUtPUT_DB_IN(bus),.OUTPUT_DISP(display));
  JC_Display panel(.Display_CLK(1'b0),.CPU_Output_Hexadecimal(hex_mode),
    .A_Register(8'ha5),.B_Register(8'h3c),.ALU(8'h81),.CPU_Flags(8'h03),
    .Memory_Address_Register(4'hd),.RAM(8'h5a),.Program_Counter(4'h7),
    .CPU_Output(display),.Bus_Display_Sample(8'h96),.Control_Flags(16'h1234),
    .Instruction_Register(8'h2e),.JC_OUPUT_SELECT(display_select),
    .JC_LED_OUTPUT(leds),.JC_7SEG_OUPUT_0(hex0),.JC_7SEG_OUPUT_1(hex1),
    .JC_7SEG_OUPUT_2(hex2),.JC_7SEG_OUPUT_3(hex3),
    .JC_7SEG_OUPUT_4(hex4),.JC_7SEG_OUPUT_5(hex5));
  task check_output_segments(input integer number,input bit is_negative,input bit is_hex);
    integer radix;
    reg [7:0] expected_high;
    begin
      radix=is_hex ? 16 : 10;
      expected_high=is_hex ? 8'hff : NUMERAL[number/100];
      if({hex5,hex4,hex3,hex2,hex1,hex0} !==
         {8'hc6,8'hff,(is_negative ? 8'hbf : 8'hff),expected_high,
          NUMERAL[(number/radix)%radix],NUMERAL[number%radix]} || leds!==8'h00)
        $fatal(1,"C display number=%0d negative=%0b hex=%0b segments=%h %h %h %h %h %h",
          number,is_negative,is_hex,hex5,hex4,hex3,hex2,hex1,hex0);
    end
  endtask
  initial begin
    #1; reset=1; #1; reset=0;
    for(x=0;x<256;x=x+1) begin
      bus=x; #1; clk=1; #1; clk=0;
      for(s=0;s<2;s=s+1) for(h=0;h<2;h=h+1) begin
        signed_mode=s; hex_mode=h; #1;
        negative=s && (x>=128); magnitude=negative ? 256-x : x;
        expected_digits=h ? magnitude : ((magnitude/100)*256+((magnitude/10)%10)*16+magnitude%10);
        if(display[16:12] !== (negative ? 5'h16 : 5'h15) || display[11:0]!==expected_digits[11:0])
          $fatal(1,"Output formatting x=%d signed=%d hex=%d display=%h",x,s,h,display);
        check_output_segments(magnitude,negative,h!=0);
      end
    end
    reset=1; #1;
    if(display[11:0]!==0) $fatal(1,"Output reset failed without clock");
    check_output_segments(0,0,1);
    hex_mode=0; #1; check_output_segments(0,0,0);
    // OUT formatting must not affect any of the other diagnostic views.
    for(selector=0;selector<16;selector=selector+1) if(selector!=8) begin
      display_select=selector[3:0]; hex_mode=0; #1;
      other_display={leds,hex5,hex4,hex3,hex2,hex1,hex0};
      hex_mode=1; #1;
      if({leds,hex5,hex4,hex3,hex2,hex1,hex0}!==other_display)
        $fatal(1,"OUT hex mode changed diagnostic view %0h",selector);
    end
    $display("PASS tb_output: 1024 formats and segment outputs, two hex/three decimal digits, clock-stopped mode changes, reset, other views");
    $finish;
  end
endmodule
