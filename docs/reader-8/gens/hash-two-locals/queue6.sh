#!/bin/bash
# use (one program per kind x widening x use where both build and the C differs; a third of the
# groups the base refuses), copy (every 6th), the rest of raise (every 6th), then the EMPTY
# family on master and on the piece.  Piece only, batches.  One job.
cd /home/claude/r8/ap
cat out/copy.base_REFUSED_piece_builds.list out/copy.both_build_C_differs.list | sort | awk 'NR % 6 == 2' > out/copy.sample.list
cat out/raise.tw_equal.list out/raise.both_build_C_differs.list | sort | awk 'NR % 6 == 2' > out/raise.rest.sample.list
[ -d bt_use ] || BT=1 nice -n 5 ruby batch.rb g_use out/use.sample.list bt_use 60
nice -n 5 ruby brun.rb bt_use out/use.batch.jsonl --jobs 1 --tree p
[ -d bt_copy ] || BT=1 nice -n 5 ruby batch.rb g_copy out/copy.sample.list bt_copy 50
nice -n 5 ruby brun.rb bt_copy out/copy.batch.jsonl --jobs 1 --tree p
[ -d bt_raise_rest ] || BT=1 nice -n 5 ruby batch.rb g_raise out/raise.rest.sample.list bt_raise_rest 40
nice -n 5 ruby brun.rb bt_raise_rest out/raise.rest.batch.jsonl --jobs 1 --tree p
[ -d bt_empty ] || BT=1 nice -n 5 ruby batch.rb g_empty out/empty.all.list bt_empty 45
nice -n 5 ruby brun.rb bt_empty out/empty.m.batch.jsonl --jobs 1 --tree m
nice -n 5 ruby brun.rb bt_empty out/empty.p.batch.jsonl --jobs 1 --tree p
echo QUEUE6 DONE
