#!/bin/bash
# costc.sh SPINEL LABEL CC name... : instructions of each program built by SPINEL
S=/tmp/claude-0/-home-claude-spinel/5de671f4-ddd3-5c81-af9a-8360b9cef1ce/scratchpad
sp=$1; t=$2; cc=$3; shift 3
for n in "$@"; do
  $sp --cc=$cc $S/cp/costin/$n.rb -o $S/in/costbin.$n.$t.$cc >/dev/null 2>&1 || { echo "$t $cc $n NOBUILD"; continue; }
  ir=$(valgrind --tool=callgrind --callgrind-out-file=/dev/null $S/in/costbin.$n.$t.$cc 2>&1 | grep -oE 'Collected : [0-9]+' | grep -oE '[0-9]+')
  echo "$t $cc $n $ir"
done
