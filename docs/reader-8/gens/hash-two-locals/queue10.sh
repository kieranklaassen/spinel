#!/bin/bash
# HARD: the members not right (or not reached) in a batch on the piece and built by the base,
# packed again and run on the base and on the piece; then the twin test on raise bads;
# then the rest of the raising singles.  One job.
cd /home/claude/r8/ap
[ -d bt_hardbad ] || BT=1 nice -n 5 ruby batch.rb g_hard out/hard.bad.both.list bt_hardbad 12
nice -n 5 ruby brun.rb bt_hardbad out/hardbad.b.batch.jsonl --jobs 1 --tree b
nice -n 5 ruby brun.rb bt_hardbad out/hardbad.p.batch.jsonl --jobs 1 --tree p
echo HARDBAD DONE
nice -n 5 ruby twinb.rb g_raise g_raise_twinB out/raise.twinb.list out/raise.twinb.jsonl
echo TWINB DONE
echo QUEUE10 DONE
