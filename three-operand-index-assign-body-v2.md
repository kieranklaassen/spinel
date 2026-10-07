## What this changes

```ruby
class Grid
  def initialize = @c = {}
  def []=(x, y, v)
    @c[[x, y]] = v
  end
  def cells = @c.to_a
end
g = [Grid.new, 1][0]
g[1, 2] = :cell
p g.cells                         # [[[1, 2], :cell]] in CRuby, [] on master
```

`spinel diff` on master: output-diff, `[]` for `[[[1, 2], :cell]]`.

`x[a, b] = v` on a boxed receiver is lowered to the Array and String splice before the class dispatch is tried, and the splice leaves any other value as it was. So beside a class defining `[]=(x, y, v)` or `[]=(*keys, v)` the assignment into an object of that class is dropped and its method never runs. `x[k] = v` is not affected.

Where a class takes `[]=` with three arguments the call is emitted twice behind `sp_poly_is_user_obj`: the class dispatch for an object of the program's own, which calls the method (or raises as CRuby does for a class that has none or counts otherwise) and answers `v`; the splice, as it was, for every other value. Only one arm runs, so the receiver and the operands that run code are held in temps ahead of the test, in CRuby's order.

A program in which no class takes `[]=` with three arguments emits the same C, and so does one that defines `method_missing` or `respond_to_missing?`, which may answer the call for an object with no `[]=`. A Struct with no `[]=` of its own keeps the splice.

Cost by callgrind, a million stores: an Array spliced beside such a class 491,114,897 to 514,200,207 (23 instructions a store, the test and the temps); with no such class, or `x[k] = v`, the same C.

Not here, the same on master: `x[a, b] += v` on a boxed receiver (refused by name); a multiple assignment's target `g[1, 2], z = 5, 6`; a call with a block argument; a boxed Struct, Hash, nil or Integer given three operands, silent where CRuby raises.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
