#!/bin/bash
# csum4.sh TREE DIR OUT: md5 of the C that TREE's compiler emits (or of its refusal) for every
# DIR/*.rb, four at a time; the tree's path is masked.
tree=$1; dir=$2; out=$3
cd $dir && ls *.rb | xargs -P 4 -I{} sh -c 'printf "%s\t%s\n" "{}" "$('$tree'/bin/spinel -S {} 2>&1 | sed "s|'$tree'|TREE|g" | md5sum | cut -d" " -f1)"' | sort > $out
