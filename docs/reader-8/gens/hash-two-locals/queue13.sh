#!/bin/bash
# USE: the members not right or not reached in a batch on the piece.  Those the base builds: packed again
# (8 a batch) and run on the base and on the piece.  Those the base refuses: packed again, piece only.
# Then the 22 programs CRuby exits non-zero on, alone, on base and piece.
cd /home/claude/r8/ap
[ -d bt_usebad ] || BT=1 nice -n 5 ruby batch.rb g_use out/use.bad.both.list bt_usebad 8
nice -n 5 ruby brun.rb bt_usebad out/xusebad.b.batch.jsonl --jobs 1 --tree b
nice -n 5 ruby brun.rb bt_usebad out/xusebad.p.batch.jsonl --jobs 1 --tree p
echo USEBAD BOTH DONE
[ -d bt_usebadref ] || BT=1 nice -n 5 ruby batch.rb g_use out/use.bad.ref.list bt_usebadref 8
nice -n 5 ruby brun.rb bt_usebadref out/use.badref.batch.jsonl --jobs 1 --tree p
echo USEBAD REF DONE
nice -n 5 ruby harness.rb g_use out/use.alone.jsonl --trees b,p --jobs 1 --list bt_use/_alone.list
echo QUEUE13 DONE
