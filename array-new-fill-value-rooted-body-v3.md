<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`Array.new(n, value)` lost a value made in place when a collection fell on the Array's own allocation. The cure is one root, taken only where nothing else is seen to hold the value; the worst measured is 7.6% on a loop that does nothing but make such Arrays (under Cost). A plain run shows the loss:

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

The temporary is now rooted unless something else holds the value (`array_fill_value_held`): an Integer, a Float, a Symbol, true, false and nil have nothing on the heap; a variable or a constant holds what is read from it, and a literal String is static. Those keep their C. Any other value is taken as made in place. Two reads are too. A Range enters an Array of mixed values through a box that copies it to the heap, so the copy is new whatever it was read from. And `self`: a method the program adds to String, Array or Hash takes its receiver as a bare C argument, so with `class String; def twice; Array.new(2, self); end; end` the Arrays of `(s + t).twice` lost it the same way.

**Measured against CRuby 3.3.6** (the programs below and the counts under Cost on master b4d30a1d; the tests, the generated C and the make targets on d02a49fb, where this branch stands). 560 generated programs: 41 kinds of value (a String made fourteen ways, an Array eight, a Hash, an object, a Range, a lambda, a value of two kinds, a String appended to in place; eight controls held elsewhere or not on the heap), n a literal, a local or a call, four places for the Array, and the block form as a control. Half keep 24 Arrays between other allocations and run at each stress level; half keep 30,000 and run plain.

| of 280 | master | this branch |
|---|---|---|
| plain run, 30,000 kept: wrong and silent | 104 | 0 |
| `SPINEL_GC_STRESS=1`, 24 kept: wrong and silent | 83 | 0 |
| `SPINEL_GC_STRESS=2`, 24 kept: the mark stops | 157 | 0 |

None right on master changes, and the clang builds, run plain and at level 2, give the same counts. 57 more programs, one a form: 26 further values and places that stop on master under `SPINEL_GC_STRESS=2` are right here (a Range literal, `3r`, a Struct, a `case`, `begin`, `||`, n itself allocating), 30 are right on both, one is below. 128 for the reads that keep their C, each inside a method, a block and a method added to a builtin class, its receiver or argument made in place: `self` in String, Array, Hash, Kernel, Object and an error class was lost on master and is held here (ten programs); the reads of locals, instance, class and global variables, constants and block parameters are right on both (112); the other six are master's and unchanged (a method added to Comparable is not found for a String, a Symbol made by `to_sym` loses its name under `SPINEL_GC_STRESS=2`, a Hash inspected as CRuby 3.4 writes it, and the literal named below). 252 for nine sizes beside fourteen values: 89 wrong or stopping on master are right here, ten stay as below. 982 over a wider grid of values, holders and sizes: 372 wrong or stopping on master are right here, 599 are right on both, eight stay as below, one is the Range bound below, and one program is refused on both in two sizes.

**Cost.** One root where the value is not proved held, counted by callgrind over 200,000 Arrays, gcc. The worst are values that were right on master and take a root they do not need: `Array.new(2, k > 2 ? s : t)`, a choice of two locals, 47,530,758 instructions on master and 51,133,135 here; `Array.new(2, [s][0])` 83,175,156 and 86,378,452; `self` inside a class of the program's own, held already, 38,908,640 and 39,121,872; a Regexp literal 38,941,484 and 38,945,268. Where the root is needed: `Array.new(2, s + t)` 103,158,855 and 107,206,050; a literal Array with elements 97,317,598 and 98,118,007. `Array.new(2, s)`, `Array.new(2, "lit")` and `Array.new(2, 7)` are master's C, in an Array of one kind and of mixed kinds, and so is `Array.new(2, nil)`.

**Not here.** `Range.new(s + t, s + u)` and `((s + t)..(s + u))` hold neither bound while the other is made and stop the same way under `SPINEL_GC_STRESS=2`, on master and here; they are other arms. A value made by statements of its own beside a size that allocates, `Array.new((s + u).size - 4, begin; s + t; end)`, is made before the size runs and is not held across it: the ten and the eight above; the arm writes the value's statements ahead of the size, which is also not Ruby's order, and moving them is a change of its own. `[1, Array.new(2, self)]` in a method added to String allocates the outer Array before `self` is read; that is the literal's arm. The block form `Array.new(n) { s + t }`, `Hash.new(s + t)`, `[s + t] * 2`, `fill`, `String.new`, `Set.new` and a Struct's or an object's `new` with values made in place are right on master at every level.

**Generated C.** `make cident REF=d02a49fb`: `6401 identical, 3 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The three are the new test and the two tests named above, where every changed line is the root or its frame slot. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/array_new_fill_value_rooted.rb`, also in `GC_STRESS_TESTS`: on master two of its fourteen lines are wrong in a plain run, six under `SPINEL_GC_STRESS=1`, and it stops under `SPINEL_GC_STRESS=2`. Its last lines are the forms that were held already. Its `self` line adds the method to Array, not String: a String method there makes `--share-strings` share `s` and `t` through the whole file, and the sum of two shared Strings has a fault of its own on master, outside this arm. Here it prints the same plain, at both stress levels with and without `SPINEL_GC_VERIFY=1`, built with clang, and under `--share-strings`; `make gc-stress-test` passes. The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings, Integers and Arrays.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
