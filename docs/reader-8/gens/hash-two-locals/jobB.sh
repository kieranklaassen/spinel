#!/bin/bash
# One cident on the tip (piece merged into master 26d456ec1035), then the piece's tools on master 8684d54ce75f + piece.
cd /home/claude/r8/ap/piece-tip-tree-26d456ec
CIDENT_JOBS=1 nice -n 5 make cident REF=26d456ec103513fd8d7d9367dbbc9060854f3116 > ../out/tip.cident.log 2>&1; echo "tip cident exit $?"; tail -12 ../out/tip.cident.log
cd /home/claude/r8/ap && ./queue12.sh
echo JOBB DONE
