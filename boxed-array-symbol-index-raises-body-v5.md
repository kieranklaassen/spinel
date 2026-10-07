<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A Symbol or a String as the index of a boxed Array answered nil where CRuby raises:

```ruby
def pick(n) = n > 0 ? {a: 1} : [[1, "s"]]
h = pick(0)
p h[:a]   # nil; CRuby: no implicit conversion of Symbol into Integer (TypeError)
```

This turns a silent nil into CRuby's raise: a program that read `h[:a]` from a boxed Array and went on with the nil now stops there, as it does under CRuby. Of 4,496 programs that read a boxed receiver by an index of every kind, 95 reach the new raise: all 95 answered wrongly on master and are right here.

Through a boxed receiver the store already raises this TypeError (`sp_poly_set_sym`, `sp_poly_set_str`: "not a write to be dropped"), and so does the read of an index that is itself boxed, since the commit "A keyword splat sent to a method without keywords arrives as its last positional, and a boxed array index of another kind raises TypeError". A Symbol or String literal index takes `sp_poly_get_sym` or `sp_poly_get_str`, which answered nil for every receiver that is no Hash. Both now raise for an Array as the store does, with CRuby's message. That is the read behind `h[:a]`, `h["a"]`, `slice(:a)` and `at`; a receiver of any other kind answers as before, and a Hash's or a Struct's read costs what it did: the test stands after their arms. By callgrind a loop reading a boxed Struct by a Symbol and by a String runs 2,360 instructions a pass on master and 2,360 here with gcc, 2,320 and 2,318 with clang.

Not here: `values_at` and `fetch` go through other functions and answer as they did (`fetch` checks its bounds with the Symbol read as a number first); so does a Symbol index on a boxed String, which is its own change. And in a program where a class defines its own `[]`, a boxed Symbol index on a boxed Array still answers nil.

No generated C changes: the two functions are in `lib/spinel_rt.h`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
