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

exits 139 in a plain run (`spinel diff`: crash, SIGSEGV). CRuby prints 6416000. With a shorter String the answer is silently wrong: in 20,000 rounds of `t = s.gsub("l", h); m = $~[0]` on `"hello world " * 500`, 197 rounds hold a wrong result or a wrong match (the first line of the test). A program that never reads `$~` is right, and so are `sub` with a Hash and `gsub` with a String replacement.

`sp_str_gsub_str_str_hash` built its result and then set the match, which allocates, while the result sat in a C local with no root. Now the result is rooted across that one call, inside the branch a program that reads `$~` takes. The match is set where it was set before and nowhere else. Two tests the corpus already has, test/string_gsub_str_hash.rb and test/sub_gsub_hash_any_values.rb, abort at `SPINEL_GC_STRESS=2` without the change; they and the new test are in `GC_STRESS_TESTS`.

Cost: `"hello".gsub("l", h)` goes from 1,382 to 1,402 instructions a round in a program that reads `$~` and from 1,033 to 1,035 in one that does not (callgrind on fc6e90cc8d29, gcc, 100,000 rounds). The change is in lib/sp_cold.c, so no generated C changes.

Not changed: `sub` with a String and a Hash needs no root, it records the match before it allocates. `k = {"l" => 1}; y = ("hel" + "lo").sub("l", k); p y, $~[0], $~.pre_match` still aborts at `SPINEL_GC_STRESS=2`: there the receiver is a call's result that nothing holds while the Hash's Integers are converted, in the generated C. A receiver with a NUL byte is read up to the NUL (`"he\0llo l".gsub("", {"" => "-"})` answers 5 characters for 17).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
