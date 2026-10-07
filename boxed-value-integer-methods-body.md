<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`odd?`, `even?`, `~` and `chr` with an encoding answered for a boxed receiver that has no such method:

```ruby
v = [1, "s"][1]
p v.odd?                     # false
p ~v                         # -1
p v.chr(Encoding::UTF_8)     # "\u0000"
```

Ruby raises NoMethodError for the first two and ArgumentError for the third (a String's `chr` takes no argument). The three arms read the receiver through `sp_poly_recv_i`, which raises for nil and converts every other value to an Integer, so a Float, a Symbol, an Array and true answered too (`2.5.odd?` false, `~2.5` -3).

Now `odd?` and `even?` dispatch on the tag as `zero?`, `positive?` and `negative?` do, and a Bignum answers its own parity. `~` reads its receiver through a helper that raises for a value that is no Integer. `chr` with an encoding tests the tag as the bare `chr` beside it does. A class's own `odd?` or `even?` is called; beside one, a boxed `odd?` did not build.

Not covered: `~` on a boxed Bignum still answers from its low 64 bits, and in a program with a class that defines `~` the boxed receiver is read as before.

The three tests fail on master. The generated C of 75 corpus programs changes, at these calls only; optcarrot's is unchanged. On an Integer the calls cost no more than before (callgrind, a call: `odd?` 2 instructions fewer with gcc and 1 with clang, `~` 1 and 2 fewer, `chr` 3 and 4 fewer).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
