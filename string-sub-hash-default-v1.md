<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = Hash.new("?")
h["q"] = "1"
p "abq".gsub("b", h)     # CRuby "a?q". Here: "aq"
m = { "b" => "x" }
m.default = "D"
p "abc".sub("c", m)      # CRuby "abD". Here: "ab"
n = Hash.new(0)
n["x"] = 7
p "axb".gsub("b", n)     # CRuby "ax0". Here: "ax"
```

CRuby reads `hash[match]`, which answers the Hash's default for a pattern that is not a key. The pair behind sub and gsub with a String pattern and a Hash (`sp_str_sub_str_str_hash`, `sp_str_gsub_str_str_hash`) asked `has_key` first and took "" on a miss; the pair for a Regexp already reads the default. Both read `sp_StrStrHash_get` now, which answers the default on a miss. A Hash of other values is already converted with its default. Two lines of `lib/sp_cold.c`; no program's generated C changes. One lookup where there were two: `s.gsub("o", h)` is 7% cheaper and `s.sub("o", h)` 13% (callgrind).

Measured on master 5390d300 above the commits beneath, CRuby 3.3.6: 6,080 lines (19 Hashes, 5 subjects, 8 patterns; gsub, sub, `$~`, gsub! and sub! with their receivers, and the size of the Hash). Right before and after 3,736; wrong made right 1,014; right made wrong 0. 1,330 are wrong before and after: 1,280 in the 160 programs that raise TypeError (below), and 50 where `gsub!("", h)` or `sub!("", h)` leaves the String as it was and answers nil. The same programs without the `$~` line (5,320 lines), plain and under `SPINEL_GC_STRESS=2`, gcc and clang: 1,014 made right, none lost. With that line, gsub with a Hash stops in the collector at level 2, before and after; another pull request cures it ("gsub with a String and a Hash keeps its result while the match is set").

**Not here.** `Hash.new("?")` that no String key is stored into, a Hash made with a block and a Hash with Symbol keys raise TypeError ("no implicit conversion of Hash into String") at run time, before and after.

**Test.** `test/string_sub_hash_default.rb`, 19 lines; 13 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("scan, lines and sub and gsub with a Hash find a String pattern by bytes": it rewrites the same two functions)
