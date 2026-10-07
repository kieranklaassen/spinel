#!/bin/bash
# usage: try.sh prog.rb [tree-names: m p4 p5] ; CC=gcc|clang ; STRESS=
export LANG=C.UTF-8
f=$1; shift
declare -A T=( [m]=/home/claude/r8/m [p4]=/home/claude/r8/p175b/p4-merged-tree-175 [p5]=/home/claude/r8/p175b/p5-merged-tree-175 [n]=/home/claude/r8/p175b/m0-on-26d456ec-tree [nc]=/home/claude/r8/master-26d456ec-tree [q4]=/home/claude/r8/p175b/p4-on-26d456ec-tree [q5]=/home/claude/r8/p175b/p5-on-26d456ec-tree )
cc=${CC:-gcc}
echo "--- ruby"; timeout 10 ruby --enable-frozen-string-literal $f 2>&1 | grep -v "warning: redefining" ; echo "[exit ${PIPESTATUS[0]}]"
for t in "$@"; do
  out=/home/claude/r8/p175b/scratch/try.$$.$t
  echo "--- $t ($cc)"
  if nice -n 10 ${T[$t]}/bin/spinel $f -o $out --cc=$cc $EXTRA > $out.log 2>&1; then
    SPINEL_GC_STRESS=$STRESS timeout 10 $out 2>&1 | head -40; echo "[exit ${PIPESTATUS[0]}]"
  else
    echo "NOT BUILT:"; grep -m3 -i "error\|refus\|unsupported\|cannot" $out.log | cut -c1-300
  fi
  rm -f $out $out.log
done
