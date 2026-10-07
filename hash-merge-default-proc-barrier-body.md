<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Hash made by `merge` from a receiver with a default proc lost the proc at the next minor collection, and a missing key answered with another Hash's default.

Cost: a merge whose receiver has a default proc pays 14 instructions (0.5% of the merge, built with gcc); every other merge costs the same to the instruction.

```ruby
names = Hash.new { |hash, k| "name #{k}" }
codes = Hash.new { |hash, k| "code #{k}" }
extra = {}
ring = Array.new(4096) { names.merge(extra) }
wrong = 0
600_000.times do |i|
  ring[i % 4096] = i.even? ? names.merge(extra) : codes.merge(extra)
  spare = Array.new(40) { |k| [k, i] }
  j = i - 4095
  wrong += 1 if j >= 0 && ring[j % 4096][7] != (j.even? ? "name 7" : "code 7")
end
p wrong
```

Master (759d120fd) prints `19`, built with gcc and with clang; `209366` under `SPINEL_GC_STRESS=1`, `0` with `SPINEL_GC_MINOR=0`. CRuby prints `0`.

`sp_poly_hash_merge` hands the receiver's default proc to the Hash it builds through a context object, allocated after that Hash. The allocation can collect; the new Hash is old after it, and the context was stored with no write barrier, so the next minor collection freed it and a missing key called through the freed slot. A merge that stores a pair records the new Hash by that store, so a plain run shows it only for two empty Hashes; under `SPINEL_GC_STRESS=2` any merge of a Hash with a default proc stops with "the mark reached a freed slot". The new Hash now takes the write barrier there, ahead of the two stores, where nothing allocates between: one line in `lib/sp_poly_cold.c`, in the branch only a receiver with a default proc enters.

Not in this change: a default block that stores (`Hash.new { |hash, k| hash[k] = "made #{k}" }`) stores into the receiver of the merge, not into its result, here as on master: `m[77]` answers, `m.size` and `m.fetch(77, :none)` do not see the pair.

No file of `src/` is touched: the generated C is the same for every program.

208 programs, each against CRuby, in a plain run and under `SPINEL_GC_STRESS=2`: eight Hashes with a default proc (Integer, String, Symbol and mixed keys, empty, `default_proc=`, a block that stores, a block that reads a local) by 26 ways to copy one (`merge` with one, two and no arguments, with an empty Hash, with a block, twice, with itself, as the argument, from a boxed receiver, a parameter and an instance variable; `merge!`, `update`, `dup`, `clone`, `to_h`, `select`, `reject`, `compact`, `transform_values`). 140 do not reach the function and are right before and after. Of the 68 that do, 51 are right in a plain run and stop under stress on master, and are right in both now; 7 are right in both before and after; 10 are the block that stores above, wrong in a plain run before and after, where master stops under stress and this prints the plain run's answer.

Cost under callgrind, 20,000 merges, instructions a merge before and after (the unit is compiled once, by gcc 13.3 here): no default proc 3,188 and 3,188; a default proc and one pair 2,674 and 2,688; a default proc and two empty Hashes 1,595 and 1,609. gcc lays two other functions of the unit out differently (`sp_rbval_hash_key`, `sp_enum_items_from`); `merge` over six kinds of key, `dup`, `slice`, `to_h`, `to_a` and `each_slice.to_a` of a boxed Hash cost the same to the instruction. Compiled by clang 18.1 the unit differs in `sp_poly_hash_merge` alone.

Test: `test/hash_merge_default_proc_barrier.rb`, in `GC_STRESS_TESTS`, 7 lines; master stops at its first line under `SPINEL_GC_STRESS=2`, with gcc and with clang, and prints its `.expected` in a plain run.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
