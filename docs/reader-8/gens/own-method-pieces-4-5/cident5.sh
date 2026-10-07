#!/bin/bash
# Piece 5's cident on the tip, with piece 4's reference cache (made by tools/cident.sh from 26d456ec in
# the piece-4 tree) copied under piece 5's cache key with the tree name rewritten.  The two trees' paths
# have the same length.  Piece 5's own new test is then "not in the reference" (it is compared by hand).
set -e
SHA=26d456ec103513fd8d7d9367dbbc9060854f3116
P4=/home/claude/r8/p175b/p4-on-26d456ec-tree
P5=/home/claude/r8/p175b/p5-on-26d456ec-tree
src=$(ls -d $P4/build/cident/$SHA-*/ | head -1)
[ -f "$src/.done" ] || { echo "no finished reference cache in $P4"; exit 2; }
cd $P5
OC=build/optcarrot-single.rb
CORPUS=$(find test benchmark packages/*/test -type f 2>/dev/null; if [ -f "$OC" ]; then echo "$OC"; fi)
CORPUS=$(printf '%s\n' "$CORPUS" | LC_ALL=C sort)
CORPUSKEY=$({
  printf '%s\n' "$CORPUS"
  printf '%s\n' "$CORPUS" | git hash-object --stdin-paths
} | git hash-object --stdin)
REFDIR=$P5/build/cident/$SHA-$CORPUSKEY
rm -rf "$REFDIR"; mkdir -p "$REFDIR"
cp -a "$src/." "$REFDIR/"
rm -f "$REFDIR"/test_own_object_id.rb.*
grep -l -F "$P4" "$REFDIR"/*.c 2>/dev/null | while read c; do LC_ALL=C sed "s|$P4|$P5|g" "$c" > "$c.tmp" && mv "$c.tmp" "$c"; done
: > "$REFDIR/.done"
CIDENT_JOBS=2 nice -n 10 make cident REF=$SHA
