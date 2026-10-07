#!/bin/bash
# var.sh CC name... : build var/NAME.c against the piece's header, count instructions
S=/tmp/claude-0/-home-claude-spinel/5de671f4-ddd3-5c81-af9a-8360b9cef1ce/scratchpad; W=/home/claude/wt/p2t21
cc=$1; shift
for n in "$@"; do
  $cc -O2 -w -ffp-contract=off -falign-functions=64 -falign-loops=64 -DSP_INT_OVERFLOW_MODE_RAISE -I$W/lib -I$W/lib/regexp $S/fs/var/$n.c $W/lib/libspinel_rt.a -lm -o $S/fs/var/$n.$cc 2>$S/fs/var/$n.$cc.err || { echo "$cc $n NOBUILD $(head -c 300 $S/fs/var/$n.$cc.err)"; continue; }
  ir=$(valgrind --tool=callgrind --callgrind-out-file=/dev/null $S/fs/var/$n.$cc 2>&1 | grep -oE 'Collected : [0-9]+' | grep -oE '[0-9]+')
  echo "$cc $n $ir $(echo "scale=2; $ir/300000" | bc) $($S/fs/var/$n.$cc | tr '\n' ' ')"
done
