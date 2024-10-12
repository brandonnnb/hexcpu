# Simple CPU Cocotb Test Bench

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def cpu_test(dut):
    """Test the simple CPU module."""
    # Create a clock with a period of 10 ns
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())

    cocotb.log.info(f"Resetting...")
    # Reset the CPU
    dut.reset.value = 1
    await RisingEdge(dut.clk)
    dut.reset.value = 0

    cocotb.log.info(f"Reset done.")

    # We're just mocking the memory for this demo

    # Run the CPU for enough clock cycles to complete the program
    for _ in range(20):
        await RisingEdge(dut.clk)
