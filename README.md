# Verification of a Counter based Sync FIFO

A parameterisable, counter-based synchronous FIFO in SystemVerilog, verified with
SVA assertions, formal methods (SymbiYosys) and a constrained random cocotb testbench.

## Results at a glance

| Method | Result |
|--------|--------|
| Formal (SymbiYosys) | All assertions fully proved by k-induction/temporal induction at DEPTH 4 and 16; all 7 covers reached |
| cocotb (Verilator) | 3 tests × 100 seeds (300 runs -> 2 random tests × 1,000 cycles each × 100 seeds = 200,000 random cycles). all passed |
| Functional coverage | 100% across 36 bins: every fill level and every read/write combination when empty, when filled to middle and full |
| Bug injection | 6/6 caught by formal, 5/6 caught by cocotb |

### Full details can be found in: 
- formal results: `results/formal_results.md` 
- cocotb results: `results/cocotb_results.md`
- design specification: `docs/spec.md`

## Repository layout

```
rtl/        fifo rtl (design under test)
sva/        concurrent SVA checker
formal/     SymbiYosys setup and formal checks
cocotb/     Makefile and cocotb/python tests (reference model + constrained random tests)
docs/       design specification and requirements
results/    formal and cocotb results, bug-injection tables, some notes
```

## Design

A synchronous counter based FIFO with parameterisable `WIDTH` and `DEPTH` (not limited to powers of 2). The counter tracks the fifo content, and `full`/`empty` come straight from it. Reads have one cycle of latency (`rd_data` updates on the clock edge after an accepted read). write when full or a read when empty get ignored.

for more details on design: `docs/spec.md`

## Verification approach

### SVA
 `sva/sync_fifo_sva.sv`
 
checks the flags against an independent reference counter, plus the pointer steps and reset behaviour. Contains a data integrity tracker that follows written entries through the FIFO to check order and actual values. Cover properties confirm that full, empty, overflow and underflow, simultaneous read/write and pointer wrap around are all actually reachable.


### Formal
`formal/sync_fifo_formal.svh`

same sva checks are rewritten as immediate assertions becase open-source Yosys does not support concurrent sva or `bind`. SymbiYosys proves all assertions by k-induction/temporal induction at DEPTH 4 and 16.

### cocotb
`cocotb/test_sync_fifo.py` `cocotb/test_sync_fifo_random.py`   

A Python testbench on Verilator. Two constrained random tests (70%/30% write heavy and 30%/70% read heavy, 1,000 cycles each) run across 100 seeds, 2 random tests × 1,000 cycles each × 100 seeds = 200,000 random cycles.

### Bug injection
6 RTL bugs were injected one at a time for both methods, which included an early `full` flag, overflow, underflow, a counting error on simultaneous read and write, reading from the wrong location, and `rd_data` not being cleared on reset.

## How to run

### Formal
```
#macOS & Linux
source ~/oss-cad-suite/environment

#Windows (untested by me)
<path>\oss-cad-suite\environment.bat  

cd formal
sby -f sync_fifo.sby
```

### cocotb
```
python3.14 -m venv .venv
source .venv/bin/activate
pip install cocotb

cd cocotb

#for random seed
make

#for fixed seed 
make COCOTB_RANDOM_SEED=<seed>

```


## Tools

- SystemVerilog
- SVA
- SymbiYosys / Yosys
- cocotb
- Python 3.14
- Verilator


