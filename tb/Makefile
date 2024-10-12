# Makefile

# defaults
SIM ?= verilator 
TOPLEVEL_LANG ?= verilog
SIM_BUILD ?= ../run/verilator

VERILOG_SOURCES += $(PWD)/rtl/cpu.sv
VERILOG_SOURCES += $(PWD)/pkg/cpu_pkg.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = cpu 

# MODULE is the basename of the Python test file
MODULE = cpu_test 

COMPILE_ARGS += "--Wall"
COMPILE_ARGS += "-O3"
COMPILE_ARGS += "--trace"

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim