#!/bin/bash
# usage: derive.sh SRC_TREE DST_TREE file...   Copies SRC's build products into DST (same commit apart from
# the named source files), ages DST's sources below every product, touches the named files and runs make.
set -e
src=$1; dst=$2; shift 2
cd "$src"
# everything git does not track (build/, bin/, lib/*.a, ...), except vendor (already copied)
git status --porcelain --ignored | awk '$1=="!!" || $1=="??" {print $2}' | grep -v '^vendor/' > /tmp/derive.$$.list || true
cd "$dst"
git status --porcelain --ignored | awk '$1=="!!" || $1=="??" {print $2}' | grep -v '^vendor/' | while read p; do rm -rf "$p"; done
while read p; do mkdir -p "$(dirname "$dst/$p")"; cp -a "$src/$p" "$dst/$(dirname "$p")/"; done < /tmp/derive.$$.list
rm -f /tmp/derive.$$.list
# age every tracked file and vendor below the products
git ls-files -z | xargs -0 touch -d '2026-10-07 03:00:00'
find vendor -type f -exec touch -d '2026-10-07 03:00:00' {} +
for f in "$@"; do touch "$f"; done
nice -n 10 make -j2
