<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

An object built by `new` could come back holding another object's String, or crash:

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

`arg_wants_root` now asks for a root for a bare read (a literal, a constant, a local, an instance variable, `self`) bound to such a parameter. The read must stay where it stands, or a variable the statement writes before the argument would be read too early. So only the temp's declaration and its root go ahead of the statement (`emit_rooted_conversion`, #7475), and the handle is assigned in place:

```c
sp_String * _t11 = NULL; SP_GC_ROOT(_t11);
sp_String * _t12 = NULL; SP_GC_ROOT(_t12);
... sp_Pair_new((_t11 = sp_String_new_shared("q")), (_t12 = sp_String_new_shared("r")))
```

One decision goes with that. A parenthesized sequence `(a; b)` moves its leading statements ahead of the statement as soon as its tail writes a prelude line, so with the two lines above `return s, (s = "bb"; new("x", "t").x)` would have run the assignment before `s` was read. A prelude of nothing but such declarations runs no code, and the sequence now stays in place for it. `prelude_is_held_decls` reads the lines to know. Counting them where they are written was tried and rejected: an operator with two call operands buffers each operand's prelude apart, and the count missed them.

`test/new_string_arg_handle_root.rb` counts the wrong objects through nine shapes of argument and has six lines on evaluation order. On master (dafa0d047, gcc and clang) it ends in SIGSEGV in a plain run. It is added to `GC_STRESS_TESTS`.

Not in this change: a literal after a splat in the middle of the arguments, `K.new(0, *qa, "r")` for `def initialize(n, x, y)`. Its handle is still held by nothing: wrong at `SPINEL_GC_STRESS=1`, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
