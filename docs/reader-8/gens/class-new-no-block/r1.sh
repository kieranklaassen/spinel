#!/bin/bash
# after the restart, lane 1 (one job): cident on M26, checks on the tip, the two cident runs on M84, checks on c1
cd /home/claude/r8/p219
export LANG=C.UTF-8
step() { echo "r-lane1 $1 $(date +%T)" >> out/q.log; }
step "start"
(cd tip-on-26d456ec-219 && CIDENT_JOBS=1 nice -n 5 make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116 > ../out/cident-tip26.txt 2>&1; echo "r-lane1 cident tip26 rc=$? $(date +%T)" >> ../out/q.log)
(cd tip-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-tip.txt 2>&1)
step "checks tip done"
(cd c1-merged-tree-219 && CIDENT_JOBS=1 nice -n 5 make cident REF=8684d54ce75ffe60dba47b754acd2104e502aaa7 > ../out/cident-c1.txt 2>&1; echo "r-lane1 cident c1 rc=$? $(date +%T)" >> ../out/q.log)
(cd tip-merged-tree-219 && CIDENT_JOBS=1 nice -n 5 make cident REF=6af6ed2187e63509131d4d9f32c7bacf7f048ff4 > ../out/cident-tip.txt 2>&1; echo "r-lane1 cident tip rc=$? $(date +%T)" >> ../out/q.log)
(cd c1-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-c1.txt 2>&1)
step "checks c1 done"
