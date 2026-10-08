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

Cost: whether a step yields one value or two is known when the program runs, so the loop is told ahead of its first item and reads the survivor from the `to_a`'s own Array. A lone `|x|` over a one-value Enumerator, right on master, pays 1 instruction an item with clang and none with gcc: `e.uniq { |x| x }` over `a.each` (of about 367 and 575 an item), over `s.each_char`, and over `a.each_slice(2)` a slice; `{ |x| x[0] }` over those slices pays 7 with gcc and 1 with clang, of 514 and 388. A lone `|*r|` over `each_with_index`, right on master: `{ |*r| r[0] }` is 6 cheaper with gcc and 3 dearer with clang, of 1,023 and 913. A block with two parameters, a bare block and no block keep their C.

The other way round, over `o = [5, 6, 5, 7].each`, `o.uniq { |*r| r }` prints `[[5], [6], [7]]` for `[5, 6, 7]` and `o.uniq(&:odd?)` prints `[[5], [6]]` for `[5, 6]`.

The `to_a` that stands in front of a block iterator over an Enumerator hands each item as the block binds it (`enum_hop_yield_view`): the first value a step yields for a lone `|x|`, all of them for a lone `|*r|` or `&:m`. That is right for `map` or `count`, whose answer is the block's. `uniq` answers the items, and got what the block binds in their place.

`emit_poly_uniq_block` now takes the Enumerator's plain `to_a` under such a view and binds the parameter itself, an item at a time, so the survivor is the item. For a lone `|x|` over steps that yield two values the first values are kept in an Array of their own, made only then. An Enumerator whose steps yield one value or several (`Enumerator.new { |y| y.yield 1; y.yield 2, 3 }`) comes out right by the same road, and so does a block that changes its `|*r|`.

Not in this change: the chain written in one expression, `[5, 6, 5].each_with_index.uniq { |x| x }`, is refused on master and here (unsupported call).

`test/enum_uniq_block_keeps_item.rb` prints 18 lines and joins `GC_STRESS_TESTS`; master prints 12 of them wrong.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/enum_uniq_block_keeps_item.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; `make cident` against master (6,512 programs identical, 1 differs: the new test); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
