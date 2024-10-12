#!/bin/bash
cd $PROJECT_ROOT/tb
svlint pkg/*.sv rtl/*.sv
verilator --lint-only -Wall -I pkg/*.sv rtl/*.sv