<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
h = { "k" => +"a", "n" => 1 }
h["k"] << "b"
a = ["ab", "c", "ab"]
p a.include?(h["k"]), a.index(h["k"]), a.delete(h["k"])
```

prints `false`, `nil` and `nil` (`spinel diff`: output-diff). CRuby prints `true`, `0` and `"ab"`.

A boxed String the program appends to is kept as a shared handle, and its tag is not `SP_TAG_STR`. The arms that search a typed String Array with a boxed needle (`include?`, `member?`, `index`, `find_index`, `rindex`, and `delete` with or without a block) tested that tag alone, so they answered as they do for a needle that is no String. Each now reads a handle's text, through `sp_poly_is_strbuf` and `sp_poly_unbox_s`, after the tests it made before. The needle is only compared, and `delete` answers the Array's own element, so nothing keeps the handle's buffer.

Cost: a plain String needle takes the arm it took (callgrind on 70cddab37194, gcc, 100,000 calls: `a.include?(h["k"])` goes from 155 to 156 instructions a call and `a.index(h["k"])` does not move); a boxed Integer needle pays the new test, 2 to 4 instructions a call. An appended needle now runs the search it skipped, 184 to 224 more. The generated C changes in 93 corpus programs, the ones that hold such a search or an `include?` on a boxed receiver, whose String Array case gains the same arm, and their tests pass; optcarrot's C is unchanged.

A frozen Array is why this depends on another pull request: `delete` raised FrozenError before it searched, so an appended needle a frozen Array does not hold would raise here where master printed nil. With the fix beneath it answers nil, and raises only for a needle the Array holds.

Not changed: an append through a reader is lost before any search runs when the instance variable is boxed (`b1.v << "b"` and then `[b1, b2][0].v` reads `"a"`), so such a needle still misses.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [x] Depends on: # the pull request for delete on a frozen Array (delete answers nil for an element a frozen Array does not hold)
