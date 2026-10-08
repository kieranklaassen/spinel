<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A regression on master, in a plain run: a parenthesized sequence runs ahead of an operand written before it.

```ruby
class Pair
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
  def self.late(s)
    return s, (s = "bb"; new("x", "t").x)
  end
end
d = Pair.new(+"w", +"v")
d.x << "z"
d.y << "z"
p Pair.late("a")     # ["a", "x"] in Ruby and on 9c7ea3ce0; ["bb", "x"] on master (9922a2c74), gcc and clang, exit 0
```

It came with "Shared String argument conversions stay rooted across calls": master built without that change's lines in `src/codegen_fold.c` prints `["a", "x"]` again. The change itself is right. A literal or a bare read bound to a shared-handle parameter now gets a rooted temp for its new handle (`emit_rooted_conversion`), and only the temp's declaration goes ahead of the statement:

```c
sp_String * _t11 = NULL; SP_GC_ROOT(_t11);
```

But a parenthesized sequence `(a; b)` moves its leading statements ahead of the statement as soon as its tail writes any prelude line, so that code the tail hoists does not run before them. With the line above, `s = "bb"` moved ahead of the read of `s`.

The declaration runs no code of the tail: the handle is made and assigned where the argument stands. A prelude of nothing but such lines is now passed on as it is, and the sequence stays in place. `prelude_is_held_decls` reads the lines to know; each is `T _tN = NULL; SP_GC_ROOT(_tN);`. Counting them where they are written was tried and rejected: an operator with two call operands buffers each operand's prelude apart, and the count missed them.

An Array converted where it is handed over writes the same line, and a sequence beside one moved ahead before that change too. Under the seeded signature of `test/rbs-seed/seeded_param_converted_arg_rooted.rb`, `"#{s}-#{(s = "b"; ConvArgHolder.new(acc, oth).col.length)}"` prints `b-40` on master and on 9c7ea3ce0, and `a-40` with this change, as Ruby does.

No program under `test/`, `benchmark/` or `packages/*/test/` has such a sequence: the generated C of all 6,530 is equal to master's, optcarrot's among them. There is no cost to measure.

`test/paren_sequence_stays_in_place.rb` reads `s` first and assigns it in a sequence further on, three ways, and has three lines where the assignment is written first. On master (9922a2c74, gcc and clang) three of its seven lines are wrong in a plain run with exit 0, and it aborts at `SPINEL_GC_STRESS=2`. On 9c7ea3ce0 it was right in a plain run. With this change it prints its `.expected` in the seven lanes run here (plain, level 1, level 1 with the verifier, level 2, `SPINEL_GC_MINOR=0`, `=1`, and `=1` with `SPINEL_GC_VERIFY_GEN=1` at level 1), gcc and clang, and the same with `--share-strings`.

**Not in this change:** a sequence whose tail hoists code of its own still moves ahead, as it did before: `return s, (s = "bb"; new(make(1), "t").x)` answers `["bb", "m1"]` on 9c7ea3ce0, on master and here.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run here on this commit on master 9922a2c74, built from nothing: the test in the seven collector lanes with gcc and clang, with and without `--share-strings`, on master and on this change; `ruby tools/gate.rb check`; the generated C of the 6,530 programs, equal to master's for every one; optcarrot, checksum 59662; `make share-strings-test` and `make int-min-test`, both pass.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

The `.expected` file was written from ruby 3.3.6 with `--enable-frozen-string-literal` (seven lines); CRuby 4.0 is not on the machine that ran the checks above, so the first box is left for the gate's run. No value passes 2^31. optcarrot's generated C did not change. It depends on no other pull request.
