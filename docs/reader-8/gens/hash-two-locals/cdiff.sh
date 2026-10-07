#!/bin/bash
# cdiff.sh file.rb [A B] : diff of the generated C of trees A and B (default b p)
f=$1; a=${2:-b}; b=${3:-p}
d=/home/claude/r8/ap/trytmp; mkdir -p $d
declare -A T=([m]=/home/claude/r8/m [b]=/home/claude/r8/ap/base-tree-ap [p]=/home/claude/r8/ap/piece-tree-ap)
for t in $a $b; do rm -f $d/cd.$$.$t.c; ${T[$t]}/bin/spinel $f -c -o $d/cd.$$.$t.c --force 2>&1 | grep -v Wrote | sed "s/^/[$t] /"; [ -f $d/cd.$$.$t.c ] && sed -i "s#/home/claude/r8/ap/[a-z]*-tree-ap/#/T/#g; s#/home/claude/r8/m/#/T/#g" $d/cd.$$.$t.c; done
if [ -f $d/cd.$$.$a.c ] && [ -f $d/cd.$$.$b.c ]; then diff $d/cd.$$.$a.c $d/cd.$$.$b.c > $d/cd.$$.diff && echo "SAME C" || { echo "C DIFFERS ($(grep -c '^[<>]' $d/cd.$$.diff) lines)"; [ -n "$SHOW" ] && head -${SHOW} $d/cd.$$.diff; }; fi
rm -f $d/cd.$$.*
