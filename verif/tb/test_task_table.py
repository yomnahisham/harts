import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_write_read_task_entry(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_id.value = 0
    dut.rd_id.value = 0
    for _ in range(3):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut.wr_en.value = 1
    dut.wr_id.value = 3
    dut.wr_priority.value = 7
    dut.wr_period.value = 100
    dut.wr_deadline.value = 90
    dut.wr_wcet.value = 25
    dut.wr_type.value = 1
    dut.wr_preemptable.value = 1
    dut.wr_status.value = 2
    dut.wr_abs_deadline.value = 123
    dut.wr_remaining_wcet.value = 20
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0

    dut.rd_en.value = 1
    dut.rd_id.value = 3
    await Timer(1, units="ns")

    assert int(dut.rd_priority.value) == 7
    assert int(dut.rd_period.value) == 100
    assert int(dut.rd_deadline.value) == 90
    assert int(dut.rd_wcet.value) == 25
    assert int(dut.rd_type.value) == 1
    assert int(dut.rd_preemptable.value) == 1
    assert int(dut.rd_status.value) == 2
