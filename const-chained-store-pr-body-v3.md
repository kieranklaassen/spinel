<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
D = [[1, 2], [3, 4]]
D.push([5]).push({})
p D[3]              # CRuby: {}. master: SIGSEGV

E = [[1, 2], [3, 4]]
E.push([5]).push(["a"])
p E[3]              # CRuby: ["a"]. master: [0, 0, 0, 0]
```

The same with `D << [5] << r`, `(D << [5]) << r`, `D.concat([[5]]).push(r)`, `D.fill([7, 8]).push(r)`, `D.each { }.push(r)` and `D.sort!.push(r)`.

The test for a constant table of Integer Arrays reads the rows a call stores where the call's receiver is the constant. In a chain the receiver is the call ahead. It is looked through now (`an_store_table` in `src/analyze_infer.c`) where that call answers its receiver: the push family, `insert`, `concat`, `fill`, `replace`, `clear`, `map!`, `collect!`, `sort!`, `sort_by!`, `reverse!`, `rotate!`, `shuffle!`, `keep_if`, `delete_if`, `each`, `each_index`, `reverse_each`, `tap` and `itself`, and `select!`, `reject!`, `uniq!` and `compact!`, which answer it or nil.

It cannot make a right program wrong: a chained store only ever turns a typed table general. `T[i] = r` at the end of a chain (`T.push(nil)[0] = ["a"]`) is read the same way and, unlike `T[i] = r` on the constant itself, never makes a table a table of Integer Arrays. The cost is the one a row pushed on the constant itself has: the table is read boxed from then on, also where the chained store never runs.

Not here: `T.to_a.push(r)` and `T.each_with_index { }.push(r)` (calls that answer their receiver and are not on the list), and the table through another name.

The test is `test/const_table_chained_store.rb`: 40 lines printed; master prints six, two of them right, and then faults. `tools/cident.sh` against master 2f204adb answers `6340 identical, 2 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the two being this test and the test of the change below it. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; not yet run under Ruby 4.0)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (the change "T << row stores a row into a constant table as T[i] = row does": this branch is that commit and one more)
