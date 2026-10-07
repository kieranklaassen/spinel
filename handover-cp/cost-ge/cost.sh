#!/bin/bash
# cost.sh TREE CC name... : instructions (callgrind) of each program
S=/tmp/claude-0/-home-claude-spinel/5de671f4-ddd3-5c81-af9a-8360b9cef1ce/scratchpad; D=$S/fx/cost-sf
t=$1; cc=$2; shift 2
for n in "$@"; do
  /home/claude/wt/$t/spinel --cc=$cc $D/$n.rb -o $D/$n.$t.$cc >/dev/null 2>&1 || { echo "$t $cc $n NOBUILD"; continue; }
  out=$($D/$n.$t.$cc 2>&1 | tr '\n' ' ')
  ir=$(valgrind --tool=callgrind --callgrind-out-file=/dev/null $D/$n.$t.$cc 2>&1 | grep -oE 'Collected : [0-9]+' | grep -oE '[0-9]+')
  echo "$t $cc $n $ir out=$out"
done
