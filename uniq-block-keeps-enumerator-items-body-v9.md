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

Cost: whether a step yields one value or several is known when the program runs, so the loop asks. By callgrind, instructions a step with gcc and with clang, on programs master runs right: a lone `|x|` over a one-value Enumerator, `e.uniq { |x| x }` over `a.each` 1.5 and 1 more (of about 225 and 176 at 8 distinct keys), over `s.each_char` 0 and 1, over `a.each_slice(2)` 1 and 4 a slice (of about 2,626 and 2,452); `{ |x| x[0] }` over those slices 0 and 4, of 767 and 756. A lone `|*r|`: `{ |*r| r[0] }` over `each_with_index`, whose every step is a pair, 0 and 0 (of 1,199 and 1,199); over a generator whose steps yield two values (`y.yield(i % 8, i)`) 18 and 9, of 1,856 and 1,872. It is stated and not cut: whether a step packs is known only when the program runs, so a loop free of the question would be the loop and the block's body written twice, which costs more than it saves. The lines master prints wrong pay for their new answer: a lone `|x|` over `each_with_index` 414 and 395 a step (of 929 and 885), for a new Array a step, made ahead of the loop; `{ |*r| r[0] }` and `&:abs` over `a.each` 25 and 22, and 22 and 24 (of 531 and 500, and of 601 and 593). A block with two parameters, a bare block and no block keep their C.

The other way round, over `o = [5, 6, 5, 7].each`, `o.uniq { |*r| r }` prints `[[5], [6], [7]]` for `[5, 6, 7]` and `o.uniq(&:odd?)` prints `[[5], [6]]` for `[5, 6]`.

The `to_a` that stands in front of a block iterator over an Enumerator hands each item as the block binds it (`enum_hop_yield_view`): the first value a step yields for a lone `|x|`, all of them for a lone `|*r|` or `&:m`. That is right for `map` or `count`, whose answer is the block's. `uniq` answers the items, and got what the block binds in their place.

`emit_poly_uniq_block` now reads the Enumerator itself under such a view. For a lone `|x|` it takes the Enumerator's plain `to_a` and makes of it what the view's `to_a` makes, ahead of the first step as it does: the first values stand in place and the block binds them, as before; beside them stands a new Array of the values of each step that packed two or more, and that Array is the step's survivor. For a lone `|*r|` or `&:m` the view's `to_a` stands as it did, a new Array of each step's values, and that Array is the survivor, as on master, but for a step of one value nothing can change in place (an Integer, a Float, a Symbol, nil, true or false): that value is taken ahead of the block and is the step's survivor. Any other one value keeps its Array for the survivor: it may be a String or an Array the Enumerator made and keeps (`each_char`, `each_slice`), and what `uniq` answers must not be an object the Enumerator's next `to_a` hands out again. So the Array a step packed is never the survivor either: the survivor is a new one of the same values. An Enumerator whose steps yield one value or several (`Enumerator.new { |y| y.yield 1; y.yield 2, 3 }`) comes out right by the same road. It does so only where the program as written gives no class a `uniq` of its own (master's `an_prog_never_gives`): no `def` and no Symbol of that name, and no site where a method is named, made or loaded by something the text does not spell. A `uniq` the program gives Enumerable or Enumerator, in a file the compiler reads or in one it does not, answers what it likes, so such a program keeps master's C.

A step that yields one value has the parameter for its item, and a block may change that String in place: over `"a\nb\na\n".each_line`, `e.uniq { |x| x.chomp!; x }` answers `["a", "b"]`, on master too, for `x.chomp!` rebinds the parameter and `uniq` kept the changed one. So for a lone `|x|` the survivor of such a step is the parameter as it is after the block ran, as it was; a step that packed several values has the new Array of them.

Not in this change: a program that holds a `def` or a Symbol named `uniq`, or a site of the five kinds master's `an_prog_never_gives` lists (`5.send(m)`, `[1].map(&pr)` with a proc in a local, a file the compiler does not read, a module mixed in), keeps master's answer, `[5, 6]` for the two lines above: so after `require "json"`, whose text holds the word `require` in a string or in a comment, and after `require "set"`, whose text mixes a module in, and not after `require "time"`. The chain written in one expression, `[5, 6, 5].each_with_index.uniq { |x| x }`, is refused on master and here (unsupported call). Under a lone `|*r|` or `&:m` a step of one value that is a String, an Array, an object or an Integer past 64 bits keeps master's answer, its Array: `%w[a b a].each.uniq { |*r| r[0] }` is `["a", "b"]`, and master and this print `[["a"], ["b"]]`; so over `each_char`, `each_line`, `each_slice` and `each_cons`. A step of no value keeps master's too: over `Enumerator.new { |y| y.yield; y.yield(nil) }`, `g.uniq { |*r| r.size }` is `[nil, nil]`; master prints `[[], [nil]]`, this `[[], nil]`. A block that changes its `|*r|` over steps of several values has the changed Array for the survivor, as on master: over `e`, `e.uniq { |*r| r << 1; r[0] }` is `[[5, 0], [6, 1]]`, and master and this print `[[5, 0, 1], [6, 1, 1]]`. A lone `|x|` over a Hash's `each` has the pair for its one value, so the survivor is the Array the Enumerator keeps, as on master. A block that changes in place the first value of a step that yields several is wrong on master and wrong here: over `w = [+"a\n", +"b\n", +"a\n"].each_with_index`, `w.uniq { |x| x.chomp!; x }` is `[["a", 0], ["b", 1]]`; master prints `["a", "b"]`, this prints `[["a\n", 0], ["b\n", 1]]`.

`test/enum_uniq_block_keeps_item.rb` prints 27 lines and carries `# spinel: gc-stress`; master prints 14 of them wrong.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/enum_uniq_block_keeps_item.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; the generated C of every program `tools/cident.sh` lists, by this head's compiler and by master's, with that tool's flags (6,716 programs identical, 1 differs: the new test; none refused); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is master's byte for byte)
- [ ] Depends on: none
