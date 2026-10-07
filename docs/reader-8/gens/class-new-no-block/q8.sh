#!/bin/bash
# lane 2 (one job): the families
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
H="nice -n 5 ruby h219.rb"
F2="--trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 1 --ccs gcc"
step() { echo "lane2 $1 $(date +%T)" >> out/q.log; }
step "start (f2g part A done)"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_top_std)' 2>> out/f2g.log
step "f2g part B done"
(cd names && nice -n 5 ruby build.rb 2> build.log)
step "names build done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc --only '^(plain|nonexc|override_isa|override_eqq|state|method|two_ns|in_class)__' 2> out/f1g.log
step "f1g part A done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_in_module|e_user_par|e_chain2|p_user|p_bare|p_inherited|p_cmp|b_.*__r_parent)' 2>> out/f2g.log
step "f2g part C done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_par_meth|e_in_class|e_first_struct|e_top_exc|p_req_arg)' 2>> out/f2g.log
step "f2g part D done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc 2>> out/f1g.log
step "f1g rest done"
