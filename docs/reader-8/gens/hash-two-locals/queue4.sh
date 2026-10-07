#!/bin/bash
cd /home/claude/r8/ap
nice -n 5 ruby brun.rb bt_raise_prio out/raise.prio.batch.jsonl --jobs 1 --tree p
echo QUEUE4 DONE
