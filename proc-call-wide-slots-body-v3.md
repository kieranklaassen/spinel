<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def f(a, *r, z) = [a, r.size, z]
pr = method(:f).to_proc
p pr.call(*(1..20).map { |j| "s#{j}" })
# CRuby ["s1", 18, "s20"]; here a segmentation fault built with gcc, ["s1", 18, nil] built with clang
p pr.call(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17)
# CRuby [1, 15, 17]; here [1, 15, 0] built with gcc, an address in the 17's place built with clang
```

Since "Sixteen arguments was the side channel's size, written out nine times" a Method's proc binds its parameters by the call's count, up to the channel's 64. A Proc call passes its true count and still packs sixteen slots, so from the seventeenth argument on the Method's proc reads past the array. Before that commit the trampoline declined both calls with NoMethodError.

The call now fills the slots it passes. `emit_proc_call_args` sizes the `sp_int` array by the count once it is past sixteen and publishes that many boxed values, up to the channel's 64. `sp_proc_call_spread_blk` hands a bound Method's proc given more than sixteen elements to `sp_proc_call_spread_wide`, a function of its own, so the common call's frame stays sixteen slots. A call of sixteen arguments or fewer, and a call of more than 64, emit the C they did. A seventeenth argument that runs code now runs; it was never evaluated. One with no value the argument temp can take (`def n = nil`, `()`) runs for its effect and arrives as nil; a bare `puts` there does not build (below).

By callgrind a spread call of sixteen or fewer, `pr.call(*arr)`, goes from 742 instructions to 740 built with gcc and from 743 to 744 built with clang.

Not in this change:

- An ordinary proc still reads sixteen: `pr = proc { |*x| x.size }; p pr.call(*(1..20).to_a)` prints 16 (CRuby 20), `lambda { |*x| x.sum }.call(1, ..., 17)` 136 (CRuby 153), `proc { |a, b = 5, *x, z| [a, b, x.size, z] }.call(*(1..20).to_a)` `[1, 2, 13, 16]` (CRuby `[1, 2, 17, 20]`). Each prints what it printed. The proc's own prologue is bounded at sixteen in every proc body, and raising that changes the C of every proc: a piece of its own.
- A call of more than 64 arguments is as before: a Method's proc raises NoMethodError, an ordinary proc reads sixteen (`proc { |*x| x.size }` given 65 prints 16), and the arguments past the sixteenth never run.
- In the first sixteen places an argument that answers nil from a method still does not build (`pr.call(1, 2, n)`), as before.
- A bare `puts` as an argument does not build, in any place: `pr.call(1, 2, puts)` fails in C (the `putchar` emitted for it holds a raw newline, and its nil is a box where the slot takes an Integer). In the first sixteen places that is as before; from the seventeenth on, the call printed a wrong line before and now fails to build.
- In a threaded build a worker parked for another worker's collection publishes the first sixteen of these slots only (`sp_publish_worker_roots`), where the collecting worker's own 64 are marked. A Method called with more than sixteen arguments fills the slots past the sixteenth today, and now a Proc call does. No program that loses a value there has been found; publishing all 64 is a line of "A Proc's rest parameter receives every argument past the sixteenth".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
