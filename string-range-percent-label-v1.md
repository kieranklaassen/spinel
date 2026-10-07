<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
r = ("a".."e")
p (r % 2)       # CRuby #<Enumerator: "a".."e":%(2)>. Here: #<Enumerator: "a".."e":step(2)>
p r.step(2)     # #<Enumerator: "a".."e":step(2)>, before and after
```

"A String Range's step(n) inspects as an Enumerator over the Range" gave `%` a row of its own in `bop_rows`, whose label is `%(n)`. No call reached it: `desugar_str_range_methods` renamed every `%` on a String Range to `step` before codegen, because the arithmetic emitter had no arm for a String Range. So `r % 2` inspected under step's name.

The rename now applies to the block form only (`r.%(2) { }`), which needs step's walking arm. Without a block `%` keeps its name, and `emit_array_arith_call` hands it to its row. The Enumerator holds what step(n)'s holds; only the label differs.

On master a2bd8900, against CRuby 3.3.6: 1,476 programs (the Range as a literal, a local, a constant, a global, an instance variable, a method's value, exclusive, endless, of two-letter ends or with made ends; nine steps; `p`, `inspect`, an interpolation, an argument, an Array member, `to_a`, `map`, `next`, `each`, `first`, `count`, `size`, `include?`, `with_index`, and the block form). In a plain run 703 are right before and 1,081 after: 378 made right, none lost. 395 are wrong before and after: `size` (3 for nil), a step of 0 or below, and a Float step, whose label now has its name and still prints the number as an Integer (`%(2)` for `%(2.0)`, as step(2.0) prints `step(2)`). Under `SPINEL_GC_STRESS=2` nothing changes: 882 stop and 269 are wrong, each as on master.

**Test.** `test/string_range_percent_label.rb`, 8 lines; 3 differ on master. It aborts under `SPINEL_GC_STRESS=2` before and after, so it is not in `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with 3.3.6)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (nothing)
