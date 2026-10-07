<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = ["x", "y"].freeze
p a.delete("zz")
p a.delete("zz") { "none" }
```

raises FrozenError at its first `delete` (`spinel diff`: exception-diff). CRuby prints `nil` and `"none"`.

CRuby's `Array#delete` raises only once it has found an element to remove, so an Array that does not hold the element is left alone. The delete functions of the four Array kinds (Integer and Symbol, Float, String, boxed) raised for a frozen Array before they searched. Each now searches a frozen Array first and answers nil where the search proves the element absent. A boxed Array proves it only among Integers, Strings, Symbols, nil, true, false and Floats that are numbers, where the runtime equality is CRuby's; with a NaN, a Complex or an object that has its own `==` on either side it raises as it did. An Array that is not frozen takes the path it took.

Cost on an Array that is not frozen (callgrind on 5a752fceb48c, gcc, 100,000 calls): a `delete` that finds nothing is 1 instruction fewer on an Integer Array, 1 more on a Float or a String Array and the same on a boxed one; a `delete` that finds its element is 2 fewer on an Integer or a boxed Array and 1 more on a Float or a String Array. The change is in lib/sp_array.c and lib/spinel_rt.h, so no generated C changes.

Not changed: `delete_at` with an index past the end of a frozen Integer, Float or String Array still raises FrozenError where CRuby answers nil. `[1.5, 0.0 / 0.0].freeze.delete(0.0 / 0.0)` still raises where CRuby answers nil: the search cannot tell one NaN from another. `delete` through a boxed receiver is the next pull request.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
