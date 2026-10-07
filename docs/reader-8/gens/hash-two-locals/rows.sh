#!/bin/bash
# rows.sh file.rb tree : the six rows (gcc, clang x stress unset,1,2) of one tree against CRuby
f=$1; t=${2:-p}
declare -A T=([m]=/home/claude/r8/m [b]=/home/claude/r8/ap/base-tree-ap [p]=/home/claude/r8/ap/piece-tree-ap)
d=/home/claude/r8/ap/trytmp; exp=$(ruby --enable-frozen-string-literal $f 2>/dev/null); xrc=$?
for cc in gcc clang; do
  o=$d/rows.$$.$cc; rm -f $o
  msg=$(${T[$t]}/bin/spinel $f -o $o --cc=$cc 2>&1 | grep -v -- '->' | head -2 | tr '\n' ' ')
  if [ ! -x $o ]; then echo "$t $cc: NOT BUILT $msg"; continue; fi
  for s in "" 1 2; do
    if [ -n "$s" ]; then got=$(SPINEL_GC_STRESS=$s timeout 20 $o 2>$d/rows.$$.err); rc=$?; else got=$(timeout 20 $o 2>$d/rows.$$.err); rc=$?; fi
    if [ "$got" = "$exp" ] && [ $rc = $xrc ]; then echo "$t $cc stress=${s:-unset}: RIGHT (exit $rc)"; else echo "$t $cc stress=${s:-unset}: NOT RIGHT exit $rc (ruby exit $xrc): $(echo "$got" | head -${SHOWN:-3} | cat -v | cut -c1-200 | tr '\n' '|') err: $(head -1 $d/rows.$$.err | cut -c1-160)"; fi
  done
  rm -f $o
done
