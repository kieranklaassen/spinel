<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Before:

```ruby
h = { prices: [9.5, 10.5], name: "x" }
p h[:prices].include?(9.5)
```

prints `false`.

After: `true`, as CRuby prints. `member?` answered false too, and so did the same list as a row of a mixed Array, as the answer of a method of two kinds, or in a parameter or an instance variable that takes two kinds.

A boxed receiver's `include?` switches on what the receiver is, with arms picked by the argument's type (`emit_poly_cases_n`, src/codegen_poly_plan.c). A Float argument had the two Range arms and none for a Float Array, so that receiver fell to the default arm, which asks a user Enumerable and answers false. It has the arm now: `sp_FloatArray_include`, the search a typed Float Array uses.

Left alone, each as on master: `key?` and `has_key?` go through the same switch and keep the default arm; a NaN keeps its answer, false, which is CRuby's for a NaN computed elsewhere and not for the same object (`nan = Float::NAN; h = { a: [nan, 1.5], b: "x" }; h[:a].include?(nan)` is true in CRuby); a Float asked of an Integer list and an Integer asked of a Float list are still false.

Measured on master 8684d54ce: the test is right at -O0 to -O3, with clang and under both stress modes. Of 6,342 corpus programs three gain the one case and nothing else, and pass (float_range_boxed_methods, range_float_arg_cover, range_int_float_end); the fourth that differs is the new test. optcarrot's C is unchanged; the scale-test ratios are master's (1.71, 4.74, 6.06, 4.18). Of 951 generated programs (one list, one needle, one method, behind a boxed value; run on dafa0d047) the C of 806 changes: 76 that were wrong print CRuby's answer, 716 print what they printed and were right, and 14 stay wrong as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
