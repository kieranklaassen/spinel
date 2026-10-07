<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`String#prepend` had two faults in one arm, and they have one cure. The first two programs below are wrong in a plain run; the third aborts at `SPINEL_GC_STRESS=2` only. No call pays for the cure: `s.prepend("a", "b")` emits the C it did, and by callgrind `s.prepend("a#{i}", "b#{i}")` runs 3 fewer instructions a call built with gcc and 2 fewer with clang.

```ruby
s = +"abcdefgh"
s.prepend((s.replace("k"); "z"), "q")
p s                                   # CRuby "zqk"; here "zqabcdefgh"

t = +"a-"
t.prepend((t << "y"; "z"))
p t                                   # CRuby "za-y"; here "za-" built with gcc

u = +"t"
u.prepend("h#{u.size}-", "m#{u.size}-")
p u                                   # here, at level 2: the mark reached a freed heap string
```

The order: with several arguments, or with its value read in place, prepend put its receiver in a temporary before the arguments ran, so an argument that changes the receiver was not seen. With one argument, as a statement, the argument and the receiver were two arguments of one `sp_str_concat` call, read in the order the C compiler picks.

The hold: with several arguments none was held while the next was built.

prepend now takes its arguments as the `concat` statement does: each in order into a temporary before anything is prepended, held while a later one is built, and a receiver that is a variable is read after them. That applies where two arguments are built, or where one runs code and the receiver is a variable. Every other prepend emits the C it did: one argument that runs no code, several literals or variables.

Not here: `$s = +"abc"; t = $s.prepend("z")`, the value of a global's prepend written to a variable, does not build, before and after.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
