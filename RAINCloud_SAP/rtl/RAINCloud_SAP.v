// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
module RAINCloud_SAP(
    input wire MAX10_CLK1_50, input wire [1:0] KEY, input wire [9:0] SW,
    output wire [7:0] HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,
    output wire [9:0] LEDR
);
    wire reset,step_key;
    wire [9:0] switches;
    input_conditioner inputs(.clk(MAX10_CLK1_50),.keys(KEY),.switches(SW),
        .reset(reset),.step_key(step_key),.switches_sync(switches));
    BE_8_BIT_Computer cpu(
        .FPGA_CLK_SOURCE(MAX10_CLK1_50),.CLK_SELECT(switches[0]),
        .CLK_STEP(step_key),.CLR(reset),.CLK_DIVIDER(switches[3:1]),
        .DISPLAY_SELECT(switches[7:4]),.TWOS_COMPLEMENT(switches[8]),
        .HEXADECIMAL_FLAG(switches[9]),.HLT_LED(LEDR[9]),
        .CLK_LED(LEDR[0]),.LED(LEDR[8:1]),
        .SEVEN_SEG_0(HEX0),.SEVEN_SEG_1(HEX1),.SEVEN_SEG_2(HEX2),
        .SEVEN_SEG_3(HEX3),.SEVEN_SEG_4(HEX4),.SEVEN_SEG_5(HEX5));
endmodule
