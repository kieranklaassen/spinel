#!/bin/bash
# lane 2b (one job) after family 2 part B (harness pid $1)
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
H="nice -n 5 ruby h219.rb"
F2="--trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 1 --ccs gcc"
step() { echo "lane2 $1 $(date +%T)" >> out/q.log; }
step "f2g part B done"
ruby flagged.rb out/f2g.jsonl c1 tip > out/flagged-f2g.txt
re="^($(paste -sd'|' out/flagged-f2g.txt))\$"
$H fam2/prog out/f2g-clang.jsonl --trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --jobs 1 --ccs clang --only "$re" 2> out/f2g-clang.log
step "clang pass of the flagged programs done"
nice -n 5 ruby twinrun.rb fam2 $(grep -v '^nm_' out/flagged-f2g.txt | while read n; do [ -f fam2/twin/$n.rb ] && echo $n; done) > out/twinrun-f2g.txt 2>&1
nice -n 5 ruby twinrun.rb fam3 sp_class_new_redefined sp_first_class_copy sp_first_class_isa sp_inherited_hook sp_later_def_user_parent sp_require_in_method sp_first_class_new sp_later_def_smallest sp_subclasses_before sp_const_get_dyn_before >> out/twinrun-f2g.txt 2>&1
step "twins run on their own done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc --only '^(nonexc|override_isa|override_eqq|two_ns|in_class)__|^plain__.*__(is_a|when|instance_of|kind_of|class_name|is_a_builtin|is_a_other|when_list|when_builtin_first|not_and_or|if_then_deep|local_first)$' 2> out/f1g.log
step "f1g part A done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(p_user|p_bare|e_chain2)' 2>> out/f2g.log
step "f2g part C1 done"
(cd names && nice -n 5 ruby build.rb 2> build.log)
step "names build done"
$H bk58/prog out/bk58.jsonl --trees m,tip --twin bk58/twin --twin-tree m --piece tip --jobs 1 --ccs gcc 2> out/bk58.log
step "bk58 done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc --only '^(plain|state|method)__' 2>> out/f1g.log
step "f1g part A2 done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_in_module|e_user_par|p_inherited|p_cmp|b_.*__r_parent)' 2>> out/f2g.log
step "f2g part C2 done"
$H fam2/prog out/f2g.jsonl $F2 --only '^(e_par_meth|e_in_class|e_first_struct|e_top_exc|p_req_arg)' 2>> out/f2g.log
step "f2g part D done"
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc 2>> out/f1g.log
step "f1g rest done"
