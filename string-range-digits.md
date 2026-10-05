<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
p ("99999999999999999998".."100000000000000000001").to_a
# CRuby: ["99999999999999999998", "99999999999999999999", "100000000000000000000", "100000000000000000001"]
# Here: [] since #7325, the four members before it
```

The walk takes two all-digit ends as numbers only up to the 18 digits a long long holds. Longer ones fell to the succ walk, which first compares the ends as bytes, and "9..." is the greater there, so the range was empty.

CRuby's `rb_str_upto_each` takes the same walk on Bignums. Past 18 digits the members are now taken by `String#succ`, which carries through the digits and keeps the begin's zeros, and each is compared with the end as a number: leading zeros aside, the longer is the greater. `include?`, `member?` and `String#upto` ride the same walk. Both forms of the walk in `lib/sp_array.c`. The compiler is not touched, so the generated C of every program is unchanged.

**It stands on #NNNN (a String Range left early reads only the members it is asked for), and on the minimum of an excluded end beneath that.** A range that was wrongly empty finished every program at once. Made right, `("5".."10000000000000000000")` has 10^19 members, and a caller that builds the whole array runs out of memory. Above #NNNN `each`, `for`, `upto`, `find` and its kin and `first(n)` take a member at a time and answer. A caller that needs every member (`to_a`, `count`) ran to an answer from the empty range and now runs out of memory, where CRuby does not finish.

**Measured against master ab9b925a, each line compared with CRuby.**

| | master | this branch |
|---|---|---|
| digits matrix, 253 generated programs over 28 pairs of all-digit and near-digit ends, 13,505 lines: right | 10,724 | 13,356 |
| 66 programs over far-apart all-digit ends: right | 30 | 54 |

None right on master becomes wrong in either. In the digits matrix 149 lines stay wrong, all wrong on master too: `max(n)`, and `include?` and a splat of a range read out of a boxed slot. Of the far-apart programs, 12 that printed a wrong answer from the empty range now run out of memory: `any?` and `none?` with no block, `lazy`, `map` with a break, `each_slice` and `step`, which still build the array.

`max(n)` over a range that crosses a width answered `[]` and now answers its n last members; CRuby answers the n greatest Strings. It is wrong before and after, as `("9".."11").max(2)` is.

**What it costs** (callgrind, whole program, instructions; master, #NNNN, this branch): `include?` over zero-padded 20-byte ends 5,750,268, 5,790,300, 5,642,577; `("1".."10000").to_a` 9,002,400, 9,072,414, 8,953,430; `("a".."zz").to_a` 1,016,916, 1,019,756, 1,036,600 (+1.9% on master); `map` over 702 members 121,086,865, 121,654,865, 125,023,665 (+3.3% on master).

**Test.** `test/string_range_digits_wide.rb`, with early exits over far-apart ends in it. It prints the same under `SPINEL_GC_STRESS=1` and `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (the wide values are Strings)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [x] Depends on: #NNNN
