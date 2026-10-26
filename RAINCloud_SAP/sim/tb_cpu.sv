// RAINCloud Digital | RAINCloud_SAP
// Original SAP design and codebase: J. Campbell.
//
`timescale 1ns/1ps
module tb_cpu;
  reg master=0,reset=0,manual=0,step=1;
  wire halt,clk;
  integer i,scenario,outputs=0,expected_output,expected_pc,expected_a,expected_flags;
  integer drivers;
  reg [5:0] bus_select;
  BE_8_BIT_Computer dut(.FPGA_CLK_SOURCE(master),.CLK_SELECT(manual),
    .CLK_STEP(step),.CLR(reset),.TWOS_COMPLEMENT(1'b0),.HEXADECIMAL_FLAG(1'b0),
    .CLK_DIVIDER(3'b111),.DISPLAY_SELECT(4'b1000),.HLT_LED(halt),.CLK_LED(clk),
    .LED(),.SEVEN_SEG_0(),.SEVEN_SEG_1(),.SEVEN_SEG_2(),
    .SEVEN_SEG_3(),.SEVEN_SEG_4(),.SEVEN_SEG_5());
  always #10 master=~master;
  // Inspect the real bus while the CPU is halted, without changing its state.
  // This also exercises B output, which the current instruction set never uses.
  task check_bus_sources;
    integer source;
    reg [7:0] expected;
    begin
      bus_select=0;
      force dut.alu_output_enable=bus_select[0];
      force dut.a_output_enable=bus_select[1];
      force dut.b_output_enable=bus_select[2];
      force dut.instruction_output_enable=bus_select[3];
      force dut.pc_output_enable=bus_select[4];
      force dut.ram_read_enable=bus_select[5];
      #1;
      if(dut.data_bus!==0) $fatal(1,"Idle FPGA bus is not zero");
      for(source=0;source<6;source=source+1) begin
        bus_select=6'b000001<<source; #1;
        case(source)
          0: expected=dut.alu_result; // ALU result
          1: expected=dut.a_value;  // A
          2: expected=dut.b_value;  // B
          3: expected={4'b0,dut.instruction_operand}; // instruction operand
          4: expected={4'b0,dut.pc_value}; // PC
          5: expected=dut.ram_display; // RAM
        endcase
        if(dut.data_bus!==expected)
          $fatal(1,"Bus source %0d: got %h expected %h",source,dut.data_bus,expected);
      end
      release dut.alu_output_enable;
      release dut.a_output_enable;
      release dut.b_output_enable;
      release dut.instruction_output_enable;
      release dut.pc_output_enable;
      release dut.ram_read_enable;
    end
  endtask
  task prepare;
    begin
      @(negedge master); reset=1; #1;
      for(i=0;i<16;i=i+1) dut.b2v_RAM.RAM[i]=0;
      outputs=0;
    end
  endtask
  task start;
    begin repeat(4) @(negedge master); reset=0; end
  endtask
  task check_halt;
    begin
      wait(halt===1); #2;
      if(dut.pc_value!==expected_pc[3:0] ||
         dut.a_value!==expected_a[7:0] ||
         dut.cpu_flags!==expected_flags[7:0] || outputs!=expected_output)
        $fatal(1,"CPU case %0d PC=%h A=%h flags=%h outputs=%0d",scenario,
          dut.pc_value,dut.a_value,dut.cpu_flags,outputs);
      repeat(5) @(negedge master);
      if(clk!==0) $fatal(1,"Halted CPU clock is not low");
      check_bus_sources();
    end
  endtask
  always @(posedge clk) if(!reset) begin
    drivers=integer'(dut.alu_output_enable)+integer'(dut.a_output_enable)+
      integer'(dut.b_output_enable)+integer'(dut.instruction_output_enable)+
      integer'(dut.pc_output_enable)+integer'(dut.ram_read_enable);
    if((^drivers)===1'bx || drivers>1) $fatal(1,"Invalid data-bus enables");
    if(dut.a_load_enable || dut.b_load_enable ||
       dut.instruction_load_enable || dut.mar_load_enable ||
       dut.output_load_enable || dut.pc_jump_enable || dut.ram_write_enable) begin
      if(drivers!=1) $fatal(1,"Bus capture without exactly one enabled source");
      if((^dut.data_bus)===1'bx) $fatal(1,"Unknown bus captured");
    end
    if(dut.output_load_enable) outputs=outputs+1;
  end
  initial begin
    #1;
    if(dut.b2v_RAM.RAM[0]!==8'h1f || dut.b2v_RAM.RAM[15]!==8'h00)
      $fatal(1,"Default program image order/path incorrect");
    for(scenario=0;scenario<8;scenario=scenario+1) begin
      prepare();
      dut.b2v_RAM.RAM[0]=8'h1e; dut.b2v_RAM.RAM[1]=8'h2f;
      dut.b2v_RAM.RAM[2]=8'h40; dut.b2v_RAM.RAM[3]=8'hf0;
      dut.b2v_RAM.RAM[14]=5; dut.b2v_RAM.RAM[15]=3;
      expected_a=8; expected_pc=4; expected_flags=0; expected_output=1;
      case(scenario)
        1: begin dut.b2v_RAM.RAM[1]=8'h3f; expected_a=2; end
        2,3,4,5,7: begin
          dut.b2v_RAM.RAM[2]=(scenario==3 || scenario==5)?8'h75:8'h85;
          dut.b2v_RAM.RAM[5]=8'h40; dut.b2v_RAM.RAM[6]=8'hf0;
          dut.b2v_RAM.RAM[15]=1;
          case(scenario)
            2: begin dut.b2v_RAM.RAM[14]=255; expected_a=0; expected_flags=3; expected_pc=7; end
            3: begin dut.b2v_RAM.RAM[14]=1; dut.b2v_RAM.RAM[1]=8'h3f;
                     expected_a=0; expected_flags=1; expected_pc=7; end
            4: begin dut.b2v_RAM.RAM[14]=1; expected_a=2; expected_output=0; end
            5: begin dut.b2v_RAM.RAM[14]=2; dut.b2v_RAM.RAM[1]=8'h3f;
                     expected_a=1; expected_output=0; end
            7: begin dut.b2v_RAM.RAM[14]=0; dut.b2v_RAM.RAM[1]=8'h3f;
                     expected_a=255; expected_flags=2; expected_pc=7; end
          endcase
        end
        6: begin
          dut.b2v_RAM.RAM[14]=255; dut.b2v_RAM.RAM[15]=1;
          dut.b2v_RAM.RAM[2]=8'h6d; dut.b2v_RAM.RAM[3]=8'h1f;
          dut.b2v_RAM.RAM[4]=8'h87; dut.b2v_RAM.RAM[5]=8'hf0;
          dut.b2v_RAM.RAM[7]=8'h40; dut.b2v_RAM.RAM[8]=8'hf0;
          expected_a=1; expected_flags=3; expected_pc=9;
        end
      endcase
      start(); check_halt();
      if(scenario==6 && dut.b2v_RAM.RAM[13]!==0) $fatal(1,"STA wrote incorrect data");
      // A reset shorter than a CPU period must immediately clear HALT/state.
      #1; reset=1; #2;
      if(halt!==0 || dut.pc_value!==0 || dut.cpu_flags!==0)
        $fatal(1,"Short reset failed after HALT");
    end
    scenario=8; prepare();
    // Exercise JMP, PC wrap 15->0, then a self-modifying store replacing JMP
    // with HLT so the second visit to address zero stops.
    dut.b2v_RAM.RAM[0]=8'h5d; dut.b2v_RAM.RAM[13]=8'h1c;
    dut.b2v_RAM.RAM[14]=8'h60; dut.b2v_RAM.RAM[15]=8'h00;
    dut.b2v_RAM.RAM[12]=8'hf0;
    expected_a=240; expected_pc=1; expected_flags=0; expected_output=0;
    start(); check_halt();
    scenario=9; prepare(); dut.b2v_RAM.RAM[0]=8'ha0;
    expected_a=0; expected_pc=1; expected_flags=0; expected_output=0;
    start(); check_halt();
    scenario=10; manual=1; step=1; prepare();
    dut.b2v_RAM.RAM[0]=8'h1e; dut.b2v_RAM.RAM[1]=8'h40;
    dut.b2v_RAM.RAM[2]=8'hf0; dut.b2v_RAM.RAM[14]=42;
    expected_a=42; expected_pc=3; expected_flags=0; expected_output=1;
    start(); repeat(4) @(negedge master);
    repeat(12) begin
      step=0; repeat(4) @(negedge master);
      step=1; repeat(4) @(negedge master);
    end
    check_halt();
    if(dut.b2v_OR.value!==42) $fatal(1,"OUT did not retain the result");
    $display("PASS tb_cpu: 11 programs, branches, flag retention, store, wrap, manual, reset, six bus sources and idle");
    $finish;
  end
  initial begin #100000; $fatal(1,"CPU regression timeout"); end
endmodule
