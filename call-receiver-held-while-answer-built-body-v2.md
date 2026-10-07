<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def mk(i) = {a: i, b: i + 1}
bad = 0
20_000.times { |i| bad += 1 unless mk(i).compact.size == 2 }
p bad
```

```
spinel diff: output-diff
  program: compact.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+10
```

Ten of the Hashes came back empty, in a plain run. With a second allocation of a varying size in the loop (`junk = Array.new(n % 200, 0)`), `mk(i) * 2` answers `[]` in 80 of 2,000,000 turns and `mk(i).invert` on a Symbol-keyed Hash dies by SIGSEGV.

The arms of `emit_array_arith_call`, `emit_op_hash_invert`, `emit_op_hash_compact` and `emit_op_hash_flatten` bind the receiver to a temporary, allocate the answer and root it, and then read the receiver. A method's result is held by nothing else, and a collection at that allocation freed it. `flatten` shows it under `SPINEL_GC_STRESS=2` only.

The receiver's temporary is now rooted where the receiver runs code (`emit_fresh_recv_rooted`: `emit_recv_rooted` behind `subtree_has_side_effect`). A local, an instance variable and a literal are held already (a literal is built into a slot of the frame, whatever its elements run) and keep the C they had.

Cost, at a receiver that is a call (callgrind, instructions a turn, master a2bd8900 and this): `* 2` 762 → 773, invert 2,122 → 2,131, compact 1,680 → 1,695, flatten 1,110 → 1,122. None at a local (424 → 424) or a literal.

Not in this change: a conditional or a `case` whose arms are literals runs no code, so as a receiver it keeps the C it had and is not held. `((i > 5 ? [i, 1] : [i, 2]) * 2).size == 4` beside the same second allocation fails in 82 of 2,000,000 turns, before and after.

On master a2bd8900, merged: `make cident` reports 6,375 identical, 2 differ: the new test and `test/hash_conformance_batch7.rb`, where `invert` is called on what `invert` answers: under `SPINEL_GC_STRESS=2` it prints `{}` for `{a: 1, b: 2}` on master and passes here. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`; on master six of its twelve loops count wrong answers in a plain run and it dies by SIGSEGV under both stress modes.

Test: `test/fresh_receiver_held_while_answer_built.rb`, also in the `SPINEL_GC_STRESS=2` list.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A Hash of mixed values is held while its copy is made"
