#!/bin/bash
cd $PROJECT_ROOT/tb
verible-verilog-format --inplace --assignment_statement_alignment preserve rtl/*.sv