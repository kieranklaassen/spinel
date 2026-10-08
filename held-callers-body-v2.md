<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: 8 instructions a call into a Struct's `new` for two such members (9 into a Data's by keyword), 6 for one beside a call of the program's own. As in the change this stands on, a builtin call that no list names counts as building: `P.new(r, n.abs)` pays 4 though master ran it right. On a receiver of several classes the bound boxes are roots pushed and popped where the switch sits in its helper, which has no frame: 30 to 33 for two arguments, 39 for one beside a rest, 15 for one beside a default that allocates, 53 for one into a method that captures it (the longer arm moves its switch into the helper). One such member alone, one such argument to a method that captures none, and either beside an Integer, scalar arithmetic, a typed index read or a literal default compile to the C they did.

```ruby
P = Struct.new(:a, :b)
P.new(7, 7)
keep = []
n = 0
while n < 2000
  r = Rational(n + 1, 3)
  q = Rational(n + 2, 5)
  keep << P.new(r, q)
  n += 1
end
bad = 0
keep.each_with_index do |s, i|
  ok = s.a == Rational(i + 1, 3) && s.b == Rational(i + 2, 5)
  (bad += 1; p [i, s.a, s.b]) unless ok
end
p bad    # CRuby: 0; master: [1127, (376/1), (376/1)] then 1
```

`spinel diff` on master: output-diff; on this branch: same. That is a plain run, exit 0, with gcc; clang prints `(1129/5)` twice for the same turn. A call on a receiver of two classes, a plain run too:

```ruby
class K; def m(a, v); @a = a; @v = v; v; end; end
class L; def m(a, v); @v = a; @a = v; a; end; end
O = [K.new, L.new]
O[0].m(7, 7)
r = (1..4)
q = (2..5)
bad = 0
i = 0
while i < 8000
  f = O[i % 2].m(r, q).first
  (bad += 1; p [i, f]) unless f == 2 - i % 2
  i += 1
end
p bad    # CRuby: 0; master, gcc: [4084, 1] [5440, 1] 2; clang: [6797, 2] 1
```

Under `SPINEL_GC_STRESS=2` one such call aborts ("the mark reached a freed slot").

A Range, a Rational, a Complex and a Time are kept by value, and a boxed slot takes one copied into a new cell (`sp_box_rational`, ...). "A Range or Rational read into a boxed parameter is held for the call" holds that cell where a method or a constructor is called by name. Two callers write their own argument lists and still handed the cell on with nothing holding it:

- a Struct's or a Data's `new`. `sp_<S>_new` roots what it is given before it allocates, so one such member is safe as it is. Beside a second member built in the list, either allocation collects the other: `struct_members_built` counts the members built where they stand, and where there are two the box is assigned to a rooted temp where it stands, `(_tN = sp_box_rational(...))`, as that change does.
- a call on a receiver of several classes. Each arm boxes the argument's temp for its own method, a positional or a keyword. Two arguments an arm makes new (a rest's slice, a `**` rest's hash) already bind to rooted locals ahead of its call (`emit_poly_arm_args`); such a box now counts among them. One alone binds where something else allocates before the callee roots it: a default the arm builds beside it (`default_built_in_place` asks the written text, as that change does for a spread slot, so a literal the prelude already holds does not count), or the cell a method keeps a captured parameter in.

Nothing runs earlier than it did.

Measured against CRuby on 445 programs, each run plain and under `SPINEL_GC_STRESS=2` with gcc and with clang (82 forms by five kinds, a Range, a Float Range, a Rational, a Complex and a Time, and 35 single programs: a Struct and a Data with one member, two and three, by keyword, with `keyword_init`, in a method, in a block, an argument that ran first, a typed member, an Integer or a call beside the read; a receiver of two and three classes with positionals, keywords, a rest, a default, a captured parameter, a class method, `&.`, `send`; the other callers of a boxed slot), against the branch this stands on:

- 156 abort under stress there and are right here: 137 with both compilers, 19 with one (C runs a call's arguments in no set order). None is lost.
- 159 are right on both, and all of them keep their C.
- 130 are under "Not in this change"; 121 of them keep their C.
- `make cident`: no program of the corpus changes C beside the new test. optcarrot's C is the same.
- callgrind, a million calls: `P.new(r, q)` 355,516,317 to 363,550,498; `D.new(a: r, b: q)` 321,574,379 to 330,750,714; `P.new(r, cnt(i))` 571,962,005 to 578,007,831; `P.new(r, i.abs)` 258,918,439 to 262,958,928; `o.m(r, q)` 305,553,266 to 338,053,266, and 344,197,244 to 373,798,355 where the two methods store what they are given (that loop prints 1499997 for 1500000 on master); `o.rs(r, 1, 2)` 479,005,702 to 518,005,283; `o.opt(r)` with `b = "x" * 2` 565,875,927 to 580,941,309; `o.cap(r)` 694,892,213 to 748,105,763. `P1.new(r)`, `P.new(r, i + 1)`, `P.new(r, XS[i % 3])`, `o.m(r)`, `o.kw(a: r, b: i)`, `o.opt(r)` with `b = [1]`, a Struct with typed members and a several-class call given Integers: the same C.

Not in this change, each the same on master (the 130):

- a proc's `call` given such a value aborts under stress (75: a lambda, a proc, `Proc.new`, `.()`, `[]`, `yield`, a callable in a boxed slot): the body takes the box out of the call's slot and roots no parameter.
- `new` on a Class value kept in a boxed slot, `[K, L][i].new(r, q)`, aborts under stress (10); a curried lambda, `F.curry[r][q]`, and a composed one, `(F >> G).call(r)`, too (10).
- `o.v = r` where `o` is of several classes aborts under stress (5): the arm takes the write barrier before the box is allocated.
- `Data#with` given such a value does not build, nor do a bound Method (`M = method(:pair); M.call(r, q)`) and `case r when f` (15); `:w.to_proc` called with such a value raises NoMethodError (5).
- `[P, Q][i].new(r, q).to_a` on two Structs prints addresses for the members in a plain run (5).
- `[v.first, v.last]` on a boxed value holding a Float Range prints `[nil, nil]` in a plain run (4). Three of those aborted under stress before they reached that line, and under stress print the plain run's line now.
- a rest handed to a method that captures it, on such a receiver, aborts under stress with Integers alone, `o.m(7, 7)` for `def m(v, *r) = -> { [v, r] }` (1).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: "A Range or Rational read into a boxed parameter is held for the call" (this branch stands on it: `arg_read_converts` for a boxed parameter, `emit_rooted_conversion`, and the text test of a default it splits in two)
