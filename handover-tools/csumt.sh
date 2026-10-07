#!/bin/bash
# csumt.sh TREE DIR OUT [SECONDS]: as csum.sh, each compile under a time limit (default 60 s);
# a compile that does not end in it is written TIMEOUT. A third column gives the seconds taken.
tree=$1; dir=$2; out=$3; lim=${4:-60}
cd $dir && for f in *.rb; do
  s=$(date +%s.%N); timeout $lim $tree/bin/spinel -S $f > /tmp/csumt.$$ 2>&1; x=$?; e=$(date +%s.%N)
  c=$(sed "s|$tree|TREE|g" /tmp/csumt.$$ | md5sum | cut -d' ' -f1); [ $x = 124 ] && c=TIMEOUT
  printf '%s\t%s\t%.2f\n' "$f" "$c" "$(echo "$e - $s" | bc)"
done > $out; rm -f /tmp/csumt.$$
