<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
n = 0
200.times do |i|
  s = (i + 1).to_s
  case s
  when i.to_s..(i + 3).to_s then n += 1
  end
end
p n   # 194. Here: 0 under SPINEL_GC_STRESS=2
```

A `when` whose Range is written on the spot compares the subject with the two ends, each bound to a temp (`emit_when_string_range`). The subject's temp is rooted; the begin's was not, so it was held by that temp alone while the end was made, and an end that allocates could free it. The begin's temp is rooted now when both ends may allocate. A begin that is a literal or a plain local read, or an end that allocates nothing, compiles to the C it did; a Range held in a value (`when r`) is another arm and is not touched.

On master dafa0d04, against CRuby 3.3.6, with gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: of 1,020 generated programs (10 ways of writing the begin, 7 of the end, 3 of the subject; a statement, a value, an excluded end, two Ranges in one `when`, inside a method) the C of 270 changes, those where both ends are made on the spot. Of the 270, 225 go from wrong to right at all three levels (221 were wrong at level 2, 4 at level 1 too), 45 are right before and after, and none is lost. Of the 28 programs in test, benchmark and packages that write a Range in a `when`, none changes its C.

Cost by callgrind, 200,000 turns of the loop above: 123.05M instructions to 125.97M (+2.4%).

**Test.** `test/when_string_range_fresh_begin.rb`, also in `GC_STRESS_TESTS`. Fails on master at level 2 with both compilers.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6; it prints six Integers)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not generated here; only a String Range written in a `when` with both ends made on the spot compiles differently)
- [ ] Depends on: # (nothing)
