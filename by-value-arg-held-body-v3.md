<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost, where the box is held: 7 instructions a `new`, 8 for two such arguments side by side, 5 into a method with a captured parameter, and 18 where the calling method had no GC frame, beside the allocation the box already makes. One group that master ran right pays 5: such a read beside a builtin call no list of the compiler names as allocating nothing (`two(r, n.abs)`, `two(r, XS.size)`, `two(r, -n)`). One such read into a method that roots its parameter first (`one(r)`, `send(:one, r)`) compiles to the C it did; so does one beside scalar arithmetic or a typed index read (`two(r, n + 1)`, `two(r, XS[n % 3])`), and every call that hands no Range, Rational, Complex or Time read to a boxed parameter.

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

A Range, a Rational, a Complex and a Time are kept by value. Where the parameter is boxed (`Slot.new(7)` makes it so), a read of one is boxed where the argument stands, `sp_Slot_new(sp_box_rational(lv_r))`, and the box copies it into a new cell. Nothing holds that cell, and three things can allocate before the callee roots its parameter:

- the constructor: `sp_Slot_new` allocates the object before `initialize` stores the argument;
- the cell of a captured parameter, which the callee allocates on entry: `def later(v) = -> { v }`;
- a second slot of the list that allocates where it stands: the other box in `pair(r, q)`, a default or an argument that calls, a rest packed in place. C leaves the order between two arguments open. Scalar arithmetic and a typed index read build nothing (`subtree_is_pure_read`) and are no such slot.

"A converted bare-read argument is rooted across the constructor" roots a bare read that reaches a container parameter through a converter, and answers no for a boxed parameter. `arg_read_converts` now answers yes there for a read kept by value (a Class aside: its box is its tag, with no cell). The box is written as it was, and once the list stands `arg_built_exposed` asks those three questions of it; where one holds, the slot's text becomes `(_tN = sp_box_rational(lv_r))`, an assignment to a rooted temp where it stood, so nothing runs earlier than it did. The list is asked as written because a spread slot can only be judged by its text: an unreached default that is a Hash or an Array literal stands there as a temp the prelude built and rooted, and allocates nothing in the call. A `super` into an `initialize` is no constructor's list: the object exists.

Measured against CRuby, each program run plain and under `SPINEL_GC_STRESS=2` with gcc and with clang:

- 240 programs (a constructor with one parameter, with a keyword, with two, under a bare `super`; a method with one and with two parameters; a default or a keyword beside the read, `send`, a captured parameter, a block, a setter, `yield`; seven kinds; read from a local, an instance variable, a constant; at top level, in a method, in a block): 144 abort under stress on master and are right here; 75 are right on both and keep master's C byte for byte; none is lost. The other 21 are under "Not in this change".
- 528 more around the three questions (a `new` with a keyword, an Integer or a default beside the read; a method called on an object, by `send`, with a block; two such reads by position and by keyword; a String or a call beside the read; a rest; a captured parameter; class methods; `super`; a splat and a `**` beside the read; a constructor whose default calls on self): 168 made right, 312 keep master's C, none lost. 12 are held though master ran them right: a default that calls a method which allocates nothing (`def initialize(v, k = base)`), which the call site cannot tell from one that does. 36 are under "Not in this change".
- 1,944 from a second generator (six kinds; a local, an instance variable, a constant; 18 callees; in a statement, under `&&`, in a ternary, as an argument, in an interpolation, under `rescue`): 1,296 keep master's C byte for byte, among them the 216 that hand one read to a method that roots its parameter first; 648 change, of which 576 abort under stress on master and are right here and 72 are the empty rest below. A Float or a String Range is read back with `==` there: `p` of one prints a freed first end under stress on master with no call at all.
- `make cident`: no program of the corpus changes C; the new test alone differs. optcarrot's C is the same.
- callgrind, a million calls: `Slot.new(r)` 197,310,354 to 204,224,338 and with a keyword 197,310,359 to 204,224,352; `pair(r, q)` 168,143,312 to 176,422,596; `later(r)`, a captured parameter, 335,276,798 to 340,350,561; `Slot.new(r)` inside `def go(k)`, a method with no GC frame on master, 245,311,456 to 263,240,513. `two(r, n.abs)` 304,025,261 to 309,029,172, and the same five for `XS.size`, `-n` and `n.succ`. `one(r)` at top level and in a method, `two(r, n + 1)`, `two(r, XS[n % 3])` and a constructor whose parameter is typed: the same C.

Not in this change, each the same on master:

- Two such values handed to a Struct's or a Data's `new`, to a proc's `call`, to a method on a receiver of several classes, or to `new` on a Class value abort under stress (15): four other writers of the same box, which keep master's C.
- An empty rest beside the read, `rs(r)` into `def rs(v, *xs)`, aborts under stress with gcc (15, and the 72): the rest's empty Array is written in place with nothing holding it and the box's allocation frees it, as any argument that calls does on master (`rs(f(n))` with `def f(n) = [n, n + 1].sum`). With clang, which builds the box first, it is right here.
- A default built in a spread slot beside the read, `m(r, *e)` into `def m(v, x = "a" * 2)` or `m(r, **h)`, aborts under stress with gcc (24): the default is the value freed. With clang it is right here.
- `Slot.new(r) { n }` into `def initialize(v, &b)` aborts under stress through the block, not the box: the same call with an Integer aborts the same on master.
- `K.new((r = q; 1), r)` prints gcc's argument order in a plain run on both trees (3); master aborts under stress and this branch prints that same line.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: # (nothing)
