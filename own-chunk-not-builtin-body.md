<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def chunk = [5, 6].each_with_index
p chunk.map { |x| x }
p chunk.map { |*r| r }
p chunk.any? { |x| x == 5 }
```

```
before the merge   [5, 6]              [[5, 0], [6, 1]]        true
now                [[5, 0], [6, 1]]    [[[5, 0]], [[6, 1]]]    false
CRuby              [5, 6]              [[5, 0], [6, 1]]        true
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-[5, 6]
 [[5, 0], [6, 1]]
-true
+[[[5, 0]], [[6, 1]]]
+false
```

The merge is "A block chained onto chunk_while and its kin binds each chunk as one value". The same for a class's method, an `attr_reader` or a Struct member named `chunk`, `chunk_while`, `slice_when`, `slice_before` or `slice_after`.

That change leaves a block as written when the Enumerator it walks comes from a call of one of those five names (`one_value_enum_source`), and asked only the name. A method of the program's own by that name answers what it likes: an `each_with_index` Enumerator yields two values a step, and its lone `|x|` was bound to the packed pair.

`one_value_enum_source` now asks whose method the call reaches. Where the program owns it (a top-level `def` or the caller's class for a bare call, the receiver's class or its reader, a class method on a constant, the receiver's builtin class or Enumerable reopened with the name), the block is bound by the Enumerator's flag, as every other source's is. Where the receiver's class is not settled and some class of the program has the name, a lone `|x|` is bound by the flag, which reads the builtin's chunks and the program's Enumerator alike. Every other call is the builtin's and keeps the C that change gave it.

Not in this change: the program's object in a receiver of no settled class, under `|*r|` or `&:sym`, is still read as the builtin's.

`test/own_method_named_chunk.rb` prints 22 lines, the builtin's forms among them; master is wrong on 12.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
