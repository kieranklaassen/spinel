<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a stated cost.** The text of a Float range with one bound omitted, which makes one String and needed nothing held, pays for the frame the root needs: 10 instructions for `(1.5..).to_s` and 27 for `(..2.5).to_s` (0.7% and 1.8% of the call); `inspect` of a String range with one bound pays 11 (0.8%). The table and what was tried to spare them are under **Cost**.

The text of a Float range could name its upper bound twice. A plain run shows it:

```ruby
a = []
200000.times { |i| a << ((i + 0.5)..(i + 1.5)).to_s }
p a[4925]
```

```
spinel diff: output-diff
  program: frange.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"4925.5..4926.5"
+"4926.5..4926.5"
```

`sp_frange_inspect` (lib/sp_cold.c) is `to_s`, `inspect` and interpolation for a Float range. It makes the lower bound's text, then the upper bound's, then the answer:

```c
const char *lo = ... sp_float_to_s(r.first);
const char *hi = ... sp_float_to_s(r.last);
return sp_sprintf("%s%s%s", lo, r.excl ? "..." : "..", hi);
```

Nothing holds `lo` while `hi` is allocated. A collection there frees it, and `hi`, a String of the same size, takes its slot, so both names point at the upper bound's text. Under `SPINEL_GC_STRESS=2` every such text begins with freed bytes, exit 0.

`inspect` of a String range has the same two steps in `sp_srange_inspect` (the second commit):

```ruby
r = ("a".."b")
a = []
200000.times { a << r.inspect }
p a.reject { |s| s == "\"a\"..\"b\"" }
```

```
spinel diff: output-diff
  program: srange.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[]
+["\"b\"..\"b\""]
```

Both functions now root the lower text across the second allocation (`SP_GC_ROOT_STR`). A Float range with no end, and a String range with either bound omitted, return before the root. The answer itself was safe already: `sp_sprintf` writes into its own buffer before it allocates.

**Measured against CRuby 3.3.6 on master 8dc55225.** 108 generated programs: twelve ranges (seven of Floats: both bounds, exclusive, an Integer written as the end, endless, beginless, a negative and a large bound, an explicit infinity; five of Strings: both bounds, exclusive, endless, beginless, two literals) in nine spellings of the text (`to_s`, `inspect`, two interpolations, out of an Array as `inspect` and as `to_s`, through a local, inside an Array's `inspect`, `format` with `%s` and `%p`), three turns, the texts kept and printed.

| of 108 | master | this branch |
|---|---|---|
| right in a plain run, under `SPINEL_GC_STRESS=1` and under 2 | 45 | 108 |
| `SPINEL_GC_STRESS=2`: wrong and silent | 63 | 0 |

The 45 are the ranges with one bound and the String ranges read by `to_s` alone, which quotes nothing.

**Cost.** 200,000 texts each (callgrind, gcc):

| | master | this branch | a text |
|---|---|---|---|
| `(lo..hi).to_s`, two Float bounds | 384,948,010 | 389,821,779 | 24 |
| `(lo...3).inspect`, an Integer written as the end | 442,615,397 | 447,639,965 | 25 |
| `(lo..).to_s` | 303,212,989 | 305,212,989 | 10 |
| `(..hi).to_s` | 302,812,989 | 308,216,665 | 27 |
| `r.inspect`, two String bounds | 356,944,074 | 360,812,202 | 19 |
| `("alpha"..).inspect` | 279,482,090 | 281,682,090 | 11 |
| `(.."omega").inspect` | 279,682,090 | 281,882,090 | 11 |
| `r.to_s`, a String range | 218,702,903 | 218,702,903 | 0 |

The rows with one bound are the stated cost. Two other spellings of the Float fix were built to spare them. The rooted step in a function of its own costs those rows 4 to 6 and the two-bound row 30 to 33, and makes gcc compile four to six other functions of lib/sp_cold.c differently. The lower text copied to the stack costs the endless row 8 and the others 71 to 74.

lib/sp_cold.c is one unit at gcc 13's inlining limit, so a change to one function can move another. Each function of the unit was compared with master's by its disassembly, in both runtimes. Besides the two functions changed, gcc compiles one exit path of `sp_poly_array_transpose` differently (the root's pop there becomes a call) and, in the threaded runtime, `sp_io_select`. Five loops of 200,000 `transpose` calls (rows of mixed values, rows of Integers, ragged rows that raise, a row that is not an Array, empty rows) measure the same on both (four to the instruction, the fourth 1,128 fewer in all); 20,000 `IO.select` calls in a threaded program measure 39,652,250 on master and 39,630,869 here.

**Not here.** `("a#{i}".."b#{i}").to_s`, a String range whose two bounds are made in the literal: both are made inside one C call (`sp_srange_new(/* "a…" */, /* "b…" */)`), and under `SPINEL_GC_STRESS=2` the text has freed bytes for one bound, on master and here. That is the literal in the emitter, not its text.

**Generated C.** `make cident REF=8dc55225`: `6448 identical, 0 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The change is in the runtime alone, so no program's C moves. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/float_range_text_lower_bound_held.rb` and `test/string_range_inspect_lower_bound_held.rb`, both in `GC_STRESS_TESTS`. On master the first is wrong in a plain run (its first line, the 4,926th of 5,000 texts) and under both stress levels; the second prints freed bytes under `SPINEL_GC_STRESS=2`. Here both print the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`. The `.expected` files are from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
