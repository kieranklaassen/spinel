## What this changes

```ruby
def mk(i) = {i => "a", -1 => "b"}
bad = 0
200_000.times { |i| bad += 1 unless mk(i).invert.size == 2 }
p bad
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
-0
+98
```

in a plain run. With a second allocation of a varying size in the loop it is `spinel diff: crash` (SIGSEGV), and so is the same loop over `{"a" => i, "b" => -1}`.

`sp_IntStrHash_invert` and `sp_StrIntHash_invert_poly` allocate the answer before they read the Hash they invert. A method's result is held by nothing else, and a collection at that allocation freed it.

Each now opens with `SP_GC_ROOT(h)`; `sp_StrStrHash_invert` already holds its own. No generated C changes. Cost (callgrind, instructions a call on a Hash in a local): 1,438 against 1,435 for String keys, 1,377 against 1,373 for Integer keys.

On master b44861f8: `make cident` reports 6,354 identical, 0 differ.

Test: `test/hash_invert_receiver_rooted.rb`, also in the `SPINEL_GC_STRESS=2` list. It dies by SIGSEGV on master in a plain run.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (made with CRuby 3.3.6, the one at hand; the test prints no Hash, so nothing in it differs between the two)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

