# PR 7214: description edit after the five fixes were cherry-picked to master, second writing

This file replaces its first writing of 16:25 UTC (sha256 891527a0...): pair 1 and its note differ, and pair 2 says "What is left of this pull request is" where it said "What this pull request still holds is".

Three exact replacements against the description as it stands on GitHub (the text after the seven pairs applied at 11:13 UTC on 2026-10-03; 5006 bytes up to the review bot's own block, sha256 ddf47e5978ca324268f826134c20b60ee50eb15c17f5d19b29fcdda3f0b8aed8). Each Old must occur exactly once in the live description. If any Old does not occur exactly once, stop and apply nothing. Nothing else in the description changes. Old and New are the text between the fence lines, without the fence lines; each is a single line.

The branch is not changed: head 6ed6183c, fourteen commits on 0919a4b0, nothing pushed. The text after all three pairs is description-after-7214-cherry-picks.md beside this file (sha256 ce5fce1842480b94263113df680fe93d42f341de7c710b111d4895be80012273, 5052 bytes).

Where each fact comes from (all in a Linux container on 2026-10-04, 16:13 to 16:52 UTC, against master ec452b59):

- The cherry-picks, by git: master holds 450e48db, 4f1f0a8a, 8e2e1883, e88a9aa0 and 42d192cf, author unchanged, each message ending "(cherry picked from commit ...)" naming 5d2df3bd, 0f29cf0e, 49c41503, 8311d8e4 and f6451115 in that order. `git cherry` marks four as equal patches; the second differs from 0f29cf0e in one line that master's #7189 had already changed (`sp_PolyArray_set(...)` where the branch has `_t->data[...] = ...`).
- Pair 1: `make cident REF=ec452b59` on a local merge of 6ed6183c with ec452b59 (tree 9a213190, not pushed), in a clone that has the release tag `2026.09.12`, 16:48 to 16:52 UTC, printed "NO LONGER REFUSED: test/tools_bisect_search.rb" and "cident: 5814 identical, 0 differ, 1 refusal changes, 0 refused by both, 0 not in the reference (against ec452b599)". The compiler there calls itself `spinel 2026.09.12+4995 (4e2270f0)`, and tools/cident.sh rewrites that release-and-revision text on both sides before it compares. The sentence being replaced was measured in a clone without the tag, where the compiler prints "unreleased revision ..." and the rewrite does not match: its 14 differing held four programs that print the compiler's own revision and differ in nothing else. The same run without the tag on this merge gave 5810 and 4, those four programs. The two sentences that follow the replaced one stay and stay true: the packed optcarrot source compiled with `-c --no-line-map` by master ec452b59 and by the merge gives the same 608,251 bytes (`cmp` silent).
- Pair 2: the five fix tests built with master 341cab5b (the parent of 450e48db): test/case_in_guard_allocating_operand.rb and test/array_fill_block_poly_value_setup.rb do not build, the other three print a wrong answer. Built with master ec452b59, all five print their `.expected`. "the decisions registry, the `--decisions` flags and `spinel bisect`" are the maintainer's own words for what stays open (his comment of 15:34 UTC on the pull request, as relayed).
- Pair 3: `git diff --stat` from ec452b59 to the merge is 28 files, 1658 insertions, 58 deletions. The nine commits e1b74dd7 to 6ed6183c rebased onto ec452b59 (locally, not pushed) apply without conflict and give the same tree as the merge (9a213190).

What the nine commits do on that merge: it builds with no warning; `make decisions-test`, `make bisect-test`, `make cli-opts-test` and `make collect-errors-test` (384 records) pass; test/tools_bisect_search.rb and the five fix tests pass as built, under `SPINEL_GC_STRESS=1`, and with every keyed decision denied; no function over 1,000 lines grows; the Makefile's `DECISION_KINDS` still lists fourteen kinds and `decisions-test` finds each in a log; `spinel bisect` run on a program whose answer depends on one bounds proof names `nn-inb` at the store's line in 5 builds.

Sentences left as they are, and why:

- "No function over 1,000 lines grows in any of the fourteen commits": still true of the branch as pushed.
- The gate fence, the paragraph under it and the optcarrot checkbox name master d5d42559: they report the run of 2026-10-03 and say so. No gate has been run on the merge with ec452b59.
- The `.expected` checkbox counts eight files, the five fix tests' among them: the branch as pushed still adds them, and they equal master's copies byte for byte.
- "The first four are the cause #7070 fixed ...": describes the fixes, wherever they live.

If the branch is later cut to the nine commits, "Fourteen commits", "the fourteen commits", the `.expected` count and the gate paragraph change too; those pairs are written then, against the text live at that time.

## 1

Old:

```
`make cident REF=0919a4b0` (the master commit this branch is rebased on; run on Linux) reports 5699 identical and 14 differing: this branch's five new tests, five existing tests that call Array#fetch with a block and gain one `({ })` level from the third commit, and the four programs that print the compiler's own revision.
```

New:

```
`make cident REF=ec452b59` on this branch merged with master ec452b59 (run on Linux) reports 5814 identical and 0 differing.
```

## 2

Old:

```
Fourteen commits. The first five are fixes that stand without the tool, each with its test. They were found by running the corpus with every keyed decision denied, which sends programs down the paths the legality checks almost never choose, and each still fails on master at d5d42559:
```

New:

```
Fourteen commits. The first five are fixes that stand without the tool, each with its test, and they are on master now, cherry-picked as 450e48db, 4f1f0a8a, 8e2e1883, e88a9aa0 and 42d192cf. What is left of this pull request is the other nine commits: the decisions registry, the `--decisions` flags and `spinel bisect`. The five were found by running the corpus with every keyed decision denied, which sends programs down the paths the legality checks almost never choose, and each failed on master until then:
```

## 3

Old:

```
The five fixes can go as their own pull requests if that is easier to take.
```

New:

```
Merged with master ec452b59, this branch's difference is those nine commits alone, in 28 files.
```
