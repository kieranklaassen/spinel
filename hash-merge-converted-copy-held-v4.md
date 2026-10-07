<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
counts = {"a" => 1, "b" => 2, "c" => 3}
labels = {"x" => "p", "y" => "q", "z" => "r"}
total = 0
20_000.times { total += counts.merge(labels).size }
p total   # 120000 in CRuby
```

```
spinel diff: crash
  ruby:    exit 0
  spinel:  exit -1 (SIGSEGV)

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-120000
```

Built with gcc or clang. With 200 keys a side, 3,000 turns raise "no implicit conversion of nil into String (TypeError)" instead.

A String-keyed Hash merged with one of another value kind is copied to the boxed kind, and so is the argument: `sp_StrPolyHash_merge(sp_StrPolyHash_from_str_int_hash(counts), sp_StrPolyHash_from_str_str_hash(labels))`. The two copies were arguments of one C call, so the one made first had no root while the second allocated its own, and a collection there freed it.

The argument's copy is now bound to a rooted temp and the receiver's copy is made after it, inside the merge call. That is Ruby's order too: the receiver is read first and merged as the argument left it. A receiver that is not a local's or an instance variable's read, or one beside an argument that runs code, is itself bound to a rooted temp ahead of the argument (`hold_recv_open`), so `counts.merge((counts["b"] = 2; labels))` has "b", which clang's order lost, and `counts.merge((counts = other; labels))` merges the Hash `counts` named, which gcc's order lost. A receiver already of the boxed kind takes only the argument's copy and is held the same way (`pair(i).merge(few)`: the same TypeError after 4,000 turns); two locals there keep master's C. The two copies also root the Hash they copy: each allocated its result before it read its argument, and in a stress run `tally(5).merge(labels)` lost the method's result there. Only this merge makes them.

Two commits. The first only moves the merge's two sites in `emit_hash_call` into one helper above it, `emit_str_keyed_merge`: the function goes from 983 lines to 964 and no generated C changes (`6356 identical, 0 differ`). The second is the fix, inside the helper.

Measured on 806 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 690 merges over twenty kinds of side (a local, a method's result, a reader, a literal, a `dup`, an arm) and every pair of key and value kinds, and 116 whose argument writes or rebinds the receiver. Of the 690, a plain run has 686 right on master and 690 here; under stress 2, 474 and 683 with gcc, 477 and 682 with clang. Of the 116, a plain run has 84 right on master with gcc and 72 with clang; all 116 are right here in all six. No program right on master is wrong here, and none that aborted or raised answers wrong. The few left abort under stress 2 as on master, in merges of another shape: Integer or Symbol keys, a boxed receiver, one value kind on both sides.

Cost: 48 of about 4,445 instructions a merge of two locals (callgrind, 4,000 turns of `counts.merge(labels).size`: 17,863,477 on master, 18,054,176 here; master does not run 20,000 to the end). A receiver that is a constant or a global pays 63, an argument that is a method's result 52, a boxed receiver that is one 20; a boxed local receiver keeps master's C.

`make cident REF=upstream/master` on 5390d3002886: `6354 identical, 3 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: the new test, `test/bundle_hash_b1.rb` and `test/env_update_hash_kinds.rb`, each with a merge of this shape; all three pass. optcarrot's generated C is byte-identical. `test/hash_merge_converted_copy_held.rb`, also in the `SPINEL_GC_STRESS=2` list, raises the TypeError on master in a plain run, built with gcc or clang, and dies there under `SPINEL_GC_STRESS=1` and `2`; it passes with gcc and clang, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, not run under 4.0 here; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
