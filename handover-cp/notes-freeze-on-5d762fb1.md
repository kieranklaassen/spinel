# Notes: the freeze pair rebuilt on master 5d762fb16716

A delta against the pair of record on 42557a3c0e7c, which its reader passed: 7405ec86e505 ("super in a freeze or frozen? override is Object's") and a2ced545cdd9 above it ("A class's own freeze and frozen? run through a boxed value"). No line of source or test changes; the second commit's message and description change in the cost sentence only.

## Why a rebuild

The move from 42557a3c0e7c to 5d762fb16716 changes two functions the pair changes:

- `emit_super` (src/codegen.c): four hunks, all in the Exception arms (the store of `super(msg)` and of the bare `super` now records the write with `sp_gc_wb` and attaches a shared String's handle). The pair's arm in that function, `super` in a `freeze` or `frozen?` override, is about 250 lines below and reads none of it.
- `emit_call_freeze_dup_arms` (src/codegen_call_object.c): one arm added for `frozen?` on a typed String that a route hands on under `--share-strings` (`String(t)`, `x.tap { }`). The pair's lines there are the boxed arms.

src/codegen_internal.h gains declarations on both sides, at different lines.

Both commits merge into 5d762fb16716 with exit 0. The re-cut commits are the same patches: `git patch-id --stable` gives 9393d984a27c for the first on both bases and 4bf87533c963 for the second.

    905cd940d4a5604ea7c0666c08702d957814447b   super in a freeze or frozen? override is Object's      (tree aabae0ee479f, on 5d762fb16716)
    cb7251d9a20e826aedec67258763e882bb4d15dd   A class's own freeze and frozen? run through a boxed value   (tree 0dd7dde62299, on the first)

## What was run on 5d762fb16716

Three trees built from nothing (the bare tip, the first commit, both; make rc 0; `nm lib/libspinel_rt.a` finds sp_poly_recur_hash_cycles). The bare tip cures neither: test/super_freeze_builtin does not build there (a C error), test/poly_own_freeze.rb prints 36 of its 47 lines wrong and test/poly_own_freeze_or_nil.rb 2 of 8.

- First commit: its test 6 of 6 cells (gcc and clang, SPINEL_GC_STRESS unset, 1, 2); `ruby tools/gate.rb check` staged rc 0; with `--share-strings` right. On it the second commit's tests print 5 of 47 and 2 of 8 lines wrong, the description's count.
- Both: the three tests 18 of 18 cells; gate rc 0; `--share-strings` right for the three.
- The families the pair was read on, run again with both commits on this tip (gcc, SPINEL_GC_STRESS unset, 1, 2) and compared with the runs on 42557a3c0e7c program by program: the 1,080 (gen-gf-freeze.rb), the 489 of the 666 by the place of the call whose C changes (gen-ctx.rb), the 68 attacks (attack-freeze-defs/). All 1,637 print the same bytes at the three levels as on 42557a3c0e7c.
- The 68 attacks on this tip, the first commit against both: 35 right stay right, 17 wrong become right, 8 that did not build are right, 6 are wrong on both, 2 do not build on either; right lost 0. With `--share-strings` (the option the move's new arm is for), the same 68 rows.
- The corpus (6,495 programs of the tip, the C each tree emits, compared byte for byte): the first commit against the bare tip, both against the bare tip, both against the first: 6,492 identical and 3 differ each time, no refusal changes. The 3 differ between any two trees, by the length of the tree's own path in a `require` line (test/conditional_require_line, test/require_expression_lines, test/source_file_required): the path literal and its length are the only lines that differ. So no corpus program's C changes by either commit. The emit ran with no time or memory bound.
- Optcarrot's generated C is unchanged by either (cmp against the bare tip's).

## The cost, re-measured (the reader's second text point)

cost-freeze-on-5d762fb1.txt: six programs, a loop of 3,000,000, gcc and clang, the bare tip, the first commit, both. The first commit's counts equal the bare tip's in all twelve cells. The second, in instructions a call more than the first:

| the loop | gcc | clang |
|---|---|---|
| `frozen?` over five kinds of value, a class defines it | 3.0 | 3.0 |
| `frozen?` over an Integer and a String | 4.0 | 7.0 |
| `freeze` over five kinds of value, a class defines it | 4.2 | 1.0 fewer |
| `freeze` over an Integer and a String | 3.0 | 7.0 |
| `frozen?` where no class defines it | 0.0 | 0.0 |

They are the counts measured on 42557a3c0e7c. With clang the `freeze` call runs from 1.0 fewer to 7.0 more by the loop around it, and the reader's own loop (4.8 more) is inside that; the message said "1.0 fewer with clang" as if it were the one figure. The message now gives the ranges: "a frozen? call 3.0 to 4.0 more with gcc and 3.0 to 7.0 with clang; a freeze call 3.0 to 4.2 more with gcc, and with clang from 1.0 fewer over five kinds of value to 7.0 more over two". The description had the four cells already; it names master 5d762fb1 now.

## The reader's other points

- "Depends on": the second description's line names the pull request it stands on by its title; the first keeps the template's bare line. Unchanged.
- The direct call of a `frozen?` that answers a Symbol printing true, in a program whose boxed `x.frozen?` did not compile (the reader's finding 3, ruled reached, not made): it is the description's second "Not covered".

## The later move

5d762fb16716 to 3d629868df96 (six merges): both commits merge with exit 0; src/analyze.c and src/codegen_call.c are shared, no function is. Not rebuilt there.

## Texts

boxed-own-freeze-commit-message-v3.txt (the commit's message, byte for byte) and boxed-own-freeze-pr-body-v3.md. The first commit's message is super-freeze-commit-message-v1.txt, byte for byte; its description is super-freeze-pr-body-v3.md as before.
