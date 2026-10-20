import random
from collections import deque
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, FallingEdge



DEPTH = 16
CYCLES = 1000 #1000 random cycles



async def reset(dut):
    dut.rst_n.value = 0 #assert reset
    dut.wr_en.value = 0
    dut.rd_en.value = 0
    dut.wr_data.value = 0

    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1 #release reset



#write heavy (70% write, 30% read)
@cocotb.test()
async def test_random_write(dut):
    Clock(dut.clk, 10, unit="ns").start() #10ns clock (100MHz)

    await reset(dut)

    model_content = deque() #reference model (https://www.geeksforgeeks.org/python/deque-in-python/)
    expected_result = None

    for cycle in range(CYCLES):

        await FallingEdge(dut.clk) #wait until mid-cycle, when all signals are stable

        if expected_result != None:
            assert int(dut.rd_data.value) == expected_result, f"read data mismatch at cycle {cycle}"

        assert int(dut.empty.value) == (len(model_content) == 0), f"empty flag wrong at cycle {cycle}"

        assert int(dut.full.value) == (len(model_content) == DEPTH), f"full flag wrong at cycle {cycle}"


        #constrained random testing
        wr_en = int(random.random() < 0.7) #write requested 70% of the time
        rd_en = int(random.random() < 0.3) #read requested 30% of the time

        wr_data = random.randint(0, 255) #8bit data

        #feed random inputs to dut
        dut.wr_en.value = wr_en
        dut.rd_en.value = rd_en
        dut.wr_data.value = wr_data

        wr_accepted = (wr_en) and (len(model_content) < DEPTH) #write only accepted when write enable AND fifo isn't full
        rd_accepted = (rd_en) and (len(model_content) > 0) #read only accepted when read enable AND fifo isn't empty

        if rd_accepted:
            expected_result = model_content.popleft() #remove the oldest entry
        else:
            expected_result = None

        if wr_accepted:
            model_content.append(wr_data)



#read heavy (70% read, 30% write)
@cocotb.test()
async def test_random_read(dut):
    Clock(dut.clk, 10, unit="ns").start() #10ns clock (100MHz)

    await reset(dut)

    model_content = deque() #reference model
    expected_result = None

    for cycle in range(CYCLES):

        await FallingEdge(dut.clk) #wait until mid-cycle, when all signals are stable

        if expected_result != None:
            assert int(dut.rd_data.value) == expected_result, f"read data mismatch at cycle {cycle}"

        assert int(dut.empty.value) == (len(model_content) == 0), f"empty flag wrong at cycle {cycle}"

        assert int(dut.full.value) == (len(model_content) == DEPTH), f"full flag wrong at cycle {cycle}"


        #constrained random testing
        wr_en = int(random.random() < 0.3) #write requested 30% of the time
        rd_en = int(random.random() < 0.7) #read requested 70% of the time

        wr_data = random.randint(0, 255) #8bit data

        #feed random inputs to dut
        dut.wr_en.value = wr_en
        dut.rd_en.value = rd_en
        dut.wr_data.value = wr_data

        wr_accepted = (wr_en) and (len(model_content) < DEPTH) #write only accepted when write enable AND fifo isn't full
        rd_accepted = (rd_en) and (len(model_content) > 0) #read only accepted when read enable AND fifo isn't empty

        if rd_accepted:
            expected_result = model_content.popleft() #remove the oldest entry
        else:
            expected_result = None

        if wr_accepted:
            model_content.append(wr_data)