<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A local read out of an Array that a later store gave another kind of element held a wrong value, with nothing said.

```ruby
t = [1, 2]
t << "s"
r = t.last
p r
```

```
spinel diff: output-diff
  program: lead.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-"s"
+0
```

The container fold makes `t` the general Array, but it runs after the scan that types each local from its writes. So `r` was typed from the Integer array, in every round, and the boxed element was narrowed into it. An Integer read out of what began as a String array came out as `"1"`, a String out of a Float array raised ArgumentError (invalid value for Float(): "s"), and `a, b, c = t` printed a pointer for `c`. `p t.last` with no local between was right, and so was an Array that began as `[]`, because the scan keeps the fold's answer for the empty literal. Master already mends one such read after the fold, `value = hash[key]` on a Hash whose values the fold boxed; this is the same rule for an Array, for every local read out of it.

`infer_write_types` now marks the plain locals that hold a typed Array before the fold and looks at them after it. If the fold widened any, the other plain locals go back to UNKNOWN and the scan runs again in the same round with those locals held as the general Array, so what is read out of them, and what is made of that, is typed from the Array as it is. A local that a parameter's store widened (`poly_array_pin`) is written as the general Array by the scan too. Nothing is kept across rounds, so a local that was the general Array only on an early estimate narrows as before.

Checked on master 70cddab37:

- `test/local_read_from_widened_array.rb` fails on master (0 for the first line, then ArgumentError) and passes here under `SPINEL_GC_STRESS=0`, `1` and `2`, with and without `SPINEL_GC_VERIFY=1`, with gcc and clang.
- 1,920 generated programs on master 70cddab37 (an Array of Integers, Floats, Strings or Symbols, 15 ways it comes to hold another kind, 32 ways a local reads from it), each against CRuby: the generated C changes in 684 and all 684 are right. On master 362 of them were right (the element read happened to be of the first kind), 210 printed a wrong answer and 112 raised. The other 1,236 compile to the same C; master is right in all of them but 29 rows of `map!` (below).
- 756 more that use the local read (80 uses, from `+` and `==` to a Hash key, an argument and a `case`), all right on master: 750 change C and answer as before, 6 compile to the same C. No program is refused and none stops building.
- With `--share-strings`, the String rows of both sets (480 and 238): 228 and 238 change C, every one right; 90 printed a wrong answer and 11 raised on master.
- `tools/cident.sh` against f3da0151f: 6373 identical, 1 differ (the new test), 0 refusal changes; the test is right there in the same 12 cells.
- Compile cost: a program in which the fold widens no typed local Array runs the scan once, as before. The compiler runs the same number of instructions on three of the largest programs of `test/` to within 0.03% (callgrind: `send_name_past_1024_receiver_names` 1,616,800,269 before and 1,617,288,339 after, `kernel_conv_protocol` 727,413,793 and 727,274,961, `bundle_misc_b` 419,281,683 and 419,270,014). The new test, with twelve such locals, compiles in 59.3 million instructions against 45.5 million.
- Run cost, for a program that was right on master because the element read was of the first kind: the local is now boxed. `r = t[0]; s += r` in a loop, with `t = [1, 2]; t << "s"`, runs 31 instructions a turn against 27 (callgrind, gcc, 200,000 turns: 5,458,367 before, 6,258,371 after); `r = t[1]; n += 1 if r == 2` the same 4 more; `r = t.first; n += 1 if r` 5 fewer; `r = t[0]; n += r.size` on a String Array that took an Integer 105 against 81.

Left alone: `t.map! { }` whose block answers another kind widens `t` in a later pass (`widen_arrays_from_map_bang`), so a local read out of that Array is still typed from the first kind. It has its own place to be mended.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
