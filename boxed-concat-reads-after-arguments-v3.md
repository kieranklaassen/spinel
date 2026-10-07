<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
g = { a: +"q", b: +"q", c: +"q", d: +"q", e: +"q" }
pad = (1..40).map { |i| "pad" + i.to_s }
m = g[:a]
m.concat((m << ("z" * 300); "w"))
p g[:a].size                      # 302 in Ruby; a segfault on master, with gcc and with clang
```

A String read out of a Hash or a mixed Array sits behind a shared handle. `concat` and `prepend` on it read the handle's bytes into a temp before their arguments run, so an argument that grows the String moves the bytes and the call joins freed ones. With one key in the Hash the same program is right in a plain run and stops under `SPINEL_GC_STRESS=1` and `2`; `u.concat("n", big(u, 500))`, where `big` appends 500 bytes to its argument, prints size 503 built with gcc and size 3 built with clang.

Now the text is read after the arguments have run, where CRuby reads it. Where an argument of `concat` or `prepend` on a boxed receiver may run code of the program or calls a String mutator by name, the boxed dispatch's String arm (`emit_face_arm`, `src/codegen_call_recv.c`) runs the arguments first, each into a rooted temp, and reads the text after them. With no such argument (a literal, a variable, `j.to_s`) the call's C is master's.

Not here, wrong on master and unchanged: a String that is not boxed (`s.prepend(big(s, 300))` on a String with a second name), an argument that assigns the receiver's variable, and the order in which several arguments run. A boxed String in an instance variable (`@s = [+"q", 1][0]; @s.concat(big(@s, 300))`), or in a local that the argument's own call first puts behind its handle, still answers the text it had before the argument ran: the receiver's value is read before the argument lifts the slot. An interpolated object's `to_s` that grows the receiver (`m.concat("#{o}")`) is not seen as an argument that can change a String: its C is master's, right in a plain run and stopping under `SPINEL_GC_STRESS=2`. A String that reached a parameter as a plain value, where another call passes an Integer, is changed as a copy on master and here; such a program stopped under `SPINEL_GC_STRESS=2` on master, on the freed bytes, and now prints there the wrong line master prints in a plain run.

Test: `test/boxed_string_concat_reads_after_arguments.rb`, 27 lines; on master it ends in a segfault before its first line.

Generated C against master (`make cident REF=06064727f`): 6331 identical, 3 differ, 0 refusal changes. The three are the new test and two optparse tests (`rest.concat(argv[(i + 1)..])` on a boxed `rest`, whose argument now has a temp of its own); both print what they print on master. optcarrot's generated C is byte-identical. Where it applies the cost is the argument's rooted temp: 16 instructions a call of `u.concat(str(j))` (callgrind, 200,000 calls).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
