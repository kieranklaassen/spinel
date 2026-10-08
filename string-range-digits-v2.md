<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("99999999999999999998".."100000000000000000001").to_a
# CRuby: ["99999999999999999998", "99999999999999999999", "100000000000000000000", "100000000000000000001"]
# Here: [] since "A String range and String#upto walk the members CRuby yields"; the four members before it
p ("0000000000000000000008".."11").to_a
# CRuby: four members, "0000000000000000000008" to "0000000000000000000011". Here: the begin alone
```

**Two stated costs.** Any other String Range walked by `to_a`, `include?` or `first(n)` pays 8 to 10 instructions more, once a walk and not once a member. And a range that was wrongly empty may now be too long to hold: `("5".."10000000000000000000")` has 10^19 members. A caller that leaves early answers at once, as it did from the empty range. One that needs every member (`to_a`, `count`, `include?` of a String that is no member) answered from the empty range and now does not finish, where CRuby does not.

The walk takes two all-digit ends as numbers only up to the 18 digits a `long long` holds. Longer ones fell to the succ walk, which compares the ends as bytes and never walks past the end's length: "9..." is the greater there, so the range was empty, and with the begin the longer it stopped after the begin.

CRuby's `rb_str_upto_each` walks them on Bignums. Two all-digit ends of unequal width, one of them past 18 digits, now walk by `String#succ`, which carries through the digits and keeps the begin's zeros, each member compared with the end as a number: leading zeros aside, the longer is the greater. At one width the succ walk is right at any width and is not touched. `to_a`, `include?`, `member?`, `first(n)`, `each`, `for` and `String#upto` all take the walk: it is written once, in the member-at-a-time pair of `lib/sp_str_walk.c`. The compiler is not touched, so no program's generated C changes.

**Where the code is.** `lib/sp_array.c` sits at gcc's inline limit for a unit: each of twelve ways of writing the hand-over inside the walk there changed what gcc inlines into `sp_StrArray_insert` and `sp_StrArray_slice_bang`, which have nothing to do with a Range. So that walk keeps its body under the name `sp_str_upto_narrow`, and `sp_str_upto_each`, now in `lib/sp_str_walk.c`, reads one byte of the begin before it hands a range on. `build/sp_array.o` is the same code but for that name, and `sp_str_walk.o` is the only other object of the runtime that changes.

**It stands on two others**, named under "Depends on". Without the first, a caller that leaves a far-apart range early (`find`, `first(3)`, `each` with a `break`) would run out of memory building the array. And `min` of a range whose end is excluded walks the range on master: over five of the pairs below it answered right from a walk that was wrong, and would answer wrong from the walk made right. Beneath the second it does not walk.

**Measured on master 8dc55225 with those beneath, against CRuby 3.3.6, with gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`, and with gcc under `--share-strings`, where every figure is the same.** 253 generated programs: 28 pairs of all-digit and near-digit ends ("9".."11", zero-padded, the begin past the end, 18, 19, 20, 22 and 30 digits, a letter in one end), each with the end included and excluded, in 64 uses (`to_a`, `each`, `map`, `first(n)`, `step`, a splat, `for`, `sort`, `min`, `max`, `count`, `include?`, `cover?`, `===`, a `when`, `upto` and the rest), the Range a literal, a local, two local ends, a parameter or read out of a boxed slot. Each prints 56 lines, 14,177 in all.

- In a plain run the programs that print every line right go from 45 to 248, and the lines from 11,284 to 14,084. No program that is right at a level is wrong at that level, with either compiler or under the flag.
- 93 lines are wrong before and after, in 5 programs: `max(n)` over a range that crosses a width (60), which answers its n last members where CRuby answers the n greatest Strings, as `("9".."11").max(2)` does on master, and `include?` of a Range read out of a boxed slot (33).
- Under level 2, 14 programs are wrong before and after; 4 of them, `step(n).to_a`, abort. With clang at level 1 those four are wrong before and after too: `step(n)` loses its Enumerator there on master ("A String Range's step(n) and % keep their Enumerator while its label is made"), and which of a program's lines that empties depends on what ran before them, so 8 lines that were right are empty and 56 that were wrong are right.

66 one-line programs over ends far apart, `("5".."10000000000000000000")` and a pair past 20 digits: 30 are right before and after; 24 go from wrong to right (`find`, `first(3)`, `take(2)`, `min(2)`, `each` and `upto` left by `break`, `any?`, `all?` and `none?` with a block, `include?` of a member near the begin); 12 that printed a wrong line from the empty range run out of memory, `any?` and `none?` with no block, `lazy`, `map` left by `break`, `each_slice` and `step`, which still build the array.

**Cost** by callgrind, whole program, instructions, a gcc build then a clang build:

| | beneath | this branch | |
|---|---|---|---|
| `("a".."e").to_a`, 20,000 times | 24.99M, 23.41M | 25.19M, 23.57M | +10, +8 a walk (+0.8%, +0.7%) |
| `("a".."e").include?("c")`, 20,000 times | 14.55M, 13.89M | 14.75M, 14.05M | +10, +8 a walk (+1.4%, +1.2%) |
| `("a".."e").first(2)`, 20,000 times | 13.62M, 12.77M | 13.82M, 12.87M | +10, +5 a walk (+1.5%, +0.8%) |
| `("a".."zz").to_a`, 200 times | 89.207M, 82.879M | 89.209M, 82.880M | +10, +8 a walk |
| `("1".."10000").to_a`, 20 times | 158.304M, 153.982M | 158.306M, 153.984M | +84, +98 a walk: two digit ends are read to their length |
| one width of 20 digits, 500 members, `to_a` 100 times | 32.77M, 30.05M | 32.79M, 30.07M | +248, +264 a walk (+0.08%, +0.09%) |
| `("a".."e").each { \|s\| n += s.size }`, 20,000 times | 32.05M, 30.95M | 30.79M, 30.75M | -3.9%, -0.6% |
| `("08".."11").each { \|s\| n += s.size }`, 20,000 times | 83.07M, 81.46M | 82.03M, 81.32M | -1.3%, -0.2% |

`each` walks on the pair, which does not pass through `sp_str_upto_each`; gcc now inlines the pair's `sp_str_walk_member`, which it called before.

**Test.** `test/string_range_digits_wide.rb`, with early exits over far-apart ends in it; 10 of its 20 lines differ beneath. It prints the same under `SPINEL_GC_STRESS=1` and `2` and with `--share-strings`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none: the wide values are Strings, which `tools/gate.rb` notes all the same)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: the compiler is not touched)
- [ ] Depends on: #____ ("A String Range left early reads only the members it is asked for") and #____ ("The minimum of a String Range with an excluded end is decided by its ends")
