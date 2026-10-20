# cocotb Results
- 3 tests × 100 seeds (300 runs, ~200,000 random cycles): all passed
- 5 of 6 injected bugs caught



## How to run

```
source .venv/bin/activate
cd cocotb

#for random seed
make

#for fixed seed 
make COCOTB_RANDOM_SEED=<seed>

```



## Setup

- Tools: cocotb, Verilator, Python 3.14
- Files: `cocotb/Makefile`, `cocotb/test_sync_fifo.py`, `cocotb/test_sync_fifo_random.py`
- Every cycle, checks `rd_data` against the model and `full` / `empty` against the model's fill level



## Tests

| Test | What it does |
|------|--------------|
| `test_reset` | Checks the fifo is empty and not full after reset (used to test if tools are working) |
| `test_random_write` | 1000 constrained random cycles, 70% write / 30% read (full/overflow) |
| `test_random_read` | 1000 constrained random cycles, 30% write / 70% read (empty/underflow) |



## Bug Injections

Eacg bug injection run is reproducible with `make COCOTB_RANDOM_SEED=<seed>`.


| # | Bug | RTL change | Caught? | Caught by? | Seed (make COCOTB_RANDOM_SEED= ) | Cycle |
|---|-----|------------|---------|------------|----------------------------------|-------|
| 1 | full asserts one entry early | full = (counter == DEPTH-1) | Yes | test_random_write | 1792517388 | 35 |
| 2 | overflow: writes allowed when full | assign write_accepted = wr_en | Yes | test_random_write | 1792517541 | 34 |
| 3 | underflow: reads allowed when empty | read_accepted = rd_en | Yes | test_random_write, test_random_read | 1792517614 | 1 |
| 4 | counting error: counter increments on a simultaneous read and write instead of holding | if (write_accepted) begin<br>&nbsp;&nbsp;&nbsp;&nbsp;counter <= counter + 1;<br>end | Yes | test_random_write test_random_read | 1792517682 | 21 & 13 |
| 5 | reading from the wrong location (using write pointer instead of read) | rd_data <= fifo_mem[wr_pointer] | Yes | test_random_write, test_random_read | 1792517753 | 2 & 5 |
| 6 | read data not cleared on reset | remove rd_data <= '0; from the reset branch | No | N/A | 1792517817 | N/A |

