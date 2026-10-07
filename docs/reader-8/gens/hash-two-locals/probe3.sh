#!/bin/bash
# probe3.sh DIR : every DIR/*.rb under CRuby, the base and the piece (gcc, stress unset);
# flags the programs where the base is right and the piece is not, and the other way round.
d=$1; T=/home/claude/r8/ap/trytmp
for f in $d/*.rb; do
  n=$(basename $f .rb)
  r=$(ruby --enable-frozen-string-literal $f 2>&1 | head -6 | tr '\n' '|' | cut -c1-160)
  for t in b p; do
    case $t in b) sp=/home/claude/r8/ap/base-tree-ap/bin/spinel;; p) sp=/home/claude/r8/ap/piece-tree-ap/bin/spinel;; esac
    o=$T/p3.$$.$t; rm -f $o
    msg=$($sp $f -o $o 2>&1 | grep -v -- '->' | head -1 | cut -c1-150)
    if [ -x $o ]; then res=$(timeout 20 $o 2>&1 | head -6 | tr '\n' '|' | cut -c1-160); else res="NOT BUILT: $msg"; fi
    eval "res_$t=\$res"; rm -f $o
  done
  flag=""
  [ "$res_b" = "$r" ] && [ "$res_p" != "$r" ] && flag="  <<<<<< base right, piece not"
  [ "$res_b" != "$r" ] && [ "$res_p" = "$r" ] && flag="  (piece right, base not)"
  [ "$res_b" != "$r" ] && [ "$res_p" != "$r" ] && [ "$res_b" != "$res_p" ] && flag="  (both not right, differ)"
  [ "$res_b" != "$r" ] && [ "$res_p" != "$r" ] && [ "$res_b" = "$res_p" ] && flag="  (both not right, same)"
  echo "$n$flag"
  echo "   ruby:  $r"
  echo "   base:  $res_b"
  echo "   piece: $res_p"
done
