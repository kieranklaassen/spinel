<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def mk(i) = {a: "x#{i}", b: "lit", c: "z"}
sig = 0
3000.times do |i|
  junk = Array.new(i % 200, 0)
  r = mk(i).each_value.to_a
  sig += r.to_s.size + r.inspect.sum
end
p sig
```

```
spinel diff: output-diff
  program: each_value.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-3961110
+3961208
```

in a plain run.

`sp_enum_hash_side`, which makes the Array for `each_key.to_a` and `each_value.to_a`, allocates it before it reads the Hash. `sp_file_extname` allocates its answer before it copies from `path`. `sp_file_basename2` roots `path` and `suffix` but not the fresh String `sp_file_basename` just answered, across its own allocation. A value made in the call is held by nothing else there. The two File functions show it under `SPINEL_GC_STRESS=2`, where `File.basename(s + ".rb", ".rb") + File.extname(s + ".txt")` came back as bytes of 0xdb; no plain run of them did in 2,000,000 turns of each.

Each now roots what it reads. The change is in `lib/` only, so no generated C changes. Cost (callgrind, instructions a call, master a2bd8900 and this): `File.extname` 378 → 396, `File.basename` with a suffix 628 → 655; `each_key.to_a` and `each_value.to_a` measure the same (1,221 → 1,220).

Not in this change: `File.basename` with both arguments made in the call (`File.basename("dir/f#{i}.rb", suf(i))`) still aborts under `SPINEL_GC_STRESS=2`. The two operands are the caller's to hold.

On master a2bd8900, merged: `make cident` reports 6,377 identical, 0 differ. The new test passes plain and under `SPINEL_GC_STRESS=1` and `2`; on master its first line is wrong in a plain run and under mode 1, and ten of its lines under mode 2.

Test: `test/hash_side_file_name_arg_rooted.rb`, also in the `SPINEL_GC_STRESS=2` list.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: the pull request "A Hash of mixed values is held while its copy is made"
