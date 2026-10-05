<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("aaa"..."zz").min   # CRuby: "aaa". Here: nil
p ("9"..."11").min     # CRuby: nil. Here: "10"
p ("11"..."9").min     # CRuby: "11". Here: nil
p ("a"...).min         # CRuby: "a". Here: RangeError
```

`sp_srange_min_v` walked a range whose end is excluded and took its least member. CRuby's `range_min` never walks: with no block and no argument the minimum is the begin, or nil when the begin is past the end, or at it with the end excluded. The two ends now decide it, for either kind of end. `lib/sp_cold.c` only; the compiler is not touched, so the generated C of every program is unchanged.

- An excluded end is compared as the walk compared it (`sp_str_cmp_bytes`), and the answer is a copy of the begin, as the walk's first member was.
- An included end is compared as `strcmp` compared it, and by its bytes alone past a NUL when `strcmp` finds no difference: `("a\0b".."a\0a").min`, which answered the begin, is nil as in CRuby.

This stands on #NNNN (the two ends of a String Range made on the spot are both kept): the compare reads the ends in place, and a begin freed while the end was made would answer nil. It stands on #MMMM (`delete_prefix` over a NUL) as well: `"xa\0b".delete_prefix("x")` recorded its length as 1, and a Range with such an end would compare short.

**Measured on master 4d56c157 above both, each line compared with CRuby 3.3.6.**
- 6,264 lines: 18 ways of making the begin by 15 pairs of contents by 5 ways of making the end, the end included and excluded, read three ways (the minimum with its bytes, `frozen?` and `== r.first`; the minimum appended to; `minmax`). 3,394 right before and after, 757 wrong made right, none right made wrong, the same counts plain and under `SPINEL_GC_STRESS=2`.
- 2,113 lines are wrong before and after: the questions of "Not here", and `minmax` over a NUL, whose maximum still compares with `strcmp`.
- Cost by callgrind. `("a"..."zz").min`, 2,000 turns: 879.24M instructions to 1.40M. `("a".."zz").min`, 200,000 turns: 22.14M to 23.34M, six instructions a call. `("a".."zz").max`: 22.14M on both. Two ends `strcmp` finds equal, `("zz".."zz").min`: 22.14M to 39.54M, both lengths being read then.

**Not here.**
- The answer for an excluded end is a copy, as it was. CRuby answers the begin itself, so `r.min.frozen?` and whether an append to the answer shows in the Range still differ.
- Two ends with the same bytes, one binary and one UTF-8: an included end takes them for equal, as before. CRuby orders the binary one first.
- The maximum, and `cover?`, still stop at a NUL.

**Test.** `test/string_range_min_excluded_end.rb`, 31 lines. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN, #MMMM
