<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
h = { prices: [9.5, 10.5], name: "x" }
p h[:prices].include?(9.5)
```

prints `false`.

After: `true`, as CRuby prints. `member?` answered false too, and so did the same list as a row of a mixed Array, as the answer of a method of two kinds, or in a parameter or an instance variable that takes two kinds.

A boxed receiver's `include?` switches on what the receiver is, with arms picked by the argument's type (`emit_poly_cases_n`, src/codegen_poly_plan.c). A Float argument had the two Range arms and none for a Float Array, so that receiver fell to the default arm, which asks a user Enumerable and answers false. It has the arm now: `sp_FloatArray_include`, the search a typed Float Array uses.

Left alone, each as on master: `key?` and `has_key?` go through the same switch and keep the default arm; a NaN keeps it too (the search finds a NaN by its bits, so it would answer true for one computed elsewhere); a Float asked of an Integer list and an Integer asked of a Float list are still false.

Measured on master dafa0d047: three corpus programs gain the one case and nothing else, and pass (`make cident`: 6,277 identical, 4 differ with the new test); scale-test keeps master's four ratios; of 951 generated programs (one list, one needle, one method, behind a boxed value) the C of 806 changes: 76 that were wrong print CRuby's answer, 716 print what they printed and were right, and 14 stay wrong as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
