<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost first: a `Hash[h]` whose result is kept, changed, walked with a block or handed on now makes the copy, which costs what `h.dup` costs (table below). One that is written into a local of another kind of Hash, or is only read by the call it is the receiver of (`Hash[h].size`), is the C it was.

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

The `to_h` that rewrite made is now emitted as a new Hash filled from the old one: for a typed Hash in `emit_builtin_op_ex`, and for a boxed value in `sp_hash_brackets_one`, which copies a Hash and hands anything else to `sp_poly_to_h_m` as before. The default is not copied, as in CRuby. A `to_h` the program wrote still answers the Hash itself.

Three forms keep the C they had, because no program can tell the copy from the Hash there:

- `Hash[]` of a literal (`Hash[a: 1]`), which is new already.
- One written straight into a local of another kind of Hash, where the conversion builds the new Hash.
- One that is only the receiver of a call that reads it and has no block: `size`, `length`, `empty?`, `count`, `keys`, `values`, `to_a`, `first`, `key?`, `has_key?`, `include?`, `member?`, `[]`, `fetch`, `dig`, `merge`, `==`, `inspect`, `to_s`.

Instructions a turn of `c = Hash[g]; t += c.size` (callgrind, the difference of two run sizes), master a2bd8900 and this, beside `c = g.dup` on master:

| entries, keys | master | this | `g.dup` on master |
|---|---|---|---|
| 1, String | 15 | 999 | 959 |
| 8, String | 15 | 2,497 | 2,457 |
| 64, String | 15 | 21,548 | 21,508 |
| 1, Integer | 18 | 1,008 | 960 |
| 8, Integer | 18 | 1,547 | 1,499 |
| 64, Integer | 18 | 10,104 | 10,056 |

On master a2bd8900: `make cident` reports 6,375 identical, 1 differ (the new test); `make infer-test` passes. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`; on master 15 of its 36 lines are wrong. Of 176 generated programs that take `Hash[]` of a Hash that has a second name, 68 are refused on both, 32 keep master's C (the copy lands in a local of another kind) and 76 get other C: 4 that were wrong are right, 68 stay wrong in other lines (the second name's, not `Hash[]`'s) and 4 raise on both. None of the 108 is right on master.

Test: `test/hash_brackets_copies_hash.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
