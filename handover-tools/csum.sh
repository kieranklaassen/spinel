#!/bin/bash
# csum.sh TREE DIR OUT: md5 of the C TREE's compiler emits for every DIR/*.rb (tree path masked)
tree=$1; dir=$2; out=$3
cd $dir && for f in *.rb; do printf '%s\t%s\n' "$f" "$($tree/bin/spinel -S $f 2>&1 | sed "s|$tree|TREE|g" | md5sum | cut -d' ' -f1)"; done > $out
