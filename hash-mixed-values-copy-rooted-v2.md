<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def mk(i) = {"a" => i, "b" => "lit", "c" => i + 1}

bad = 0
20_000.times { |i| bad += 1 unless mk(i).dup.length == 3 }
p bad   # 0 in CRuby; 10 here
```

```
spinel diff: output-diff
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+10
```

Built with gcc or clang: ten of the copies come back empty. `sp_StrPolyHash_dup` and `sp_SymPolyHash_dup` allocate the copy before they read the Hash they copy, and a method's result is held by nothing else: a collection at that allocation freed it, and the loop then ran over a length of zero. `clone`, `merge` with no argument and `merge({})` end in the same two functions.

Each now opens with `SP_GC_ROOT(h)`, as `sp_StrIntHash_dup`, `sp_StrStrHash_dup`, `sp_IntStrHash_dup`, `sp_IntIntHash_dup` and `sp_PolyPolyHash_dup` do.

Measured on 25 programs, gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: `dup`, `clone`, `merge`, `merge({})` and a local's `dup`, over String keys with mixed values, Symbol keys with Integer values and with mixed ones, and two kinds that were right (String values, keys of any kind). In a plain run and under stress 2, 13 are right on master and 25 here, with either compiler; no program right on master is wrong here.

`mk(i).merge({})` is cured here: the empty literal is folded away and the call is emitted as `sp_StrPolyHash_dup(sp_mk(i))`, a copy with nothing made beside it, so how a call's operands are ordered does not reach it.

Cost: the root, 18 instructions of about 1,207 a copy (callgrind, 200,000 turns of `h.dup`: 241,563,709 on master, 245,170,682 here).

`make cident REF=upstream/master` on 5390d3002886: `6357 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`: a runtime change, no generated C moves. `test/hash_mixed_values_copy_rooted.rb`, also in the `SPINEL_GC_STRESS=2` list, prints 1 or 2 for each 0 on master in a plain run, built with gcc or clang, and fails there under stress 2 and under minor collections too; it passes with both, plain, under `SPINEL_GC_STRESS=1` and `2`, and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints no Hash, whose inspect changed after 3.3)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
