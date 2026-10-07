<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Several arguments of `concat` or `prepend` were nested in one C expression, `sp_str_concat(sp_str_concat(s, a), b)`. C does not say which operand is built first, and nothing held the text one argument made while the next was built:

```ruby
n = 0
s = +"s"
p s.concat((n = 1; "x"), n.to_s)    # "sx1" in Ruby; "sx0" on master built with gcc

300.times { |i| s = +"r#{i}"; x = s.concat("a#{i}", "b#{i}") }   # aborts at SPINEL_GC_STRESS=2, gcc and clang
```

The arguments are now joined one statement at a time into a rooted temp (`emit_str_args_joined`), for `concat` used as a value and for `prepend`.

One decision: Ruby reads each String's text when the call runs, after every argument (`s.concat(t, (t << "z"; "a"))` appends "tz"), so a call is joined only where the join reads no String earlier than Ruby does (`str_args_nested`). Each argument is made where it stands, or is followed only by arguments that run no code of the program's, or is a String the join can read late (one two names hold, or a local only this call can assign). Every other call compiles to master's C: arguments that are all literals and plain reads, an Integer among them, more than 32, and an argument the join could read too early.

A joined call that was right pays 12 to 44 instructions (callgrind, 200,000 calls of `x = s.concat("a#{i}", "b#{i}")`: 236,108,587 to 238,891,801, 14 a call).

Not in this change, each as on master: `concat` as a statement on a variable, which has an emitter of its own (`s.concat(t, (t << "z"; "a"))` appends "t" there); a `prepend` whose argument appends to its receiver (`s.prepend((s << "z"; "b"), "x#{1}")` answers "bx1s" for "bx1sz"); a boxed String; and the calls kept on master's C, where an argument's text can still be lost at `SPINEL_GC_STRESS`. Where one of these shares a program with a cured call, master's abort at level 2 gives way to the wrong answer master prints in a plain run.

`test/string_concat_args_held.rb` goes through a local, a receiver that is no variable, an element and an instance variable, as a value and as a statement. On master (2f204adb0) it differs from Ruby in a plain run with gcc and with clang; it is added to `GC_STRESS_TESTS`.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (the file was written from ruby 3.3.6 with that flag)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical before and after on 2f204adb0)
- [ ] Depends on: # (nothing)
