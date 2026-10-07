<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Hash#sort_by` with a block whose value allocates answers pairs out of order in a plain run. This sorts one Hash six times and counts the sorts that are out of order:

```ruby
h = {}
30000.times { |i| h[(i * 7919) % 30011] = i }
bad = 0
6.times do |r|
  s = h.sort_by { |k, _v| k.to_s.rjust(40, "0") }
  ok = s.size == 30000
  i = 1
  while ok && i < s.size
    ok = false if s[i - 1][0] >= s[i][0]
    i += 1
  end
  bad += 1 unless ok
end
p bad
```

```
spinel diff: output-diff
  program: sort_by_six.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+4
```

With `{ |k, v| [v % 7, k] }` as the block some of the six sorts are wrong too (gcc and clang print the same counts). In the test, `h.sort_by { |k, v| [v.size, v] }` over 6,000 String entries raises `comparison of Array with Array failed (ArgumentError)`, and under `SPINEL_GC_STRESS=2` three entries are enough: `{1 => 1, 2 => 2, 3 => 7}.sort_by { |k, _v| k.to_s }` aborts in the mark. With this change `spinel diff` reports `same` for these programs.

Cause: `emit_hash_sort_by_expr` evaluated the block into the plain C temporary of `emit_hash_block_eval` and only then emitted the `[sort_key, pair]` tuple's `sp_PolyArray_new()`, so a collection at that allocation freed the block's value before `sp_PolyArray_push` stored it.

Cure: where the block's value can hold a reference (`ty_gc_holds_refs`), the tuple is allocated before the block runs (one emitted line moves up; no root, no new statement). It is rooted and empty meanwhile, and the push that stores the value cannot collect: a new tuple has room for it, and the boxing helpers that allocate root what they are given. An Integer, a Float, a Symbol, true, false, nil, a Rational or a Time holds none, and a block with such a value keeps its C byte for byte. `min_by(n)`, `sort_by { }.to_h` and `sort_by { }.first(n)` on a Hash take the same lines.

Cost where the line moves: 4 instructions an entry with gcc (2,714 to 2,718; callgrind, `h.sort_by { |k, v| v + t }` over a Hash of 100 Strings) and 2 with clang. A block with an Integer value costs what it did.

Checked with 553 generated programs, gcc and clang, with and without `--share-strings`: master prints CRuby's answer for 527 in a plain run, 480 under `SPINEL_GC_STRESS=1` and 301 under `SPINEL_GC_STRESS=2`, and this branch for all 553 at each; none is right on master and wrong here. The generated C of 7 corpus programs changes, each by the moved line, and optcarrot's is unchanged.

Not here: `(a + b).to_sym` on a String nothing else holds leaves a Symbol with a freed name under `SPINEL_GC_STRESS=2` (there `h.map { |k, v| (v + t).to_sym }` prints wrong Symbols). A sort_by with such a block value sorts wrong there as before, and one over a Hash with such keys, which aborted on master, now runs on and prints them; with the sort_by replaced by one over the value itself, master prints the same bytes.

Test: `test/hash_sort_by_fresh_key.rb`. On master 7 of its 48 lines differ in a plain run (the six sorts of 500 entries, two orders at larger sizes, then the false ArgumentError).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
