#!/bin/bash
# queue 1: new-master build, family 2 (gcc), tests and cident on the new master
cd /home/claude/r8/p219
export LANG=C.UTF-8
tail --pid=$1 -f /dev/null 2>/dev/null
echo "f3 done $(date +%T)" >> out/q.log
(cd tip-on-26d456ec-219 && nice -n 5 make -j2 > ../build-tip26.log 2>&1; echo "tip26 build $? $(date +%T)" >> ../out/q.log)
nice -n 5 ruby h219.rb fam2/prog out/f2g.jsonl --trees c1,tip --twin fam2/twin --twin-tree c1 --piece tip --skip-same --jobs 2 --ccs gcc --only '^(e_top_std|e_in_module|e_user_par|e_chain2|e_par_meth|e_in_class|e_first_struct|e_top_exc|p_user|p_bare|p_inherited|p_cmp|p_req_arg|pos_|pre_|nm_[A-M]|b_.*__r_parent|scu_|bp_)' 2> out/f2g.log
echo "f2g done $(date +%T)" >> out/q.log
(cd tip-on-26d456ec-219 && CIDENT_JOBS=2 nice -n 5 make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116 > ../out/cident-tip26.txt 2>&1; echo "cident tip26 $? $(date +%T)" >> ../out/q.log)
