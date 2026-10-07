# Sixth piece: a module a class includes twice (hand-over of 10-07, 17:33 UTC)

"Including a module a class already has does not move it to the front". A fix, alone on master, its own pull request. Nothing was opened, posted or pushed on matz/spinel; it was read by git only.

Cut on master 9274c732eaa2 (the tip at 15:47 UTC): commit 13a4f44a4f21, tree d05cf0bd05311978749b852cf14d0a326abc5f2c. Built once more on 759d120fd207 (the tip at 17:27 UTC, 30 commits on): the patch applies, tree 06152c510f467a926c2855e0de8a7a8a341b427e; that move touches src/analyze_scope.c only in alias_target_defined_before and alias_refuse_early_call, no function of the piece. Recipe: `git apply --index handover-tools/patches/piece6-include-held-on-9274c732eaa2.patch` on either master, committed with `handover-tools/texts/inc-commit-message.txt`. One file of source, src/analyze_scope.c (443 lines added, 2 changed), and one test.

## The fault

`include` copies a module's methods into the class and a later copy of a name supersedes an earlier one. CRuby's `include` leaves out a module the class or a superclass holds already. So on master a module two includes share, the module itself named again, or a module a superclass includes puts its method over the one CRuby finds in front of it: a silent wrong answer.

## The cure, by the inverted test

register_includes works out CRuby's order of the modules behind each class (`inc_own`) once, only for a program where some include names a module held already and only where the statements give the order. At an include that reaches a class with such a module, a name is copied from the def that order gives the class. Scopes, shadow names and super chains are made as on master; only the def behind a copy changes. Modules keep the copies master gives them, so for an include-only name a class ends with CRuby's def or with master's, never a third.

## Counts, on 9274c732eaa2 against CRuby 3.3.6

| set | programs | C changes | wrong to right | right on both | master's bytes | wrong, other bytes | rule (a) | rule (b) |
|---|---|---|---|---|---|---|---|---|
| `mro-gen.rb` | 1,080 | 111 | 45 | 66 | 0 | 0 | 0 | 0 |
| `mro2-gen.rb` (27 shapes) | 9,150 | 1,007 | 379 | 586 | 42 | 0 | 0 | 0 |
| `mro3-gen.rb` (39 shapes) | 9,320 | 3,468 | 1,134 | 1,952 | 378 | 4 | 0 | 0 |
| `mro4-gen.rb` (12 spoilers) | 4,480 | 2,534 | 1,256 | 1,136 | 142 | 0 | 0 | 0 |

A program whose C does not change was not run. The changed ones were run once with the default cc at collector stress unset, master and piece; 315 of them (every ninth, thirtieth and twenty-third right one of the three large sets) also under gcc and clang at stress unset, 1 and 2: 1,890 runs right. "Master's bytes": wrong, stopped or not built on master, the same bytes on the piece (mro3's 378 are 252 wrong, 122 stopped, 4 not built). The 4 wrong with other bytes: three read a constant through the includes (the constant-read fault, next piece), one calls a protected method CRuby refuses.

The order worked out (`own-check2.rb`, a compiler with `order-dump.patch`) equals CRuby's `ancestors` for every class and module in all 1,456 programs of the three large sets that it is worked out for (298, 671, 487; the first program of each graph and shape).

`tools/cident.sh` against 9274c732eaa2: 6418 identical, 1 differ, 0 refusal changes, 0 refused by both. The one is test/include_module_already_included.rb. `LC_ALL=C.UTF-8 ruby tools/gate.rb check` with the commit staged: exit 0, on both masters. The test under gcc and clang, with and without `--int-overflow=promote`, stress 0, 1, 2: 12 runs pass, on both masters.

Compile time, user seconds of `spinel -S`, two runs each, master then piece: chain-200 0.81, 0.80 and 0.72, 0.68; chain-400 17.81, 17.36 and 15.95, 15.57; chainx-400 (no module named twice) 17.84, 17.92 and 16.19, 15.97; wide-100 0.09, 0.08 and 0.07, 0.08; wide-500 1.25, 1.20 and 1.15, 1.06; subs-1000 1.38, 1.30 and 1.11, 1.16; subsx-1000 0.08, 0.07 and 0.08, 0.07. An earlier cut asked each name by a scan of every scope and took 0.82 s for wide-100; the piece keeps an index of the defs as written and a memo of the answers.

## Holes found in earlier cuts, and closed

1. A def under a condition in a late reopening (`hand/a1.rb`): master right, the cut wrong. Now every def must be a plain statement of a body, or the program is left.
2. A def made after the first statement that runs (`hand/b1.rb`), found by reasoning before any run: such a def is not followed.
3. A class the order is not worked out for (it includes Comparable, or aliases) that copies from a module the cut had corrected, where the class holds the module's parts in another order (`hand/d1.rb`, `hand/d3.rb`): master right, the cut wrong. Found by reasoning, not by the sets. Now only classes are corrected.
4. Compile time cubic in the modules of a wide graph: the index and the memo.

## Not here

- A method that calls `super` (the class's own, or the def in front): the chain through a module held twice is master's (`hand/e1.rb`, `hand/d2.rb`). On master 53% of the super answers of the first set are not right; a piece of its own.
- `ancestors` lists a module a superclass holds in front of the superclass (`hand/w2.rb`): the table codegen emits, a piece of its own.
- A program outside the lines: prepend, extend but `extend self`, hooks, define_method, undef, class_eval, a def in a block (`Struct.new do ... end`, `hand/b5.rb`), an include after the first statement that runs, at the top level or in a required file, a module given an include after it was mixed in.

## Not run

The full `make gate`; CRuby 4.0 (the `.expected` is CRuby 3.3.6's with `--enable-frozen-string-literal`; the name for the 4.0.7 run is test/include_module_already_included.rb); the 32-bit lane; optcarrot; `--share-strings` (no String is made or shared).

## Finds on master met here (for the miner)

- `super` from an include copy that a later include superseded stops with NoMethodError "super: no superclass method '__inc 0 tag'", and the shadow names of two classes collide.
- `ancestors`, as above.
- A module_function's instance copy is not transplanted: `K.new.send(:who)` answers another module's where CRuby raises for a private method.
- `owner` of a method that came through a module's include names the module in between.
- A protected method called from outside answers.

## Texts and sums

Files under `handover-tools/` at the branch head; each sum is the sha256 of the file, which ends in one newline. The body opens with the first line of `.github/PULL_REQUEST_TEMPLATE.md` as it stands on 759d120fd207.

| text | file | sha256 |
|---|---|---|
| title | `texts/inc-pr-title.txt` | `0ecec62d04b867650a7f4ebbc827a0db1529e606ccca406641067872566bd0b6` |
| body | `texts/inc-pr-body-upstream.md` | `ea03d69206de0086ee823b1c0f00161968e113f7785e672e36ca55cc1fcdb31e` |
| commit message | `texts/inc-commit-message.txt` | `3267166ed85b61e54a6bc5ebe134eb64ec5a5cb2e8ff2e5b6ef25168051851d4` |
| patch, on master | `patches/piece6-include-held-on-9274c732eaa2.patch` | `4cfef9b1bc648efca55cdd4c38229b8aafa52ff24ee7cd7c25a9726511cf77f0` |
