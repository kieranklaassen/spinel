#!/bin/bash
# after the restart, lane 2 (one job): family 1 part A (resumes), names build, family 2 part C1, the builder's 58
cd /home/claude/r8/p219
export LANG=C.UTF-8
H="nice -n 5 ruby h219.rb"
F2="--trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 1 --ccs gcc"
step() { echo "r-lane2 $1 $(date +%T)" >> out/q.log; }
step "start"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc --only '^(nonexc|override_isa|override_eqq|two_ns|in_class)__|^plain__.*__(is_a|when|instance_of|kind_of|class_name|is_a_builtin|is_a_other|when_list|when_builtin_first|not_and_or|if_then_deep|local_first)$' 2> out/f1g.log
step "f1g part A done"
(cd names && nice -n 5 ruby build.rb 2> build.log)
step "names build done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(p_user|p_bare|e_chain2)' 2>> out/f2g.log
step "f2g part C1 done"
$H bk58/prog out/bk58.jsonl --trees m,tip --twin bk58/twin --twin-tree m --piece tip --jobs 1 --ccs gcc 2> out/bk58.log
step "bk58 done"
