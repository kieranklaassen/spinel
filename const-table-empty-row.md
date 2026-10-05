<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
GRAPH = [[1, 2], [], [3], []]          # an adjacency list; nodes 1 and 3 have no edge
p GRAPH[1]            # CRuby: []. Here: [0, 0, 0, 0, 0, 0, 0, 0]
p GRAPH[1].size       # CRuby: 0. Here: 8
p GRAPH[3].empty?     # CRuby: true. Here: false
row = GRAPH[1]
row << 5
p GRAPH               # CRuby: [[1, 2], [5], [3], []]. Here: [[1, 2], [], [3], []]
GRAPH.each { |a, b| p [a, b] }         # CRuby: [nil, nil] for the empty rows. Here: [0, 0]
```

Nothing is said. A frozen table does the same, and so does an instance variable holding one once the table is a general Array (after `@rows.each { |a, b| ... }` or `@rows.inspect`).

A constant or an instance variable whose rows are all Integer Arrays hands out `T[i]` as an `sp_IntArray`, read out of the boxed table without a test, and spreads a row over two block parameters as Integers (`const_array_elems_all_int_array`, `ivar_array_elems_all_int_array` in `src/analyze_infer.c`). Both step over a row whose type is not settled yet, so that the answer can still become yes while types are being worked out. An empty `[]` has no type of its own either, and it never gets one: it is built as a poly array. So the row was stepped over, the table was called a table of Integer Arrays, and the empty row was read through the wrong struct: a length of 8, and the poly array's storage as the elements. A bare `Array.new` and an empty `{}` went the same way, the Hash to a crash.

A row that is an empty container with no type is now a row of another kind: where the table is written, where a row is stored into it (`T[1] = []`, `@rows << []`), and where the block of a `map` that builds it ends. Such a table stays boxed. A row not typed yet is stepped over as before. One new function of three lines, asked in four places.

**Measured against master 701529f0, each program compared with CRuby 3.3.6.** 8,525 generated programs, each a different one: a table of rows (Integer, Float, String, Symbol, mixed, with nil, with a literal past 64 bits, of two lengths) with an empty row nowhere, first, in the middle, last, twice, alone, or written `Array.new` or `{}`; held in a constant, a frozen constant, a module's constant, an instance variable, and an instance variable after `inspect`; used 31 ways (`T[i]` printed, sized, compared, tested with `empty?`, `first`, `include?`, `equal?`, mapped, iterated, appended to directly and through a local; `each`, `reverse_each`, `map`, `filter_map`, `select`, `any?` with two parameters; `each`, `each_with_index`, `fetch`, `dig`, `flatten`; a row or an empty row stored or pushed later; a row cleared in place).

| | master 701529f0 | this branch |
|---|---|---|
| 7,599 programs | | generated C identical to master's |
| 926 programs (Integer rows with an empty row, or an empty row stored later) | 273 as CRuby, 47 raise as CRuby does, 512 wrong and silent, 94 crash | 867 as CRuby, 59 raise as CRuby does |

No program that answered as CRuby on master answers differently. The 94 crashes are the `{}` row; 12 of them are `T[1] << 5` on that Hash, which now raises NoMethodError as CRuby does. The other 47 are a store or a push into a frozen table: FrozenError before and after.

**The cost.** A table that holds an empty row is read boxed from now on, also by a program that never read the empty row wrongly (the 273 above). A loop that does nothing but read such rows is 5 to 7 times slower: 50,000,000 reads of `T[i & 1][i & 3]` take 0.08 s on master and 0.54 s here, 3,000,000 walks of a five-node adjacency list with an edgeless node 0.08 s and 0.38 s (gcc 13.3, best of five). A table with no empty row is untouched, its C identical. Building the empty row as an Integer Array instead would keep such a table typed; that is a larger change and not this one.

A table with a row holding a literal past 64 bits was already boxed and is unchanged, and so is a row emptied in place (`T[0].clear`).

Not in this change, wrong on master and still wrong:

- an empty row written in parentheses, `T = [[1, 2], ([]), [3]]`;
- an empty row held in a local that is never filled, `e = []; T = [[1, 2], e, [3]]` or `T[1] = e` (with `e = {}`, a crash);
- an empty row stored over a nil one by `T[1] ||= []`;
- a row pushed onto a constant after it is written (`T << []`, `T << ["a"]`), which is not looked at for any kind of row.

Each reads the row back as an Integer Array it is not (eight zeros for the empty row). The same row in a literal that is the receiver itself, `[[1, 2], []].each { |a, b| ... }`, is typed elsewhere and is a separate change.

**Generated C.** `tools/cident.sh` against 701529f0: `5924 identical, 0 differ, 0 refusal changes, 0 refused by both, 1 not in the reference` (the new test). No test's, no benchmark's and not optcarrot's C changes. Compared again on master 92510d6c1 together with the sibling change to `each`: of 6,017 programs only the two new tests differ.

**Test.** `test/const_table_empty_row.rb` (50 lines printed; 26 differ on master). It prints the same under `SPINEL_GC_STRESS=1` and `2`.

The `.expected` file was written with CRuby 3.3.6 run with `--enable-frozen-string-literal`; CRuby 4.0.7 with the same flag prints it byte for byte.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
