/**************************************************************************
*
*    File Name:  IS42S16320F.v
*      Version:  2.24
*         Date:  May  7, 2025
*       Author:  J.CAMPBELL
*        Company: RAINCloud
*    Simulator:  QuestaIntel
*
*       Ports:
*         Clk      : System clock input
*         Cke      : Clock enable input
*         Cs_n     : Chip select (active low)
*         Ras_n    : Row address strobe (active low)
*         Cas_n    : Column address strobe (active low)
*         We_n     : Write enable (active low)
*         Addr     : Address bus [addr_bits-1:0]
*         Ba       : Bank address [1:0]
*         Dq       : Bidirectional data bus [data_bits-1:0]
*         Dqm      : Data mask inputs [1:0]
*
*  Description:
*    Behavioral SDRAM model of the IS42S16320F device. Implements bank
*    activation, precharge, auto-refresh, read/write operations, burst
*    transfers, mode register programming, and timing checks to emulate
*    real SDRAM behavior.
*
*  Dependencies:
*    None
*
*  Copyright (c) 2025 RAINCloud
*  Released under the MIT License.
*
**************************************************************************/


`timescale 1ns/1ps

module IS42S16320F
    #(
        parameter addr_bits = 13,
        parameter data_bits = 16,
        parameter col_bits  = 10,
        parameter mem_sizes = 8388607
    )
    (
        // SDRAM Interface (ordered):
        input  wire                 Clk,
        input  wire                 Cke,
        input  wire                 Cs_n,
        input  wire                 Ras_n,
        input  wire                 Cas_n,
        input  wire                 We_n,
        input  wire [addr_bits-1:0] Addr,
        input  wire [1:0]           Ba,
        inout  wire [data_bits-1:0] Dq,
        input  wire [1:0]           Dqm
);
    // Memory storage for each bank.
    reg [data_bits - 1 : 0] Bank0 [0 : mem_sizes];
    reg [data_bits - 1 : 0] Bank1 [0 : mem_sizes];
    reg [data_bits - 1 : 0] Bank2 [0 : mem_sizes];
    reg [data_bits - 1 : 0] Bank3 [0 : mem_sizes];

    // Pipeline arrays for addressing and command processing.
    reg [1 : 0] Bank_addr [0 : 3];                
    reg [col_bits - 1 : 0] Col_addr [0 : 3];       
    reg [3 : 0] Command [0 : 3];                  
    reg [1 : 0] Dqm_reg0, Dqm_reg1;               
    reg [addr_bits - 1 : 0] B0_row_addr, B1_row_addr, B2_row_addr, B3_row_addr;

    reg [addr_bits - 1 : 0] Mode_reg;
    reg [data_bits - 1 : 0] Dq_reg, Dq_dqm;
    reg [col_bits - 1 : 0]  Col_temp, Burst_counter;

    // Bank activation and precharge flags.
    reg Act_b0, Act_b1, Act_b2, Act_b3;   
    reg Pc_b0, Pc_b1, Pc_b2, Pc_b3;       

    // Precharge, auto-precharge, and interrupt logic.
    reg [1 : 0] Bank_precharge [0 : 3];
    reg A10_precharge [0 : 3];
    reg Auto_precharge [0 : 3];
    reg Read_precharge [0 : 3];
    reg Write_precharge [0 : 3];
    reg RW_interrupt_read [0 : 3];
    reg RW_interrupt_write [0 : 3];
    reg [1 : 0] RW_interrupt_bank;
    integer RW_interrupt_counter [0 : 3];
    integer Count_precharge [0 : 3];

    // Data bus control signals.
    reg Data_in_enable;
    reg Data_out_enable;

    reg [1 : 0] Bank, Prev_bank;
    reg [addr_bits - 1 : 0] Row;
    reg [col_bits - 1 : 0] Col, Col_brst;

    // Internal clock generation.
    reg CkeZ, Sys_clk;

    // SDRAM command decodes.
    wire Active_enable    = ~Cs_n & ~Ras_n &  Cas_n &  We_n;
    wire Aref_enable      = ~Cs_n & ~Ras_n & ~Cas_n &  We_n;
    wire Burst_term       = ~Cs_n &  Ras_n &  Cas_n & ~We_n;
    wire Mode_reg_enable  = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n;
    wire Prech_enable     = ~Cs_n & ~Ras_n &  Cas_n & ~We_n;
    wire Read_enable      = ~Cs_n &  Ras_n & ~Cas_n &  We_n;
    wire Write_enable     = ~Cs_n &  Ras_n & ~Cas_n & ~We_n;

    // Mode Register bits for burst length, CAS latency, and write burst mode.
    wire Burst_length_1   = ~Mode_reg[2] & ~Mode_reg[1] & ~Mode_reg[0];
    wire Burst_length_2   = ~Mode_reg[2] & ~Mode_reg[1] &  Mode_reg[0];
    wire Burst_length_4   = ~Mode_reg[2] &  Mode_reg[1] & ~Mode_reg[0];
    wire Burst_length_8   = ~Mode_reg[2] &  Mode_reg[1] &  Mode_reg[0];
    wire Burst_length_f   =  Mode_reg[2] &  Mode_reg[1] &  Mode_reg[0];

    wire Cas_latency_2    = ~Mode_reg[6] &  Mode_reg[5] & ~Mode_reg[4];
    wire Cas_latency_3    = ~Mode_reg[6] &  Mode_reg[5] &  Mode_reg[4];

    wire Write_burst_mode = Mode_reg[9];

    // Debug and data-check signals.
    wire Debug            = 1'b1;                          
    wire Dq_chk           = Sys_clk & Data_in_enable;      

    // Drive the DQ bus.
    assign Dq = Dq_reg;

    // Command symbolic definitions.
    `define ACT       0
    `define NOP       1
    `define READ      2
    `define WRITE     3
    `define PRECH     4
    `define A_REF     5
    `define BST       6
    `define LMR       7

    // Timing parameters.
    parameter tAC  =   5.4;
    parameter tHZ  =   5.4;
    parameter tOH  =   2.5;
    parameter tMRD =   2.0;     
    parameter tRAS =  37.0;
    parameter tRC  =  60.0;
    parameter tRCD =  15.0;
    parameter tRFC =  54.0;
    parameter tRP  =  15.0;
    parameter tRRD =  14.0;
    parameter tWRa =   7.0;     
    parameter tWRm =  14.0;     

    // Time check variables.
    time  MRD_chk;
    time  WR_chkm [0 : 3];
    time  RFC_chk, RRD_chk;
    time  RC_chk0, RC_chk1, RC_chk2, RC_chk3;
    time  RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3;
    time  RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3;
    time  RP_chk0, RP_chk1, RP_chk2, RP_chk3;

    // Initialization block.
    initial begin
        Dq_reg = {data_bits{1'bz}};
        Data_in_enable = 0; 
        Data_out_enable = 0;
        Act_b0 = 1; Act_b1 = 1; Act_b2 = 1; Act_b3 = 1;
        Pc_b0 = 0; Pc_b1 = 0; Pc_b2 = 0; Pc_b3 = 0;
        WR_chkm[0] = 0; WR_chkm[1] = 0; WR_chkm[2] = 0; WR_chkm[3] = 0;
        RW_interrupt_read[0] = 0; RW_interrupt_read[1] = 0; RW_interrupt_read[2] = 0; RW_interrupt_read[3] = 0;
        RW_interrupt_write[0] = 0; RW_interrupt_write[1] = 0; RW_interrupt_write[2] = 0; RW_interrupt_write[3] = 0;
        MRD_chk = 0; RFC_chk = 0; RRD_chk = 0;
        RAS_chk0 = 0; RAS_chk1 = 0; RAS_chk2 = 0; RAS_chk3 = 0;
        RCD_chk0 = 0; RCD_chk1 = 0; RCD_chk2 = 0; RCD_chk3 = 0;
        RC_chk0 = 0; RC_chk1 = 0; RC_chk2 = 0; RC_chk3 = 0;
        RP_chk0 = 0; RP_chk1 = 0; RP_chk2 = 0; RP_chk3 = 0;
        $timeformat (-9, 1, " ns", 12);
    end

    // Internal clock generation.
    always begin
        @ (posedge Clk) begin
            Sys_clk = CkeZ;
            CkeZ = Cke;
        end
        @ (negedge Clk) begin
            Sys_clk = 1'b0;
        end
    end

    // Pipeline updates.
    always @ (posedge Sys_clk) begin
        Command[0] = Command[1];
        Command[1] = Command[2];
        Command[2] = Command[3];
        Command[3] = `NOP;

        Col_addr[0] = Col_addr[1];
        Col_addr[1] = Col_addr[2];
        Col_addr[2] = Col_addr[3];
        Col_addr[3] = {col_bits{1'b0}};

        Bank_addr[0] = Bank_addr[1];
        Bank_addr[1] = Bank_addr[2];
        Bank_addr[2] = Bank_addr[3];
        Bank_addr[3] = 2'b0;

        Bank_precharge[0] = Bank_precharge[1];
        Bank_precharge[1] = Bank_precharge[2];
        Bank_precharge[2] = Bank_precharge[3];
        Bank_precharge[3] = 2'b0;

        A10_precharge[0] = A10_precharge[1];
        A10_precharge[1] = A10_precharge[2];
        A10_precharge[2] = A10_precharge[3];
        A10_precharge[3] = 1'b0;

        Dqm_reg0 = Dqm_reg1;
        Dqm_reg1 = Dqm;

        if (Auto_precharge[0] === 1'b1) begin
            Count_precharge[0] = Count_precharge[0] + 1;
        end
        if (Auto_precharge[1] === 1'b1) begin
            Count_precharge[1] = Count_precharge[1] + 1;
        end
        if (Auto_precharge[2] === 1'b1) begin
            Count_precharge[2] = Count_precharge[2] + 1;
        end
        if (Auto_precharge[3] === 1'b1) begin
            Count_precharge[3] = Count_precharge[3] + 1;
        end

        if (RW_interrupt_write[0] === 1'b1) begin
            RW_interrupt_counter[0] = RW_interrupt_counter[0] + 1;
        end
        if (RW_interrupt_write[1] === 1'b1) begin
            RW_interrupt_counter[1] = RW_interrupt_counter[1] + 1;
        end
        if (RW_interrupt_write[2] === 1'b1) begin
            RW_interrupt_counter[2] = RW_interrupt_counter[2] + 1;
        end
        if (RW_interrupt_write[3] === 1'b1) begin
            RW_interrupt_counter[3] = RW_interrupt_counter[3] + 1;
        end

        MRD_chk = MRD_chk + 1;

        if (Aref_enable === 1'b1) begin
            if (Debug) begin
                $display ("%t AREF : Auto Refresh", $time);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%t ERROR: tRFC violation during Auto Refresh", $time);
            end
            if (($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) ||
                ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP)) begin
                $display ("%t ERROR: tRP violation during Auto Refresh", $time);
            end
            if (Pc_b0 === 1'b0 || Pc_b1 === 1'b0 || Pc_b2 === 1'b0 || Pc_b3 === 1'b0) begin
                $display ("%t ERROR: All banks must be Precharge before Auto Refresh", $time);
            end
            if (MRD_chk < tMRD) begin
                $display ("%t ERROR: tMRD violation during Auto Refresh", $time);
            end
            RFC_chk = $time;
        end
        
        if (Mode_reg_enable === 1'b1) begin
            Mode_reg = Addr;
            if (Debug) begin
                $display ("%t LMR  : Load Mode Register", $time);
                case (Addr[6 : 4])
                    3'b010  : $display ("%m :                             CAS Latency      = 2");
                    3'b011  : $display ("%m :                             CAS Latency      = 3");
                    default : $display ("%m :                             CAS Latency      = Reserved");
                endcase
                case (Addr[2 : 0])
                    3'b000  : $display ("%m :                             Burst Length     = 1");
                    3'b001  : $display ("%m :                             Burst Length     = 2");
                    3'b010  : $display ("%m :                             Burst Length     = 4");
                    3'b011  : $display ("%m :                             Burst Length     = 8");
                    3'b111  : $display ("%m :                             Burst Length     = Full");
                    default : $display ("%m :                             Burst Length     = Reserved");
                endcase
                if (Addr[3] === 1'b0) begin
                    $display ("%m :                             Burst Type       = Sequential");
                end else if (Addr[3] === 1'b1) begin
                    $display ("%m :                             Burst Type       = Interleaved");
                end else begin
                    $display ("%m :                             Burst Type       = Reserved");
                end
                if (Addr[9] === 1'b0) begin
                    $display ("%m :                             Write Burst Mode = Programmed Burst Length");
                end else if (Addr[9] === 1'b1) begin
                    $display ("%m :                             Write Burst Mode = Single Location Access");
                end else begin
                    $display ("%m :                             Write Burst Mode = Reserved");
                end
            end
            if (Pc_b0 === 1'b0 && Pc_b1 === 1'b0 && Pc_b2 === 1'b0 && Pc_b3 === 1'b0) begin
                $display ("%t ERROR: all banks must be Precharge before Load Mode Register", $time);
            end
            if (($time - RP_chk0 < tRP) || ($time - RP_chk1 < tRP) ||
                ($time - RP_chk2 < tRP) || ($time - RP_chk3 < tRP)) begin
                $display ("%t ERROR: tRP violation during Load Mode Register", $time);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%t ERROR: tRFC violation during Load Mode Register", $time);
            end
            if (MRD_chk < tMRD) begin
                $display ("%t ERROR: tMRD violation during Load Mode Register", $time);
            end
            MRD_chk = 0;
        end
        
        if (Active_enable === 1'b1) begin
            if ((Ba === 2'b00 && Act_b0 === 1'b1) || (Ba === 2'b01 && Act_b1 === 1'b1) ||
                (Ba === 2'b10 && Act_b2 === 1'b1) || (Ba === 2'b11 && Act_b3 === 1'b1)) begin
                $display ("%t ERROR: Bank already activated -- data can be corrupted", $time);
            end
            if (Ba === 2'b00 && Pc_b0 === 1'b1) begin
                if (Debug) begin
                    $display ("%t ACT  : Bank = 0 Row = %d", $time, Addr);
                end
                if ($time - RC_chk0 < tRC) begin
                    $display ("%t ERROR: tRC violation during Activate bank 0", $time);
                end
                if ($time - RP_chk0 < tRP) begin
                    $display ("%t ERROR: tRP violation during Activate bank 0", $time);
                end
                Act_b0 = 1'b1;
                Pc_b0 = 1'b0;
                B0_row_addr = Addr [addr_bits - 1 : 0];
                RAS_chk0 = $time;
                RC_chk0  = $time;
                RCD_chk0 = $time;
            end
            if (Ba == 2'b01 && Pc_b1 == 1'b1) begin
                if (Debug) begin
                    $display ("%t ACT  : Bank = 1 Row = %d", $time, Addr);
                end
                if ($time - RC_chk1 < tRC) begin
                    $display ("%t ERROR: tRC violation during Activate bank 1", $time);
                end
                if ($time - RP_chk1 < tRP) begin
                    $display ("%t ERROR: tRP violation during Activate bank 1", $time);
                end
                Act_b1 = 1'b1;
                Pc_b1 = 1'b0;
                B1_row_addr = Addr [addr_bits - 1 : 0];
                RAS_chk1 = $time;
                RC_chk1  = $time;
                RCD_chk1 = $time;
            end
            if (Ba == 2'b10 && Pc_b2 == 1'b1) begin
                if (Debug) begin
                    $display ("%t ACT  : Bank = 2 Row = %d", $time, Addr);
                end
                if ($time - RC_chk2 < tRC) begin
                    $display ("%t ERROR: tRC violation during Activate bank 2", $time);
                end
                if ($time - RP_chk2 < tRP) begin
                    $display ("%t ERROR: tRP violation during Activate bank 2", $time);
                end
                Act_b2 = 1'b1;
                Pc_b2 = 1'b0;
                B2_row_addr = Addr [addr_bits - 1 : 0];
                RAS_chk2 = $time;
                RC_chk2  = $time;
                RCD_chk2 = $time;
            end
            if (Ba == 2'b11 && Pc_b3 == 1'b1) begin
                if (Debug) begin
                    $display ("%t ACT  : Bank = 3 Row = %d", $time, Addr);
                end
                if ($time - RC_chk3 < tRC) begin
                    $display ("%t ERROR: tRC violation during Activate bank 3", $time);
                end
                if ($time - RP_chk3 < tRP) begin
                    $display ("%t ERROR: tRP violation during Activate bank 3", $time);
                end
                Act_b3 = 1'b1;
                Pc_b3 = 1'b0;
                B3_row_addr = Addr [addr_bits - 1 : 0];
                RAS_chk3 = $time;
                RC_chk3  = $time;
                RCD_chk3 = $time;
            end
            if ((Prev_bank != Ba) && ($time - RRD_chk < tRRD)) begin
                $display ("%t ERROR: tRRD violation during Activate bank = %d", $time, Ba);
            end
            if ($time - RFC_chk < tRFC) begin
                $display ("%t ERROR: tRFC violation during Activate bank = %d", $time, Ba);
            end
            if (MRD_chk < tMRD ) begin
                $display ("%t ERROR: tMRD violation during Activate bank = %d", $time, Ba);
            end
            RRD_chk = $time;
            Prev_bank = Ba;
        end
        
        if (Prech_enable == 1'b1) begin
            if ($time - MRD_chk < tMRD) begin
                $display ("%t ERROR: tMRD violaiton during Precharge", $time);
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b00)) && Act_b0 === 1'b1) begin
                Act_b0 = 1'b0;
                Pc_b0 = 1'b1;
                RP_chk0 = $time;
                if ($time - RAS_chk0 < tRAS) begin
                    $display ("%t ERROR: tRAS violation during Precharge", $time);
                end
                if ($time - WR_chkm[0] < tWRm) begin
                    $display ("%t ERROR: tWR violation during Precharge", $time);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b01)) && Act_b1 === 1'b1) begin
                Act_b1 = 1'b0;
                Pc_b1 = 1'b1;
                RP_chk1 = $time;
                if ($time - RAS_chk1 < tRAS) begin
                    $display ("%t ERROR: tRAS violation during Precharge", $time);
                end
                if ($time - WR_chkm[1] < tWRm) begin
                    $display ("%t ERROR: tWR violation during Precharge", $time);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b10)) && Act_b2 === 1'b1) begin
                Act_b2 = 1'b0;
                Pc_b2 = 1'b1;
                RP_chk2 = $time;
                if ($time - RAS_chk2 < tRAS) begin
                    $display ("%t ERROR: tRAS violation during Precharge", $time);
                end
                if ($time - WR_chkm[2] < tWRm) begin
                    $display ("%t ERROR: tWR violation during Precharge", $time);
                end
            end
            if ((Addr[10] === 1'b1 || (Addr[10] === 1'b0 && Ba === 2'b11)) && Act_b3 === 1'b1) begin
                Act_b3 = 1'b0;
                Pc_b3 = 1'b1;
                RP_chk3 = $time;
                if ($time - RAS_chk3 < tRAS) begin
                    $display ("%t ERROR: tRAS violation during Precharge", $time);
                end
                if ($time - WR_chkm[3] < tWRm) begin
                    $display ("%t ERROR: tWR violation during Precharge", $time);
                end
            end
            if (Data_in_enable === 1'b1 && (Bank === Ba || Addr[10] === 1'b1)) begin
                Data_in_enable = 1'b0;
            end
            if (Cas_latency_3 === 1'b1) begin
                Command[2] = `PRECH;
                Bank_precharge[2] = Ba;
                A10_precharge[2] = Addr[10];
            end else if (Cas_latency_2 === 1'b1) begin
                Command[1] = `PRECH;
                Bank_precharge[1] = Ba;
                A10_precharge[1] = Addr[10];
            end
        end
        
        if (Burst_term === 1'b1) begin
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;
            end
            if (Cas_latency_3 === 1'b1) begin
                Command[2] = `BST;
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `BST;
            end
            if (Debug) begin
                $display ("%t BST  : Burst Terminate",$time);
            end
        end
        
        if (Read_enable === 1'b1) begin
            if ((Ba == 2'b00 && Pc_b0 == 1'b1) || (Ba == 2'b01 && Pc_b1 == 1'b1) ||
                (Ba == 2'b10 && Pc_b2 == 1'b1) || (Ba == 2'b11 && Pc_b3 == 1'b1)) begin
                $display("%t ERROR: Bank is not Activated for Read", $time);
            end
            if ((Ba == 2'b00) && ($time - RCD_chk0 < tRCD) ||
                (Ba == 2'b01) && ($time - RCD_chk1 < tRCD) ||
                (Ba == 2'b10) && ($time - RCD_chk2 < tRCD) ||
                (Ba == 2'b11) && ($time - RCD_chk3 < tRCD)) begin
                $display("%t ERROR: tRCD violation during Read", $time);
            end
            if (Cas_latency_3 == 1'b1) begin
                Command[2] = `READ;
                Col_addr[2] = Addr;
                Bank_addr[2] = Ba;
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `READ;
                Col_addr[1] = Addr;
                Bank_addr[1] = Ba;
            end
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Write_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_write[RW_interrupt_bank] = 1'b1;
                    RW_interrupt_counter[RW_interrupt_bank] = 0;
                    if (Debug) begin
                        $display ("%t NOTE : Read interrupt Write with Autoprecharge", $time);
                    end
                end
            end
            if (Addr[10] == 1'b1) begin
                Auto_precharge[Ba] = 1'b1;
                Count_precharge[Ba] = 0;
                RW_interrupt_bank = Ba;
                Read_precharge[Ba] = 1'b1;
            end
        end

        if (Write_enable == 1'b1) begin
            if ((Ba == 2'b00 && Pc_b0 == 1'b1) || (Ba == 2'b01 && Pc_b1 == 1'b1) ||
                (Ba == 2'b10 && Pc_b2 == 1'b1) || (Ba == 2'b11 && Pc_b3 == 1'b1)) begin
                $display("%t ERROR: Bank is not Activated for Write", $time);
            end
            if ((Ba == 2'b00) && ($time - RCD_chk0 < tRCD) ||
                (Ba == 2'b01) && ($time - RCD_chk1 < tRCD) ||
                (Ba == 2'b10) && ($time - RCD_chk2 < tRCD) ||
                (Ba == 2'b11) && ($time - RCD_chk3 < tRCD)) begin
                $display("%t ERROR: tRCD violation during Read", $time);
            end
            Command[0] = `WRITE;
            Col_addr[0] = Addr;
            Bank_addr[0] = Ba;
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Write_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_write[RW_interrupt_bank] = 1'b1;
                    if (Debug) begin
                        $display ("%t NOTE : Read Bank %d interrupt Write Bank %d with Autoprecharge", $time, Ba, RW_interrupt_bank);
                    end
                end
            end
            if (Data_out_enable == 1'b1) begin
                Data_out_enable = 1'b0;
                if (Auto_precharge[RW_interrupt_bank] == 1'b1 && Read_precharge[RW_interrupt_bank] == 1'b1) begin
                    RW_interrupt_read[RW_interrupt_bank] = 1'b1;
                    if (Debug) begin
                        $display ("%t NOTE : Write Bank %d interrupt Read Bank %d with Autoprecharge", $time, Ba, RW_interrupt_bank);
                    end
                end
            end
            if (Addr[10] == 1'b1) begin
                Auto_precharge[Ba] = 1'b1;
                Count_precharge[Ba] = 0;
                RW_interrupt_bank = Ba;
                Write_precharge[Ba] = 1'b1;
            end
        end

        if ((Auto_precharge[0] == 1'b1) && (Write_precharge[0] == 1'b1)) begin
            if ((($time - RAS_chk0 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [0] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge [0] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [0] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [0] >= 8))) ||
                 (RW_interrupt_write[0] == 1'b1 && RW_interrupt_counter[0] >= 1)) begin
                    Auto_precharge[0] = 1'b0;
                    Write_precharge[0] = 1'b0;
                    RW_interrupt_write[0] = 1'b0;
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $time + tWRa;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 0", $time);
                    end
            end
        end
        if ((Auto_precharge[1] == 1'b1) && (Write_precharge[1] == 1'b1)) begin
            if ((($time - RAS_chk1 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [1] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge [1] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [1] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [1] >= 8))) ||
                 (RW_interrupt_write[1] == 1'b1 && RW_interrupt_counter[1] >= 1)) begin
                    Auto_precharge[1] = 1'b0;
                    Write_precharge[1] = 1'b0;
                    RW_interrupt_write[1] = 1'b0;
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $time + tWRa;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 1", $time);
                    end
            end
        end
        if ((Auto_precharge[2] == 1'b1) && (Write_precharge[2] == 1'b1)) begin
            if ((($time - RAS_chk2 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [2] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge [2] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [2] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [2] >= 8))) ||
                 (RW_interrupt_write[2] == 1'b1 && RW_interrupt_counter[2] >= 1)) begin
                    Auto_precharge[2] = 1'b0;
                    Write_precharge[2] = 1'b0;
                    RW_interrupt_write[2] = 1'b0;
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $time + tWRa;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 2", $time);
                    end
            end
        end
        if ((Auto_precharge[3] == 1'b1) && (Write_precharge[3] == 1'b1)) begin
            if ((($time - RAS_chk3 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [3] >= 1) ||
                 (Burst_length_2 == 1'b1 && Count_precharge [3] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [3] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [3] >= 8))) ||
                 (RW_interrupt_write[3] == 1'b1 && RW_interrupt_counter[3] >= 1)) begin
                    Auto_precharge[3] = 1'b0;
                    Write_precharge[3] = 1'b0;
                    RW_interrupt_write[3] = 1'b0;
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $time + tWRa;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 3", $time);
                    end
            end
        end

        if ((Auto_precharge[0] == 1'b1) && (Read_precharge[0] == 1'b1)) begin
            if ((($time - RAS_chk0 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[0] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[0] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[0] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[0] >= 8))) ||
                 (RW_interrupt_read[0] == 1'b1)) begin
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $time;
                    Auto_precharge[0] = 1'b0;
                    Read_precharge[0] = 1'b0;
                    RW_interrupt_read[0] = 1'b0;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 0", $time);
                    end
            end
        end
        if ((Auto_precharge[1] == 1'b1) && (Read_precharge[1] == 1'b1)) begin
            if ((($time - RAS_chk1 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[1] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[1] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[1] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[1] >= 8))) ||
                 (RW_interrupt_read[1] == 1'b1)) begin
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $time;
                    Auto_precharge[1] = 1'b0;
                    Read_precharge[1] = 1'b0;
                    RW_interrupt_read[1] = 1'b0;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 1", $time);
                    end
            end
        end
        if ((Auto_precharge[2] == 1'b1) && (Read_precharge[2] == 1'b1)) begin
            if ((($time - RAS_chk2 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[2] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[2] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[2] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[2] >= 8))) ||
                 (RW_interrupt_read[2] == 1'b1)) begin
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $time;
                    Auto_precharge[2] = 1'b0;
                    Read_precharge[2] = 1'b0;
                    RW_interrupt_read[2] = 1'b0;
                    if (Debug) begin
                        $display ("%t NOTE : Start Internal Auto Precharge for Bank 2", $time);
                    end
            end
        end
        if ((Auto_precharge[3] == 1'b1) && (Read_precharge[3] == 1'b1)) begin
            if ((($time - RAS_chk3 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[3] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[3] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[3] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[3] >= 8))) ||
                 (RW_interrupt_read[3] == 1'b1)) begin
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $time;
                    Auto_precharge[3] = 1'b0;
                    Read_precharge[3] = 1'b0;
                    RW_interrupt_read[3] = 1'b0;
                    if (Debug) begin
                        $display("%t NOTE : Start Internal Auto Precharge for Bank 3", $time);
                    end
            end
        end

        if (Command[0] == `PRECH) begin
            if (Bank_precharge[0] == Bank || A10_precharge[0] == 1'b1) begin
                if (Data_out_enable == 1'b1) begin
                    Data_out_enable = 1'b0;
                end
            end
        end else if (Command[0] == `BST) begin
            if (Data_out_enable == 1'b1) begin
                Data_out_enable = 1'b0;
            end
        end

        if (Data_out_enable == 1'b0) begin
            Dq_reg <= #tOH {data_bits{1'bz}};
        end

        if (Command[0] == `READ) begin
            Bank = Bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            case (Bank_addr[0])
                2'b00 : Row = B0_row_addr;
                2'b01 : Row = B1_row_addr;
                2'b10 : Row = B2_row_addr;
                2'b11 : Row = B3_row_addr;
            endcase
            Burst_counter = 0;
            Data_in_enable = 1'b0;
            Data_out_enable = 1'b1;
        end else if (Command[0] == `WRITE) begin
            Bank = Bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            case (Bank_addr[0])
                2'b00 : Row = B0_row_addr;
                2'b01 : Row = B1_row_addr;
                2'b10 : Row = B2_row_addr;
                2'b11 : Row = B3_row_addr;
            endcase
            Burst_counter = 0;
            Data_in_enable = 1'b1;
            Data_out_enable = 1'b0;
        end

        if (Data_in_enable == 1'b1) begin     // WRITE operation
            case (Bank)
                2'b00 : Dq_dqm = Bank0[{Row, Col}];
                2'b01 : Dq_dqm = Bank1[{Row, Col}];
                2'b10 : Dq_dqm = Bank2[{Row, Col}];
                2'b11 : Dq_dqm = Bank3[{Row, Col}];
            endcase

            if (Dqm[0] == 1'b0) begin
                Dq_dqm [ 7 : 0] = Dq [ 7 : 0];
            end
            if (Dqm[1] == 1'b0) begin
                Dq_dqm [15 : 8] = Dq [15 : 8];
            end

            case (Bank)
                2'b00 : Bank0[{Row, Col}] = Dq_dqm;
                2'b01 : Bank1[{Row, Col}] = Dq_dqm;
                2'b10 : Bank2[{Row, Col}] = Dq_dqm;
                2'b11 : Bank3[{Row, Col}] = Dq_dqm;
            endcase

            if (Dqm !== 2'b11) begin
                WR_chkm [Bank] = $time;
                if (Debug) begin
                    $display("%t WRITE: Bank = %d Row = %d, Col = %d, Data = %h", 
                             $time, Bank, Row, Col, Dq_dqm);
                end
            end else begin
                if (Debug) begin
                    $display("%t WRITE: Bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", 
                             $time, Bank, Row, Col);
                end
            end

            #tHZ Burst_decode;

        end else if (Data_out_enable == 1'b1) begin // READ operation
            case (Bank)
                2'b00 : Dq_dqm = Bank0[{Row, Col}];
                2'b01 : Dq_dqm = Bank1[{Row, Col}];
                2'b10 : Dq_dqm = Bank2[{Row, Col}];
                2'b11 : Dq_dqm = Bank3[{Row, Col}];
            endcase

            if (Dqm_reg0 [0] == 1'b1) begin
                Dq_dqm [ 7 : 0] = 8'bz;
            end
            if (Dqm_reg0 [1] == 1'b1) begin
                Dq_dqm [15 : 8] = 8'bz;
            end

            if (Dqm_reg0 !== 2'b11) begin
                Dq_reg = #tAC Dq_dqm;
                if (Debug) begin
                    $display("%t READ : Bank = %d Row = %d, Col = %d, Data = %h", 
                             $time, Bank, Row, Col, Dq_reg);
                end
            end else begin
                Dq_reg = #tHZ {data_bits{1'bz}};
                if (Debug) begin
                    $display("%t READ : Bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", 
                             $time, Bank, Row, Col);
                end
            end

            Burst_decode;
        end
    end

    task Burst_decode;
        begin
            Burst_counter = Burst_counter + 1;
            if (Mode_reg[3] == 1'b0) begin
                Col_temp = Col + 1;
            end else if (Mode_reg[3] == 1'b1) begin
                Col_temp[2] =  Burst_counter[2] ^ Col_brst[2];
                Col_temp[1] =  Burst_counter[1] ^ Col_brst[1];
                Col_temp[0] =  Burst_counter[0] ^ Col_brst[0];
            end

            if (Burst_length_2) begin
                Col [0] = Col_temp [0];
            end else if (Burst_length_4) begin
                Col [1 : 0] = Col_temp [1 : 0];
            end else if (Burst_length_8) begin
                Col [2 : 0] = Col_temp [2 : 0];
            end else begin
                Col = Col_temp;
            end

            if (Write_burst_mode == 1'b1) begin
                Data_in_enable = 1'b0;
            end

            if (Burst_length_1 == 1'b1) begin
                if (Burst_counter >= 1) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_2 == 1'b1) begin
                if (Burst_counter >= 2) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_4 == 1'b1) begin
                if (Burst_counter >= 4) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_8 == 1'b1) begin
                if (Burst_counter >= 8) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end
        end
    endtask

    specify
        specparam
            tAH  =  0.8,
            tAS  =  1.5,
            tCH  =  2.5,
            tCL  =  2.5,
            tCK  =  5.0,
            tDH  =  0.8,
            tDS  =  1.5,
            tCKH =  0.8,
            tCKS =  1.5,
            tCMH =  0.8,
            tCMS =  1.5;
        $width    (posedge Clk,           tCH);
        $width    (negedge Clk,           tCL);
        $period   (negedge Clk,           tCK);
        $setuphold(posedge Clk,    Cke,   tCKS, tCKH);
        $setuphold(posedge Clk,    Cs_n,  tCMS, tCMH);
        $setuphold(posedge Clk,    Cas_n, tCMS, tCMH);
        $setuphold(posedge Clk,    Ras_n, tCMS, tCMH);
        $setuphold(posedge Clk,    We_n,  tCMS, tCMH);
        $setuphold(posedge Clk,    Addr,  tAS,  tAH);
        $setuphold(posedge Clk,    Ba,    tAS,  tAH);
        $setuphold(posedge Clk,    Dqm,   tCMS, tCMH);
        $setuphold(posedge Dq_chk, Dq,    tDS,  tDH);
    endspecify

endmodule
