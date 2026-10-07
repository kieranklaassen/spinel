<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
a = ["ab", "c", "ab"]
p a.include?(h["k"]), a.index(h["k"]), a.delete(h["k"])
```

prints `false`, `nil` and `nil` (`spinel diff`: output-diff). CRuby prints `true`, `0` and `"ab"`.

A boxed String the program appends to is kept as a shared handle, and its tag is not `SP_TAG_STR`. The arms that search a typed String Array with a boxed needle (`include?`, `member?`, `index`, `find_index`, `rindex`, and `delete` with or without a block) tested that tag alone, so they answered as they do for a needle that is no String. Each keeps its String arm and its nil arm as they were and gains a handle arm after them, through `sp_poly_is_strbuf` and `sp_poly_unbox_s`. The needle is only compared, and `delete` answers the Array's own element, so nothing keeps the handle's buffer.

Cost: a plain String needle takes the arm it took (callgrind on 8578e3fb543a, 100,000 calls: `a.include?(h["k"])` goes from 155 to 156 instructions a call and `a.index(h["k"])` from 215 to 214); an Integer needle pays the new test, 8 to 11. The generated C changes in 93 corpus programs, the ones with such a search, in that expression alone, and their tests pass; optcarrot's C is unchanged.

Not changed: an append through a reader of a boxed object is lost before any search runs (`b1.v << "b"` and then `[b1, b2][0].v` reads `"a"`), so such a needle still misses.

## `make gate` (on this branch merged with current master)

```
not run yet
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
