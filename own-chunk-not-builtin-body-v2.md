<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def chunk = [5, 6].each_with_index
p chunk.map { |x| x }
```

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +1 @@
-[5, 6]
+[[5, 0], [6, 1]]
```

The same for a method, an `attr_reader`, a Struct member or a class method of the program's own named `chunk`, `chunk_while`, `slice_when`, `slice_before` or `slice_after`: a lone `|x|` got the whole pair, a lone `|*r|` got it wrapped once more, and `chunk.any? { |x| x == 5 }` answered false.

Cost: none on a call of the builtin's, whose C is unchanged. A call of the program's own that master ran right by the values it met (`chunk.none? { |x| x == 99 }`) now costs what the same method costs under any other name: over 2,000 items, 7 instructions an item more with gcc and 86 with clang, of 585 and 502.

The builtin's five yield one chunk a step, so the `to_a` that stands in front of a block over one of them hands each chunk on as the one value it is. `one_value_enum_source` knew them by the call's name alone, and a method of the program's own by one of the names, which answers what it likes, was read the same way.

The name now stands for the builtin's unless the call is proven to reach the program's own: a bare call or one on `self` where the top level or the enclosing class defines the name; a receiver typed as an object of a class of the program that defines or reads it; a constant naming a class with a class method of the name; an Array, Hash or Range whose class the program reopened with the name, where the call carries no block. Every other call is read as before and keeps its C.

Not in this change, each as on master: a top-level `def chunk` called bare from inside a class, `self.class.chunk`, `A::B.chunk`, a `chunk` added to Object, and a receiver that is a local or a parameter of two classes are still read as the builtin's (`[[5, 0], [6, 1]]` for `[5, 6]`); a builtin reopened with the name and called with a block still runs the builtin's (`[1, 2, 4].chunk_while { |x, y| y == x + 1 }` beside `class Array; def chunk_while = each_with_index; end`).

Depends on "uniq with a block keeps an Enumerator's items, not what the block binds": without it `p chunk.uniq { |x| x }`, right on master only because `chunk` was read as the builtin's, prints `[5, 6]` for `[[5, 0], [6, 1]]`.

`test/own_method_named_chunk.rb` prints 24 lines; master prints 11 of them wrong.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
