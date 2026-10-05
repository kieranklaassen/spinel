<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Page
  def text
    return @text if @text
    b = +""
    b << "x" << "y"
    @text = b
  end
end
c = Page.new
p c.text, c.text        # CRuby: "xy", "xy". Master: nil, "xy"
```

A tail instance variable write hands back the slot when the slot's type is the return's (`emit_stmt_tail_inner`, test/ivar_tail_write_return.rb). A String that is appended to in place under a second name lives in a shared-handle slot, and a String return cannot take the handle as it stands, so the write went out as a statement and the method fell to `return NULL`. The memo above, and any builder that ends by storing what it built with `<<`, `concat` or a bang method, answered nil with nothing said.

Such a write now goes out in its value form: the write, then the slot's ordinary read. That is the C `(@text = b)` and `return @text = b` already produce on master:

```c
return ({ { __typeof__(self) _wb7 = self; _wb7->iv_v = lv_x; sp_gc_wb((void *)_wb7); } (_sp_ret_strbuf = (void *)self->iv_v, self->iv_v ? sp_str_concat(sp_String_cstr(self->iv_v), (&("\xff")[1])) : NULL); });
```

It applies only where the slot is the shared String handle, the return (or the `begin` result) is a String, and the method's value can be seen to be wanted. Every other tail write is master's C byte for byte.

**Where the value is wanted.** That read is a copy of the String, and a setter called as a statement would throw it away (`def take(x); @s = x; end` beside `k.take(s)`; three tests in the suite have one). So the first such write walks the program once and lists every place a method's name is used, with what becomes of the value there. The value form is used when the list has any of these for the method's name:

| wanted | programs |
|---|---|
| a call that is not a plain statement | `p c.set("b")`, `r = c.set("b")`, `c.set("b").size`, `"#{c.set("b")}"`, `puts "none" unless c.set("b")`, `c&.set("b")`, `[1].map { c.set("b") }`, `-> { c.set("b") }` |
| a call that ends a method whose own value is wanted, three methods deep | `def outer(c) = c.set("b")` beside `p outer(c)` |
| the name as a Symbol or a String anywhere | `c.send(:set, "b")`, `c.public_send("set", "b")`, `c.method(:set)`, `alias set2 set`, `alias_method :set2, :set`, `[c].map(&:text)` |
| a name made at run time anywhere | `c.send(n, "b")`, any `to_sym` or `intern`, `:"a#{b}"` |
| `super` in a method of that name | `def set(n) = super` |
| an op-assign through the name | `c.text ||= "z"`, `c.text += "!"` |
| a name the runtime calls by itself | `"#{c}"` for `to_s` (every `to_` name), `p c` for `inspect`, `raise e` for `message` (`full_message`, `detailed_message`), `method_missing`, operators |
| what cannot be told | a method no call names; a write that is the last of a block inside the method |

Everything else is a call whose value nothing takes, and the method keeps master's C:

| dropped | programs |
|---|---|
| a statement that is not the last of its sequence | `c.set("b")` then `p c.v` |
| the last statement of the program, of a `while` or an `until` | `until c.v; c.set("b"); end` |
| the last statement of an `if` or `unless` that is itself such a statement | `c.set("b") if c.v.nil?` |
| the last statement of a method whose own calls are all such statements | `def outer(c); c.set("b"); end` beside `outer(c)` |
| an attribute assignment, which is worth its right side | `c.v = "b"`, `r = (c.v = "b")` |

87 programs, one per route. Of the 58 that take the value, 51 were wrong or raising on master and are right here. The other seven are master's answer on both: `[c].map(&:text)` after a first call was right; three do not come to this write (a method no call names is not compiled, and a write at the tail of a `case` arm is right on master); `c.text += "!"` is refused, `c.text ||= "z"` does not build and a call answered by `method_missing` raises, on master alike. The C of the 18 that drop the value is master's. A build without the walk (the value form for every such write) answers no program of the 87 better than this one.

Left as it is:

- Dropped, but read as wanted, so the answer is right and the copy is made: `k && c.set("b")`, `[1, 2].each { c.set("b") }`, the last statement of a `case` arm, of a `begin` with a `rescue`, of `initialize`, a chain four methods deep, an operator method (`c << "b"`), and any program that says `to_sym` or has the method's name in a String (9 programs).
- Wanted, but not seen, which keeps master's nil. I found no program of this kind that runs on master: `eval("c.set('b')")` is refused ("eval of a runtime string") and `c.instance_eval("set('b')")` raises NoMethodError, on master and here. A name the runtime calls by itself that is not in the list above would be one.
- The local twin, `y = x` as a method's last statement, does not build on master and is not touched.

**Measured, each program compared with CRuby 3.3.6.** 786 generated programs whose method ends in `@v = ...` (14 places the method lives, 12 ways the value came to be, with and without a second method appending to the variable, 10 uses of the answer), each with a twin ending in `(@v = ...)`. The C of 262 changes, in the one line of the write. Each of the ten uses takes the value, so every one of the 262 is a method whose value is used.

| of the 786 | master 9c4eec71 | this branch |
|---|---|---|
| as CRuby | 472 | 692 |
| wrong and silent | 228 | 66 |
| raises where CRuby does not | 58 | 0 |
| the C does not build | 28 | 28 |

182 wrong and 38 raising become right. None right on master changes its answer. The 28 that do not build are master's C, unchanged (26 end a block's body with the write; 2 compare the answer with the variable in a class method and at the top level).

**Limits.** 20 of the 786 raised on master and print one wrong line here:

```ruby
r = c.set("b")
r << "!"
p r, c.v                # CRuby: "ab!", "ab!". Here: "ab!", "ab". Master: FrozenError at `r << "!"`, r being nil
```

The twin of each, the same program with `(@v = x)` as the method's last statement, prints "ab!" and "ab" on master: a method's String return of a shared String is a copy, for every tail on master (`@v = x; @v`, `return @v = x`, `@v = x; x`, and 27 programs of this matrix whose C does not change print the same two lines). The right answer needs the method to hand back the handle itself, which is sharing and not in this piece. For each of the 260 changed programs that build, the output here is byte for byte the output of its `(@v = ...)` twin on master, and the C differs from master's in the write's own line only.

The other 46 left wrong are that same use where the C does not change (27), `r.equal?(c.v)` (18, false before and after) and one that stores nil and appends to it.

**Cost.** A method of this shape whose calls all drop its value is master's C. `def take(x); @s = x; end` called 20,000 times as a statement with a 1,000-byte String: 1,513,415 instructions on master and 1,513,415 here (callgrind). The walk is made once, and only by a program that has such a write: a program of 4,000 such methods compiles in 9.5 s on master and here.

**Generated C.** `make cident REF=9c4eec71`: `6135 identical, 1 differ, 0 refusal changes, 0 refused by both, 0 not in the reference`. The one is the new test. Whether optcarrot's generated C changes is not known: there is no checkout of it where this was written.

**Test.** `test/ivar_tail_write_shared_string.rb`: 12 of its 18 lines are wrong on master, which also prints a nineteenth. Its last case is a method nobody asks, which keeps storing. It prints the same under `SPINEL_GC_STRESS=1` and `2` and built with clang.

`emit_stmt_tail_inner` goes from 498 to 508 lines; the walk is five new functions, the longest 48 lines. `make scale-test` prints the four ratios master prints (1.71x, 4.73x, 6.06x, 4.22x).

The `.expected` file is from CRuby 3.3.6 run with `--enable-frozen-string-literal`; 4.0 is not installed where this was written. The test prints Strings and one Integer.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
