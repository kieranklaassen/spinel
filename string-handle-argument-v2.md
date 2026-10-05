<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An object built by `new` could come back holding another object's String, or none:

```ruby
class Pair
  attr_reader :x, :y
  def initialize(x, y)
    @x = x
    @y = y
  end
end
d = Pair.new(+"w", +"v")
d.x << "z"
d.y << "z"
all = []
20_000.times { all << Pair.new("q", "r") }
p all.count { |k| k.x != "q" || k.y != "r" }   # 5 on master, 0 in Ruby
```

With 24 objects in place of 20,000, `SPINEL_GC_STRESS=1` prints 20, and `SPINEL_GC_STRESS=2` stops with "the mark reached a freed slot".

`d.x << "z"` makes `@x` a String changed in place, so the member holds its String through a handle. A String that is not a handle already gets one where it is bound to the parameter (`emit_arg_or_default_fill` writes `sp_String_new_shared(...)` around it). A fresh argument is hoisted into a rooted temp before the call (`emit_arg_rooted`), but `arg_wants_root` answers no for a bare read (a literal, a constant, a local, an instance variable, `self`), since the value it reads is held where it is read. The handle wrapped around it is not: the call was emitted as

```c
sp_Pair_new(sp_String_new_shared("q"), sp_String_new_shared("r"))
```

and the first handle allocated is held by nothing while the second is allocated, and neither while `sp_Pair_new` allocates the object.

`arg_wants_root` now asks for a root for a bare read bound to such a parameter, unless it reads a handle already (`strbuf_slot_ref`, the case the binder passes through unwrapped) or is nil (the NULL handle). A bare read must not be hoisted, as the comment above that function says: a variable the statement writes before the argument would be read too early. `emit_rooted_conversion` (#7475) is the form for that and is used as it is: only the temp's declaration and its root go ahead of the statement, and the handle is made and assigned where the argument stands:

```c
sp_String * _t11 = NULL; SP_GC_ROOT(_t11);
sp_String * _t12 = NULL; SP_GC_ROOT(_t12);
... sp_Pair_new((_t11 = sp_String_new_shared("q")), (_t12 = sp_String_new_shared("r")))
```

A parenthesized sequence `(a; b)` moves its leading statements ahead of the statement as soon as its tail writes a prelude line. A literal argument in the tail used to write none, so with the two lines above `return s, (s = "bb"; new("x", "t").x)` would have run the assignment before `s` was read. A prelude of nothing but those declarations runs no code of the tail, so the sequence now passes it on and stays in place. It knows by reading the prelude (`prelude_is_held_decls`): every line is `T _tN = NULL; SP_GC_ROOT(_tN);`, the line `emit_rooted_conversion` writes, which assigns no variable and calls nothing. The lines are read and not counted where they are written, because an operator with two call operands catches each operand's prelude in a buffer of its own and passes it on as bytes (`emit_operands_in_order`); counted, `return s, (s = "bb"; new("x", "2").x + new("y", "3").y)` ran the assignment early again. A prelude that holds anything else goes the way it does on master. An argument #7475 converts writes the same line, so a sequence around one stays in place as well: `x = s + (s = 50; ConvArgHolder.new(acc, oth).col.length)` with that change's seeded signature answers `[4, 50]` before and after, at plain and at level 2, and `make rbs-seed-test` passes.

The Struct constructor's member values (`emit_struct_new_call`) take the same in-place form, and so does a String element of a splat bound to such a parameter (`Pair.new("q", *a)`, `emit_elem_param`), which got its handle inline with nothing holding it; the default a short splat leaves to fill (`def initialize(x, y = "r")` called `new(*a)`) is held with it. `emit_expr_node` grows by 5 lines, to 846.

Measured with both compilers built on 5c2dea515, which this branch is one commit on: optcarrot's generated C is byte-identical, so is that of the 64 programs in `benchmark/` and the 156 package tests, and 3 of the 5,858 in `test/*.rb` change (`frozen_chilled_builtin_strings`, `issue_3307_container_reader_mutation`, `string_handle_yield_boxed_nil`), each by such a temp; the three print the same bytes before and after in a plain run and at levels 1 and 2, with gcc and clang. A temp exists only where the binder allocates a handle, so a call that allocates nothing gains nothing: `Pair.new("q", "r")` on a class whose Strings are not changed in place compiles to the C it did (callgrind, 200,000 calls: 13,945,525 before and after). Where both members are changed in place the two temps cost 36 instructions a call (242,763,456 to 249,919,368, a call being about 1,210), and `Pair.new("q", *a)` 41 (248,413,531 to 256,620,363).

Evaluation order was checked with 74 programs that write the variable ahead of the argument inside a class method, `(s = "bb")` then `new(s, "t")`, one for each place the two can stand (operators, interpolation, `return a, b`, multiple assignment, `||=`, call and yield arguments, `case`, conditions, loops, `rescue`, blocks), each built with gcc and with clang and compared with CRuby. Built with clang, all 74 answer as CRuby does in a plain run on master and with this change. Built with gcc, 64 do on master and the same 64 with this change; the other ten (`==`, `<=>`, `*`, `[]`, `[]=`, a Range, a receiver's argument and three more) are master's own, where C leaves the order of two operands open. Master ends every one of the 74 in SIGSEGV or an abort at `SPINEL_GC_STRESS=2`, with both compilers; with this change each gives there the answer of its plain run, at level 1, level 1 with `SPINEL_GC_VERIFY=1` and level 2.

A further 388 programs (two objects made in a sequence's tail, the sequence under nested operators, in `return a, b`, in an interpolation and in a multiple assignment, and splats with and without a default) were built with gcc and with clang on 5c2dea515 and with this change and run plain, at level 1, at level 1 with `SPINEL_GC_VERIFY=1` and at level 2. 59 compile to master's C. Of the other 329, none that is right on master under a setting is wrong there with this change: 277 that fail on master are right under all eight, and 8 are right before and after. In the other 44 the plain run prints the same bytes before and after: ten are not Ruby's answer only when built with gcc (the order of two operands again), 33 are not with either compiler (`return s, (s = "bb"; ...)` beside an Array or a nested call, a keyword splat), and one raises. In 30 of the 44 master ended a stress level in SIGSEGV or an abort, and that level now prints what master's plain run prints, byte for byte (54 runs); in 11 more, level 2 still stops on the collector's report, as it does on master or where master ended in SIGSEGV, which is another cause.

`test/new_string_arg_handle_root.rb` builds 20,000 objects through each of nine shapes and counts the ones holding another String: two literals, a literal by keyword, constants, the parameters of a class method, the parameters of a method, instance variables, `self`, an Array's element splatted beside a literal, and a splat that leaves a default to fill. Each object is looked at one construction later, when a String it lost has been handed out again. On master (5c2dea515, Linux x86-64, gcc and clang) the plain run and `SPINEL_GC_STRESS=1` end in SIGSEGV; `SPINEL_GC_STRESS=1 SPINEL_GC_VERIFY=1` and level 2 report it. With this change it prints nine zeros under each of those and under `SPINEL_GC_MINOR=1 SPINEL_GC_VERIFY_GEN=1 SPINEL_GC_STRESS=1`, built with gcc and with clang. Its last six lines are order: `(s = "bb") + new(s, "t").x`, the same in an interpolation and in `return a, b`, `return s, (s = "bb"; new("x", "t").x)`, and that sequence with two objects made in its tail, in `return a, b` and in an interpolation. Master answers those as CRuby does; they are there so the root cannot move the read. The test is added to `GC_STRESS_TESTS`.

Found by sorting what the collector stress lane fails on by the allocation that frees the lost object. Of 1,820 generated programs that ask `frozen?` of a String through a reader (7 values x 11 holders x where the read stands), 84 fail at level 2 on master, every one a literal handed to a class's `new` for a String changed in place; none did with this change as it was first written, and no other program's output moved (measured then, on a7dfefc1a). On 5c2dea515, of 252 programs that hand 28 kinds of value to `new` in nine places, 27 fail at level 1 or 2 on master and are right under every setting with this change, with gcc and clang; the other 225 compile to master's C.

Not in this change, each another cause and each the same before and after:

- `"a#{i}".to_sym` as the argument: the String is freed inside `sp_sym_intern`, and the nine programs that hand one to `new` print a wrong Symbol at level 2;
- a block given to `new` (`K.new { i * 3 }`), which `sp_X_new` does not root: the nine programs that do stop at level 2 and at level 1 with `SPINEL_GC_VERIFY=1`;
- a literal after a splat in the middle of the arguments, `K.new(0, *qa, "r")` for `def initialize(n, x, y)`: its handle is still held by nothing. 24 of them leave 21 wrong objects at level 1, and level 2 stops.

A rest or a post parameter fed from a splat (`K.new("q", *a)`, `K.new(*qr)` for `def initialize(x, *rest)`, `K.new(*qa, "r")` for `def initialize(*a, y)`) is right now in a plain run and at level 1, where master leaves wrong objects (one to three of 20,000 in a plain run, 21 of 24 at level 1); level 2 still stops on the mark path, as it does on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 5c2dea515)
- [ ] Depends on: # (nothing)
