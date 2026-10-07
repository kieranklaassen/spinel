<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
m = ["xab-cd".match(/a(b)-(c)/), 0][ARGV.size]
p m&.captures&.size
```

- Master: it does not build (`incompatible type for argument 1 of 'sp_PolyArray_length'`).
- CRuby and here: `2`.

Nor do `m&.string&.size`, `m&.pre_match&.empty?`, `m&.begin(1)&.to_s` or `e&.with_index(1)&.to_a`, on a MatchData or an Enumerator read out of a container. Each first call alone builds since "A boxed handle's answer is boxed into a poly dispatch's slot": the handle's emitter asks what the call answers with the receiver pinned to the handle, and boxes that answer into the poly slot. But `infer_type` records what it answers on the call's node. Once the first call was emitted its node said Array (or String, or Integer) while its C value was the box, so the second `&.` picked the typed arm and handed it the box.

The question is now a pure read, between `an_pure_read_begin` and `an_pure_read_end`: the answer is used and nothing is recorded. Two lines in `emit_unresolved_call`.

Not here, with `.` or `&.`, on master and here:

- `m.names` and `m.named_captures` on a boxed MatchData answer `[]` and `{}`.
- `p e.with_index(1)` prints the inner Enumerator's text, `#<Enumerator: [4, 5]:each>`, boxed or not.

Test: `test/safe_nav_boxed_handle_chain.rb`, 26 lines, 34 expected; it does not build on master.

Generated C against master (`make cident REF=9274c732eaa2`): 6418 identical, 1 differ, 0 refusal changes. The one is the new test. optcarrot's generated C is byte-identical.

56 small programs written for this change (a second `&.` call of each kind on what `captures`, `names`, `to_a`, `named_captures`, `string`, `pre_match`, `post_match`, `offset`, `begin`, `end`, `byteoffset`, `values_at` and `size` answer on a boxed MatchData, and `with_index`, `each_with_index`, `with_object`, `next_values`, `peek_values`, `size`, `next`, `peek`, `rewind` and `to_a` on a boxed Enumerator, each with a nil receiver beside it), with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 23 are right in all six on master, 51 here. The 28 more did not build. No program loses a cell; the five left print the same on both (the first point above, and `with_object`, which a boxed Enumerator does not answer).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
