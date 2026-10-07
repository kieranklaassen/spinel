<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: 4 instructions a call for each such argument, 6 into a constructor, beside the allocation its box already makes. A call that hands no Range, Rational, Complex or Time read to a boxed parameter compiles to the C it did.

```ruby
class Slot; def initialize(v) = @v = v; def v = @v; end
Slot.new(7)
keep = []
n = 0
while n < 2000
  r = Rational(n, 7)
  keep << Slot.new(r)
  n += 1
end
bad = 0
keep.each_with_index { |o, i| (bad += 1; p [i, o.v]) unless o.v == Rational(i, 7) }
p bad    # CRuby: 0; master: [1798, (257/1)] then 1
```

`spinel diff` on master: output-diff, `[1798, (257/1)]` and `1` for `0`; on this branch: same.

That is a plain run, with gcc and with clang. Under `SPINEL_GC_STRESS=2` a single `Slot.new(r)` aborts ("the mark reached a freed slot").

A Range, a Rational, a Complex and a Time are kept by value. Where the parameter is boxed (`Slot.new(7)` makes it so), a read of one is boxed where the argument stands, `sp_Slot_new(sp_box_rational(lv_r))`, and the box copies it into a new cell. Nothing holds that cell: `sp_Slot_new` allocates the object before `initialize` stores the argument; in `pair(r, q)` the second box's allocation collects the first; and a parameter a lambda captures lives in a cell the method allocates before it stores the argument (`def later(v) = -> { v }`).

"A converted bare-read argument is rooted across the constructor" roots a bare read that reaches a container parameter through a converter, and answers no for a boxed parameter. `arg_read_converts` now answers yes there for a read kept by value (a Class aside: its box is its tag, with no cell), so `emit_arg_rooted` assigns the box to a rooted temp where the argument stands, `(_tN = sp_box_rational(lv_r))`, and nothing runs earlier than it did. `emit_rooted_conversion` learns the boxed parameter's declaration. One file, `src/codegen_fold.c` +15 -4.

The root does not wait on what the callee does. A method with one parameter usually roots the box before it allocates, and such a call pays the 4 instructions for nothing; the captured parameter above is the one that does not, and a call site cannot see which it has.

Measured against CRuby, each program run plain and under `SPINEL_GC_STRESS=2` with gcc and with clang:

- 144 forms (a constructor with one parameter, with a keyword, with two parameters, under a bare `super`; a method with one and with two parameters; a Range, an exclusive Range, a String Range, a Float Range, a Rational, a Complex, a Time; read from a local, an instance variable, a constant; at top level, in a method, in a block): 126 abort under stress on master and 18 are right; all 144 are right here.
- 96 more around the call (a default or a keyword beside the read, `send`, a captured parameter, a receiver built in the call, a block, a setter, `yield`, literals): 18 made right, 57 right on both, none lost. The other 21 are under "Not here".
- `make cident`: 5 programs of the corpus change C besides the new test (`builtins_min_max_by`, `enum_optional_arg_false`, `issue_3232`, `range_min_by_count`, `set_range_operand`); each prints the same, plain and under stress, on both trees.
- callgrind, a million calls: `Slot.new(r)` 268,705,377 to 274,715,646; `one(q)` 99,364,538 to 103,370,403; `pair(q, r)`, two such arguments, 174,699,828 to 182,719,358; `pair(q, 1)` 99,364,538 to 103,370,403; a constructor whose parameter is typed 80,319,694 to 80,319,700.

Not here, the same on master: two such values handed to a Struct's or a Data's `new`, to a proc's `call`, to a method on a receiver of several classes, or to `new` on a Class value abort under stress (15 of the 96: four other writers of the same box). A rest packed beside the read (`def rs(a, *b)`, `rs(r)`) is right with clang now and aborts with gcc as before: there the box's allocation frees the rest's Array (3). `K.new((r = q; 1), r)` prints gcc's argument order in a plain run on both trees; master aborts under stress and this branch prints that same line (3).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
