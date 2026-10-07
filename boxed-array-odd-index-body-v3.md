<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed Array read through an index that is no Integer answered element 0:

```ruby
def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]
h = pick(0)
p h[1.5]    # 10; CRuby: "s"
p h[true]   # 10; CRuby: no implicit conversion of true into Integer (TypeError)
```

This turns a silent wrong element into CRuby's answer. Of 1,718 probe programs it changes 228: 226 printed element 0 or went on with it, 2 raised another error class, and all 228 now answer as CRuby does. The 1,193 that were right stay right.

`sp_poly_index_poly` took an Integer, nil, a String, a Symbol and a Range, and read an Array through anything else as index 0. Such an index now converts as an Integer argument does, with `sp_poly_arg_int_chk`, the conversion `fetch` with a block already uses: a Float or a Rational is cut, an object answers `to_int`, and `true`, `false`, an Array or a Hash is CRuby's TypeError. That is the read behind `h[i]`, `h.at(i)`, `h.slice(i)` and `h[i] ||= v`. An Integer index takes the line's first arm and never meets the conversion.

Not here: a Float Range index, which CRuby slices by, still reads element 0 (converting it would raise where no raise is due); a Bignum or a NaN index still does not raise CRuby's RangeError.

Separate, no order: "A Symbol or String index on a boxed Array raises TypeError", "A Symbol index on a boxed String or Symbol raises TypeError" and "fetch and values_at on a boxed Array refuse an index that is no Integer".

No generated C changes: the function is in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
