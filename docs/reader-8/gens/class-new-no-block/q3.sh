#!/bin/bash
# queue 3 (replaces queues 1 and 2 after the new-master build): the coordinator's asks first.
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
echo "q3 start $(date +%T)" >> out/q.log
H="nice -n 5 ruby h219.rb"
F2="--trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 2 --ccs gcc"
step() { echo "$1 $(date +%T)" >> out/q.log; }
[ -x tip-on-26d456ec-219/bin/spinel ] && nice -n 5 ./runtests26.sh > out/tests26.txt 2>&1
step "tests26 done"
$H bk13/prog out/bk13.jsonl --trees m,c1,tip --twin bk13/twin --twin-tree m --piece tip --jobs 2 2> out/bk13.log
step "bk13 done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(pos_|pre_|nm_|scu_|bp_|refl_|left_)' 2>> out/f2g.log
step "f2g part A done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_top_std)' 2>> out/f2g.log
step "f2g part B done"
(cd tip-on-26d456ec-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116 > ../out/cident-tip26.txt 2>&1; echo "cident tip26 $? $(date +%T)" >> ../out/q.log)
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 2 --ccs gcc --only '^(plain|nonexc|override_isa|override_eqq|state|method|two_ns|in_class)__' 2> out/f1g.log
step "f1g part A done"
(cd c1-merged-tree-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=8684d54ce75ffe60dba47b754acd2104e502aaa7 > ../out/cident-c1.txt 2>&1; echo "cident c1 $? $(date +%T)" >> ../out/q.log)
(cd tip-merged-tree-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=6af6ed2187e63509131d4d9f32c7bacf7f048ff4 > ../out/cident-tip.txt 2>&1; echo "cident tip $? $(date +%T)" >> ../out/q.log)
(cd tip-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-tip.txt 2>&1)
step "checks tip done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_in_module|e_user_par|e_chain2|p_user|p_bare|p_inherited|p_cmp|b_.*__r_parent)' 2>> out/f2g.log
step "f2g part C done"
nice -n 5 ruby corpus.rb corpus/list.txt out/corpus.tsv 2> out/corpus.log
step "corpus done"
(cd c1-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-c1.txt 2>&1)
step "checks c1 done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_par_meth|e_in_class|e_first_struct|e_top_exc|p_req_arg)' 2>> out/f2g.log
step "f2g part D done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 2 --ccs gcc 2>> out/f1g.log
step "f1g rest done"
