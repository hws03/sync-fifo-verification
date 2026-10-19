import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


@cocotb.test()
async def test_reset(dut):

	#10ns clock
    Clock(dut.clk, 10, unit="ns").start() 

    #hold inputs low and reset for 2 cycles
    dut.rst_n.value = 0
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0
    await ClockCycles(dut.clk, 2)

    #stop reset
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    assert dut.empty.value == 1, "fifo empty after reset"
    assert dut.full.value == 0, "fifo not full after reset"