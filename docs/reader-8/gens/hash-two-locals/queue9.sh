#!/bin/bash
# HARD: the members not right in a batch, alone, on base and piece; then the twin test on raise bads; then the rest of the raising singles.
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_hard out/hard.single.jsonl --trees b,p --jobs 1 --list out/hard.bad.list
echo HARD SINGLES DONE
nice -n 5 ruby twinb.rb g_raise g_raise_twinB out/raise.prio.bad.list out/raise.twinb.jsonl
echo TWINB DONE
nice -n 5 ruby harness.rb g_raise out/raise.alone.jsonl --trees b,p --jobs 1 --list out/raise.prio.alone.list
echo QUEUE9 DONE
