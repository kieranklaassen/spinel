<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Grid
  def initialize
    @rows = [[1, 2], [3, 4]]
  end

  def add
    @rows << []
    p @rows[2], @rows[2].size   # CRuby: [] and 0. master dafa0d04: [0, 0, 0, 0, 0, 0, 0, 0] and 8
  end
end
Grid.new.add
```

The same with `push`. With `@rows[1] = []` in place of the push, and that row read after it, master does not compile: an `sp_IntArray *` initialised from an `sp_PolyArray *`.

`narrow_int_table_ivars` pins such an ivar as a table of Integer Arrays and lets an empty `[]` stored into it pass, as "typed by the table it lands in". Nothing typed it: `mark_empty_array_operands` built it as a poly array, and the table's reader took that as a bare `sp_IntArray *`. It now gives an empty literal pushed into a table of Integer rows, or stored into it at an Integer index, the kind of its rows. `src/analyze.c`, 10 lines.

One program gets an answer where it had a build failure, and the answer is not CRuby's: a stored row kept under a name and then given an element of another kind. `e = (@t[1] = []); e << "s"; p e, @t[1]` prints ["s"] and [], where CRuby prints ["s"] twice. Master prints the same two lines with the `[]` written `([7] - [7])`, and copies a row with no empty literal at all (`e = @t[1]; e << "s"`): the copy is the typed table's and is not made here.

Not in this change, and as on master: an empty row that is no bare `[]` (`@t << Array.new` reads back as eight zeros).

The test is `test/ivar_table_stored_empty_row.rb`: 20 lines printed; master does not compile it. `tools/cident.sh` against master dafa0d04 answers `6281 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`, the one being the test. optcarrot's C does not change.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag, equal under Ruby 4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none in the test)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
