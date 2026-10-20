# Counter Based Sync FIFO Spec

## Parameters

- `WIDTH` default 8: data width (bits)
- `DEPTH` default 16: number of entries. Counter version means this doesn't have to be a power of 2

## Ports

| Port | in/out | Width | Description |
| --- | --- | --- | --- |
| `clk` | in | 1 | Clock |
| `rst_n` | in | 1 | Synchronous active low reset |
| `wr_en` | in | 1 | Write request |
| `wr_data` | in | [WIDTH]| Write data |
| `rd_en` | in | 1 | Read request |
| `rd_data` | out | [WIDTH] | Read data |
| `empty` | out | 1 | FIFO is holding 0 entries |
| `full` | out | 1 | FIFO is holding [DEPTH] entries |

## Behaviour

- **Reset**: synchronous and active low. clears: counter, wr/rd pointer and `rd_data`. FIFO comes out of reset empty. Memory contents are not reset.
- **Write accepted**: when `wr_en && !full`, the data is stored at the write pointer and the pointer increments, wrapping from `DEPTH-1` to 0.
- **Read accepted**: when `rd_en && !empty`, `rd_data` updates on the next clock edge, otherwise, it holds its value. The read pointer increments, wrapping from `DEPTH-1` to 0.
- **Write when Full**: ignored, even if `rd_en` is high.
- **Read when Empty**: ignored, even if `wr_en` is high.
- **Simultaneous read and wirite accepted**: the counter is unchanged.
- **Counter funcitonality**: goes up by 1 on an accepted write only, down by 1 on an accepted read only, and holds otherwise. 
- **Full / Empty**: `full = (counter == DEPTH)` and `empty = (counter == 0)`, both combinational from the counter.

## Requirements

| # | Requirement |
| --- | --- |
| 1 | `full` and `empty` are never high together |
| 2 | `empty` is high and `full` is low after reset |
| 3 | write is NOT accepted when `full` is high (no overflow) |
| 4 | Read is NOT accepted when `empty` is high (no underflow) |
| 5 | `full` is high exactly when a total of [DEPTH] entries are stored |
| 6 | `empty` is high exactly when 0 entries are stored |
| 7 | Data comes out in the order it went in, unchanged |


