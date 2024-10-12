import os
from time import sleep
from rich.console import Console
from rich.table import Table
from enum import Enum

# Constants
MEMORY_SIZE = 256
MAX_UNSIGNED_8_BIT = 127
SPEED = 1
PRINT_INTERVAL = 100

# Opcodes class
class Opcode(Enum):
    LDAM = 0x0  # Load A register from memory
    LDBM = 0x1  # Load B register from memory
    STAM = 0x2  # Store A register to memory
    LDAC = 0x3  # Load A register with constant
    LDBC = 0x4  # Load B register with constant
    LDAP = 0x5  # Load A register with PC-relative address
    LDAI = 0x6  # Load A register indirect
    LDBI = 0x7  # Load B register indirect
    STAI = 0x8  # Store A register indirect
    BR = 0x9   # Unconditional branch
    BRZ = 0xA  # Branch if zero
    BRN = 0xB  # Branch if negative
    BRB = 0xC  # Branch to B register
    ADD = 0xD  # Add B register to A register
    SUB = 0xE  # Subtract B register from A register
    PFIX = 0xF  # Prefix instruction

class HexCPU:
    def __init__(self):
        self.mem = [0] * MEMORY_SIZE
        self.pc = 0
        self.areg = 0
        self.breg = 0
        self.oreg = 0
        self.inst = 0
        self.running = True
        self.console = Console()
        self.instruction_log = []
        self.opcode_handlers = {
            Opcode.LDAM: self.load_a_from_mem,
            Opcode.LDBM: self.load_b_from_mem,
            Opcode.STAM: self.store_a_to_mem,
            Opcode.LDAC: self.load_a_with_constant,
            Opcode.LDBC: self.load_b_with_constant,
            Opcode.LDAP: self.load_a_pc_relative,
            Opcode.LDAI: self.load_a_indirect,
            Opcode.LDBI: self.load_b_indirect,
            Opcode.STAI: self.store_a_indirect,
            Opcode.BR: self.unconditional_branch,
            Opcode.BRZ: self.branch_if_zero,
            Opcode.BRN: self.branch_if_negative,
            Opcode.BRB: self.branch_to_b,
            Opcode.ADD: self.add_b_to_a,
            Opcode.SUB: self.subtract_b_from_a,
            Opcode.PFIX: self.prefix_instruction,
        }

    def load_program_from_file(self, filename=f"{os.environ.get('PROJECT_ROOT')}/tb/model/a.bin"):
        try:
            with open(filename, 'r') as codefile:
                codefile_iter = iter(codefile.read())
                self.load_program_from_iter(codefile_iter)
        except FileNotFoundError:
            print(f"Error: '{filename}' file not found.")
            exit(1)

    def load_program_from_binary(self, binary_data):
        codefile_iter = iter(binary_data)
        self.load_program_from_iter(codefile_iter)

    def load_program_from_iter(self, codefile_iter):
        i = 0
        byte = self.getbyte(codefile_iter)
        while byte is not None:
            self.mem[i] = byte
            i += 1
            byte = self.getbyte(codefile_iter)

    def getbyte(self, codefile_iter):
        high = self.gethex(codefile_iter)
        if high is None:
            return None
        low = self.gethex(codefile_iter)
        if low is None:
            return None
        return (high << 4) | low

    def gethex(self, codefile_iter):
        for ch in codefile_iter:
            if ch in (' ', '\n'):
                continue
            elif '0' <= ch <= '9' or 'A' <= ch <= 'F':
                return int(ch, 16)
            else:
                raise ValueError(f"Invalid hex character: {ch}")
        return None

    def step(self, print=False):
        self.fetch()
        self.decode_and_execute()
        if print:
            self.print_state()

    def reset(self):
        self.running = True
        self.oreg = 0
        self.pc = 0
        self.areg = 0
        self.breg = 0
        self.mem = 0

    def run(self):
        self.running = True
        self.oreg = 0
        self.pc = 0

        self.steps=0
        while self.running:
            self.step(print=True)
            self.steps+=1
            if self.steps % PRINT_INTERVAL == 0:
                self.print_state()
            sleep(1/SPEED)

    def fetch(self):
        self.inst = self.mem[self.pc]
        self.pc = (self.pc + 1) % MEMORY_SIZE
        self.oreg = (self.oreg | (self.inst & 0xF)) % MEMORY_SIZE

    def decode_and_execute(self):
        opcode = Opcode((self.inst >> 4) & 0xF)
        handler = self.opcode_handlers.get(opcode, self.unknown_opcode)
        handler()

    def load_a_from_mem(self):
        self.areg = self.mem[self.oreg]
        self.oreg = 0

    def load_b_from_mem(self):
        self.breg = self.mem[self.oreg]
        self.oreg = 0

    def store_a_to_mem(self):
        self.mem[self.oreg] = self.areg
        self.oreg = 0

    def load_a_with_constant(self):
        self.areg = self.oreg
        self.oreg = 0

    def load_b_with_constant(self):
        self.breg = self.oreg
        self.oreg = 0

    def load_a_pc_relative(self):
        self.areg = (self.pc + self.oreg) % MEMORY_SIZE
        self.oreg = 0

    def load_a_indirect(self):
        self.areg = self.mem[(self.areg + self.oreg) % MEMORY_SIZE]
        self.oreg = 0

    def load_b_indirect(self):
        self.breg = self.mem[(self.breg + self.oreg) % MEMORY_SIZE]
        self.oreg = 0

    def store_a_indirect(self):
        self.mem[(self.breg + self.oreg) % MEMORY_SIZE] = self.areg
        self.oreg = 0

    def unconditional_branch(self):
        if self.oreg == 0xFE:
            self.stop()
        else:
            self.pc = (self.pc + self.oreg) % MEMORY_SIZE
        self.oreg = 0

    def branch_if_zero(self):
        if self.areg == 0:
            self.pc = (self.pc + self.oreg) % MEMORY_SIZE
        self.oreg = 0

    def branch_if_negative(self):
        if self.areg & 0x80:  # Check if the highest bit is set
            self.pc = (self.pc + self.oreg) % MEMORY_SIZE
        self.oreg = 0

    def branch_to_b(self):
        self.pc = self.breg
        self.oreg = 0

    def add_b_to_a(self):
        self.areg = (self.areg + self.breg) % MEMORY_SIZE
        self.oreg = 0

    def subtract_b_from_a(self):
        self.areg = (self.areg - self.breg) % MEMORY_SIZE
        self.oreg = 0

    def prefix_instruction(self):
        self.oreg = ((self.oreg << 4) % MEMORY_SIZE)

    def unknown_opcode(self):
        print(f"Unknown opcode: {(self.inst >> 4) & 0xF}")
        self.running = False

    def stop(self):
        print(f"\nareg = {self.areg}")
        self.running = False

    def print_state(self):
        opcode = Opcode((self.inst >> 4) & 0xF)
        opcode_name = opcode.name if opcode else f"Unknown ({opcode})"

        table = Table(title="Internal State")

        table.add_column("Register", justify="right", style="cyan", no_wrap=True)
        table.add_column("Value", style="magenta")

        table.add_row("PC", f"{self.pc}")
        table.add_row("A Register", f"{self.areg}")
        table.add_row("B Register", f"{self.breg}")
        table.add_row("O Register", f"{self.oreg}")
        table.add_row("Instruction", f"{self.inst} ({opcode_name})")
        table.add_row("Memory: ", f"{[hex(x) for x in self.mem]}")
        self.console.print(table)

if __name__ == '__main__':
    cpu = HexCPU()
    cpu.load_program_from_file()
    cpu.run()