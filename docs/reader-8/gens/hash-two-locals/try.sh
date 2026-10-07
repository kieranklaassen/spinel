#!/bin/bash
# try.sh file.rb [trees...] : CRuby and each tree's answer (gcc; CC=clang for clang; STRESS=n)
f=$1; shift; trees=${@:-m b p}
d=/home/claude/r8/ap/trytmp; mkdir -p $d
declare -A T=([m]=/home/claude/r8/m [b]=/home/claude/r8/ap/base-tree-ap [p]=/home/claude/r8/ap/piece-tree-ap)
echo "--- ruby"; ruby --enable-frozen-string-literal $f 2>&1 | head -${LINES_MAX:-14}
for t in $trees; do
  o=$d/try.$$.$t; rm -f $o
  echo "--- $t $(SP_FIXPOINT_LOG=1 ${T[$t]}/bin/spinel $f -o $o --cc=${CC:-gcc} 2>&1 | grep -v -- '->' | head -4 | tr '\n' ' ')"
  [ -x $o ] && { if [ -n "$STRESS" ]; then export SPINEL_GC_STRESS=$STRESS; fi; timeout 10 $o 2>&1 | head -${LINES_MAX:-14}; echo "[exit ${PIPESTATUS[0]}]"; rm -f $o; }
done
