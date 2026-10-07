#!/bin/bash
# The piece's tools on master 8684d54ce75f merged with the piece (/home/claude/r8/ap/piece-tree-ap):
# reject-test, share-strings-test, refusals, then cident against the base commit c5fedca7 (master + cap fix).
cd /home/claude/r8/ap/piece-tree-ap
echo "== make reject-test"; nice -n 5 make reject-test 2>&1 | tail -5; echo "exit ${PIPESTATUS[0]}"
echo "== make share-strings-test"; nice -n 5 make share-strings-test 2>&1 | tail -5; echo "exit ${PIPESTATUS[0]}"
echo "== tools/refusals.sh"; REFUSALS_JOBS=1 nice -n 5 tools/refusals.sh 2>&1 | tail -8; echo "exit ${PIPESTATUS[0]}"
echo "== make cident REF=c5fedca7"; CIDENT_JOBS=1 nice -n 5 make cident REF=c5fedca7ab344fc17db0e4ec106c2dff47d3bf5c > ../out/cident.8684.log 2>&1; echo "exit $?"; tail -25 ../out/cident.8684.log
echo QUEUE12 DONE
