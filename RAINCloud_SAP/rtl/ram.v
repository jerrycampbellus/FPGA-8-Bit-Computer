// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
module RAM #(parameter INIT_FILE="programs/ram_init.hex", parameter FPGA_MODE=0)(
    input wire CLK,Read_Enable,Write_Enable,
    input wire [3:0] Address, input wire [7:0] Data_In_DB,
    output wire [7:0] Data_Out_DB,Data_DISP
);
    reg [7:0] RAM [0:15];
    initial $readmemh(INIT_FILE,RAM,0,15);
    assign Data_Out_DB=Read_Enable ? RAM[Address] : (FPGA_MODE ? 8'b0 : 8'bz);
    assign Data_DISP=RAM[Address];
    always @(posedge CLK) if(Write_Enable) RAM[Address]<=Data_In_DB;
endmodule
