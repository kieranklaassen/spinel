<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def mk(i) = {i => "a", -1 => "b"}
bad = 0
200_000.times { |i| bad += 1 unless mk(i).invert.size == 2 }
p bad
```

```
spinel diff: output-diff
  program: invert.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+98
```

in a plain run. With a second allocation of a varying size each turn, as in the test, the loop dies by SIGSEGV. The same loop over `{"a" => i, "b" => -1}` dies under `SPINEL_GC_STRESS=1` and answers wrong on every turn under `SPINEL_GC_STRESS=2`; a plain run of it was right for 1,000,000 turns on this master.

`sp_IntStrHash_invert` and `sp_StrIntHash_invert_poly` allocate the answer before they read the Hash they invert. A method's result is held by nothing else, and a collection at that allocation freed it.

Each now opens with `SP_GC_ROOT(h)`; `sp_StrStrHash_invert` already holds its own. The change is in `lib/spinel_rt.h` only, so no generated C changes. Cost (callgrind, instructions a call on a Hash in a local): 1,443 against 1,439 for String keys, 1,381 against 1,371 for Integer keys.

Test: `test/hash_invert_receiver_rooted.rb`, also in the `SPINEL_GC_STRESS=2` list. On master a2bd8900 it dies by SIGSEGV in a plain run (after its first line) and under `SPINEL_GC_STRESS=1`, and counts every turn of both loops wrong under `SPINEL_GC_STRESS=2`; here it passes in the three.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6; not run under 4.0 here)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
