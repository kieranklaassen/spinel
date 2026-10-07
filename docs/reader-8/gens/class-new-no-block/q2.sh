#!/bin/bash
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
echo "q2 start $(date +%T)" >> out/q.log
nice -n 5 ruby h219.rb bk13/prog out/bk13.jsonl --trees m,c1,tip --twin bk13/twin --twin-tree m --piece tip --jobs 2 2> out/bk13.log
echo "bk13 done $(date +%T)" >> out/q.log
nice -n 5 ./runtests26.sh > out/tests26.txt 2>&1
echo "tests26 done $(date +%T)" >> out/q.log
nice -n 5 ruby h219.rb fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 2 --ccs gcc --only '^(plain|state|method|two_ns|ns_builtin_leaf|override_isa|override_eqq|blockform|exception_parent|nonexc|ask_module|module_included|in_class)__' 2> out/f1g.log
echo "f1g done $(date +%T)" >> out/q.log
(cd c1-merged-tree-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=8684d54ce75ffe60dba47b754acd2104e502aaa7 > ../out/cident-c1.txt 2>&1; echo "cident c1 $? $(date +%T)" >> ../out/q.log)
(cd tip-merged-tree-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=6af6ed2187e63509131d4d9f32c7bacf7f048ff4 > ../out/cident-tip.txt 2>&1; echo "cident tip $? $(date +%T)" >> ../out/q.log)
nice -n 5 ruby corpus.rb corpus/list.txt out/corpus.tsv 2> out/corpus.log
echo "corpus done $(date +%T)" >> out/q.log
(cd tip-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-tip.txt 2>&1)
(cd c1-merged-tree-219 && { nice -n 5 tools/refusals.sh; echo "refusals.sh rc=$?"; nice -n 5 make reject-test; echo "reject-test rc=$?"; nice -n 5 make share-strings-test; echo "share-strings-test rc=$?"; } > ../out/checks-c1.txt 2>&1)
echo "checks done $(date +%T)" >> out/q.log
