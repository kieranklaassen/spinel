<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
BASE = 3
ROWS = [[1, 2], [BASE + 1, 2]].map { |a| a.map { |n| n * 2 } }
p ROWS[1][0]                       # 0 under --int-overflow=promote, CRuby: 8
```

With `--int-overflow=promote`, a plain run, gcc and clang; without the flag the program is right. It was right with the flag too before "A constant mapped from a literal table of Integer rows reads its rows unboxed".

In that mode an Integer `+`, `-` or `*` whose operands are not both literals is a boxed value, since it can leave the word, and the row literal that holds one is built as an Array of boxed values. `an_settled_int`, which says whether a row's element is an Integer no later inference can widen, took any arithmetic over settled Integers as one, so the constant read that row as an Integer array. With the flag such arithmetic now counts as settled only where `infer_operator_call` keeps it an Integer: two literals whose result fits the word. `/`, `%` and unary minus cannot leave the word and count as before over settled operands.

Two commits. The first moves that test out of `infer_operator_call` into `infer_promote_op_in_word` and changes no generated C, with the flag or without (`tools/cident.sh`, both ways); the second asks it from `an_settled_int`.

Without the flag no generated C changes. With it, the C of a program changes only where a row holds such arithmetic, to what it was before the rule; optcarrot's generated C is unchanged in both modes.

Test: `test/const_rows_arith_under_promote.rb`. It runs in both suites; the lines are wrong only under `make test SPINEL_INT_OVERFLOW=promote`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
