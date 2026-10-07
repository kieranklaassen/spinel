## What this changes

```ruby
h = {a: 1}
g = h
m = {1 => :a}
g.merge!(m)
p h.to_a
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
-[[:a, 1], [1, :a]]
+[[:a, 1]]
```

The argument widened `g` to the poly-keyed variant while `h` kept its literal's, so `g = h` was written as a conversion, which builds another Hash, and what went in through `g` never reached `h`. The same entries were lost the other way round (`h.merge!(m)`, read through `g`), with `update`, `replace` and a store in a block. Where the two variants have no conversion between them (`m = {"k" => 2}`) the write was refused.

The alias loop in `infer_write_types` already gives an Array under two names the boxed kind on both. A Hash now takes the poly-keyed variant on both and keeps it: the literal is marked for it and the slots are pinned, as `widen_arg_hash` does for a caller's local. It does so where each local is written once, with a literal, `Hash.new` or another such local.

What was chosen:

- Two String-keyed names given a value of another kind take the poly-keyed variant too, not the String-keyed one with boxed values. Nothing pins that variant across rounds; derived again each round it came after the round's writes were typed, and a copy kept in a local (`c = h.dup`) was refused. The cost: `h["c"]` on such a Hash is 289 instructions against 157, a store 321 against 174 (callgrind).
- Two names are joined on kinds each had last round too. A second name is typed from the first before the first's own stores widen it, so it runs a round behind and often reaches the same kind by itself; joined a round early, a kind that is kept would be the wrong one. A changed program takes at most two rounds more.
- Not changed, and still converting: a local written twice, a conditional (`g = c ? h : k`), a parameter, and a Hash that came from a call, an instance variable, a global, a constant or an element.

Measured on master dafa0d04 with the fix for a Hash parameter given two kinds of value under it, against CRuby 3.3.6, plain and under `SPINEL_GC_STRESS=1` and `2`: of 47,871 generated programs (a Hash, a second name, a change through one and a read through the other, copies, methods that store into a parameter) 29,234 get the same C and 3,071 are refused on both sides. Of the other 15,566, 15,531 are right in all three runs; master refuses 4,704 of the 15,566. 23 print on where CRuby raises (an Integer method or `t += v` on a String value, `sort_by` over mixed values): 14 do on master too, 9 are refused there. 12 are right plain and under stress 1 and abort under stress 2 ("the mark reached a freed heap string"), 11 of them in `h.sort_by { |k, _v| k.to_s }`, which aborts so on master for `h = {1 => 1, 2 => 2, 3 => 7}` alone; on master 3 of the 12 abort the same way, 6 are wrong and 3 are refused. None that is right on master is wrong, refused or not building here, and none reaches the round cap.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
