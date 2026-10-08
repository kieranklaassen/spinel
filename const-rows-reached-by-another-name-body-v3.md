<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
module Tables
  ROWS = [[1, 2], [3, 4]].map { |a| a.map { |n| n * 2 } }
  def self.cell(i, j) = ROWS[i][j]
end
row = Tables::ROWS[0]
row[0] = 2.5
p Tables.cell(0, 0)                # 2, CRuby: 2.5

TABLE = [[1, 2], [3, 4]].map { |a| a.map { |n| n * 2 } }
class Cursor
  attr_reader :row
  def initialize; @row = TABLE[0]; end
end
Cursor.new.row << "s"
p TABLE[0][2]                      # nil, CRuby: "s"
```

A plain run, gcc and clang. Both were right before "A constant mapped from a literal table of Integer rows reads its rows unboxed".

The cost: a table whose row another name reaches is built with boxed rows again, also where that name only reads the row (`cursor.row.size`), since no list tells that reach from one that stores. A read `TABLE[i][j]` of such a table costs 18 instructions more with gcc and 8 to 10 with clang where the element is summed (callgrind, 200,000 reads), and every value computed from an element is boxed with it: where the row sits in an instance variable and its element is added to an Integer instance variable (`@clk = CLOCKS[k]`, then `@count += @clk[j]`), a use costs 62 to 70 more. Where no other name reaches a row the generated C is master's: optcarrot's is unchanged, and so is the corpus's but for the new test.

Such a constant holds its rows as Integer arrays, which is sound only where nothing reaches a row but an index. The check went by names: reads of the constant's bare name, reads of an instance variable, calls of a method. A row is reached with none of those through a path (`Tables::ROWS`), `const_get`, an `attr_reader`, `instance_variable_get`, an alias, a Method object, `super`, `Kernel#Array` calling `to_a`, `x.row ||= v`, and a method of the program's own named like an iterator (`def each = yield`), whose block's value was taken as dropped. The row then took a Float or a String into an Integer slot, lost the store to a copy, or the program was refused or raised TypeError.

A path is now examined as the bare name is, so `Tables::ROWS[i][j]` keeps the Integer rows, and `super` counts as a call of the method it is written in. For the rest the check goes by spelling: a constant, an instance variable or a method whose name is written as a Symbol or a String anywhere in the program may be reached through it, and its table is built as it was before that rule.

```
spinel diff: output-diff
--- stdout (ruby)
+++ stdout (spinel)
@@ -1,2 +1,2 @@
-2.5
-"s"
+2
+nil
```

Where the change applies the generated C is what the rule's absence gives. A Symbol or a String that happens to spell the name (a Hash key `row:` beside an instance variable `@row` that holds a row) also returns the table to boxed rows.

Two commits. The first finds a method's calls through the name index (`an_calls_named_first`) where the check walked every call of the program, and changes no generated C (`tools/cident.sh`). The second is the fix; it gathers the Symbols and Strings once and again when the node table changes. Compiling optcarrot takes 9.8 million instructions fewer than on master (callgrind: 8,346.4 million to 8,336.7 million; the second commit alone adds 0.6 million).

Test: `test/const_rows_reached_by_another_name.rb`.

Not here: a row past the end of the table (`ROWS[5][0]` prints nil where CRuby raises NoMethodError, as a literal table does), and under `--int-overflow=promote` a row computed by arithmetic. And master's `a[i] += x` past the end of an Integer Array, with a boxed `x`, stores a number where CRuby raises NoMethodError: `x = [24, "s"][0]; a = [0] * 3; a[5] += x; p a` prints `[0, 0, 0, nil, nil, -9223372036854775784]`. A table returned to boxed rows hands that statement a boxed element, so a program that spells the constant's name and adds an element past the end of an Integer Array prints such an Array, as it did before the rule, where it raised with Integer rows.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on master `9922a2c74ee1`, gcc and clang: the new test at `SPINEL_GC_STRESS` unset, 1 and 2 (also with `--share-strings`); `tools/gate.rb check` with each commit staged; `tools/cident.sh` against master at each commit (the first changes no C; the second only lets the new test build); `make int-min-test`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: nothing
