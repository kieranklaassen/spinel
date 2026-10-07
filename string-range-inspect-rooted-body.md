<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = "ab" * 3000
b = "cd" * 3000
r = (a..b)
bad = 0
20000.times do
  s = r.inspect
  bad += 1 unless s[1] == "a" && s[2] == "b" && s.size == 12006
end
p bad
```

prints 2000 in a plain run (`spinel diff`: output-diff). CRuby prints 0. Under `SPINEL_GC_STRESS=2` a bare `p ("aa".."ac")` prints four poisoned bytes where "aa" belongs.

`sp_srange_inspect` builds the begin's inspect and then the end's, and nothing held the first String while the second was allocated. It is rooted now. The test is in `GC_STRESS_TESTS`.

Cost: one root a call, 1,744 to 1,764 instructions for `r.inspect` on a short Range (callgrind on b06496ff, 100,000 calls). The change is in lib/sp_cold.c, so no generated C changes.

Not changed: a String Range whose bounds are computed inside the literal, `(a * 300..b * 300)`, is still wrong under `SPINEL_GC_STRESS=2`, and `puts (a * 300..b * 300).to_s`, which never calls inspect, prints poisoned bytes there too.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
