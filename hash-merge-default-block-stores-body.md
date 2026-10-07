<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A default block carried into a merged Hash was given the receiver of `merge`, not the Hash that was read: a block that stores stored into the receiver. The cure costs one instruction a read that runs the default block through a merged Hash (147 to 148 with gcc 13.3, 144 to 145 with clang 18.1); a merge, a read that finds its key, a Hash that was never merged and one whose default was set by `default_proc=` cost the same to the instruction.

```ruby
words = Hash.new { |hash, key| hash[key] = "made #{key}" }
words[:a] = "a"
extra = {}
extra[:b] = "b"
merged = words.merge(extra)
p merged[:zz]
p merged.size
p words.size
p words.key?(:zz)
```

Master (8dc552254) prints `"made zz"`, `2`, `2`, `true`. CRuby prints `"made zz"`, `3`, `1`, `false`.

`merge` gives its result the receiver's default block through `sp_poly_hash_dproc_bridge`, which keeps the receiver. Where the default was set by `default_proc=` on a String- or Symbol-keyed Hash the bridge hands the block the result. Where it came from `Hash.new { }` it handed the block the receiver, so the key appeared in the receiver, the result never kept it and ran the block at every read, and a block that reads its Hash (`hash.size`) read the receiver. The bridge hands that block the result too: in `lib/spinel_rt.h` one word of that function changes (`ph` to `h`) and its `(void)h;` goes, the parameter being read now. `dup`, `clone` and a merge of a merge go through the same bridge.

Depends on the pull request that makes a merged Hash's default proc survive a minor collection: without it the test stops at the merge under `SPINEL_GC_STRESS=2`.

600 programs, each line against CRuby, before and after: a default from `Hash.new { }` and from `default_proc=`, Integer, String and Symbol keys, ten blocks (three that store, ones that read the Hash's size, a key, its keys or another key, one that stores through a captured Array, one that asks which Hash it was given), ten ways to copy (`merge` with a variable, a literal, twice, two arguments, none, a block; `dup`, `clone`, `merge!`, a splat). 472 are right before and after and 128 were wrong and are right; none is wrong now.

`make cident` against that pull request: 6449 identical, 0 differ; the change is in the runtime.

Test: `test/hash_merge_default_proc_stores.rb` prints 11 lines; master is wrong in 7.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (A merged Hash's default proc survives a minor collection)
