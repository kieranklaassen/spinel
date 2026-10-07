<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = [1, "x", nil].freeze
h = { "a" => a, "n" => 1 }
h["a"].delete("x")
p a
```

prints `[1, nil]` (`spinel diff`: output-diff). CRuby raises FrozenError: can't modify frozen Array: [1, "x", nil].

An Array read back from a Hash or another Array is deleted from by `sp_poly_delete_key`. Its loop over a boxed Array removed the element without a look at the frozen flag, so the frozen Array lost it. Now the loop raises at the first element it would remove. An element the Array does not hold still answers nil, or the block's value.

Cost: one test for each element removed. The change is in lib/spinel_rt.h, so no generated C changes.

Not changed: the call answers its argument and not the Array's element (`[1, "x"]` read back from a Hash answers `1.0` to `delete(1.0)` where CRuby answers `1`), and an Integer Array read back from a Hash answers nil to `delete(2.0)` and keeps its `2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
