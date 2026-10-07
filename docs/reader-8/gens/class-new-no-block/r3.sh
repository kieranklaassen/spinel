#!/bin/bash
# after the restart, lane 2 continued (one job): family 2 part C1, the builder's 58
cd /home/claude/r8/p219
export LANG=C.UTF-8
H="nice -n 5 ruby h219.rb"
F2="--trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 1 --ccs gcc"
step() { echo "r-lane2 $1 $(date +%T)" >> out/q.log; }
step "names build and runtime-name scan done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(p_user|p_bare|e_chain2)' 2>> out/f2g.log
step "f2g part C1 done"
$H bk58/prog out/bk58.jsonl --trees m,tip --twin bk58/twin --twin-tree m --piece tip --jobs 1 --ccs gcc 2> out/bk58.log
step "bk58 done"
