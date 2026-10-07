<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = {" " => "_"}
s = ("abcdefghij" * 40 + " ") * 2000
n = 0
8.times do
  t = s.gsub(" ", h)
  n += t.size if t[400] == "_" && $~[0] == " "
end
p n
```

exits 139 in a plain run (`spinel diff`: crash, SIGSEGV). CRuby prints 6416000. With short Strings the result is silently another String: in 200,000 rounds of `r = w.gsub("l", h)` on `"hello" + i.to_s`, one round answers the String the next line makes. A program that never reads `$~` is right, and so are `sub` with a Hash and `gsub` with a String replacement.

`sp_str_gsub_str_str_hash` built its result and then set the match, which allocates, while the result sat in a C local with no root. Now the result is rooted across that one call, inside the branch a program that reads `$~` takes. The match is set where it was set before and nowhere else. The test is in `GC_STRESS_TESTS`.

Cost: `"hello".gsub("l", h)` goes from 1,279 to 1,299 instructions a call in a program that reads `$~` and from 978 to 980 in one that does not (callgrind on 8578e3fb543a, 100,000 calls). The change is in lib/sp_cold.c, so no generated C changes.

Not changed: a receiver with a NUL byte is read up to the NUL (`"he\0llo l".gsub("", {"" => "-"})` answers 5 characters for 17).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
