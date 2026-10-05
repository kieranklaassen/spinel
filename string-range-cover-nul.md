<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("a\0b".."a\0c").cover?("a\0a")   # CRuby: false. Here: true
p ("a\0b".."a\0a").max              # CRuby: nil. Here: "a\u0000a"
p ("a\0a"..."a\0c").max             # CRuby: "a\u0000b". Here: "a\u0000a"
```

`sp_srange_cover` compares with `strcmp`, which stops at a NUL byte, so every String that shares an end's bytes up to one compares equal to that end. `===` rides it, so `when "a\0b".."a\0c"` takes every String that begins "a\0". `sp_srange_max_v` has the same compare, and so has its walk for the greatest member of an excluded end.

The three compare with `sp_str_cmp_bytes` now, as the walk does. Two Strings with no NUL byte compare as they did. `lib/sp_cold.c` only; the compiler is not touched, so the generated C of every program is unchanged.

It stands on #NNNN (the minimum of an excluded end), which makes the same repair to `min`: `minmax` needs both.

**Measured against master ab9b925a, each line compared with CRuby.** 47 generated programs (`cover?`, `===`, `case`/`when`, `include?`, `member?`, `max`, `min`, `minmax` over 12 pairs of ends and 14 subjects, most with a NUL byte, the end included and excluded, the range as a literal, in a local, passed to a method, read out of a boxed slot): of 4,935 lines, 374 wrong become right and none right becomes wrong. 9 of the 374 are #NNNN's; this change makes the other 365 right.

**Test.** `test/string_range_cover_nul.rb`, 21 lines; 10 differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN
