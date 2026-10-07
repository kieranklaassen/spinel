#!/bin/bash
# lane 2, last: a thin sample of every group of the two families not run yet (one job)
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
H="nice -n 5 ruby h219.rb"
step() { echo "r-lane2 $1 $(date +%T)" >> out/q.log; }
$H fam1/prog out/f1g.jsonl --trees m,c1 --skip-same --jobs 1 --ccs gcc --only '^(state|state_nosuper|method|blockform|five_levels|exception_parent|builtin_parent|module_included|ask_module|reopened_std|first_struct|ask_builtin_parent|two_ns_rev|ns_builtin_leaf)__raise_class__array_push__(is_a|when|instance_of)$' 2>> out/f1g.log
step "f1g sample of the unrun groups done"
$H fam2/prog out/f2g.jsonl --trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 1 --ccs gcc --only '^(e_in_module|e_user_par|e_after_code|e_first_struct|e_in_class|e_nested|e_par_init|e_par_ivar|e_par_meth|e_siblings|e_top_arg|e_top_exc)__(r_std|q_isa_own)$|^(p_abstract|p_arr_sub|p_basic|p_cmp|p_in_mod|p_inherited|p_kw_struct|p_object|p_req_arg|p_two)__(is_a|hi|sub_kw)$|^b_.*__r_parent$' 2>> out/f2g.log
step "f2g sample of the unrun groups done"
