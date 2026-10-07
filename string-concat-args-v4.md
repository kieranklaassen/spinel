<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Several arguments of `concat` or `prepend` were nested in one C expression, `sp_str_concat(sp_str_concat(s, a), b)`. C does not say which operand is built first, and nothing held the text one argument made while the next was built:

```ruby
n = 0
s = +"s"
p s.concat((n = 1; "x"), n.to_s)    # "sx1" in Ruby; "sx0" on master built with gcc

300.times { |i| s = +"r#{i}"; x = s.concat("a#{i}", "b#{i}") }   # aborts at SPINEL_GC_STRESS=2, gcc and clang
```

The arguments are now joined one statement at a time into a rooted temp (`emit_str_args_joined`): for `concat` used as a value on a String one name holds, and for `prepend`.

What it costs: a joined call that was right on master pays 12 to 44 instructions built with gcc and 13 to 53 built with clang (callgrind, 200,000 calls each of nine shapes; `x = s.concat("a#{i}", "b#{i}")`: 236,108,587 to 238,892,929 with gcc, 14 a call, and 239,279,191 to 242,685,259 with clang, 17). A `prepend` of two interpolations on a String two names hold gets 14 cheaper (12 with clang). In each of those shapes an argument's text or the order was lost. One shape pays where there may be nothing to cure: a `concat` on a local whose first argument runs code and whose others are literals is joined because that code may append to the receiver (`s.concat((s.concat("q"); "a"), "Z")` answered "raZ" for "rqaZ" on master), and where it does not, the call pays 27 (gcc: 167,865,436 to 173,266,573) or 32 (clang). A conditional of literals, `to_s` of a String and a literal behind code pay nothing: those calls compile to master's C.

One decision: Ruby reads each String's text when the call runs, after every argument (`s.concat(t, (t << "z"; "a"))` appends "tz"), so a call is joined only where the join reads no String earlier than Ruby does (`str_args_nested`). Every argument is a String, and each is made where it stands, or is followed only by arguments that run no code of the program's (a literal, a plain read, a builtin of Strings that calls nothing; `t + u` is one, and raises in Ruby only where `u` is nil), or is a String the join can read late (one two names hold, or a local only this call can assign). Every other call compiles to master's C: arguments that are all literals and plain reads; a call with nothing to hold and no order to keep (every argument after the first runs nothing and makes nothing, and the first runs no code of the program's, or the rest are literals and the receiver is read as before); an argument that is no String (Ruby converts or refuses it when the call runs, after every argument); more than 32; and an argument the join could read too early.

Not in this change, each as on master: `concat` as a statement on a variable, which has an emitter of its own (`s.concat(t, (t << "z"; "a"))` appends "t" there); `concat` as a value on a String two names hold (the same call answers "sta" for "stza"); a `prepend` whose argument appends to its receiver or assigns it (`s.prepend((s << "z"; "b"), "x#{1}")` answers "bx1s" for "bx1sz"); and the calls kept on master's C, where an argument's text can still be lost at `SPINEL_GC_STRESS`. Where one of these shares a call or a program with a cured one, master's abort at level 2 gives way to the wrong answer master prints in a plain run; so it does where master's plain answer is wrong for a reason of its own (a nil in a String-typed argument taken as empty, `upcase` on invalid bytes, a String method of the program's that appends to `self`).

`test/string_concat_args_held.rb` goes through a local, a receiver that is no variable, an element and an instance variable, as a value and as a statement. On master (5390d3002) it differs from Ruby in a plain run with gcc and with clang; it is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 5390d3002)
- [ ] Depends on: # (nothing)
