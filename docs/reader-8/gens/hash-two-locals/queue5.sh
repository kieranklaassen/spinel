#!/bin/bash
# hold (every 2nd changed program) and core (all changed), piece only, batches.  One job.
cd /home/claude/r8/ap
cat out/hold.base_REFUSED_piece_builds.list out/hold.both_build_C_differs.list | sort | awk 'NR % 2 == 1' > out/hold.sample.list
cat out/core.base_REFUSED_piece_builds.list out/core.both_build_C_differs.list | sort > out/core.sample.list
for fam in hold core; do
  [ -d bt_$fam ] || BT=1 nice -n 5 ruby batch.rb g_$fam out/$fam.sample.list bt_$fam 50
  nice -n 5 ruby brun.rb bt_$fam out/$fam.batch.jsonl --jobs 1 --tree p
done
echo QUEUE5 DONE
