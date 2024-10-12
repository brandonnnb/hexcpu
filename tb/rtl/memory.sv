// Simple 256B memory module
module memory
  import cpu_pkg::*;
(
  // Clock & Reset
  input wire i_clk,
  input wire i_rst,

  // Memory interface
  output memory_data_t    o_mem_rd_data,
  output wire             o_mem_rd_valid,
  input  memory_data_t    i_mem_wr_data,
  input  wire             i_mem_valid,
  output wire             o_mem_ready,
  input  memory_address_t i_mem_addr,
  input  memory_mode_t    i_mem_mode
);

memory_data_t memory_array_q [(1 << MEMORY_ADDR_WIDTH)-1:0];

// TODO: Add a memory


endmodule
