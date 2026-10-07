<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`when *x` read `x` as an Array whatever it was.

Cost: one test of the operand's tag a `when *x`, 19 instructions on the 789 a test of a list of three takes. No program's C changes: the change is in `lib/spinel_rt.h`.

```ruby
r = (1..3)
puts(case 2 when *r then "in" else "out" end)
word = "ab"
puts(case nil when *word then "in" else "out" end)
puts(case "ab" when *word then "in" else "out" end)
```

Master (a2bd8900) prints `out`, `in`, `out`. CRuby prints `in`, `out`, `in`.

`sp_case_splat_match` takes the length of its operand and reads its elements. A Range has none to read that way, so it matched nothing; a String, a Symbol or a Hash held boxed read as a list of nil, so it matched a nil subject and not what it holds. The helper now spreads such an operand with `sp_splat_to_array`, as the other splats do: an Integer or a String Range to its members, a Hash to its pairs, and a number, a String, a Symbol or a boolean to itself. An endless Range raises RangeError there, as in CRuby. An Array and nil are read as before, and so is every other operand.

Not in this change: a Float Range, which CRuby refuses to spread, is still no match; an object of the program (a Struct, an Enumerable, a class with a `to_a` of its own) is not spread and is read as before.

Test: `test/case_when_splat_spread.rb`, 20 lines; 13 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
