<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("99999999999999999998".."100000000000000000001").to_a
# CRuby: ["99999999999999999998", "99999999999999999999", "100000000000000000000", "100000000000000000001"]
# Here: [] since #7325, the four members before it
```

`sp_str_upto_each` walks two all-digit ends as numbers only up to the 18 digits a long long holds. Longer ones fell to the succ walk, which first compares the ends as bytes, and "9..." is the greater there, so the range was empty.

CRuby's `rb_str_upto_each` takes the same walk on Bignums. Past 18 digits the members are now taken by `String#succ`, which carries through the digits and keeps the begin's zeros, and each is compared with the end as a number: leading zeros aside, the longer is the greater. `include?`, `member?` and `String#upto` ride the same walk. One function in `lib/sp_array.c`. The compiler is not touched, so the generated C of every program is unchanged.

This stands on #NNNN (the minimum of an excluded end): with the wide range no longer empty, `min` of its excluded end would walk it and answer its least member, where master answers nil. Alone on master this change makes 20 such lines wrong; above #NNNN none.

**Measured against master 344d83ad, each line compared with CRuby.** 253 generated programs (65 ways of reading the range; the range as a literal, in a local, built from two locals, passed to a method, read out of a boxed slot) over 28 pairs of all-digit and near-digit ends, the end included and excluded: of 13,505 lines, 2,632 wrong become right and none right becomes wrong. 149 stay wrong, all wrong on master too: `max(n)`, and `include?` and a splat of a range read out of a boxed slot.

**Test.** `test/string_range_digits_wide.rb`, 15 lines; 7 differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (the wide values are Strings)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN
