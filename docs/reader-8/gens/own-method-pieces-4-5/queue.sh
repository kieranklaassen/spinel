#!/bin/bash
# runs the lines of queue.txt one after another; lines may be appended while it runs
cd /home/claude/r8/p175b
export LANG=C.UTF-8
n=0
while :; do
  n=$((n+1))
  line=$(sed -n "${n}p" queue.txt)
  [ -z "$line" ] && break
  echo "[$(date +%H:%M:%S)] start $n: $line" >> queue.log
  bash -c "$line" >> queue.log 2>&1
  echo "[$(date +%H:%M:%S)] done $n (exit $?)" >> queue.log
done
echo "[$(date +%H:%M:%S)] queue empty after $((n-1))" >> queue.log
