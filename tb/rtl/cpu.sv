module cpu
  import cpu_pkg::*;
(
  // Clock & Reset
  input wire i_clk,
  input wire i_rst,

  // Instruction interface
  input  instruction_t    i_instrn,
  input  wire             i_instrn_valid,
  output wire             o_instrn_ready,
  output memory_address_t o_instrn_addr,
  output wire             o_instrn_addr_valid,

  // Memory interface
  input  memory_data_t    i_mem_rd_data,
  input  wire             i_mem_rd_valid,
  output memory_data_t    o_mem_wr_data,
  output wire             o_mem_valid,
  input  wire             i_mem_ready,
  output memory_address_t o_mem_addr,
  output memory_mode_t    o_mem_mode
);

  logic [INSTRN_ADDR_WIDTH-1:0] pc_d, pc_q;
  instruction_t cir_d, cir_q;

  logic signed [INSTRN_ADDR_WIDTH-1:0] mdr_d, mdr_q;

  logic signed [CPU_WORD_WIDTH-1:0] areg_d, areg_q;
  logic signed [CPU_WORD_WIDTH-1:0] breg_d, breg_q;
  logic signed [CPU_WORD_WIDTH-1:0] oreg_d, oreg_q;

  logic signed [CPU_WORD_WIDTH-1:0] pc_add_oreg;
  logic signed [CPU_WORD_WIDTH-1:0] alu_result;

  // Memory address mode flags
  memory_addr_mode_t addr_mode;

  // PC Branch mode
  branch_mode_t branch_mode;

  // Memory r/w mode flags
  logic is_mem_read_instrn, is_mem_write_instrn;

  cpu_state_t cpu_state_d, cpu_state_q;

  ////////////////////////////////////////////////////////
  // FETCH
  ////////////////////////////////////////////////////////

  assign o_instrn_ready = (cpu_state_q == BLOCKED_INSTRN_READ);

  // TODO: Sneaking suspicion we could remove i_instrn_valid mux here because of
  // clock gating below
  assign cir_d = i_instrn_valid ? i_instrn : cir_q;

  assign o_instrn_addr = pc_q;
  assign o_instrn_addr_valid = (cpu_state_q inside {WRITEBACK, BLOCKED_INSTRN_READ}) && !i_instrn_valid;

  ////////////////////////////////////////////////////////
  // DECODE
  ////////////////////////////////////////////////////////

  assign cpu_state_d = (

      // Waiting for an instruction and one arrives
      (cpu_state_q == BLOCKED_INSTRN_READ) && i_instrn_valid ? EXECUTE :

      // Executing a memory read instruction (More than 1 cycle)
      (cpu_state_q == EXECUTE) && is_mem_read_instrn         ? BLOCKED_MEMORY_READ :

      // Executing a memory write instruction (More than 1 cycle)
      (cpu_state_q == EXECUTE) && is_mem_write_instrn        ? BLOCKED_MEMORY_WRITE :

      // All other execute stages take 1 cycle
      (cpu_state_q == EXECUTE)                               ? WRITEBACK :

      // Memory read response
      (cpu_state_q == BLOCKED_MEMORY_READ) && i_mem_rd_valid ? WRITEBACK :

      // Memory write response
      (cpu_state_q == BLOCKED_MEMORY_WRITE) && i_mem_ready   ? WRITEBACK :

      // Finished updating state
      (cpu_state_q == WRITEBACK)                             ? BLOCKED_INSTRN_READ :

      /*DEFAULT*/                                              BLOCKED_INSTRN_READ
  );

  assign addr_mode = (
    cir_q.opcode inside {LDAI}       ? AREG_RELATIVE :
    cir_q.opcode inside {LDBI, STAI} ? BREG_RELATIVE :
                                       IMMEDIATE
  );

  assign branch_mode = (
    cir_q.opcode inside {BR, BRZ, BRN} ? PC_RELATIVE:
    cir_q.opcode inside {BRB}          ? BREG_ABSOLUTE:
                                         INCREMENT
  );

  assign is_mem_read_instrn = cir_q.opcode inside {LDAM, LDBM, LDAI, LDBI};
  assign is_mem_write_instrn = cir_q.opcode inside {STAM, STAI};

  ////////////////////////////////////////////////////////
  // EXECUTE
  ////////////////////////////////////////////////////////

  assign alu_result = (cir_q.opcode == ADD ? (areg_q + breg_q) :
      /* DEFAULT */ (areg_q - breg_q));

  assign areg_d = (
    cir_q.opcode inside { LDAC }       ? oreg_q :
    cir_q.opcode inside { LDAP }       ? pc_add_oreg :
    cir_q.opcode inside { LDAI, LDAM } ? mdr_q :
    cir_q.opcode inside { ADD, SUB }   ? alu_result :
    /* DEFAULT */                        areg_q
  );

  assign breg_d = (
    cir_q.opcode inside { LDBC }       ? oreg_q :
    cir_q.opcode inside { LDBI, LDBM } ? mdr_q :
    /* DEFAULT */                        breg_q
  );

  assign oreg_d = (
    cir_q.opcode inside { PFIX } ? { oreg_q[7:4], cir_q.operand } :
                                   { cir_q.operand, oreg_q[3:0] }
  );

  ////////////////////////////////////////////////////////
  // MEMORY
  ////////////////////////////////////////////////////////

  assign o_mem_addr = (
    addr_mode == IMMEDIATE     ? oreg_q          :
    addr_mode == AREG_RELATIVE ? areg_q + oreg_q :
    addr_mode == BREG_RELATIVE ? breg_q + oreg_q :
    /* UNREACHABLE */            'x
  );

  assign o_mem_mode = is_mem_read_instrn ? READ : WRITE;
  assign o_mem_valid = i_mem_ready && (cpu_state_q == BLOCKED_MEMORY_WRITE);

  assign o_mem_wr_data = areg_q;

  // Memory data register will accept any valid data.
  assign mdr_d = i_mem_rd_valid ? i_mem_rd_data : mdr_q;

  ////////////////////////////////////////////////////////
  // BRANCHING
  ////////////////////////////////////////////////////////

  assign pc_add_oreg = pc_q + oreg_q;

  assign pc_d = (
    branch_mode == INCREMENT     ? pc_q + INSTRN_ADDR_WIDTH'(1) :
    branch_mode == PC_RELATIVE   ? pc_add_oreg :
    branch_mode == BREG_ABSOLUTE ? breg_q :
    /* UNREACHABLE */              'x
  );

  ////////////////////////////////////////////////////////
  // FLOPS
  ////////////////////////////////////////////////////////

  // FSM
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      cpu_state_q <= cpu_state_t'(0);
    end else begin
      cpu_state_q <= cpu_state_d;
    end
  end

  // CIR only updates once an instruction comes in
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      cir_q <= '0;
      // TODO: Optimise to include valid?
    end else if (cpu_state_q == BLOCKED_INSTRN_READ) begin
      cir_q <= cir_d;
    end
  end

  // MDR only updates when we are pending a memory read
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      mdr_q <= '0;
      // TODO: Optimise to include valid?
    end else if (cpu_state_q == BLOCKED_MEMORY_READ) begin
      mdr_q <= mdr_d;
    end
  end

  // Registers only update during writeback phase
  always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
      pc_q   <= '0;
      areg_q <= '0;
      breg_q <= '0;
      oreg_q <= '0;
    end else if (cpu_state_q == WRITEBACK) begin
      pc_q   <= pc_d;
      areg_q <= areg_d;
      breg_q <= breg_d;
      oreg_q <= oreg_d;
    end
  end

endmodule
