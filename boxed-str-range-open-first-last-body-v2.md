<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { a: ("aa"..), n: 1 }
p h[:a].last
```

prints nil (`spinel diff`: exception-diff). CRuby raises RangeError: cannot get the last element of endless range. `p [(.."ad")].map { |r| r.first }` prints `[nil]` the same way.

`sp_poly_first` and `sp_poly_last` answered a boxed String Range's bound without a test, so the absent one came back as nil. Their String Range arm now tests it and raises through `sp_srange_open_raise`, the helper of the pull request this one depends on. A Range read from an Array or a Hash, through `fetch`, `send`, `map` or a parameter that also takes an Array reaches that arm.

Cost: one test in that arm, 2 instructions a call at most (callgrind on 70cddab37194, gcc, 100,000 rounds of `h[:a].first` and `h[:a].last` on a closed Range). The change is in lib/spinel_rt.h, so no generated C changes.

Not changed: `begin` and `end` of a boxed String Range raise NoMethodError (undefined method 'begin' for an instance of Range). With a count, `first(1)` of a boxed endless Range raises RangeError (cannot convert endless range to an array) where CRuby answers `["aa"]`, and `first(2) { 1 }` prints nil.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the pull request for an unboxed String Range's first and last (its raise helper)
