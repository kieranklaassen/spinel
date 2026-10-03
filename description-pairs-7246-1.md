# PR 7246: description edit for head b8f48be9, final writing

Second writing of this file (2026-10-03 19:45 UTC), after its reading: the
nine Olds are unchanged; the News of pairs 1, 2, 3 and 8 are reworded (pair 3
now names the further appends), the News of pairs 4 to 7 and 9 are unchanged.
It replaces description-edits.md.

For the session that edits the description of matz/spinel PR 7246.
Head: b8f48be9 (was e3bb92b3), three commits on f672bd97. The branch was not
rebased; the gate below ran on its merge with master 1d26ef67.

The live description these pairs are written against is
live-description-1543.md beside this file: 3,738 bytes with one trailing
newline, sha256
5e4421d9b14af8fd665fbc29abc7a0dcf587565b58ba622d2935fc413f75abe1, up to the
block CodeRabbit appends.

STOP RULE. Before changing anything, count each of the nine Olds below in the
live description. Every Old must occur EXACTLY ONCE. If any Old occurs zero
times or more than once, stop, apply NOTHING (none of the other pairs either),
and report which Old and how many times it occurred.

Each Old and each New is the text between its two fence lines, byte for byte,
with no newline at either end. Every Old is a single line or part of one. The
New of pair 1 is two paragraphs (its Old, an empty line, one new paragraph)
and the New of pair 3 is three, with one empty line between paragraphs; every
other New is a single line. The pairs stand in the order
their Olds occur in the description.

- Pair 1 adds a paragraph after a sentence: its New begins with its Old, so
  apply it once. Nothing else on that line changes.
- Pairs 2, 3, 7, 8 and 9 are each part of a longer line; nothing else on that
  line changes.
- Pairs 4, 5 and 6 are each a whole line inside the fenced block under the
  "`make gate`" heading; the other three lines of that block do not change.
  The `Tests:` line is "Tests:", five spaces, the count and " pass,", eight
  spaces, "0 fail,", eight spaces, "0 error".

No New contains another pair's Old, and applying the nine in this order or in
the reverse order gives the same text (checked by script).

Where each fact comes from:

- Pairs 4, 5, 6 and 7 (the Mac's): the full `make gate` on macOS (arm64),
  CRuby 4.0.7, on b8f48be9 merged with master 1d26ef67 (merge clean), 18:51 to
  19:06 UTC on 2026-10-03, ALL GREEN, as relayed. The lines are in that log's
  spelling and spacing. The sentence after pair 7's, about `timeout`, stays:
  a copy of `build/spinel-timeout` was on PATH under that name.
- Pair 9 (the Mac's): `cmp` of `build/optcarrot-single.c` from the merge's
  compiler and from master 1d26ef67's, byte-identical, as relayed.
- Pair 8 (the Mac's): under CRuby 4.0.7 with `--enable-frozen-string-literal`
  on macOS, `test/ivar_table_row_store_retyped.rb` prints exactly its
  `.expected` (6 lines) and `test/ivar_table_nil_typed_store.rb` exactly its
  `.expected` (20 lines), as relayed. Both files were written from ruby 3.3.6
  with that flag in a Linux container.
- Pair 2 (the thread's, Linux container): C compared between a f672bd97 build
  and a b8f48be9 build, at install paths of equal length, for the 5,904
  programs of f672bd97's tree (5,474 `test/*.rb`, 185 `test/reject/*.rb`, 39
  `test/infer/*.rb`, 64 `benchmark/*.rb`, 142 in the packages' tests). Four
  differ, each only in the build revision inside `RUBY_DESCRIPTION`.
- Pairs 1 and 3 (the thread's, Linux container): what "master" does was
  measured on f672bd97 and again on 1d26ef67 at 19:15 UTC on 2026-10-03, with
  the same result on both. `test/ivar_table_nil_typed_store.rb` does not build
  there; `x = nil; @t << x` does not build; `h = nil; h ||= []; @t[i] = h`
  prints eight zeros for `[]`. The 66 generated stores, each compared with
  CRuby on output and exit status: master 38 right, 10 wrong, 18 not built
  (the same on both commits, store by store); b8f48be9 and its merge with
  1d26ef67 62 right, 4 wrong, none not built; none right on master is lost.
  The four left are `h ||= {}` and `h ||= []; h << "q"`, each stored by index
  and appended, with the outcomes pair 3 gives. The "others like them" of
  pair 3 are from twenty further stores (more20/ beside this file: mk.rb,
  res.txt), run the same way on the same four compilers: appended, an Array
  given a Float, a Symbol, another Array, or a String by concat, unshift or
  `[]=`, and `x = {} if flag`, do not build on master and print a wrong answer
  with exit status 0 on b8f48be9 and on the merge (seven of ten appends; the
  other three, an Integer pushed, map, a nil pushed, are right there and do
  not build on master). `def nothing = nil; @t[i] = nothing` builds neither on
  master nor here, which is why pair 1 says "a method's answer of such a
  local". `git diff --numstat` of
  `src/analyze.c` is 19 added and 2 removed from f672bd97 to b8f48be9 and from
  1d26ef67 to the merge; `narrow_int_table_ivars` is 176 lines before and 193
  after on both.

After the nine pairs the description equals description-after-7246.md beside
this file (5,815 bytes with one trailing newline, sha256
20c5f43d4ded7d5908c04f8b8904aa747ff55bef6cff8d7d3bcc0e0314179623), up to the block CodeRabbit appends.

There are 9 pairs.

## 1

Old:

```
A table whose rows stay int arrays stays pinned.
```

New:

```
A table whose rows stay int arrays stays pinned.

The vet also runs on the pass's one run after the fixpoint, and that run matters: a value typed nil in every round has its boxed type only there. On master `x = nil; @t << x` (or a parameter only ever passed nil) gave C that does not build, and `h = nil; h ||= []; @t[i] = h; @t[i]` printed `[0, 0, 0, 0, 0, 0, 0, 0]` for `[]`; both are right now. The cost: a table that stores by index a nil-only local, a parameter only ever passed nil, or a method's answer of such a local (`x = nil; @t[i] = x`) becomes a boxed array where master keeps the table. Its answers are right.
```

## 2

Old:

```
The emitted C of all 5,903 programs in `test/`, `test/reject/`, `test/infer/`, `benchmark/`, `examples/` and the packages' tests is byte-identical before and after (both compilers built on 0d370b71): no table pinned there loses a row.
```

New:

```
The emitted C of the 5,904 programs the branch's base f672bd97 has in `test/`, `test/reject/`, `test/infer/`, `benchmark/` and the packages' tests is byte-identical before and after (f672bd97 against this branch's head; four of them differ only in the build revision inside `RUBY_DESCRIPTION`): no table pinned there loses a row.
```

## 3

Old:

```
The change is 17 lines in `src/analyze.c`, all in `narrow_int_table_ivars` (191 lines).
```

New:

```
`test/ivar_table_nil_typed_store.rb` has the stores the run after the fixpoint catches (a nil-only local and a nil-only parameter appended, `h ||= []` and `h = [] if flag` stored by index) and the nil-only index store; its C does not build on master. Of 66 generated stores of such a value, 62 are right where master has 38, and none master has right is lost.

The four left are not right on master either: a value typed nil in every round that ends as a Hash (`h ||= {}`) or as an Array given a String (`h ||= []; h << "q"`), each stored by index and appended. Appended, their C does not build on master; here it builds and they print a wrong answer (nil for `{}`, an Array holding one address for `["q"]`) with exit status 0, as the Array given a String does on master when stored by index. The store and the slot are right; the method reading the row back is still typed for an int array. So for those two appends, and for others like them (an Array given a Float, a Symbol or another Array; `h = {} if flag`), this branch turns a build failure into a silently wrong answer; that comes with the first commit's vet after the fixpoint.

The branch has three commits. The second kept a pinned table after the fixpoint and the third takes that back, so the change to `src/analyze.c` is the first commit's plus a comment: 19 lines added and 2 removed, all in `narrow_int_table_ivars` (193 lines).
```

## 4

Old:

```
scale-test: work at 4x the program, compiled to C, is 6.31x (limit 6.90)
```

New:

```
scale-test: work at 4x the program, compiled to C, is 6.29x (limit 6.90)
```

## 5

Old:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.25x (linear 4.00, limit 4.50)
```

New:

```
scale-test: call-shape work at 4x the units, compiled to C, is 4.24x (linear 4.00, limit 4.50)
```

## 6

Old:

```
Tests:     5595 pass,        0 fail,        0 error
```

New:

```
Tests:     5660 pass,        0 fail,        0 error
```

## 7

Old:

```
Run on macOS (arm64) at f672bd97 plus this branch.
```

New:

```
Run on macOS (arm64) with CRuby 4.0.7 on master 1d26ef67 merged with this branch's three commits (head b8f48be9).
```

## 8

Old:

```
(the file was written from ruby 3.3.6 with that flag; it prints Integers and one Array of Integers)
```

New:

```
(CRuby 4.0.7 with that flag prints exactly what both new tests' `.expected` files hold, run on macOS; they were written from ruby 3.3.6)
```

## 9

Old:

```
(it did not change: byte-identical to master's at f672bd97)
```

New:

```
(it did not change: byte-identical to master's at 1d26ef67)
```
