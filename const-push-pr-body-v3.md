<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
D = [[1, 2], [3, 4]]
D << ["a"]
p D[2]              # CRuby: ["a"]. Here: [0, 0, 0, 0]

E = [[1, 2], [3, 4]]
E << []
p E[2], E[2].size   # CRuby: [] and 0. Here: [0, 0, 0, 0, 0, 0, 0, 0] and 8

F = [[1, 2], [3, 4]]
F.push({})
p F[2]              # CRuby: {}. Here: SIGSEGV
```

The same with `append`, `unshift`, `prepend`, `insert` and `concat`. `D.map! { [] }`, `D.fill(["x"])` and `D.replace([["a"]])` read the new rows as Integer Arrays too, and so does a `map!` whose block answers Integers: after `D.map! { |r| r.reverse }`, `p D[0]` prints [0, 1, 0, 0, 0, 0, 0, 0].

The test for a constant table of Integer Arrays (`const_array_elems_all_int_array` in `src/analyze_infer.c`) reads the rows stored after the constant is written from `T[i] = v` and `T.store(i, v)`. Its twin for an instance variable reads the push family, `insert` and `concat` as well. A row pushed onto a constant was not read, so the table stayed a table of Integer Arrays whatever was pushed, and `T[i]` read the pushed row as an `sp_IntArray` without a test.

The loop that reads a row-storing call is one function now (`an_stored_rows_int`), asked by both tests: a row of another kind pushed onto the constant makes it a general table, an Integer Array pushed leaves it a table of Integer Arrays. `map!` and `collect!` called on the constant write its rows anew, and the table is a general one after them. `fill` and `replace` do too, unless the call hands over Integer Arrays and nothing else: `D.fill(r)` with a row of that type and no block, `D.replace([r, s])` with every row written out. The table stays a table of Integer Arrays then, as it was read before. 69 lines added, 33 removed; the instance variable's test reads what it read.

**Measured on master 9b52e40e with #7497 and four further empty-row changes beneath (a local holding an empty row, one in parentheses, `each` with two parameters, `T[i] ||= v`), each program compared with CRuby 3.3.6.** 15,960 generated programs, each a different one: a constant table of Integer, Float or String rows (at top level, frozen, used inside a method, in a module); a row stored 19 ways (`<<`, `push`, `append`, `unshift`, `prepend`, `insert`, `concat` of a literal and of a local, `push(*x)`, `map!`, `collect!`, `fill`, `replace`, a chain, two at once; `T[1] = v`, through a second name, through a method, and no store beside them); the row `[]`, `["a"]`, `[1.5]`, `[7]`, `{}`, `nil`, `Array.new`, `5`, `[1, "a"]` or `([])`; read back 7 ways.

| | master 9b52e40e | this change |
|---|---|---|
| 13,360 programs | | generated C identical to the commit beneath |
| 2,600 programs (a table of Integer rows) | 168 as CRuby, 668 raise as CRuby does, 1,296 wrong and silent, 423 crash, 45 raise where CRuby does not | 1,653 as CRuby, 857 raise as CRuby does, the same 45 wrong and 45 raising |

Master and the commits beneath answer the same on each of the 2,600. No program that answered as CRuby answers differently, and none that raised or crashed answers silently. 650 of the 668 are a frozen table: FrozenError before and after. 99 of the crashes are a Hash or nil where the program sends a row's method (`D[2] << 5`, `D[2].size`): now NoMethodError as CRuby. The 45 and 45 are a Float or a String row pushed onto the table and then pushed an Integer (`D << [1.5]; D[2] << 5` gives [1.5, 5.0], and with `["a"]` raises "cannot store Integer into an Array[String]"): the row's own typing, as with `D[2] = [1.5]`.

**The cost.** A table whose rows are written anew by `map!` or `collect!`, or that is given rows through a local or a splat (`x = [[7]]; D.concat(x)`, `D.push(*x)`), is read boxed from then on, also when every new row is an Integer Array, and so is one filled or replaced with nil: 96 of the 168, the same output from boxed reads. A loop that only reads such a table pays for it. callgrind, a million `D[i & 3][i & 1]` on a table of four rows:

| after | the commit beneath | this change |
|---|---|---|
| `x = [[7, 8]]; D.concat(x)` | 28.7M instructions | 144.7M |
| `x = [[7, 8]]; D.push(*x)` | 28.7M | 145.7M |
| `D.map! { [7, 8] }` | 28.7M | 142.7M |
| `D.fill([7, 8])`, `D.replace([[2, 1], [4, 3], [6, 5], [8, 7]])` | 28.7M | 28.7M, the same C |
| `D << [7, 8]`, no store at all | 28.7M | 28.7M, the same C |

A table held in a local is a general Array once it is handed to the constant, so its type says nothing of its rows, and the local's own writes are not followed here. The instance variable's test answers the same for `concat` of a local and for a splat. For `map!` the general table is the fix above: its block answers rows of any kind. The other 72 of the 168 store a row of another kind and do not read it.

Not in this change, and the same before and after it: a table appended to through another name (`t = D; t << ["a"]`) or by a method it is handed to (`add(D, ["a"])`) is not followed, and the row reads [0, 0, 0, 0]. Nor is a store chained on the value of another: `D.push([5]).push(["a"])`, and `D.fill([7, 8]).push(["a"])` where the `fill` leaves the table typed, read the last row as an Integer Array, exactly as on master. Of the 560 programs of the first two kinds, 168 answer as CRuby, 140 raise FrozenError as CRuby does, 180 are wrong, 66 crash and 6 raise in another way. The instance variable's test gives up on a table that escapes; a constant table handed to a method is the common use of one, so that scan is not asked here. A nil pushed or stored leaves the table typed, with a null row: `D << nil; p D[2]` prints nil, and `D[2].size` crashes where CRuby raises NoMethodError.

**Generated C.** This change stands on master alone: #7497, which it builds on, is merged. `tools/cident.sh` against master fa08b100: `6111 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`; the one is the new test. No other test's, no benchmark's and not optcarrot's C changes, the instance variable tables' tests among them.

**Test.** `test/const_table_pushed_row.rb` (27 lines printed; 14 differ without this change, and the last five hold the typed read after `fill` and `replace`). It prints the same under `SPINEL_GC_STRESS=1` and `2`.

The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; the test prints the same, byte for byte, under Ruby 4.0.7 with that flag.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, equal under Ruby 4.0.7; the test prints Arrays, Integers and a Float)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing; it builds on #7497, which is merged)
