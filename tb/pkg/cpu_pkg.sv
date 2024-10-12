package cpu_pkg;

  localparam int MEMORY_ADDR_WIDTH = 8;
  localparam int INSTRN_ADDR_WIDTH = 8;
  localparam int MEMORY_DATA_WIDTH = 8;
  localparam int CPU_WORD_WIDTH = 8;

  typedef enum logic [2:0] {
    BLOCKED_INSTRN_READ,
    BLOCKED_MEMORY_READ,
    BLOCKED_MEMORY_WRITE,
    EXECUTE,
    WRITEBACK
  } cpu_state_t;

  typedef enum logic {
    READ,
    WRITE
  } memory_mode_t;

  typedef enum logic[1:0] {
    IMMEDIATE,
    AREG_RELATIVE,
    BREG_RELATIVE
  } memory_addr_mode_t;

  typedef enum logic[1:0] {
    INCREMENT,
    PC_RELATIVE,
    BREG_ABSOLUTE
  } branch_mode_t;

  typedef logic [MEMORY_ADDR_WIDTH-1:0] memory_address_t;
  typedef logic [MEMORY_DATA_WIDTH-1:0] memory_data_t;

  typedef enum logic [3:0] {
    LDAM = 4'h0,
    LDBM = 4'h1,
    STAM = 4'h2,
    LDAC = 4'h3,
    LDBC = 4'h4,
    LDAP = 4'h5,
    LDAI = 4'h6,
    LDBI = 4'h7,
    STAI = 4'h8,
    BR   = 4'h9,
    BRZ  = 4'hA,
    BRN  = 4'hB,
    BRB  = 4'hC,
    ADD  = 4'hD,
    SUB  = 4'hE,
    PFIX = 4'hF
  } opcode_t;

  typedef struct packed {
    opcode_t    opcode;
    logic [3:0] operand;
  } instruction_t;

  /* verilator lint_off UNUSEDPARAM */
  localparam int INSTRN_DATA_WIDTH = $bits(instruction_t);
  /* verilator lint_on UNUSEDPARAM */

endpackage
