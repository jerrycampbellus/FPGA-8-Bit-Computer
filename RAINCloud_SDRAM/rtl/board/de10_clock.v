/**************************************************************************
* RAINCloud / SDRAM_Tester / de10_clock.v
* Release: 26101404, controller 1.2.1 (October 14, 2026)
* Intel MAX 10 PLL boundary: 50 MHz reference/core and SDRAM clock +8 ns.
* Quartus PLL period/phase parameters below are in picoseconds. The top waits
* for locked before releasing reset; the SDC constrains the fitted I/O paths.
* The behavioral replacement in tests/tb_board.sv does not model analog lock,
* jitter or fitted routing. See docs/TIMING.md and docs/TESTBENCH.md.
**************************************************************************/
module de10_clock(input ref_clk, output core_clk, output sdram_clk, output locked);
  wire [4:0] clocks;
  altpll pll(.inclk({1'b0,ref_clk}),.areset(1'b0),.clk(clocks),.locked(locked),
    .clkena(6'b111111),.extclkena(4'b1111),.fbin(1'b1),.pfdena(1'b1),.pllena(1'b1));
  defparam pll.bandwidth_type="AUTO",
    pll.clk0_divide_by=1, pll.clk0_multiply_by=1, pll.clk0_duty_cycle=50, pll.clk0_phase_shift="0",
    pll.clk1_divide_by=1, pll.clk1_multiply_by=1, pll.clk1_duty_cycle=50, pll.clk1_phase_shift="8000",
    pll.compensate_clock="CLK0", pll.inclk0_input_frequency=20000,
    pll.intended_device_family="MAX 10", pll.operation_mode="NORMAL", pll.pll_type="AUTO",
    pll.port_activeclock="PORT_UNUSED", pll.port_areset="PORT_USED", pll.port_clkbad0="PORT_UNUSED",
    pll.port_clkbad1="PORT_UNUSED", pll.port_clkloss="PORT_UNUSED", pll.port_clkswitch="PORT_UNUSED",
    pll.port_configupdate="PORT_UNUSED", pll.port_fbin="PORT_UNUSED", pll.port_inclk0="PORT_USED",
    pll.port_inclk1="PORT_UNUSED", pll.port_locked="PORT_USED", pll.port_pfdena="PORT_UNUSED",
    pll.port_phasecounterselect="PORT_UNUSED", pll.port_phasedone="PORT_UNUSED",
    pll.port_phasestep="PORT_UNUSED", pll.port_phaseupdown="PORT_UNUSED", pll.port_pllena="PORT_UNUSED",
    pll.port_scanaclr="PORT_UNUSED", pll.port_scanclk="PORT_UNUSED", pll.port_scanclkena="PORT_UNUSED",
    pll.port_scandata="PORT_UNUSED", pll.port_scandataout="PORT_UNUSED", pll.port_scandone="PORT_UNUSED",
    pll.port_scanread="PORT_UNUSED", pll.port_scanwrite="PORT_UNUSED", pll.port_clk0="PORT_USED",
    pll.port_clk1="PORT_USED", pll.port_clk2="PORT_UNUSED", pll.port_clk3="PORT_UNUSED",
    pll.port_clk4="PORT_UNUSED", pll.port_clk5="PORT_UNUSED", pll.width_clock=5;
  assign core_clk=clocks[0]; assign sdram_clk=clocks[1];
endmodule
