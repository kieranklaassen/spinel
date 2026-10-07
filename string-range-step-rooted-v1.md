<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
x = 3.to_s
y = 8.to_s
n = 0
3000.times { n += (x..y).step(2).to_a.size + ((x..y) % 2).map(&:size).sum }
p n                # CRuby 18000. Here: 17994 with clang in a plain run; an abort under SPINEL_GC_STRESS=2

r = ("a".."e")
p r.step(2).to_a   # ["a", "c", "e"]. Here: an abort under SPINEL_GC_STRESS=2
```

Both were right at every level before "A String Range's step(n) inspects as an Enumerator over the Range" was merged. That change made the two rows of `bop_rows` for step with an argument and for % end in one call whose three arguments each allocate: the new Enumerator, the boxed Range and the label's String. Nothing held the one made first while the others were made, so a collection in between freed the Enumerator or the box: a short Array in a plain run, a StopIteration out of `next` with clang under `SPINEL_GC_STRESS=1`, an abort at level 2.

The Enumerator and the boxed Range now go into rooted temps and the label is made last. Two rows of `src/builtin_ops.c`; a program's C changes only where it calls step(n) or % on a String Range.

Cost by callgrind: `("a".."e").step(2).to_a` +25 instructions a call (+0.9%) with gcc and with clang; `(("a".."zz") % 7).to_a`, 702 members, within 0.02%.

**Not here.**

- `p` of such an Enumerator can print a freed begin under `SPINEL_GC_STRESS=2`, as `p ("a".."e")` itself does there. `test/srange_step_inspect.rb` stopped in the collector at level 2 and runs to its end with this change, but its two inspect lines print that begin, so it is not added to `GC_STRESS_TESTS`.
- `r % 2` inspects as `step(2)` where CRuby prints `%(2)`: the call is renamed to step before it reaches its row.
- A Range made on the spot or answered by a method, `(i.to_s..j.to_s).step(2)`, can lose an end at level 2 before step runs, before and after.
- `r.step(2).size` answers 3 where CRuby answers nil, before and after.

**Test.** `test/string_range_step_rooted.rb`, also in `GC_STRESS_TESTS`. On master it fails with clang in a plain run and with gcc and clang at level 2.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
