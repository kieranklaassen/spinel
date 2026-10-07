# Notes, letter FX (own then, no block): the head on the tip, body v5

Class: fix with a stated cost. Reader 4's verdict on the delta 37be4cd385a9: PASS WITH TEXT FIXES (T1 to T3). The cost is STATED, not cut (the coordinator's ruling of 16:07 UTC 10-07): master charges `dup` and `to_s` the same switch in the same program (the cells below), and a cut would need a set of the kinds a box can hold that master has for no name. The body says a later cost change, one answer for every name master dispatches this way, would repay them all.

## The head on the tip

- 586cb2a44385c7548e8d899879d6377578fac6e7, tree 410203e071b8, on master 9274c732eaa2 (the tip at 16:11 UTC 10-07), one final newline, author and committer dates equal. The same 176 added and removed lines, in the same order, as the carried head (1494b2634c6e on 4f8b737c1402; cmp of the two lists). Master's 4f8b737c1402 to 9274c732eaa2 changes nothing in src/codegen_call_object.c.
- Built there: test/poly_own_then.rb passes with gcc and clang at SPINEL_GC_STRESS unset, 1 and 2 (6 of 6 cells) and built with `--share-strings`; `ruby tools/gate.rb check` with the piece staged exits 0. Bare master 9274c732eaa2 (built) does not build the test (line 33).
- `git merge-tree` with the freeze commit on the same tip (5066ac160144, which changes other arms of emit_call_freeze_dup_arms): exit 0.

## The text fixes (body v5)

- T2: the first paragraph no longer says one program pays. It says: in a program where a class defines or reads `then` or `yield_self`, every blockless call of that name on a boxed value takes the class switch.
- T1: the cost names its programs and its master. Measured again on 9274c732eaa2 (callgrind; `cost-fx/`): `tst_stmt` (`row = [5, q]; v = row[0]` before the loop, `v.then` dropped, 200,000 calls) 77,429,902 to 78,437,464 with gcc, 77,450,089 to 78,257,636 with clang: +5.04 and +4.04 a call, of 387. `tst_own` (`x = row[i % 4]; x.then` each turn, 300,000 calls) 120,010,017 to 121,821,372 and 121,260,006 to 122,471,492: +6.04 and +4.04, of 400. The reader's k5 is another program (`v = row[0]` inside the loop) and gave +4.04 and +5.04 of 398 on a2bd890054b6; the body now says which program each figure is.
- T3: "Not covered" names a read inside a block within the guard, the else of `case t when nil`, and the second call of a chain (`t.then.then.n` does not build; `t.then&.then` runs).

## Master's own charge for the switch (bare master 1df866be9c54; `cost-k/`)

`row = [5, "s"]; v = row[0]`, the call dropped in a while loop of 200,000; the same program with and without `class Q; def NAME ...; end`, the method called once on a typed Q, the box never holding a Q (the reader's k6 shape): `v.dup` +5.02 gcc, +4.03 clang a call; `v.to_s` +5.04, +4.05; `v.nil?` +1.52, +2.43. The same shape for `then` on the tip with this piece (`then6`): +5.04 gcc, +4.04 clang.
