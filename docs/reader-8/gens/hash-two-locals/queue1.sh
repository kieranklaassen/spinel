#!/bin/bash
cd /home/claude/r8/ap
nice -n 5 ruby harness.rb g_raise out/raise.ref.jsonl --trees b,p --jobs 1 --list out/raise.base_REFUSED_piece_builds.list
nice -n 5 ruby harness.rb g_hold out/hold.ref.jsonl --trees b,p --jobs 1 --list out/hold.base_REFUSED_piece_builds.list
nice -n 5 ruby harness.rb g_core out/core.ref.jsonl --trees b,p --jobs 1 --list out/core.base_REFUSED_piece_builds.list
echo QUEUE1 DONE
