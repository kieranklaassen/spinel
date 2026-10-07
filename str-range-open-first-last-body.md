<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
p ("aa"..).last
```

prints nil (`spinel diff`: exception-diff). CRuby raises RangeError: cannot get the last element of endless range. `p (.."ad").first` prints nil the same way, where CRuby raises RangeError: cannot get the first element of beginless range.

`first` and `last` with no count shared the template of `begin` and `end`, which rightly answer nil for the open side. Their templates now test the bound and raise for an absent one (`sp_srange_open_raise`).

Cost: none measured. A round of `r.first.size + r.last.size` is 103 instructions before and after (callgrind on 8578e3fb543a, 100,000 rounds). The generated C changes in 4 corpus programs, the four that call `first` or `last` on a String Range, and their output is unchanged.

Not changed: a boxed String Range takes another road (`sp_poly_first`, `sp_poly_last`) and still answers nil: `h = { a: ("aa"..), n: 1 }; p h[:a].last`. `("aa"..).last(1)` raises RangeError with another message (cannot convert endless range to an array) and `(.."ad").first(1)` raises TypeError. `("aa"..).count` raises RangeError where CRuby answers Infinity, and `("aa"...).min` raises where CRuby answers "aa".

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
