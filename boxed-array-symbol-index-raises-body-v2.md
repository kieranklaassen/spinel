<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol or a String as the index of a boxed Array answered nil where CRuby raises:

```ruby
def pick(n) = n > 0 ? {a: 1} : [[1, "s"]]
h = pick(0)
p h[:a]   # nil; CRuby: no implicit conversion of Symbol into Integer (TypeError)
```

This turns a silent nil into CRuby's raise: a program that read `h[:a]` from a boxed Array and went on with the nil now stops there, as it does under CRuby. Of 63 programs of a probe that this changes, all 63 end in the uncaught TypeError under CRuby; 47 of them printed nil and ran on, the other 16 raised NoMethodError on that nil.

Through a boxed receiver the store already raises this TypeError (`sp_poly_set_sym`, `sp_poly_set_str`: "not a write to be dropped"). The read, `sp_poly_get_sym` and `sp_poly_get_str`, answered nil for every receiver that is no Hash. Both now raise for an Array as the store does, with CRuby's message. That is the read behind `h[:a]`, `h["a"]`, `fetch`, `at`, `h[:a] += 1` and a later step of `dig`; a receiver of any other kind answers as before.

Not here: `values_at` and an index that is `true`, an Array or a Float go through other functions and answer as they did; so does a Symbol index on a boxed String, which is its own change.

No generated C changes: the two functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
not run yet: this branch waits for the full gate
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
