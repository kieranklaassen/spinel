<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`odd?`, `even?`, `~` and `chr` with an encoding answered for a boxed receiver that has no such method:

```ruby
v = [1, "s"][1]
p v.odd?                     # false
p ~v                         # -1
p v.chr(Encoding::UTF_8)     # "\u0000"
```

Ruby raises NoMethodError for the first two and ArgumentError for the third (a String's `chr` takes no argument). The three arms read the receiver through `sp_poly_recv_i`, which raises for nil and reads a String, a Float, a Symbol, an Array, true or a MatchData as an Integer (`2.5.odd?` false, `~2.5` -3).

Now `odd?` and `even?` dispatch on the tag as `zero?`, `positive?` and `negative?` do, and a Bignum answers its own parity. `~` reads its receiver through a helper that raises for a value that is no Integer. `chr` with an encoding tests the tag as the bare `chr` beside it does, and a String's ArgumentError takes its count from the instance arity table (`builtin_arity_expected`). An object of a class of the program's own that defines `odd?` or `even?` has its method called, where master raised TypeError or did not build.

Where the program defines `odd?` or `even?` in Integer, Numeric, Comparable, Object, Kernel or BasicObject, or at the top level, the call is compiled as before, so an Integer in the box still answers Integer's own (`test/boxed_integer_only_inherited.rb`, which passes on master too).

Not covered: `~` on a boxed Bignum still answers from its low 64 bits; in a program with a class that defines `~` the boxed receiver is read as before; a boxed Regexp's `~` raises where it answered -1 (Ruby matches `$_`); with `odd?` defined in Numeric or Object, a Float or a String in the box is still read as an Integer (the boxed dispatch has no arm from a builtin's tag to an inherited definition).

Three of the four tests fail on master. The generated C of 76 corpus programs changes, at these calls only; optcarrot's is unchanged. On a boxed Integer no call costs more than before (callgrind, instructions a call, gcc and clang: `odd?` 1 and 2 fewer, `even?` the same and 2 fewer, `~` 2 fewer, `chr` 2 fewer and the same).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
