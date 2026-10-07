<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$x1 = 1.to_s
n = 0
1000000.times do |i|
  s = (i + 1).to_s
  case s
  when i.to_s..(i + 3).to_s then n += 1
  end
end
p n   # CRuby: 999982. Here: 999981
```

A `when` whose Range is written on the spot compares the subject with the two ends, each bound to a temp (`emit_when_string_range`). The subject's temp is rooted; the begin's was not, so it was held by that temp alone while the end was made, and an end that allocates could free it: once in the million turns above in a plain run, with gcc and clang, and at every turn under `SPINEL_GC_STRESS=2`, where 200 turns of the loop count 0 and CRuby counts 194. The begin's temp is rooted now when both ends may allocate by the compiler's own test (`operand_may_allocate`). A begin that is a literal without a NUL byte or a plain local read, or an end that allocates nothing by that test, compiles to the C it did; a literal begin holding a NUL takes the root for nothing. A Range held in a value (`when r`) is another arm and is not touched.

On master 06064727, against CRuby 3.3.6, with gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: of 1,020 generated programs (10 ways of writing the begin, 7 of the end, 3 of the subject; a statement, a value, an excluded end, two Ranges in one `when`, inside a method) the C of 270 changes, those where both ends are made on the spot. Of the 270, 225 go from wrong to right (221 were wrong at level 2, 4 at level 1 too), 45 are right before and after, and none is lost. Of the 232 programs in test, benchmark and packages that hold a `when` and a `..`, none changes its C.

Cost by callgrind, 200,000 turns of the loop: with gcc 123.05M instructions to 125.97M (+2.4%), with clang 130.42M to 136.82M (+4.9%).

**Not here.** Three shapes are the same on master and here, right in a plain run and wrong under `SPINEL_GC_STRESS=2`: a begin read from a local that the end clears (`when lo..(lo = nil; mk(i + 3))`), an end that is an operator write (`when mk(i)..(hi += "1")`), and an end in a `begin` block (`when mk(i)..(begin; mk(i + 3); end)`).

**Test.** `test/when_string_range_fresh_begin.rb`, also in `GC_STRESS_TESTS`. Fails on master at level 2 with both compilers.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6; it prints six Integers)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not generated here; only a String Range written in a `when` with both ends made on the spot compiles differently)
- [ ] Depends on: # (nothing)
