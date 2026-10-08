<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

**A fix with a cost.** An object built by `new` could come back holding another object's String, or crash:

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
p all.count { |k| k.x != "q" || k.y != "r" }   # 0 in Ruby; 5 on master
```

`d.x << "z"` makes `@x` a String changed in place, so the member holds its String through a handle, and the call wraps each argument in one: `sp_Pair_new(sp_String_new_shared("q"), sp_String_new_shared("r"))`. Nothing holds the first handle while the second is allocated, nor either while `sp_Pair_new` allocates the object.

`arg_wants_root` now asks for a root for a bare read (a literal, a constant, a local, an instance variable, `self`) bound to such a parameter. The read must stay where it stands, or a variable the statement writes before the argument would be read too early. So only the temp's declaration and its root go ahead of the statement (`emit_rooted_conversion`, which upstream pull request 7475 added), and the handle is assigned in place:

```c
sp_String * _t11 = NULL; SP_GC_ROOT(_t11);
sp_String * _t12 = NULL; SP_GC_ROOT(_t12);
... sp_Pair_new((_t11 = sp_String_new_shared("q")), (_t12 = sp_String_new_shared("r")))
```

One decision goes with that. A parenthesized sequence `(a; b)` moves its leading statements ahead of the statement as soon as its tail writes a prelude line, so with the two lines above `return s, (s = "bb"; new("x", "t").x)` would have run the assignment before `s` was read. A prelude of nothing but such declarations runs no code, and the sequence now stays in place for it. `prelude_is_held_decls` reads the lines to know. Counting them where they are written was tried and rejected: an operator with two call operands buffers each operand's prelude apart, and the count missed them.

`test/new_string_arg_handle_root.rb` counts the wrong objects through nine shapes of argument and has six lines on evaluation order. On master (9c7ea3ce0, gcc and clang) it ends in SIGSEGV in a plain run and in four more of the seven lanes, and aborts in the other two (the verifier, and level 2); with this change it is right in all seven. It is added to `GC_STRESS_TESTS`.

The cost, callgrind on 9c7ea3ce0, 200,000 calls each, in instructions a call:

| call | gcc | clang | master's answer |
|---|---|---|---|
| `Doc.new("q")`, one handle | 17 | 18 | wrong in a plain run: the lengths sum to 232525, not 200000 |
| `Pair.new("q", "r")`, two handles | 36 | 38 | wrong in a plain run: 96648725270, not 200000 |
| `put(d, "q")`, a literal handed to a method with no receiver, which stores it | 18 | 16 | right |
| `d.set("q")`, `d.set(s)`, `Cell.new(i)` | 0 | 0 | right (the C is equal) |

The third row is a cost on a program master runs right: the callee roots its parameter before anything allocates, so the handle was safe there. It is not cut here. The temp is asked for where the argument is bound (`emit_arg_rooted`, reached from about forty call sites), and leaving it out needs to know that nothing allocates between the wrap and the callee's root: the receiver, the block, the arguments beside it and the expression around the call, none of which that place sees.

The generated C of four of the 6,265 other tests gains the temps (`frozen_chilled_builtin_strings`, `issue_3307_container_reader_mutation`, `string_handle_yield_boxed_nil`, `string_hash_read_or_bang_self`); each answers in every lane as it does on master. All 67 benchmarks and optcarrot compile to the same C.

Not in this change: a literal after a splat in the middle of the arguments, `K.new(0, *qa, "r")` for `def initialize(n, x, y)`. Its handle is still held by nothing: wrong at `SPINEL_GC_STRESS=1`, as on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #

Notes: the test and its `.expected` file are those of the earlier cut, byte for byte; no value passes 2^31; optcarrot's C did not change (byte-identical before and after on 9c7ea3ce0, checksum 59662); it depends on nothing.
