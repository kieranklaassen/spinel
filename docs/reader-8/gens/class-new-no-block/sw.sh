#!/bin/bash
# wait for the new-master build (make pid $1) to end, stop queue 1 (bash pid $2) by pid, start queue 3
cd /home/claude/r8/p219
tail --pid=$1 -f /dev/null 2>/dev/null
kids=$(ps -o pid= --ppid $2)
kill $2 2>/dev/null
for k in $kids; do
  gk=$(ps -o pid= --ppid $k)
  kill $k 2>/dev/null
  for g in $gk; do kill $g 2>/dev/null; done
done
echo "tip26 build ended, queue 1 stopped $(date +%T)" >> out/q.log
exec ./q3.sh 1
