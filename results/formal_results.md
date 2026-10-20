# Formal Results
- All assertions fully proved by k-induction/temporal induction at DEPTH 4 and 16
- All 7 covers reached
- Six injected bugs caught



## How to run

```
#macOS & Linux
source ~/oss-cad-suite/environment

#Windows (untested by me)
<path>\oss-cad-suite\environment.bat  

cd formal
sby -f sync_fifo.sby
```



## Setup

- Tools: SymbiYosys with the smtbmc engine
- Files: `rtl/sync_fifo.sv` , `formal/sync_fifo_formal.svh`
- Note: open source Yosys only understands a small part of SVA, full concurrent assertions (`assert property (@(posedge clk) …)`, `|=>`, `disable iff`, `##1`) and `bind` mostly need the commercial Verific front end, so concurrent assertion checks written in `sva/sync_fifo_sva.sv` are rewritten as immediate assertions in `formal/sync_fifo_formal.svh` to allow Yosys to work properly.
- Settings: prove depth 10, cover depth 40, FIFO size set with `chparam -set DEPTH 4` (4 for bug injections) and `16`



## Bug Injections

| # | Bug | RTL change | Caught? | Assertion that failed | Step |
|---|-----|------------|---------|-----------------------|------|
| 1 | full asserts one entry early | `full = (counter == DEPTH-1)` | Yes | `ast_full_when_counter_eq_depth` | 4 |
| 2 | overflow: writes allowed when full | `assign write_accepted = wr_en` | Yes | `ast_counter_matches_test`<br>`ast_full_when_counter_eq_depth`<br>`ast_ptrs_match_count` | 6 |
| 3 | underflow: reads allowed when empty | `read_accepted = rd_en` | Yes | `ast_counter_matches_test`<br>`ast_empty_when_counter_is_0`<br>`ast_ptrs_match_count`<br>`ast_tracked_data_in_mem` | 2 |
| 4 | counting error: counter increments on a simultaneous read and write instead of holding | `if (write_accepted) counter <= counter + 1;` | Yes | `ast_counter_matches_test` | 3 |
| 5 | reading from the wrong location (using write pointer instead of read) | `rd_data <= fifo_mem[wr_pointer]` | Yes | `ast_data_tracker_integrity` | 3 |
| 6 | read data not cleared on reset | `rd_data <= '0;` removed from the reset branch | Yes | `ast_rstn_rd_data` | 2 |



## Helper Assertions
- Helper assertions were added in `formal/sync_fifo_formal.svh` because, without them, k-induction started from unreachable states (for example, the tracker following data that wasnt actually in memory) and failed on `ast_data_tracker_integrity`. Describing the FIFOs real state ruled these out, turning a 13-minute bounded result into a full proof in under a second.
