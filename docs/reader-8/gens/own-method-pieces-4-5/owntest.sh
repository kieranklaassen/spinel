#!/bin/bash
# usage: owntest.sh TEST.rb TREEDIR... : build with gcc and clang, run at three stress levels, compare with .expected and with CRuby
export LANG=C.UTF-8
t=$1; shift
exp=$t.expected
ruby --enable-frozen-string-literal $t 2>/dev/null > /home/claude/r8/p175b/scratch/own.ruby.out
cmp -s /home/claude/r8/p175b/scratch/own.ruby.out $exp && echo "CRuby 3.3.6 stdout == .expected ($(wc -l < $exp) lines)" || echo "CRuby 3.3.6 stdout DIFFERS from .expected"
for tree in "$@"; do
  for cc in gcc clang; do
    out=/home/claude/r8/p175b/scratch/own.$$.bin
    if nice -n 10 $tree/bin/spinel $t -o $out --cc=$cc > $out.log 2>&1; then
      for s in "" 1 2; do
        SPINEL_GC_STRESS=$s timeout 20 $out > $out.o 2> $out.e; st=$?
        d=$(diff $exp $out.o | grep -c '^[<>]')
        nd=$(diff $exp $out.o | grep -c '^>')
        echo "$(basename $tree) $cc stress='$s': exit $st, $(wc -l < $out.o) lines, differing lines vs expected: $(diff <(nl $exp) <(nl $out.o) | grep -c '^<')"
      done
    else
      echo "$(basename $tree) $cc: NOT BUILT: $(grep -m1 -i 'error\|refus\|unsupported' $out.log | cut -c1-200)"
    fi
    rm -f $out $out.log $out.o $out.e
  done
done
