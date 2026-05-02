import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from sim_timing import CLK_PERIOD_NS


@cocotb.test()
async def test_tick_generation(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    dut.rst_n.value = 0
    dut.enable.value = 0
    dut.tick_divider.value = 2
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    dut.enable.value = 1

    pulses = 0
    for _ in range(12):
        await RisingEdge(dut.clk)
        if int(dut.tick_pulse.value):
            pulses += 1
    assert pulses >= 3
