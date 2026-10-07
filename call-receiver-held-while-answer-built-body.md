## What this changes

```ruby
def mk(i) = {a: i, b: i + 1}
bad = 0
20_000.times { |i| bad += 1 unless mk(i).compact.size == 2 }
p bad
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
-0
+10
```

Ten of the Hashes came back empty, in a plain run. With a second allocation of a varying size in the loop (`junk = Array.new(n % 200, 0)`), `mk(i) * 2` answers `[]` in 80 of 2,000,000 turns and `mk(i).invert` on a Symbol-keyed Hash is `spinel diff: crash` (SIGSEGV).

The arms of `emit_array_arith_call`, `emit_op_hash_invert`, `emit_op_hash_compact` and `emit_op_hash_flatten` bind the receiver to a temporary, allocate the answer and root it, and then read the receiver. A method's result is held by nothing else, and a collection at that allocation freed it. `flatten` shows it under `SPINEL_GC_STRESS=2` only.

The receiver's temporary is now rooted where the receiver runs code (`emit_fresh_recv_rooted`: `emit_recv_rooted` behind `subtree_has_side_effect`). A local, an instance variable and a literal are held already (a literal is built into a slot of the frame, whatever its elements run) and keep the C they had: 90 such programs compile byte for byte as on master.

Cost, at a receiver that is a call (callgrind, instructions a turn): `* 2` 773 against 762, invert 2,133 against 2,124, compact 1,695 against 1,680, flatten 1,121 against 1,110. None at a local or a literal.

On master b44861f8: `make cident` reports 6,352 identical, 2 differ: the new test and `test/hash_conformance_batch7.rb`, where `invert` is called on what `invert` answers; it passes, plain and under `SPINEL_GC_STRESS=2`.

Test: `test/fresh_receiver_held_while_answer_built.rb`, also in the `SPINEL_GC_STRESS=2` list. Six of its twelve loops count wrong answers on master in a plain run.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6, the one at hand; the test prints no Hash, so nothing in it differs between the two)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

