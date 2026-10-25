// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
// Five microsteps. Flags [0]=zero, [1]=ADD carry / SUB borrow.
// Conditional branches test SET, preserving the original opcode behavior.
module MicroCode_StateMachine(
    input wire [2:0] Micro_Count,
    input wire [3:0] Instruction_OpCode,
    input wire [7:0] ALU_Flags,
    output reg Halt_Signal,Jump_Signal,Program_Count_Enable,Program_Count_Out,
    output reg A_Reg_Out,A_Reg_In,ALU_Out,Subtract,ALU_Flags_Out,
    output reg B_Reg_Out,B_Reg_In,RAM_Read_Enable,RAM_Write_Enable,
    output reg Instruction_Reg_Out,Instruction_Reg_In,
    output reg Memory_Address_In,Memory_Address_Enable,DB_Enable,Output_Enable
);
    always @* begin
        Halt_Signal=0; Jump_Signal=0; Program_Count_Enable=0; Program_Count_Out=0;
        A_Reg_Out=0; A_Reg_In=0; ALU_Out=0; Subtract=0; ALU_Flags_Out=0;
        B_Reg_Out=0; B_Reg_In=0; RAM_Read_Enable=0; RAM_Write_Enable=0;
        Instruction_Reg_Out=0; Instruction_Reg_In=0;
        Memory_Address_In=0; Memory_Address_Enable=0; DB_Enable=1; Output_Enable=0;
        case(Micro_Count)
            0: begin
                Program_Count_Out=1; Memory_Address_Enable=1;
                Memory_Address_In=1; Program_Count_Enable=1;
            end
            1: begin
                Memory_Address_Enable=1; RAM_Read_Enable=1; Instruction_Reg_In=1;
            end
            2: case(Instruction_OpCode)
                4'h0: begin end
                4'h1,4'h2,4'h3,4'h6: begin
                    Instruction_Reg_Out=1; Memory_Address_Enable=1; Memory_Address_In=1;
                end
                4'h4: begin A_Reg_Out=1; Output_Enable=1; end
                4'h5: begin Instruction_Reg_Out=1; Jump_Signal=1; end
                4'h7: if(ALU_Flags[0]) begin Instruction_Reg_Out=1; Jump_Signal=1; end
                4'h8: if(ALU_Flags[1]) begin Instruction_Reg_Out=1; Jump_Signal=1; end
                default: Halt_Signal=1;
            endcase
            3: case(Instruction_OpCode)
                4'h1: begin Memory_Address_Enable=1; RAM_Read_Enable=1; A_Reg_In=1; end
                4'h2,4'h3: begin Memory_Address_Enable=1; RAM_Read_Enable=1; B_Reg_In=1; end
                4'h6: begin Memory_Address_Enable=1; A_Reg_Out=1; RAM_Write_Enable=1; end
                default: begin end
            endcase
            4: if(Instruction_OpCode==4'h2 || Instruction_OpCode==4'h3) begin
                Subtract=(Instruction_OpCode==4'h3);
                ALU_Out=1; A_Reg_In=1; ALU_Flags_Out=1;
            end
            default: Halt_Signal=1;
        endcase
    end
endmodule
