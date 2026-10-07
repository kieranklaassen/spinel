<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost first: a Hash walk whose block can leave a Hash shorter pays 0 to 7 instructions a turn in `each`, `each_key` and `each_value`, and 4 to 15 in the walks built on `each` (table below). The list that decides cannot prove a block harmless where it calls a method defined in a class, a proc, a block of its own (`times`, `each`, `map`) or a method on a boxed value; a block of reads, writes, builtin calls on typed values and calls of harmless methods of the program is proved, and its walk is the C it was.

```ruby
h = {"a" => 1, "b" => 2, "c" => 3}
h.each { |k, _v| h.delete(k) }
p h
```

```
spinel diff: output-diff
  program: unit.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-{}
+{"b" => 2}
```

Deleting the entry a walk is at slides the next one into its slot, and the walk stepped past it. `each` and `each_pair` already stay on the slot for Integer and Symbol keys. String keys, boxed keys, and `each_key` and `each_value` with any key did not, and neither did the walks built on `each` over such a Hash: `each_with_index`, `each_with_object`, `each_entry`, `cycle`, `count`, `find`, `find_index`, `any?`, `all?`, `none?`, `one?`, `filter_map`, `flat_map`, `group_by`, `min_by`, `max_by`, `partition`, `take_while` and `drop_while`.

Such a walk keeps the key of the turn in a temporary, and on a turn that left the Hash shorter it steps only if the slot still holds that entry. The key is compared by identity and never read through (a String key's pointer, an Integer's or a Symbol's word, a boxed key's tag and word), so a NaN key is itself and a key the turn deleted needs no root. Every turn that does not step has made the Hash shorter, so the walk ends.

Only a walk whose block can leave a Hash shorter takes the step. `subtree_may_shrink_hash`, beside `subtree_may_run_proc`, says it cannot for reads, writes of variables, conditions and loops, blockless builtin calls over numbers, Strings, Symbols and typed Arrays, `puts` and `p` of those, a lookup or a store in a Hash whose keys run no code, an append and a `raise`. A method of the program called by its bare name is asked through its body, and where a method being spliced yields, the caller's block is. It is a list of what is known not to, so a node or a call it does not name takes the step.

Instructions a turn for a walk that takes the step and deletes nothing (callgrind; a Hash of 8 walked 12,500 times by `{ |k, v| t += o.f(1) }`, where `f` is a method of a class of the program), master 8dc5522 and this:

| keys | `each` | `each_key` | `each_value` | `count` | `flat_map` |
|---|---|---|---|---|---|
| String | 109.1 → 112.4 | 19.8 → 18.7 | 104.6 → 111.7 | 475.5 → 480.2 | 868.0 → 880.6 |
| Integer | same C | 16.8 → 16.5 | 39.5 → 46.2 | same C | same C |
| Symbol | same C | 16.8 → 16.5 | 43.5 → 50.8 | same C | same C |
| two kinds (boxed) | 25.0 → 25.0 | 22.8 → 20.8 | 22.8 → 20.8 | 388.9 → 399.1 | 784.7 → 799.2 |

The other walks built on `each` pay 3.7 to 7.8 a turn over String keys and 8.8 to 10.6 over boxed keys.

In `each` and `each_pair` a turn that deletes and a later turn that adds raises as CRuby does: the length an added key is measured against now follows the delete.

Not in this change:

- `map`, `select`, `reject`, `sum`, `sort_by`, `to_h`, `transform_values` and `transform_keys` still step past the entry.
- A walk over a Hash held in a boxed variable (a local given two kinds of value) is emitted elsewhere and still steps past it.
- A turn that deletes two entries at or before the one the walk is at skipped two entries and skips one.
- A turn that deletes an entry and adds one goes on, where CRuby raises "can't add a new key into hash during iteration"; in `each_key` and `each_value` an added key never raises.

Measured on master 8dc5522:

- `make cident`: 6,362 identical, 85 differ, no refusal changes. The 84 beside the new test are walks whose block calls a method of a class, a block of its own or a method on a boxed value; they take the step and pay the cost above.
- `make infer-test` passes. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc and with clang, with and without `--share-strings`.
- 3,780 generated programs (7 kinds of key, 30 walks, 18 block bodies), in the three modes: 2,066 keep master's C. Of the 1,714 that get other C, 1,322 that were wrong are right, 269 were right and are, and 123 are wrong on both (119 delete and add in one turn, 4 add in `each_key` or `each_value`). None that was right is not, and none that raised prints a wrong answer. (The three modes were run on master 9274c732; every program's C is byte for byte the same there and on 8dc5522, with and without this change.)
- 504 programs that shorten the Hash some other way (through a method of the program and what it calls, a default, a proc, `send`, an alias, `reject!`, `shift`, `clear`), in the three modes: 402 that were wrong are right, 42 were right and are, 8 raise and 4 are refused on both, and 48 are wrong on both. In 42 of those the method that deletes is never called, here or on master (a builtin the program reopens, a singleton method, `to_ary`, `===`, a top-level `alias` over a name that has a body); in 6 `replace` in a walk goes on where CRuby raises. None that was right is not.

Test: `test/hash_walk_deletes_current_key.rb`. Master prints 20 of its 35 lines wrong.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
