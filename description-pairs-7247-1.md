# PR 7247: description edit for head 29d81a9b, final writing

This file replaces description-pairs-7247.md. Its pairs 1 and 2 are that
file's two pairs, unchanged; pairs 3 to 8 are new.

For the session that edits the description of matz/spinel PR 7247.
Head: 29d81a9b2978fc6e5ff01921e18ed1bdcfea7d95 (was 5591c5a9), one commit
directly on master 53b3beee.

STOP RULE. Before changing anything, count each of the eight Olds below in the
live description. Every Old must occur EXACTLY ONCE. If any Old occurs zero
times or more than once, stop, apply NOTHING (none of the other pairs either),
and report which Old and how many times it occurred.

Each Old and each New is the single line between its two fence lines, byte for
byte, with no newline at either end. Pairs 3, 4 and 5 are each a whole line
inside the fenced block under the "`make gate`" heading; the other three lines
of that block do not change. The `Tests:` line is "Tests:", five spaces,
the count and " pass,", eight spaces, "0 fail,", eight spaces, "0 error".
Pairs 1, 2, 6, 7 and 8 are each part of a longer line; nothing else on that
line changes. No New contains any Old, so the order of applying does not
matter.

Where each fact comes from:

- Pairs 3, 4, 5 and 6 (the Mac's): the full `make gate` on macOS (arm64),
  CRuby 4.0.7, on 29d81a9b directly on master 53b3beee, 13:05 to 13:23 UTC on
  2026-10-03, ALL GREEN, as relayed. The lines are in that log's spelling and
  spacing.
- Pair 7: the Mac's, from the same run (optcarrot checksum 59662, generated C
  byte-identical to master 53b3beee's). The same compare was also made in a
  Linux container: `build/optcarrot-single.c` from a 53b3beee build and from a
  29d81a9b build, `cmp` silent.
- Pair 8 (the Mac's): `ruby --enable-frozen-string-literal
  test/paren_sequence_empty_container.rb | cmp -
  test/paren_sequence_empty_container.rb.expected` under CRuby 4.0.7 on macOS,
  silent, exit 0, as relayed.
- Pair 1 (the thread's, Linux container): the 86 programs built with a
  53b3beee compiler and compared with CRuby: 17 the same, 48 different, 21 not
  built; all 86 the same with 29d81a9b.
- Pair 2 (the thread's, Linux container): C compared between a 53b3beee build
  and a 29d81a9b build for the 5,758 programs of 53b3beee's tree (5,508
  `test/*.rb`, 64 `benchmark/*.rb`, 3 under `examples/`, 183 under
  `packages/`), counted by git.

After the eight pairs the description equals
/mnt/project-files/paren-sequence/pr-body.md up to the block CodeRabbit
appends.

There are 8 pairs.

## 1

Old:

```
17 answered as CRuby does on 0d370b71, 48 answered differently
```

New:

```
17 answered as CRuby does on 53b3beee, 48 answered differently
```

## 2

Old:

```
The C of the 5,721 programs under `test/`, `benchmark/`, `examples/` and `packages/` is byte-identical between 0d370b71 and the same commit with this change, and so is optcarrot's
```

New:

```
The C of the 5,758 programs under `test/`, `benchmark/`, `examples/` and `packages/` is byte-identical between 53b3beee and this branch on it, and so is optcarrot's
```

## 3

Old:

```
scale-test: work at 4x the program, compiled to C, is 6.31x (limit 6.90)
```

New:

```
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
```

## 4

Old:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.25x (linear 4.00, limit 4.50)
```

New:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
```

## 5

Old:

```
Tests:     5595 pass,        0 fail,        0 error
```

New:

```
Tests:     5631 pass,        0 fail,        0 error
```

## 6

Old:

```
Run on macOS (arm64) at 917dd251 plus this branch.
```

New:

```
Run on macOS (arm64) with CRuby 4.0.7 on this branch (29d81a9b), which sits on master 53b3beee.
```

## 7

Old:

```
(it did not change)
```

New:

```
(it did not change: byte-identical to master's at 53b3beee)
```

## 8

Old:

```
; it prints no non-empty Hash, so 4.0 prints the same.
```

New:

```
; CRuby 4.0.7 with that flag prints it exactly, run on macOS.
```
