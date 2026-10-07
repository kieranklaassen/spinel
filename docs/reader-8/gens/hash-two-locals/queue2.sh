#!/bin/bash
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_raise out/raise.twref.jsonl --trees b,p --jobs 1 --list out/raise.tw_refused.list
echo QUEUE2 DONE
