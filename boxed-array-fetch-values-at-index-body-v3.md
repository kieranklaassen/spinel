<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`fetch` and `values_at` on a boxed Array read an index that is no Integer as a number:

```ruby
def pick(n) = n > 0 ? {a: 1} : [10, "s", :z]
h = pick(0)
p h.fetch(true)     # 10; CRuby: no implicit conversion of true into Integer (TypeError)
p h.values_at(:a)   # ["s"]; CRuby: no implicit conversion of Symbol into Integer (TypeError)
p h.fetch(1.5)      # 10; CRuby: "s"
```

This turns a silent wrong element into CRuby's answer. Of 1,612 probe programs it changes 282: 279 printed a wrong element or went on with it, 3 raised another error class, and all 282 now answer as CRuby does. The 1,187 that were right stay right.

An Integer index pays nothing, and `fetch` is cheaper. By callgrind a loop of three fetches (two on a boxed Array, one on a boxed Hash) runs 655 instructions an iteration on master and 337 here with gcc, 598 and 326 with clang; `values_at` with two Integers runs 572 and 570 with gcc, 578 and 568 with clang.

`sp_poly_fetch` and `sp_poly_arr_values_at` read the index with `sp_poly_to_i`, which answers a number for anything: a Symbol, a String, `true` or an Array read element 0 or another wrong one, and `fetch` read a Float as 0 once it was in bounds. Both now convert the index as `fetch` with a block already does (`sp_poly_fetch_blk`), with `sp_poly_arg_int_chk`: a Float is cut, and anything that is no number is CRuby's TypeError. `fetch` then reads the element by the index it has converted, where it went back through the generic index; `values_at` takes an Integer as it is.

Not here: a Float Range in `values_at`, which CRuby slices by, still reads one element (converting it would raise where no raise is due); `fetch` with a block still hands the block the converted index.

Separate, no order: "A Symbol or String index on a boxed Array raises TypeError", "A Symbol index on a boxed String or Symbol raises TypeError" and "A Float, true or Array index on a boxed Array is not element 0".

No generated C changes: the two functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
