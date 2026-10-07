<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

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

exits 139 in a plain run (`spinel diff`: crash, SIGSEGV). CRuby prints 6416000. On a 6 KB String, 20,000 rounds of `s.gsub("l", h)` followed by `$~[0]` answer a freed String 197 times. A program that never reads `$~` is right, and so are `sub` with a Hash and `gsub` with a String replacement.

`sp_str_gsub_str_str_hash` built its result and then set the match, which allocates, while the result sat in a C local with no root. Now the result is rooted across that one call, inside the branch a program that reads `$~` takes. The match is set where it was set before and nowhere else. The test is in `GC_STRESS_TESTS`.

Cost: `"hello".gsub("l", h)` goes from 1,405 to 1,425 instructions a call in a program that reads `$~` and from 1,204 to 1,206 in one that does not (callgrind on dafa0d047, 100,000 calls). The change is in lib/sp_cold.c, so no generated C changes.

Not changed: a receiver with a NUL byte is read up to the NUL (`"he\0llo l".gsub("", {"" => "-"})` answers 5 characters for 17). Under `SPINEL_GC_STRESS=2` such a program aborted in the call; it now prints that same wrong answer, as it does in a plain run.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
