<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
m = ["xab-cd".match(/a(b)-(c)/), 0][ARGV.size]
p m&.captures&.size
```

- Master: it does not build (`incompatible type for argument 1 of 'sp_PolyArray_length'`).
- CRuby and here: `2`.

Nor do `m&.string&.size`, `m&.pre_match&.empty?`, `m&.begin(1)&.to_s` or `e&.with_index(1)&.to_a`, on a MatchData or an Enumerator read out of a container; nor `a&.ip_address&.size` on a boxed Addrinfo, nor a first call handed on as an argument (`sz(m&.captures)`), nor a first `&.` alone on a handle read out by an index or a key (`p xs[0]&.pre_match`, `h[:m]&.string`). On a local, each first call alone builds since "A boxed handle's answer is boxed into a poly dispatch's slot": the handle's emitter asks what the call answers with the receiver pinned to the handle, and boxes that answer into the poly slot. But `infer_type` records what it answers on the call's node. Once the first call was emitted its node said Array (or String, or Integer) while its C value was the box, so the second `&.` picked the typed arm and handed it the box.

For a `&.` call the question is now a pure read, between `an_pure_read_begin` and `an_pure_read_end`: the answer is used and nothing is recorded. A `.` call's C value is the handle's own answer, so it keeps the record and master's C: `xs[0].string == xs[0].pre_match + "llo"` is typed by it.

Two places keep the recorded question for a `&.` call too, because their C is right as it is and reads the record:

- A `&.` chain that is a statement (`m&.captures&.size` on a line of its own). `emit_iteration_stmt_sn` tries such a statement as a loop first, and the statement emitted after it declines is typed by what that try recorded. A flag set around the try (`g_sn_stmt_probe`) keeps the record there.
- The call as an operand of an `==` or a `!=` that the typed comparison folds to a constant: `m&.string == "b".nil?` is `false` whatever `m` is, and master emits no comparison for it. `handle_answer_folds` lists what is folded: the other operand is `true` or `false`, or an Integer or a Float that cannot be nil, and is of another kind than the handle's answer.

Not here, with `.` or `&.`, on master and here:

- `m.names` and `m.named_captures` on a boxed MatchData of a Regexp with named groups answer `[]` and `{}`.
- `p e.with_index(1)` prints the inner Enumerator's text, `#<Enumerator: [4, 5]:each>`, boxed or not.
- A true-or-false reader of a boxed Addrinfo followed by `&.` (`a&.ipv4?&.to_s`) does not build.
- `.class` on the first call's answer with a further link (`m&.captures&.class&.name`) does not build.
- An iterator with a block on the chain, as a statement: `m&.captures&.each { |c| p c }` does not build. The statement keeps the recorded question, the first point above.

Test: `test/safe_nav_boxed_handle_chain.rb`, 32 lines, 38 of output; it does not build on master.

Generated C against the commit this stands on (`make cident`, both on 3d629868df96): 6499 identical, 1 differ, 0 refusal changes; no compile met cident's time or memory bound. The one is the new test. optcarrot's generated C is byte-identical.

Three sets of small programs, measured on 3d629868df96 against the commit this stands on, with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`. 50 from the boxed handle work (a MatchData, an Enumerator and an Addrinfo out of a container, nil and not, a reader of each kind, alone and under a second `&.`): 44 have that commit's C; the 6 that differ did not build and are right in all six here. 360 with a MatchData read out of an Array by an index or out of a Hash by a key (the element a MatchData or nil; `&.` and `.`; `pre_match`, `post_match`, `string`, `captures` and `begin(0)`; printed, under a further call, interpolated, assigned, in an Array literal, on either side of `==` and as an argument): the 180 with `.` have that commit's C; the 180 with `&.` did not build and are right in all six here. 2,048 with the call as an operand of `==` or `!=` (a MatchData or nil; four readers; `&.` and `.`; eight kinds of other operand, on either side; printed, assigned, as a condition and under `&&`): every one has that commit's C. No program loses a cell.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A &. statement evaluates its receiver once", and the first commit of "A `&.` call whose value hoists builds, and runs in its place", which makes `node_parent`: this commit stands on both)
