<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
e = [5, 6, 5].each_with_index
p e.uniq { |x| x }
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[[5, 0], [6, 1]]
+[5, 6]
```

Cost: whether a step yields one value or several is known when the program runs, so the loop is told ahead of its first item and asks it of each survivor. A lone `|x|` over a one-value Enumerator, right on master, pays by callgrind, a step with gcc and with clang: `e.uniq { |x| x }` over `a.each` 5 fewer and 1 more (of about 225 and 176 at 8 distinct keys), over `s.each_char` 0 and 1, over `a.each_slice(2)` 0 and 4 a slice (of 2,626 and 2,452); `{ |x| x[0] }` over those slices 7 and 5, of 767 and 756. A lone `|*r|` over `each_with_index`, right on master: `{ |*r| r[0] }` is 53 and 27 cheaper, of 1,206 and 1,199. A block with two parameters, a bare block and no block keep their C.

The other way round, over `o = [5, 6, 5, 7].each`, `o.uniq { |*r| r }` prints `[[5], [6], [7]]` for `[5, 6, 7]` and `o.uniq(&:odd?)` prints `[[5], [6]]` for `[5, 6]`.

The `to_a` that stands in front of a block iterator over an Enumerator hands each item as the block binds it (`enum_hop_yield_view`): the first value a step yields for a lone `|x|`, all of them for a lone `|*r|` or `&:m`. That is right for `map` or `count`, whose answer is the block's. `uniq` answers the items, and got what the block binds in their place.

`emit_poly_uniq_block` now takes the Enumerator's plain `to_a` under such a view and binds the parameter itself, an item at a time, so the survivor is the item. For a lone `|x|` over steps that yield two values the first values are kept in an Array of their own, made only then. An Enumerator whose steps yield one value or several (`Enumerator.new { |y| y.yield 1; y.yield 2, 3 }`) comes out right by the same road, and so does a block that changes its `|*r|`.

A step that yields one value has the parameter for its item, and a block may change that String in place: over `"a\nb\na\n".each_line`, `e.uniq { |x| x.chomp!; x }` answers `["a", "b"]`, on master too, for `x.chomp!` rebinds the parameter and `uniq` kept the changed one. So for a lone `|x|` the survivor of such a step is the parameter as it is after the block ran, as it was; only a step that packs several values (`sp_yielded_packed`) is read from the `to_a`'s own Array.

Not in this change: the chain written in one expression, `[5, 6, 5].each_with_index.uniq { |x| x }`, is refused on master and here (unsupported call). A block that changes in place the first value of a step that yields several is wrong on master and wrong here: over `w = [+"a\n", +"b\n", +"a\n"].each_with_index`, `w.uniq { |x| x.chomp!; x }` is `[["a", 0], ["b", 1]]`; master prints `["a", "b"]`, this prints `[["a\n", 0], ["b\n", 1]]`. So is `e.uniq(&:chomp!)` over `each_line`: `["a", "b"]`; master `[["a\n"], ["b\n"]]`, this `["a\n", "b\n"]`.

`test/enum_uniq_block_keeps_item.rb` prints 21 lines and joins `GC_STRESS_TESTS`; master prints 12 of them wrong.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/enum_uniq_block_keeps_item.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; `make cident` against master (6,553 programs identical, 1 differs: the new test); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
