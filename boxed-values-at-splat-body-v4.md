<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A splatted Range among the indexes of `values_at` on a boxed receiver gave none of its members, and a splatted Integer was dropped:

```ruby
a = [[10, 20, 30], nil][ARGV.size]
p a.values_at(*(0..1))      # []; CRuby: [10, 20]
p a.values_at(0, *(1..2))   # [10]; CRuby: [10, 20, 30]
p a.values_at(*2)           # []; CRuby: [30]
```

No loop costs more. By callgrind `a.values_at(0, *r)` with `r = (2..1)` ran 685 instructions a call and runs 446 (gcc; clang 690 and 440). A splatted scalar that is nil when the call runs is the one read that was right and now passes a new test, the one for nil: it ran 613 and runs 450 (605 and 443). A splatted Array, boxed or not, and a splatted `nil` run what they ran.

`values_at` on a boxed receiver reads a splatted list with `sp_poly_to_poly_array`, which copies an Array and so answers none for what is no Array; the call then answered from its other indexes alone. An operand typed as an Integer Range now has its members walked onto the list of indexes where it has both its ends (`sp_poly_values_at_range`, with no array between). One typed as a scalar is pushed as the index it is unless it is nil when the call runs (`sp_poly_values_at_scalar`): what is typed Integer, Float or String can hold nil (a local set on one branch, a parameter left out, a method's value, an element), and nil splats to none, as it did.

A splat asks its operand `to_a`, and a Range's `to_a` walks its `each`; both arms answer for the built-in ones. So neither arm is taken, and the splat is read as before, in a program that has a def named `to_a`, the Symbol `:to_a` or the String `"to_a"` anywhere (`each` too, for the Range arm), a def named `method_missing`, `respond_to_missing?` or `respond_to?`, the Symbol or the String `define_method`, `define_singleton_method` or `alias_method`, or a call of one of those three whose name is not written out. 33 such programs print master's lines: with a `to_a` on Integer, Float, String, Symbol, Range, NilClass, Numeric, Comparable, Kernel, Object, a class of the program's or at the top level, and with a `to_a` or a `Range#each` given by a def, `alias`, `alias_method` or `define_method` (the name a Symbol, a String or computed), `send`, a prepended module, Enumerable, Comparable, a `method_missing` or a `respond_to?`, with an `each` of another class, or with the Symbol `:to_a` alone.

Nor is an arm taken where a later argument of the call ran ahead of the splat. Master holds an argument that has an effect in a temp ahead of the statement and reads the splat's operand after it, so in `a.values_at(*j, (j = 1; 0))` the operand read is the one that argument left, not the one CRuby splats. Such a splat is read as before unless its operand is held in its place too.

Every other operand is read as before, in the same C: an Array, nil, and anything boxed. Of 768 programs (four receivers, 48 operands, four places in the list), 160 compile to the same C. Of the other 608, 304 answered wrongly and now print CRuby's line. 176 were right and are: they splat an empty Range or a scalar that is nil when the call runs, and nothing is what those hold. The last 128 print the same wrong line on both and are listed below. None that was right is lost, in the default mode, with `--int-overflow=promote` or with `--share-strings`; nor in 20 programs of 24 reads whose later argument assigns the operand, or that have a `Range#each`, a `to_a` named by a String or a `method_missing` of their own.

Not here, each still as on master:

- a splatted boxed Range or boxed Integer, `k = [1, nil][0]; a.values_at(*k)`, prints `[]` (CRuby: `[20]`): 32 of the 768. Under `--int-overflow=promote` an Integer local or a method's Integer is such a box.
- a Range without an end gives none where CRuby raises, RangeError for `*(1..)` and TypeError for `*(..1)`; so does one whose end is nil when the call runs: 64. The largest Integer as a Range's end and the smallest as its begin read as no end, so `*((x - 1)..x)` with the largest `x` gives none (CRuby: two nils): 48.
- the smallest Integer as a splatted scalar reads as nil and gives none (CRuby: one nil): 16.
- a splatted String Range or Float Range adds nothing where CRuby raises TypeError: 32.
- a splatted empty Array literal as the only index, `a.values_at(*[])`, raises NoMethodError (CRuby: `[]`).
- a splatted list that holds a literal Array, `a.values_at(0, *[[0]])`, does not build (CRuby: TypeError). "A boxed values_at builds when an index needs a statement of its own" is for it.
- a program with a def named `to_a`, the Symbol `:to_a` or the String `"to_a"` anywhere, or any other of the names above, keeps every answer it had, a splatted Range's none among them; a `respond_to?(:to_a)` is enough.
- a splat whose later argument has an effect is read as on master, so `a.values_at(*r, (r = (0..1); 2))` with `r = (2..1)` prints `[30]`, CRuby's line, and in `i = 0; a.values_at((i += 1; 0), *i, (i += 1; 0), *i)` the first splat is still dropped: `[10, 10, 30]`, where master prints `[10, 10]` (CRuby: `[10, 20, 10, 30]`).

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 84f5b5020 with this branch's one commit (d2f92b8e5): the build; `tools/gate.rb check`; the six new tests in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the C of 3 of the six new tests differs, the others compile as on master; the other 6,609 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,601) and with `--share-strings` (6,600)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints the six `.expected` files exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (`test/boxed_values_at_splat_min.rb` is; the other five tests have none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 84f5b5020)
- [ ] Depends on: # (nothing)
