#!/bin/bash
# On upstream master 26d456ec1035 (plain build at /home/claude/r8/master-26d456ec-tree) and on the
# piece merged into it (/home/claude/r8/ap/piece-tip-tree-26d456ec, tree b54a75ff166f):
# the piece's own test, then my rule (a) and rule (b) programs at six rows, then one cident.
cd /home/claude/r8/ap
N=/home/claude/r8/master-26d456ec-tree/bin/spinel
T=/home/claude/r8/ap/piece-tip-tree-26d456ec/bin/spinel
t=piece-tip-tree-26d456ec/test/hash_local_alias_widened.rb
echo "== own test, new master:"; $N $t -o trytmp/tip.own.n 2>&1 | grep -v -- '->' | head -2; [ -x trytmp/tip.own.n ] && echo "BUILT on the new master"
echo "== own test, tip piece:"
for cc in gcc clang; do
  $T $t -o trytmp/tip.own.$cc --cc=$cc 2>&1 | grep -v -- '->' | head -2
  for s in "" 1 2; do
    if [ -n "$s" ]; then SPINEL_GC_STRESS=$s trytmp/tip.own.$cc > trytmp/tip.own.out 2>&1; rc=$?; else trytmp/tip.own.$cc > trytmp/tip.own.out 2>&1; rc=$?; fi
    cmp -s trytmp/tip.own.out $t.expected && echo "$cc stress=${s:-unset}: EQUAL to .expected (exit $rc)" || echo "$cc stress=${s:-unset}: DIFFERS (exit $rc)"
  done
done
ruby --enable-frozen-string-literal $t | cmp -s - $t.expected && echo "CRuby 3.3.6 output EQUAL to .expected"
echo "== tip set"
nice -n 5 ruby harness.rb tipset out/tipset.jsonl --trees n,t --jobs 1
echo TIPSET DONE
cd piece-tip-tree-26d456ec && CIDENT_JOBS=1 nice -n 5 make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116 > ../out/tip.cident.log 2>&1; echo "cident exit $?"; tail -15 ../out/tip.cident.log
echo TIPRUN DONE
