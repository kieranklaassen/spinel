#!/bin/bash
# wait for the piece gcc run to write its table, then stop the rest of the chain
cd /home/claude/r8/an
until [ -f changed.p.gcc.tsv ]; do sleep 20; done
echo "p gcc table written"
