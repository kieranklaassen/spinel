<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = {"s" => "ab", "i" => 3}
p (1..h["s"]).to_a
```

prints [] (`spinel diff`: exception-diff). CRuby raises ArgumentError: bad value for range. `p (h["s"]..h["s"]).to_a` prints [0], where CRuby prints ["ab"].

`sp_range_new_pend`, `sp_range_lo_bound` and the `for` loop's `sp_for_lo` and `sp_for_hi` convert a boxed bound through `sp_poly_to_i`, which reads a String as its leading digits and a Symbol as its id, so the program walked a Range of numbers it never wrote. Now a boxed String or Symbol end beside an Integer begin raises ArgumentError, as in CRuby. Anywhere else CRuby may build a String or Symbol Range, which the Integer representation cannot hold, so the Range is refused when it is built, with NotImplementedError, as a Float begin decided at run time already is.

Of 184 probe programs with such a Range, 44 that printed a wrong answer are right and 30 are refused.

Cost: 14 of those 184 were right and are refused too. They build `(x..x)` from one boxed String or Symbol and ask only `count`, `cover?`, `include?`, `===`, `class`, `exclude_end?` or `==`. With two different Strings the first four are wrong on master (`(x..y).count` is 1 for "aa" and "ad"); the last three are right on master for any value. Building a Range from a boxed Integer costs 4 instructions more (486 to 494 for two Ranges, callgrind on b06496ff); a `for` loop is unchanged at 310. No compiler file changes, so no generated C changes.

Not changed: `(x..3)` with a boxed String raises NotImplementedError where CRuby raises ArgumentError, because the begin is read before the end is known. A boxed true or false still converts to 1 or 0 (`(1..x).to_a` prints [1], CRuby: ArgumentError).

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the snapshot is hand-written for the lines CRuby answers and this refuses)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
