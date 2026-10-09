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

The same for a method or a class method of the program's own named `chunk`, `chunk_while`, `slice_when`, `slice_before` or `slice_after`: a lone `|x|` got the whole pair, a lone `|*r|` got it wrapped once more, and `chunk.any? { |x| x == 5 }` answered false.

Cost: none on a call of the builtin's, whose C is unchanged. A call of the program's own that master ran right by the values it met (`chunk.none? { |x| x == -99 }`) now costs what the same method costs under any other name. An item, gcc and clang, over 2,000 Integers: 70 and 149 instructions more between 20 and 60 rounds (of 530 and 446), 32 fewer and 47 more over 1,000 rounds (of 654 and 571); over 2,000 Strings (`x == "zz"`): 207 and 203 more between 20 and 60 rounds, 161 and 157 more over 1,000 (of 696 and 672).

The builtin's five yield one chunk a step, so the `to_a` that stands in front of a block over one of them hands each chunk on as the one value it is. `one_value_enum_source` knew them by the call's name alone, and a method of the program's own by one of the names, which answers what it likes, was read the same way.

The name now stands for the builtin's unless the call is proven to reach the program's own: a bare call or one on `self` where the top level or the enclosing class defines the name; a receiver typed as an object of a class of the program that defines it; a constant naming a class with a class method of the name; an Array, Hash or Range whose class the program reopened with the name, where the call carries no block. Every other call is read as before and keeps its C.

The proof is of the program's one `def` of the name, so it is asked only where the program as written holds no other `def` of that name, no Symbol of it, and no site where a method is named, made or loaded by something the text does not spell (master's `an_prog_never_gives`). A second `def`, in a branch the compiler rules dead or in a file it does not read, may be the one CRuby runs, and master, which reads the name as the builtin's, answers some such programs right: with `def chunk = [5, 6].each_with_index` and then `if RUBY_ENGINE == "ruby"` around `def chunk = [[5, 0], [6, 1]].each`, `p chunk.map { |x| x }` prints `[[5, 0], [6, 1]]` on CRuby, on master and here.

Not in this change, each as on master: a reader or a Struct member of the name, which is a Symbol of it (`attr_reader :chunk`, `Struct.new(:chunk)`), a name the program defines twice (`def chunk` in two classes), and any program that holds such a site (`require "json"`, whose text holds the word `require` in a comment or in a string, or a module mixed in, `class Foo; include Comparable; end`, ahead of the two lines above) are still read as the builtin's; so are a top-level `def chunk` called bare from inside a class, `self.class.chunk`, `A::B.chunk`, a `chunk` added to Object, and a receiver that is a local or a parameter of two classes (`[[5, 0], [6, 1]]` for `[5, 6]`); a builtin reopened with the name and called with a block still runs the builtin's (`[1, 2, 4].chunk_while { |x, y| y == x + 1 }` beside `class Array; def chunk_while = each_with_index; end`); a receiver that ends in a `to_a` the program wrote is still read as the builtin's (`a.to_a.chunk.map { |x| x }` beside `class Array; def chunk = each_with_index; end`); and a Range reopened with one of the other four names still raises (`(1..2).chunk_while.map { |x| x }` beside `class Range; def chunk_while = each_with_index; end`: NoMethodError), as does a Hash's where the Enumerator is held in a local first (`e = h.slice_when; e.map { |x| x }` beside `class Hash; def slice_when = each_with_index; end`: NoMethodError).

Depends on "uniq with a block keeps an Enumerator's items, not what the block binds": without it `p chunk.uniq { |x| x }`, right on master only because `chunk` was read as the builtin's, prints `[5, 6]` for `[[5, 0], [6, 1]]`.

`test/own_method_named_chunk.rb` prints 20 lines; master prints 8 of them wrong.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this head, in a container without CRuby 4.0: the build; `test/own_method_named_chunk.rb` with gcc and clang at `SPINEL_GC_STRESS` 0, 1 and 2 and with `--share-strings`; `ruby tools/gate.rb check`; the generated C of every program `tools/cident.sh` lists, by this head's compiler and by its base's, with that tool's flags (6,717 programs identical, 1 differs: the new test; none refused); `make share-strings-test` and `make int-min-test`; the test's `.expected` is CRuby 3.3.6's, run with `--enable-frozen-string-literal`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (the test has none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not: the C is its base's byte for byte)
- [x] Depends on: the pull request "uniq with a block keeps an Enumerator's items, not what the block binds"
