#tells cocotb which simulator to use, which rtl to compile, which module is the top, and which python file holds the tests

SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES += $(PWD)/../rtl/sync_fifo.sv

COCOTB_TOPLEVEL = sync_fifo
COCOTB_TEST_MODULES = test_sync_fifo,test_sync_fifo_random

#allow the known benign width warnings, and dump a waveform
EXTRA_ARGS += -Wno-WIDTHEXPAND -Wno-EOFNEWLINE --trace
EXTRA_ARGS += -CFLAGS -std=c++17

include $(shell cocotb-config --makefiles)/Makefile.sim
