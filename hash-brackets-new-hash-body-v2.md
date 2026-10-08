<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost first: on master `Hash[h]` is `h` itself and costs nothing. A `Hash[h]` whose result is kept, changed, walked with a block or handed on now makes the copy, so a program that was right because it only read what it kept (`c = Hash[h]; p c.size`) pays for a copy it did not need. For a typed Hash that is what `h.dup` costs. For a Hash held in a boxed variable (a local given two kinds of value) it is 1.4 to 2 times `h.dup` where the keys are typed, because the copy there is a Hash that takes any key and value, and under half of `h.dup` where the keys are boxed already (table below). One that is written into a local of another kind of Hash, or is only read by the call it is the receiver of (`Hash[h].size`), is the C it was.

```ruby
g = {"a" => 1}
c = Hash[g]
c["b"] = 2
p g.size
```

```
spinel diff: output-diff
  program: brackets.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-1
+2
```

`c` was `g` itself, and every write through the copy landed in the original. `Hash[x]` is rewritten to `x.to_h` before `x` has a type, and a Hash's `to_h` answers the Hash.

The `to_h` that rewrite made is emitted as a new Hash of the old one's entries: for a typed Hash in `emit_builtin_op_ex`, and for a boxed value in `sp_hash_brackets_one`, which copies a Hash and hands anything else to `sp_poly_to_h_m` as before. A boxed table is copied as it stands (`sp_PolyPolyHash_copy_table`), so a key changed after it went in stays where it was put, as in CRuby; a Hash of another kind is read entry by entry, once. The copy takes neither the default nor the frozen state. `nil` is no Hash: ArgumentError, "odd number of arguments for Hash".

The copy is held for the whole statement: a call it is the receiver of (`Hash[h].invert`, `Hash[h].dup`) allocates before anything else holds it. Its slot is declared and rooted in the statement's prelude and assigned where the expression runs. A `to_h` the program wrote still answers the Hash itself.

A Hash in a boxed variable is copied into a Hash of boxed keys and not into one of its own kind, which is what `dup` makes: a later store of another kind into the same-kind copy raises TypeError ("the hash was not widened for this store"), and the new Hash takes it as CRuby's does.

Three forms keep the C they had:

- `Hash[]` of a literal (`Hash[a: 1]`), which is new already.
- One written straight into a local of another kind of Hash, where the conversion builds the new Hash.
- One that is only the receiver of a call that reads it and has no block: `size`, `length`, `empty?`, `count`, `keys`, `values`, `to_a`, `first`, `key?`, `has_key?`, `include?`, `member?`, `[]`, `fetch`, `dig`, `merge`, `==`, `inspect`, `to_s`.

Instructions an entry for `c = Hash[h]` beside `c = h.dup` (callgrind; a Hash of 8 copied 20,000 times, the loop without the copy taken off; `h.dup` is the same on master 548d4196 and here):

| keys, values | `Hash[h]`, typed `h` | `h.dup` | `Hash[h]`, `h` in a boxed variable | `h.dup` |
|---|---|---|---|---|
| Integer, Integer | 176.4 | 170.5 | 340.9 | 181.0 |
| Symbol, Integer | 177.4 | 168.4 | 349.7 | 179.0 |
| String, Integer | 292.2 | 287.3 | 444.2 | 297.2 |
| String, String | 308.1 | 303.2 | 449.1 | 313.1 |
| String, two kinds | 275.4 | 266.2 | 411.7 | 276.7 |
| two kinds, Integer | 140.2 | 316.9 | 139.3 | 327.0 |

On master the same `Hash[h]` is 0 to 6 instructions a copy: it copies nothing.

Not in this change (each is the C it was, and prints what it printed):

- A default read through the copy in a read form: `Hash[h]["zz"]` answers `h`'s default where CRuby answers nil.
- A `Hash[h]` written straight into a local of another kind of Hash keeps `h`'s default, and raises FrozenError on a store where `h` is frozen.
- An argument that changes `h` in a read form: `Hash[h].fetch((h.delete("a"); "a"), 0)` answers 0 where CRuby answers the value.
- `Hash[nil]` in a read form (`Hash[n].size`) still dies by SIGSEGV; everywhere else it raises the ArgumentError.
- A boxed value is not copied where a class of the program defines `to_h`.

Measured on master 548d4196:

- `make cident` reports 6,484 identical, 1 differ (the new test), no refusal changes; `make infer-test` passes.
- The test passes plain and under `SPINEL_GC_STRESS=1` and `2`, built with gcc and with clang, with and without `--share-strings`.
- 1,869 generated programs (7 kinds of Hash; held in a typed local, a boxed variable or an instance variable, or answered by a method; 67 uses of `Hash[h]`), in the three modes on both trees: 418 are as they were (390 get the C they had; 28, `Hash[h].compare_by_identity`, are refused on both). Of the 1,451 that get other C: 774 that are right stay right; 542 that print a wrong line are right here; 32 that raise are right here; 43 that master runs right plain and wrong or dead under stress are right in all three; 50 print a wrong line on both (28 with `nil` in a local that also holds a Hash, which print 0 where CRuby raises; 22 that delete from the copy while walking it, where the copy's size is wrong and the original's is now right); 4 raise on both (a default asked of the copy); 6 are right plain and under `SPINEL_GC_STRESS=1` and die under `2` on both, in `Hash[h].sort_by { |k, v| k.to_s }`, where `sort_by` loses the block's String with or without the copy. None that was right is wrong, and none that raised prints a wrong line.
- The three modes were run on master 42557a3c. On 548d4196 every one of the 1,869 has the C it has there, with and without this change, and a sample of 189 of them (every kind of Hash and every holder, 54 of the 67 uses) was run again in the three modes on both trees, with the same result for each.

Test: `test/hash_brackets_copies_hash.rb`. Master prints 17 of its 43 lines wrong and dies by SIGSEGV at the `nil` line.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
