// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Capture OUT immediately. Formatting remains responsive after HALT.
module Output_Register(
    input wire CLK,OUTPUT_READ_EN,TWOS_COMPLIMENT_FLAG,HEXADECIMAL_FLAG,CLR,
    input wire [7:0] OUtPUT_DB_IN, output wire [16:0] OUTPUT_DISP
);
    reg [7:0] value;
    wire negative=TWOS_COMPLIMENT_FLAG && value[7];
    wire [7:0] magnitude=negative ? (~value+8'd1) : value;
    wire [11:0] digits=HEXADECIMAL_FLAG ? {4'b0,magnitude} : bcd(magnitude);
    assign OUTPUT_DISP={negative ? 5'h16 : 5'h15,digits};
    always @(posedge CLK or posedge CLR)
        if(CLR) value<=0;
        else if(OUTPUT_READ_EN) value<=OUtPUT_DB_IN;
    function [11:0] bcd;
        input [7:0] bin;
        integer i;
        reg [11:0] work;
        begin
            work=0;
            for(i=7;i>=0;i=i-1) begin
                if(work[3:0]>=5) work[3:0]=work[3:0]+4'd3;
                if(work[7:4]>=5) work[7:4]=work[7:4]+4'd3;
                if(work[11:8]>=5) work[11:8]=work[11:8]+4'd3;
                work={work[10:0],bin[i]};
            end
            bcd=work;
        end
    endfunction
endmodule
