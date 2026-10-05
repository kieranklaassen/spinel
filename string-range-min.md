<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("aaa"..."zz").min   # CRuby: "aaa". Here: nil since #7325, "aaa" before it
p ("9"..."11").min     # CRuby: nil. Here: "10"
p ("11"..."9").min     # CRuby: "11". Here: nil
p ("a"...).min         # CRuby: "a". Here: RangeError
```

`sp_srange_min_v` walked a range whose end is excluded and took its least member. CRuby's `range_min` never walks: with no block the minimum is the begin, or nil when the begin is past the end, or at it with the end excluded. Since #7325 a String Range holds the members CRuby walks, so `("aaa"..."zz")` holds none, and its minimum, which was right by accident, became nil.

`sp_srange_min_v` now compares the two ends, for either kind of end. The maximum of an excluded end still walks, as CRuby's does. One function in `lib/sp_cold.c`. The compiler is not touched, so the generated C of every program is unchanged.

**Measured against master 344d83ad, each line compared with CRuby.** The 8 generated programs that reach the function (`min` and `minmax` over 76 pairs of ends, the end included and excluded, the range as a literal, in a local, built from two locals and passed to a method): of 1,216 lines, 56 wrong become right and none right becomes wrong.

**Test.** `test/string_range_min_excluded_end.rb`, 23 lines. On master it prints 5, two of them wrong, and stops at the RangeError. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: # (nothing)
