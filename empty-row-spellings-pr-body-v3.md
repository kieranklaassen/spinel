<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
e = {}
T = [[1, 2], e, [3]]
p T[1]              # CRuby: {}. master: SIGSEGV

U = [[1, 2], ([]), [3]]
p U[1]              # CRuby: []. master: [0, 0, 0, 0, 0, 0, 0, 0]
```

With `e = []` the first prints the eight zeros too, and a table the local is stored into (`e = []; T[1] = e`) answers 8 for `T[1].size`. `[[1, 2], ([]), [3, 4]].each { |a, b| p [a, b] }` prints [0, 0] for the middle row, where CRuby prints [nil, nil].

The test for a table of Integer Arrays (`an_row_open_empty` in `src/analyze_infer.c`) steps over a row whose type is not settled yet, and takes an empty literal for a row of another kind. A local that is never filled is not typed either, and is built as the boxed container its literal is; a literal in parentheses is a ParenthesesNode, which is no literal. Both were stepped over, the table was called a table of Integer Arrays, and the row was read as an `sp_IntArray` without a test.

Two commits. The first: a read of a local whose every write is an empty container, while nothing has typed it, is such a row; a local that is filled is typed by what fills it and is the row it was. The second: the test, and the loop that types `each`'s two parameters (`src/analyze_pass.c`), look through the parentheses.

The cost: a table holding such a row is read boxed, as a table with a bare `[]` row is on master.

One program gets an answer where it crashed, and the answer is not CRuby's:

```ruby
class K
  def go
    e = []
    [1].each { e = {} }
    @t = [e, [1, 2], [3, 4]]
    i = 1
    p @t[i], @t[i].size, @t[0][0] + 1   # CRuby: NoMethodError (nil + 1)
  end
end
K.new.go
```

master ends in SIGSEGV; this prints [1, 2], 2 and 1. Master prints the same three lines with the row written `{}` in the literal (`@t = [{}, [1, 2], [3, 4]]`): a Hash row of an instance variable's table read with an Integer key answers 0. That answer is master's and is not made here.

The tests are `test/const_table_local_empty_row.rb` (26 lines printed; master ends it in SIGSEGV) and `test/const_table_paren_empty_row.rb` (20 lines, 10 differ on master). `tools/cident.sh` against master 06064727 answers `6334 identical, 2 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the two being the tests (1 with the first commit alone). optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, equal under Ruby 4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the tests)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
