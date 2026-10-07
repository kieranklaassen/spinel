#!/bin/bash
# HARD family: C of both trees, then batches on the piece; then the raising singles of raise.  One job.
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_hard out/hard.c.jsonl --trees b,p --conly --jobs 1
ruby stage.rb out/hard.c.jsonl out/hard > out/hard.stage.txt
cat out/hard.base_REFUSED_piece_builds.list out/hard.both_build_C_differs.list 2>/dev/null | sort > out/hard.changed.list
[ -d bt_hard ] || BT=1 nice -n 5 ruby batch.rb g_hard out/hard.changed.list bt_hard 30
nice -n 5 ruby brun.rb bt_hard out/hard.batch.jsonl --jobs 1 --tree p
nice -n 5 ruby harness.rb g_raise out/raise.alone.jsonl --trees b,p --jobs 1 --list out/raise.prio.alone.list
echo QUEUE7 DONE
