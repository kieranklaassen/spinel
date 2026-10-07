<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Array.new(n, value)` lost a value made in place when a collection fell on the Array's own allocation. A plain run shows it:

```ruby
s = "abc"
t = "def"
u = "xyz"
rows = []
3000.times do
  rows << Array.new(2, s + t)
  z = s + u
  z = u + s
end
p rows.uniq
```

```
spinel diff: output-diff
  program: fill.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[["abcdef", "abcdef"]]
+[["abcdef", "abcdef"], ["xyzabc", "xyzabc"]]
```

The arm for `Array.new(n, value)` in `emit_new_call_arms` binds the value to a C temporary and allocates the Array in the next statement:

```c
const char * _t3 = sp_str_plus(lv_s, lv_t);
sp_StrArray *_t4 = sp_StrArray_new();
```

Nothing holds `_t3` across that allocation, so a collection there frees it and the Array is filled with whatever is made in its place. Under `SPINEL_GC_STRESS=2` the mark stops on the freed value in the first round. Two tests of the suite have the shape and fail that way on master: `test/array_new_container_default.rb` stops, and `test/bundle_class_21.rb` prints -2604246222170760229 three times for 42 and exits 0.

The temporary is now rooted unless something else holds the value (`array_fill_value_held`): an Integer, a Float, a Symbol, true, false and nil have nothing on the heap; a variable or a constant holds what is read from it, and a literal String is static. Those keep their C. Any other value is taken as made in place. One read is too: a Range enters an Array of mixed values through a box that copies it to the heap, so the copy is new whatever it was read from.

**Measured against CRuby 3.3.6 on master 26d456ec.** 560 generated programs: 41 kinds of value (a String made fourteen ways, an Array eight, a Hash, an object, a Range, a lambda, a value of two kinds, a String appended to in place; eight controls held elsewhere or not on the heap), n a literal, a local or a call, four places for the Array, and the block form as a control. Half keep 24 Arrays between other allocations and run at each stress level; half keep 30,000 and run plain.

| of 280 | master | this branch |
|---|---|---|
| plain run, 30,000 kept: wrong and silent | 104 | 0 |
| `SPINEL_GC_STRESS=1`, 24 kept: wrong and silent | 83 | 0 |
| `SPINEL_GC_STRESS=2`, 24 kept: the mark stops | 157 | 0 |

None right on master changes, and the clang builds, run plain and at level 2, give the same counts. 57 more programs, one a form: 26 further values and places that stop on master under `SPINEL_GC_STRESS=2` are right here (a Range literal, `3r`, a Struct, a `case`, `begin`, `||`, n itself allocating), 30 are right on both, one is below.

**Cost.** One root where the value is made in place. `Array.new(2, s + t)` 200,000 times: 103,156,790 instructions on master, 107,205,115 here (callgrind). A literal Array with elements was held by its own temporary already and takes the root too: 97,315,526 and 98,115,944. `Array.new(2, s)`, `Array.new(2, "lit")` and `Array.new(2, 7)` are master's C, in an Array of one kind and of mixed kinds, and so is `Array.new(2, nil)`.

**Not here.** `Range.new(s + t, s + u)` holds neither bound while the other is made and stops the same way under `SPINEL_GC_STRESS=2`, on master and here; it is another arm. The block form `Array.new(n) { s + t }`, `Hash.new(s + t)`, `[s + t] * 2`, `fill`, `String.new`, `Set.new` and a Struct's or an object's `new` with values made in place are right on master at every level.

**Generated C.** `make cident REF=26d456ec`: `6348 identical, 3 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The three are the new test and the two tests named above, where every changed line is the root or its frame slot. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/array_new_fill_value_rooted.rb`, also in `GC_STRESS_TESTS`: on master two of its thirteen lines are wrong in a plain run, five under `SPINEL_GC_STRESS=1`, and it stops under `SPINEL_GC_STRESS=2`. Its last lines are the forms that were held already. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings, Integers and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
