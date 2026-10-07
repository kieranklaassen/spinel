#!/bin/bash
# try.sh file.rb : CRuby, master and the piece (gcc; CC=clang for clang; SHARE=1; STRESS=n)
export LANG=C.UTF-8
[ -n "$SHARE" ] && SH=--share-strings
CCX=${CC:-gcc}
f=$1
T=/home/claude/r8/p220/tmp
echo "--- ruby"; ruby --enable-frozen-string-literal $f 2>&1 | head -${N:-14}
for t in m p; do
  if [ $t = m ]; then d=/home/claude/r8/m; else d=/home/claude/r8/p220/piece-tree-220; fi
  echo "--- $t"; $d/bin/spinel $SH $f -o $T/try.$$.$t --cc=$CCX 2>&1 | grep -v -- '->' | grep -E 'error|refus|Error|cannot|unsupported|warning: ' | head -4
  [ -x $T/try.$$.$t ] && { SPINEL_GC_STRESS=$STRESS timeout 10 $T/try.$$.$t 2>&1 | head -${N:-14}; echo "[exit ${PIPESTATUS[0]}]"; rm -f $T/try.$$.$t; }
done
