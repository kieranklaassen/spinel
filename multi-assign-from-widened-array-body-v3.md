<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A multiple assignment out of an Array that a later store gave another kind of element left wrong values in its targets, with nothing said.

```ruby
t = [1, 2]
t << "s"
a, b, c = t
p c.class
```

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-String
+Integer
```

`p c` prints the String's address as a number. Out of a Float Array the target reads 0.0, `a, *r = t` prints `[2, 0]` or raises TypeError, `x, *m, z = t` does not compile, and `a, b = t.last, 5` prints 0.

**It has a cost, yours to weigh.** The targets of such an assignment are now boxed, also in a program that was right because the elements it took were of the first kind. `a, b = t; s += a + b` in a loop, out of `[1, 2]` pushed a String, goes from 41.7 instructions a turn to 90.7, which is what the same loop costs on master where the Array is written `[1, 2, "s"]`; out of an Array that is never widened it costs 40.7 before and after. A second cost: a builtin written with a multiple assignment follows its boxed receiver too, so `r = t.first; r.gcd(8)` in a loop goes from 221 instructions a turn to 243 with gcc and from 198 to 201 with clang. No list keeps the unboxed targets: which element a target takes is settled when the program runs, and a plain `a = t[0]` out of such an Array is boxed on master already. An assignment whose right side reads as it did when its targets were joined is not joined again, so a program with no widening compiles to the same C. Compiling 500 such assignments out of widened Arrays goes from 0.73 to 2.09 billion instructions, where master takes 2.25 for the same program with the Arrays written mixed; 2,000 go from 7.7 to 29.5, against 32.0. With no widening the compiler runs 0.4% and 0.2% more on those two sizes.

`rejoin_local_writes` lets a local follow the writes whose values widen after `infer_write_types` joined them. A multiple assignment was left where it was: its targets are joined inside `infer_write_types`, before the container fold makes the Integer Array a general one, so they kept the element's first type. `infer_write_multi_assign` now notes in `lw_joined` what the right side read as when it joined the targets (each value's, for a literal right side), and `rejoin_local_writes` joins again the targets of an assignment whose right side reads differently since, with the same pass, called for that one assignment. An assignment whose right side is unchanged is not joined again, so a narrowing made on purpose stays.

Checked on master 42557a3c0e7c, with gcc and clang:

- `test/multi_assign_from_widened_array.rb` does not compile on master and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`.
- 1,920 generated programs, each a local Array of one kind widened by a later store of another kind and then read, each against CRuby: 1,842 compile to the same C. Of the 78 that change, 66 go to right (44 printed a wrong answer, 22 raised) and 12 were right and stay right.
- 1,792 more where `map!` rewrites the Array with another kind: 1,732 compile to the same C. Of the 60 that change, 54 go to right (35 wrong, 19 raised) and 6 were right and stay right.
- 756 programs that read an element of the Array's own kind out of such an Array and use it as that kind, which master runs right: 642 compile to the same C, and the 114 that change print what they printed.
- `tools/cident.sh` against 42557a3c0e7c: 6469 identical, 1 differ, 0 refusal changes. The one is the new test, which master does not build.
- Compile cost where no multiple assignment reads a widened Array: `kernel_conv_protocol` 737,734,325 instructions on master and 737,724,551 here; `bundle_misc_b` 427,475,782 and 427,640,836; 500 widened Arrays read by plain writes 5,268,443,357 and 5,268,588,878.

Left alone:

- `r = t.last; u << r`, a read out of such an Array stored into another typed Array, raises TypeError as before.
- `t = [+"a", +"b"]; t[1] = 7; r, b = t; p b; r << "x"; p t` ended in a segmentation fault and now prints `["a", 7]` where CRuby prints `["ax", 7]`, as master does for the same program with the Array written `[+"a", 7]`. The append that does not reach the Array is not in this change.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
