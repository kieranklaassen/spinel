<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A method called on a small object made in place could read a freed String:

```ruby
class Name
  def initialize(r) = @s = "hello world " * r
  def has(k) = @s[k] ? 1 : 0
end
bad = 0
100_000.times { bad += 1 unless Name.new(240).has("wor" + "ld") == 1 }
p bad        # 0 in Ruby; 1111 on master, with gcc and with clang
```

A class with a few fields that is never written is kept by value: the struct lives in the C temp its call reads it from.

```c
sp_Name  _t3 = sp_Name_new(240LL);
const char * _t5 = sp_str_plus_lit(...);
SP_GC_ROOT(_t5);
... sp_Name_has(_t3, _t5)
```

Nothing holds `_t3.iv_s` while the argument allocates, or while the method itself does. A receiver held in a local is right (`n = Name.new(240); n.has(...)`), and so is a class kept behind a pointer, whose temp is rooted at these places already.

The temp's String fields are now rooted one by one (`emit_gc_root_tmp_refs`, which a by-value argument already goes through), at the four places that take such a receiver into a temp: the plain call (`emit_object_call`), a method with a block expanded at its call (`emit_inline_call_x`), a comparison the class defines (`emit_pre_root`), and an interpolated part with its own `to_s` (`interp_plan`).

The comment in `emit_inline_call_x` said a by-value receiver "must not be rooted". That holds for the temp as a whole: rooting the struct hands the collector its first field as if it were an object. It does not hold for a String field inside it, which is a pointer like any other and is rooted here the way a local of that class is. The comment is corrected.

A receiver read from a local, an instance variable or `self` compiles to master's C, and so does a by-value class with no String field. The root costs 16 instructions a call (callgrind, 200,000 calls of `C.new(3).len("ab")`: 104,918,836 to 108,118,839).

`test/value_object_receiver_string_root.rb` counts the wrong answers of 2,000 calls through eight forms. On master (dafa0d047, gcc and clang) every form is wrong in a plain run, so it is an ordinary test and not in `GC_STRESS_TESTS`.

Not in this change: `!Name.new(240)` where the class defines `!`. That arm passes its receiver inline, for a class behind a pointer as well, and still reads a freed String, as on master.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag; it is nine lines, each `0`)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on dafa0d047)
- [ ] Depends on: # (nothing)
