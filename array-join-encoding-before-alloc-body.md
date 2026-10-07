<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def pair(d, i) = [d.byteslice(7 + i % 2, 8), d.byteslice(0, 8)]
src = ("\xC3\xA9\xC3\xA9\xFF\xC3\xA9" + "z" * 12).b
utf8 = 0
k = 0
while k < 200_000
  r = pair(src, k).join
  utf8 += 1 if r.encoding.to_s != "ASCII-8BIT"
  k += 1
end
p utf8   # 7, CRuby: 0
```

`sp_StrArray_join` copied the pieces into a buffer, allocated the result, and then walked the Array a second time to pick the result's encoding. It roots nothing, and that allocation can collect: an Array only the call holds (a method's value, as here) was freed with its elements, and the second walk read their lengths and binary marks out of freed memory. Where the result took the slot of the piece with the high bytes, a join of binary pieces answered UTF-8. The second walk came with "Interpolation and Array#join pick their encoding as CRuby does"; the interpolation roots its parts and the boxed join roots its Array, so only the typed join is affected. The encoding is now picked in the loop that copies, before the result is allocated.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-0
+7
```

A plain run is wrong for 7 of the 200,000 joins; at `SPINEL_GC_STRESS=2` for 25,000. One walk for two is cheaper: 200,000 joins of three Strings with a separator go from 135.3M to 127.5M instructions (callgrind). No generated C changes. Test: `test/array_join_encoding_before_alloc.rb`, added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
