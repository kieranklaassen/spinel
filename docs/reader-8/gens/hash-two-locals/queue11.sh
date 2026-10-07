#!/bin/bash
# HARD: the rule (a) candidates and the members no batch reached, alone, on master, base and piece;
# then queue6 (use, copy, raise rest, empty).
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_hard out/hard.single2.jsonl --trees m,b,p --jobs 1 --list out/hard.single2.list
echo HARD SINGLES DONE
./queue6.sh
