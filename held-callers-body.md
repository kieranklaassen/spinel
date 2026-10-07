<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: 5 instructions a call for one such argument, 8 into a Struct's `new` for two, 9 into a proc's `call` for two; 6 for one into a method on a receiver of several classes, whose switch now stays at its call site where an arm holds a box (for two that costs less than the helper did; the numbers are below). A typed member and an Integer argument compile to the C they did.

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

`spinel diff` on master: output-diff; on this branch: same. That is a plain run, exit 0, with gcc; clang prints `(1129/5)` twice for the same turn. The same loop over `keep << F.call(r, q)` with `F = ->(a, b) { [a, b] }` answers turn 1450 with `[(484/1), (1453/5)]`. And a call on a receiver of two classes, a plain run too:

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

A Range, a Rational, a Complex and a Time are kept by value, and a boxed slot takes one copied into a new cell (`sp_box_rational`, ...). "A Range or Rational read into a boxed parameter is held for the call" holds that cell where a method or a constructor is called by name. Three callers write their own argument lists and still handed the cell on with nothing holding it:

- a Struct's or a Data's `new`: `sp_<S>_new` allocates the object before it stores a member, and a second member's box collects the first;
- a proc's `call`: the call's slots keep the box only until the body takes it for its parameter and clears the slot; the body roots no parameter, so its first allocation collects it. That publish is written three times: for a Proc, for a callable in a boxed slot, and for one that shares the slot with a class that has its own `call`;
- a call on a receiver of several classes: each arm boxes the argument's temp for its own method, a positional or a keyword.

Each now assigns the box to a rooted temp where it stands, `(_tN = sp_box_rational(...))`, as that change does. `emit_struct_new_call` asks `arg_read_converts` and calls `emit_rooted_conversion`; the other two go through one new helper, `emit_boxed_text_held`, at the line that boxed. Nothing runs earlier than it did, and a value of any other kind is boxed by the line that boxed it. The root does not wait on what the callee does with the value: a proc is always handed boxes, so its call pays whether or not the body's parameters are typed.

A long switch on a receiver is moved into a helper without a frame (`pd_hoist`), and there the held temp would be a root pushed and popped on every call, 40 instructions. So a switch whose arm holds a box stays at its call site, where the temp is a slot of the frame.

Measured against CRuby, each program run plain and under `SPINEL_GC_STRESS=2` with gcc and with clang:

- 325 programs, 65 forms of the three callers (one argument and two, by keyword, `.()`, `[]`, `yield`, `&.`, in a method, in a block, an argument that ran first, a typed member, an Integer beside it) by five kinds (a Range, a Float Range, a Rational, a Complex, a Time). Against the branch this stands on: 162 abort under stress there and are right here, 109 are right on both, none is lost. The other 54 are under "Not here".
- `make cident`: 9 programs of the corpus change C besides the new test. Each hands such a box to a proc or to an arm: a Time to the logger's formatter (`logger_basic`, `logger_reopen`, `logger_reopen_rotated`), a Range in `boxed_random_methods`, `int_array_nil_cr2` and `poly_dispatch_struct_arg_arm`, a `Process::Tms` in `proc_tms_param`, several kinds in `proc_param_value_struct_types` and `poly_callable_struct_args`. Eight print the same on both trees, plain and under stress, gcc and clang. `test/poly_callable_struct_args.rb` prints a freed Complex under `SPINEL_GC_STRESS=2` on master, exit 0 (its eleventh line ends `-3.1638862116397002e+134-3.1638862116397002e+134i` for `0+1i`), and is right here. optcarrot's C is the same.
- callgrind, a million calls: `P.new(r, q)` 355,514,078 to 363,549,383 and `P1.new(r)` 250,705,548 to 255,715,805; `F.call(r, q)` 256,148,923 to 265,218,811, `G.call(r)` 178,795,095 to 183,802,416, and 217,801,222 to 226,845,152 where the lambda's two parameters are typed; `o.m(r)` on two classes 191,084,276 to 197,089,767. `o.m(r, q)`, which master moves into a helper: 344,195,061 to 287,298,896 where the two methods store what they are given, 303,552,190 to 239,574,916 where they are one-liners. Against the same switch kept inline on master (`SPINEL_NO_PD_HOIST`) the hold is 9 for the first (278,691,389 to 287,798,153) and 48 for the one-liners (191,547,257 to 239,574,906: gcc no longer folds the two arms into one). A Struct with typed members (107,145,028), a lambda (70,666,385) and a several-class call (73,672,309) given Integers: the same.

Not here, the same on master (the 54):

- `new` on a Class value kept in a boxed slot, `[K, L][i].new(r, q)`, aborts under stress (10): a fourth writer of the same box, whose argument temps "A class-value new holds the values it builds" roots; one condition there, in a change that stands on both.
- a curried lambda, `F.curry[r][q]`, and a composed one, `(F >> G).call(r)`, abort under stress (10): the same class in two other emitters. The composed one aborts with a String argument too.
- `o.v = r` where `o` is of several classes aborts under stress (5). Another cause: the arm takes the write barrier before the box is allocated, `SP_WBO(o)->iv_v = sp_box_rational(...)`; a setter on one class takes it after.
- `Data#with` given such a value does not build, nor do two more writers of the proc's publish, a bound Method (`M = method(:pair); M.call(r, q)`) and `case r when f` (15); `:w.to_proc` called with such a value raises NoMethodError (5).
- `[P, Q][i].new(r, q).to_a` on two Structs prints addresses for the members in a plain run (5).
- `[v.first, v.last]` on a boxed value holding a Float Range prints `[nil, nil]` in a plain run (4). Three of those four aborted under stress before they reached that line, and under stress print the plain run's line now.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: "A Range or Rational read into a boxed parameter is held for the call" (this branch stands on it: `arg_read_converts` for a boxed parameter, `emit_rooted_conversion`'s declaration)
