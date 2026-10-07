<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def keep(&b) = b
fs = [7, 8, 9].map { |e| x = e; x.then { |v| keep { v + 1 } } }
p fs.map(&:call)          # [9, 10, 10]; CRuby prints [8, 9, 10]
ks = []
[[1], [2, 3]].each { |a| b = a; b.then { |v| ks << keep { v.sum } } }
p ks.map(&:call)          # [5, 5]; CRuby prints [1, 5]
```

Each closure kept from a `then` or `tap` block read the parameter of the run after its own.

The block is spliced into the frame, and a parameter that a closure captures lives in a cell. The body's prologue makes that cell anew at each run and stores the parameter in it (`emit_block_locals_reset`), so a closure keeps the cell of its run. The binding stored the parameter into the cell too, ahead of the prologue, where the cell is still the one the previous run's closure holds.

The binding now fills the plain slot only. Both ways the body is emitted (`emit_block_value_into` for `then`, `emit_iter_step_body` for `tap`) run the prologue before the first statement, so nothing read the cell between the two stores. `emit_cell_shadow_store` has no caller left and is removed: 30 lines out, none in.

One store fewer at each run; nothing is added.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
