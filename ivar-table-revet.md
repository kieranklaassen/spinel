<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A row stored into an ivar table was read back as the wrong kind of Array when it comes through methods written below the ones they call:

```ruby
class Deep
  def initialize
    @banks = [[1]]
    @patterns = [[]]
  end
  def bank
    @banks[0] = a1
    @banks[0]
  end
  def a4
    h = @patterns[0]
    h << 7
    h << 8
    h
  end
  def a3; a4; end
  def a2; a3; end
  def a1; a2; end
end
p Deep.new.bank     # [0, 8, 0, 0, 0, 0, 0, 0]   CRuby: [7, 8]
```

With `a1` written first and `a4` last, as `test/ivar_table_late_typed_row_store.rb` has them, it printed `[7, 8]`.

`narrow_int_table_ivars` pins a table once every value stored into it is an int array, and d5e6a326 made it wait while a stored value has no type yet. Here the value has a type on the round the pass first sees it, and the wrong one: `a4` answers `h << 8`, typed an int array before `h`, read out of `@patterns`, settled as boxed, and `a3`, `a2` and `a1`, standing below `a4`, take that answer within the round. The table was pinned on it, a pinned table was not vetted again, and when `a1` came out boxed a round later the row went in, and was read back, as a bare `sp_IntArray *`.

A table this pass pinned is now vetted on every round like one it has not pinned yet, and goes back to the poly array when a store is no longer a row, for the rounds to come to decide from there. That is the reset `narrow_object_arrays` gives its own narrowing every round. A table whose rows stay int arrays stays pinned.

Found with `tools/order_probe.rb` (#7099): `test/ivar_table_late_typed_row_store.rb` with the methods of `Deep` reversed gave the answer above, and its two orders now have the same types (the probe reports nothing for it). The emitted C of all 5,903 programs in `test/`, `test/reject/`, `test/infer/`, `benchmark/`, `examples/` and the packages' tests is byte-identical before and after (both compilers built on 0d370b71): no table pinned there loses a row.

`test/ivar_table_row_store_retyped.rb` has the program above; the same store with the table's other readers beside it (a local read out of the row, a block over the table, an element handed to a parameter), which have to follow the table back to the boxed Array; and a table whose row comes through three methods and stays an int array, which keeps its `sp_PtrArray *` slot. It prints its `.expected` plain and under `SPINEL_GC_STRESS=1`, and prints the wrong row on master. The change is 17 lines in `src/analyze.c`, all in `narrow_int_table_ivars` (191 lines).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it prints Integers and one Array of Integers)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (OPTCARROT_LINE)
- [ ] Depends on: # (nothing; #7099 is the probe that found it and is merged)
