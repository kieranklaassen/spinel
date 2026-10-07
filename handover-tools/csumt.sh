#!/bin/bash
# csumt.sh TREE DIR OUT [SECONDS]: as csum.sh, each compile under a time limit (default 60 s);
# a compile that does not end is written TIMEOUT. A second column gives the seconds taken.
tree=$1; dir=$2; out=$3; lim=${4:-60}
cd $dir && for f in *.rb; do s=$(date +%s.%N); c=$(timeout $lim $tree/bin/spinel -S $f 2>&1 | sed "s|$tree|TREE|g" | md5sum | cut -d' ' -f1); [ ${PIPESTATUS[0]} = 124 ] && c=TIMEOUT; e=$(date +%s.%N); printf '%s\t%s\t%.2f\n' "$f" "$c" "$(echo "$e - $s" | bc)"; done > $out
