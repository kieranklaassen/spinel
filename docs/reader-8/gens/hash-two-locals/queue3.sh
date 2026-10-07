#!/bin/bash
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_raise out/raise.alone.jsonl --trees b,p --jobs 1 --list out/raise.prio.alone.list
echo QUEUE3 DONE
