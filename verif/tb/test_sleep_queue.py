import cocotb
from cocotb.clock import Clock
from cocotb.triggers import NextTimeStep, ReadOnly, RisingEdge

from sim_timing import CLK_PERIOD_NS


@cocotb.test()
async def test_sleep_wake_order(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())
    dut.rst_n.value = 0
    dut.flush.value = 0
    dut.enqueue.value = 0
    dut.tick.value = 0
    dut.enq_id.value = 0
    dut.enq_count.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    data = [(1, 3), (2, 1), (3, 2)]
    for task_id, cnt in data:
        dut.enq_id.value = task_id
        dut.enq_count.value = cnt
        dut.enqueue.value = 1
        await RisingEdge(dut.clk)
        dut.enqueue.value = 0
        await RisingEdge(dut.clk)

    woke = []
    for _ in range(5):
        dut.tick.value = 1
        await RisingEdge(dut.clk)
        await ReadOnly()
        if int(dut.wake_valid.value):
            woke.append(int(dut.wake_id.value))
        await NextTimeStep()
        dut.tick.value = 0
        await RisingEdge(dut.clk)

    assert woke == [2, 3, 1]
