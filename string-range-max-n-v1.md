<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("9".."11").max(2)   # CRuby ["9", "11"]. Here: ["11", "10"]
p ("a".."bb").max(3)   # CRuby ["z", "y", "x"]. Here: ["bb", "ba", "az"]
```

**A stated cost.** `max(n)` of a String Range between ends of one length pays 29 instructions a call with gcc and 32 with clang, for reading the two lengths (+1.8%, +2.0% on five members). Between ends of two lengths it now sorts its members, which the right answer needs.

Range#max with a count is Enumerable's: the n greatest members by `<=>`. The row took the last n members of the walk, reversed, which is that only where the walk is in the order of `<=>`. A String Range walks by succ: `("9".."11")` walks "9", "10", "11", and "9" is the greatest of them; `("a".."bb")` passes "z" on its way to "aa".

Between ends of one length every member has that length, and succ makes of a String only a greater one of its length or a longer one, so there the walk is in order and is left as it is. Where the two ends differ in byte length the members are sorted, by the whole-String comparison `sort` uses, before the last n are taken. The lengths are read before the walk allocates.

It is one row of `src/builtin_ops.c`; the runtime is not touched. `min(n)` is not touched either: Range#min with a count is `first(n)`, the walk's own order, in CRuby too.

**Measured on master c594707b against CRuby 3.3.6, the generated C compiled by gcc and by clang, plain and under `SPINEL_GC_STRESS=1` and `2`, and with gcc under `--share-strings`; every figure is the same in all of them.** 176 programs: 22 uses (`max(n)` with a count of 0, 1, 2, 3, 100, -1 and a variable; its size, its first, joined, asked twice, appended to; with a block; `max_by(n)`; `max`, `min`, `min(n)`, `minmax`, `to_a`, `sort.last(n)`) by 8 holders (a literal, a local, two ends made at run time, a parameter, an instance variable, a boxed slot, a method's value, frozen). Each prints a line a pair, the end included and excluded, over 18 pairs: 6 between ends of one length, 11 across lengths, one past 18 digits. 6,336 lines.

- 721 wrong lines are right. 4,982 are right before and after. No line that is right is wrong, and no program stops.
- 633 are wrong before and after, and each prints what it printed: 286 over the ends past 18 digits, which master walks as an empty Range; 238 are the message of a negative count ("negative array size" for CRuby's "negative size (-1)"); 96 are `min` and `minmax` of a Range whose end is excluded, across lengths (`("9"..."11").min` is "10" for nil); 13 are `min(n)` of a Range read out of a boxed slot, which answers the n least where CRuby answers `first(n)`.
- Of master's own 6,306 tests the generated C of one changes, `test/range_min_max_count_bounds.rb`, with and without `--share-strings`; it passes as it did.

**Cost** by callgrind, whole program, instructions, the generated C compiled by gcc and then by clang:

| | master | this branch | |
|---|---|---|---|
| `("a".."e").max(2)`, 20,000 times | 31.37M, 31.39M | 31.95M, 32.03M | +29, +32 a call (+1.8%, +2.0%) |
| `("aaa".."zzz").max(2)`, 17,576 members, 20 times | 259.831M, 258.762M | 259.832M, 258.762M | +70, -9 a call |
| `("9".."11").max(2)`, 20,000 times | 63.36M, 63.23M | 74.57M, 74.34M | +17.7%, +17.6%: three members sorted |
| `("a".."zz").max(3)`, 702 members, 200 times | 89.83M, 89.40M | 171.70M, 170.52M | +91%, +91%: the sort |
| `("1".."1000").max(3)`, 50 times | 38.76M, 38.62M | 70.46M, 70.03M | +82%, +81%: the sort |

The last three answered wrong before.

**Test.** `test/string_range_max_n_lengths.rb`: 10 of its 18 lines differ on master. It prints the same under `SPINEL_GC_STRESS=1` and `2`, under the verifier and with `--share-strings`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
