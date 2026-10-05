<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("aaa"..."zz").min   # CRuby: "aaa". Here: nil since #7325, "aaa" before it
p ("9"..."11").min     # CRuby: nil. Here: "10"
p ("11"..."9").min     # CRuby: "11". Here: nil
p ("a"...).min         # CRuby: "a". Here: RangeError
```

`sp_srange_min_v` walked a range whose end is excluded and took its least member. CRuby's `range_min` never walks: with no block the minimum is the begin, or nil when the begin is past the end, or at it with the end excluded. Since #7325 a String Range holds the members CRuby walks, so `("aaa"..."zz")` holds none, and its minimum, which was right by accident, became nil.

`sp_srange_min_v` now compares the two ends, whole (`sp_str_cmp_bytes`: an end may hold a NUL byte), for either kind of end. The maximum of an excluded end still walks, as CRuby's does. One function in `lib/sp_cold.c`. The compiler is not touched, so the generated C of every program is unchanged.

This stands on #NNNN (the two ends of a String Range made on the spot are both kept). Master's walk answered a copy; the compare reads the ends in place, and a begin freed while the end was made would answer nil: `(i.to_s...(i + 3).to_s).min` in a loop was nil 98 times in 800,000 with this change alone on master, and never is above #NNNN.

**Measured against master ab9b925a, each line compared with CRuby.** The 8 generated programs that reach the function (`min` and `minmax` over 76 pairs of ends, the end included and excluded, the range as a literal, in a local, built from two locals and passed to a method): of 1,216 lines, 56 wrong become right and none right becomes wrong.

**Test.** `test/string_range_min_excluded_end.rb`, 27 lines, four of them over ends with a NUL byte. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN
