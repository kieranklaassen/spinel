#!/bin/bash
# the two tests the pull request adds, on each tree, gcc and clang, stress unset/1/2, with and without --share-strings
export LANG=C.UTF-8
T=/home/claude/r8/p219/tip-on-26d456ec-219/test
declare -A P=( [m26]=/home/claude/r8/master-26d456ec-tree [tip26]=/home/claude/r8/p219/tip-on-26d456ec-219 )
for t in rescued_own_exception_boxed_class class_new_no_block_named; do
  for tree in m26 tip26; do
    for cc in gcc clang; do
      for fl in "" "--share-strings"; do
        b=/home/claude/r8/p219/probe/tb.$$
        rm -f $b
        (cd $T && ${P[$tree]}/bin/spinel $t.rb -o $b --cc=$cc $fl >/dev/null 2>$b.err)
        if [ ! -x $b ]; then echo "$t $tree $cc ${fl:-plain}: NOT BUILT: $(grep -v warning $b.err | head -1)"; continue; fi
        res=""
        for s in "" 1 2; do
          out=$(cd $T && SPINEL_GC_STRESS=$s timeout 60 $b 2>/dev/null); rc=$?
          n=$(diff <(echo "$out") $T/$t.rb.expected | grep -c '^[<>]')
          res="$res stress${s:-0}:rc=$rc,difflines=$n"
        done
        echo "$t $tree $cc ${fl:-plain}:$res"
      done
    done
  done
done
