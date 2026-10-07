#!/bin/bash
# EMPTY family on master and on the piece, batches.  One job.
cd /home/claude/r8/ap
[ -d bt_empty ] || BT=1 nice -n 5 ruby batch.rb g_empty out/empty.all.list bt_empty 45
nice -n 5 ruby brun.rb bt_empty out/empty.m.batch.jsonl --jobs 1 --tree m
nice -n 5 ruby brun.rb bt_empty out/empty.p.batch.jsonl --jobs 1 --tree p
echo QUEUE8 DONE
