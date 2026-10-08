<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A splatted Range among the indexes of `values_at` on a boxed receiver gave none of its members:

```ruby
a = [[10, 20, 30], nil][ARGV.size]
p a.values_at(*(0..1))      # []; CRuby: [10, 20]
p a.values_at(0, *(1..2))   # [10]; CRuby: [10, 20, 30]
p a.values_at(*2)           # []; CRuby: [30]
```

`values_at` on a boxed receiver reads a splatted list with `sp_poly_to_poly_array`, which copies an Array and so answers none for what is no Array; the call then answered from its other indexes alone. An operand typed as an Integer Range now has its members walked onto the list of indexes (`sp_poly_values_at_range`, with no array between), and one typed as a scalar that is not nil is pushed as the index it is.

Every other operand is read as before, in the same C: an Array, nil, and anything boxed. Of 896 programs (seven receivers, 32 operands, four places in the list), 560 compile to the same C. Of the other 336, 312 answered wrongly and now print CRuby's line. The last 24 splat an empty Range, which was right because nothing is what it holds: `a.values_at(0, *r)` with `r = (2..1)` ran 696 instructions a call and runs 454 (gcc; clang 699 and 450). None that was right is lost.

This stands on "fetch and values_at on a boxed Array refuse an index that is no Integer": alone, a splatted Symbol or String (`a.values_at(*:a)`) would answer as `a.values_at(:a)` does on master, an element, where CRuby raises TypeError.

In the corpus only the new test's C differs; the programs that name `values_at` were compared in both overflow modes and under `--share-strings` as well.

Not here, each still as on master:

- a splatted boxed Range or boxed Integer, `k = [1, nil][0]; a.values_at(*k)`, prints `[]` (CRuby: `[20]`): 72 of the 896. Spreading a box at run time cures them and costs a splatted boxed Array, which is right today, 37 instructions a call with gcc (907 to 944; clang 905 to 932). Under `--int-overflow=promote` an Integer local is such a box.
- a splatted String Range or Enumerator adds nothing to the list: 48.
- a splatted Float Range adds nothing where CRuby raises TypeError: 24.
- a splatted empty Array literal as the only index, `a.values_at(*[])`, raises NoMethodError (CRuby: `[]`): 10.
- a splatted list that holds a literal Array, `a.values_at(0, *[[0]])`, does not build (CRuby: TypeError): 24. "A boxed values_at builds when an index needs a statement of its own" is for it.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on Linux (x86_64, gcc 13.3.0, ruby 3.3.6), on master 9c7ea3ce0 merged with this branch's 2 commits (3dd895dbf, 0c8ac0ff4): the build; `tools/gate.rb check`; the new test and the fetch fix's test in eighteen cells each (gcc and clang; the default mode, `--int-overflow=promote` and `--share-strings`; `SPINEL_GC_STRESS` unset, 1 and 2); `tools/cident.sh` against master (the new test's C differs; the other 6,514 corpus programs, optcarrot among them, compile to the same C; so does every other program that compiles with `--int-overflow=promote` (6,506) and with `--share-strings` (6,405)); and the legs `share-strings-test` and `int-min-test` alone, which pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (not run under CRuby 4.0 here; ruby 3.3.6 with that flag prints `test/boxed_values_at_splat.rb.expected` exactly)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: `tools/cident.sh` finds it byte-identical to master's at 9c7ea3ce0)
- [x] Depends on: # (the pull request "fetch and values_at on a boxed Array refuse an index that is no Integer"; its commit 3dd895dbf is this branch's first, with the same id)
