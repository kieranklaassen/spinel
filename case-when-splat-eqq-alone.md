<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Class, a Range or a Regexp inside `when *list` matched a subject equal to it.

Cost: one test of the subject a `when *list`, 11 instructions on the 808 a test of a list of three takes. No program's C changes: the change is in `lib/spinel_rt.h`.

```ruby
classes = [Integer, :z]
puts(case Integer when *classes then "in" else "out" end)
ranges = [1..3]
puts(case (1..3) when *ranges then "in" else "out" end)
```

Master (a2bd8900) prints `in` twice. CRuby prints `out` twice: `Integer === Integer` and `(1..3) === (1..3)` are false.

`sp_case_splat_match` takes an element equal to the subject for a match before it asks the element `===`. For those three kinds the two differ, and only a subject of one of those kinds is equal to such an element, so for such a subject the elements are asked through `sp_poly_case_eq` alone. Every other subject matches an element equal to it, as before.

This sits on the pull request "A `when *x` spreads what x holds before it is searched": both change `sp_case_splat_match`.

Test: `test/case_when_splat_eqq_alone.rb`, 16 lines; 5 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
