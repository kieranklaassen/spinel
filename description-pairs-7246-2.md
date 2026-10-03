# PR 7246: description edit for head 8479317c (the pin is kept after the fixpoint)

For the session that edits the description of matz/spinel PR 7246.
Head: 8479317c914101417c90d2183e281d4ef6ca2a8c (was b8f48be9), four commits
on f672bd97; the fourth reverts the third, so the tree is 56f929eb's. The
branch was not rebased; the gate below ran on its merge with master 1d26ef67.

Written against live-description-2018.md beside this file: the description
as the Mac read it at 20:18 UTC on 2026-10-03, 5,815 bytes with one trailing
newline, sha256
20c5f43d4ded7d5908c04f8b8904aa747ff55bef6cff8d7d3bcc0e0314179623, up to the
block CodeRabbit appends. It is byte for byte description-after-7246.md.

STOP RULE. Before changing anything, count each of the 7 Olds below in
the live description. Every Old must occur EXACTLY ONCE. If any Old occurs
zero times or more than once, stop, apply NOTHING (none of the other pairs
either), and report which Old and how many times it occurred.

Each Old and each New is the text between its two fence lines, byte for byte,
with no newline at either end. Every Old is a single line or part of one. The
New of pair 3 is two paragraphs with one empty line between them; every other
New is a single line. The pairs stand in the order their Olds occur in the
description. No New contains an Old, and applying the pairs in this order or
in the reverse order gives the same text (checked by script).

- Pairs 1, 3 and 4 each replace a whole line (a paragraph).
- Pairs 2, 6 and 7 are each part of a longer line; nothing else on that line
  changes.
- Pair 5 is a whole line inside the fenced block under the "`make gate`"
  heading; the other five lines of that block do not change. The `Tests:`
  line is "Tests:", five spaces, the count and " pass,", eight spaces,
  "0 fail,", eight spaces, "0 error".
- The optcarrot box does not change: master is still 1d26ef67.

Where each fact comes from:

- Pairs 5 and 6 (the Mac's): the full `make gate` on macOS (arm64), CRuby
  4.0.7, on 8479317c merged with master 1d26ef67 (merge clean), 20:46 to
  20:51 UTC on 2026-10-03, ALL GREEN, as relayed; the six lines in that log's
  spelling and spacing differ from the live fence in the `Tests:` count only
  (5659, one fewer than on b8f48be9: the removed test). The sentence after
  pair 6's, about `timeout`, stays: a copy of `build/spinel-timeout` was on
  PATH under that name. optcarrot's generated C from the merge's compiler is
  identical by `cmp` to master 1d26ef67's, as relayed, so the box stands.
- Pair 7 (the Mac's): under CRuby 4.0.7 with `--enable-frozen-string-literal`
  on macOS `test/ivar_table_row_store_retyped.rb` prints exactly its
  `.expected`, as relayed. It is the only new test with an `.expected` now;
  `test/infer/ivar_table_nil_only_store.rb` is compiled by `infer-test` and
  its C is grepped.
- Pair 1 (the thread's, Linux container): on 8479317c `x = nil; @t[i] = x`
  keeps `sp_PtrArray *` (the infer fixture's `iv_loc`), as on master 1d26ef67.
- Pair 2 (the thread's): test/infer/ivar_table_nil_only_store.rb and its two
  `infer-test` lines; `make infer-test` passes on 8479317c. The three slots
  are `sp_PtrArray *` on master 1d26ef67 too, and `sp_PolyArray *` at b8f48be9
  merged with it.
- Pair 3, first paragraph (the thread's): of the generated stores in
  keep-pin-8479317c/ (gen66.txt, more20.txt; columns mst = 1d26ef67, rows =
  8479317c's tree), g_nil_local_idx and g_param_nil_only_idx are right on
  both; g_nil_local_push and g_param_nil_only_push do not build on either;
  g_nil_or_ary_idx prints the eight zeros on both; m_hash_if_push does not
  build on either and m_hash_if_idx is wrong on both.
- Pair 3, second paragraph: 41 and 38 of the 66 are the thread's run on
  8479317c's tree and on master 1d26ef67 (9 wrong and 16 not built against 10
  and 18; the three that differ are right on 8479317c), and the second
  reader's on the head merged with 1d26ef67, the same. 62 is the thread's run
  on b8f48be9 and on its merge with 1d26ef67. The 914 programs, the 54 (42
  silently wrong, 12 not built) and "none" are the second reader's run
  (review-7246/second-reading-late-unpin/, gen5 and gen6): master 1d26ef67,
  b8f48be9 merged, and 56f929eb merged, whose tree is 8479317c merged's.
- Pair 4 (the thread's): keep-pin-8479317c/u.rb prints true under CRuby,
  f672bd97, master 1d26ef67 and 8479317c, and false with exit status 0 at
  b8f48be9 and at its merge with 1d26ef67. `git diff 56f929eb 8479317c` is
  empty. `git diff --numstat f672bd97 8479317c`: 24 and 6 in src/analyze.c, 2
  and 0 in the Makefile; `narrow_int_table_ivars` is 194 lines.
- Unchanged sentences checked again on 8479317c's tree (the thread's): the C
  of the 5,904 programs of f672bd97 (5,900 identical, four differ only in
  RUBY_DESCRIPTION); test/ivar_table_row_store_retyped.rb plain and under
  SPINEL_GC_STRESS=1 and 2, and the wrong row on master 1d26ef67;
  tools/order_probe.rb reports nothing for
  test/ivar_table_late_typed_row_store.rb, and one finding for it on master.

After the 7 pairs the description equals
description-after-7246-keep-pin.md beside this file (6,053 bytes with
one trailing newline, sha256
121204ab4e963384478297f9ca604ea9a36231d4e15a587149f591b278b504d8), up to the block CodeRabbit appends.

There are 7 pairs.

## 1

Old:

```
The vet also runs on the pass's one run after the fixpoint, and that run matters: a value typed nil in every round has its boxed type only there. On master `x = nil; @t << x` (or a parameter only ever passed nil) gave C that does not build, and `h = nil; h ||= []; @t[i] = h; @t[i]` printed `[0, 0, 0, 0, 0, 0, 0, 0]` for `[]`; both are right now. The cost: a table that stores by index a nil-only local, a parameter only ever passed nil, or a method's answer of such a local (`x = nil; @t[i] = x`) becomes a boxed array where master keeps the table. Its answers are right.
```

New:

```
After the fixpoint the pass runs once more, and there a pinned table is left as the rounds decided it, as on master: no round is left then to retype what was read out of the table. So `x = nil; @t[i] = x` keeps its table.
```

## 2

Old:

```
`test/ivar_table_nil_typed_store.rb` has the stores the run after the fixpoint catches (a nil-only local and a nil-only parameter appended, `h ||= []` and `h = [] if flag` stored by index) and the nil-only index store; its C does not build on master. Of 66 generated stores of such a value, 62 are right where master has 38, and none master has right is lost.
```

New:

```
`test/infer/ivar_table_nil_only_store.rb` has three stores by index of a value that is only ever nil (a local, a parameter, the answer of a method that returns such a local), and `infer-test` asserts that each table keeps its `sp_PtrArray *` slot, as it does on master.
```

## 3

Old:

```
The four left are not right on master either: a value typed nil in every round that ends as a Hash (`h ||= {}`) or as an Array given a String (`h ||= []; h << "q"`), each stored by index and appended. Appended, their C does not build on master; here it builds and they print a wrong answer (nil for `{}`, an Array holding one address for `["q"]`) with exit status 0, as the Array given a String does on master when stored by index. The store and the slot are right; the method reading the row back is still typed for an int array. So for those two appends, and for others like them (an Array given a Float, a Symbol or another Array; `h = {} if flag`), this branch turns a build failure into a silently wrong answer; that comes with the first commit's vet after the fixpoint.
```

New:

```
What this branch does not do: a value typed nil in every round has its boxed type only after the fixpoint, and stored into such a table it is as on master. Such values are `h = nil; h ||= []`, `h = {} if flag`, and a local or a parameter that is only ever nil. Stored by index, the ones that are only ever nil are right, on master and here. Appended, `x = nil; @t << x` gives C that does not build, on master and here; and `h = nil; h ||= []; @t[i] = h; @t[i]` prints `[0, 0, 0, 0, 0, 0, 0, 0]` for `[]`, on master and here.

The cost, in numbers from generated programs that are not in this PR: of 66 stores of such a value into an int table, 41 are right here and 38 on master. A head of this branch that un-pinned the table after the fixpoint (the third commit) had 62 of them right as printed, but of 914 further generated programs it had 54 wrong or unbuilt that master has right; this head differs from master in none of the 914.
```

## 4

Old:

```
The branch has three commits. The second kept a pinned table after the fixpoint and the third takes that back, so the change to `src/analyze.c` is the first commit's plus a comment: 19 lines added and 2 removed, all in `narrow_int_table_ivars` (193 lines).
```

New:

```
The branch has four commits: the fix, which vetted a pinned table on every run of the pass; one that keeps a pinned table on the run after the fixpoint; one that took that back; and one that restores it, because un-pinning there lost a program master has right (after `x = nil; @t[i] = x`, `r = @t[k]; r.equal?(@t[k])` printed false: the local stayed an int array while the element went boxed). The tree is the second commit's, so the branch as it stands vets a pinned table again in every round and leaves it alone after the fixpoint. In `src/analyze.c` it is 24 lines added and 6 removed: `narrow_int_table_ivars` (194 lines) is told whether it runs in a round, and its two callers say so. The `Makefile` gains the infer fixture's two lines.
```

## 5

Old:

```
Tests:     5660 pass,        0 fail,        0 error
```

New:

```
Tests:     5659 pass,        0 fail,        0 error
```

## 6

Old:

```
on master 1d26ef67 merged with this branch's three commits (head b8f48be9).
```

New:

```
on master 1d26ef67 merged with this branch's four commits (head 8479317c).
```

## 7

Old:

```
(CRuby 4.0.7 with that flag prints exactly what both new tests' `.expected` files hold, run on macOS; they were written from ruby 3.3.6)
```

New:

```
(CRuby 4.0.7 with that flag prints exactly what the new test's `.expected` file holds, run on macOS; it was written from ruby 3.3.6. The infer fixture has no `.expected`)
```
