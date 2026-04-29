import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.enqueue.value = 0
    dut.dequeue.value = 0
    dut.flush.value = 0
    dut.enq_id.value = 0
    dut.enq_key.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(2):
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_sorted_enqueue_dequeue(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    await reset_dut(dut)

    items = [(1, 10), (2, 30), (3, 20), (4, 5)]
    for task_id, key in items:
        dut.enq_id.value = task_id
        dut.enq_key.value = key
        dut.enqueue.value = 1
        await RisingEdge(dut.clk)
        dut.enqueue.value = 0
        await RisingEdge(dut.clk)

    expected = [2, 3, 1, 4]
    for exp in expected:
        assert int(dut.head_id.value) == exp
        assert int(dut.head_valid.value) == 1
        dut.dequeue.value = 1
        await RisingEdge(dut.clk)
        dut.dequeue.value = 0
        await RisingEdge(dut.clk)
