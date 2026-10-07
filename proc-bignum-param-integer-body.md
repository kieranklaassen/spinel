<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
show = proc { |n| p n }
show.call(2**70)
show.call(7)                # CRuby 7; here a segmentation fault, and nil for a 0

pr = proc { |e| p e + 1 }
pr.call(7)                  # the same fault, now that the call through qr types the parameter
qr = pr
qr.call(2**70)

def each_total
  yield 2**70
  yield 7
end
each_total { |n| puts n }   # does not build: assignment to 'sp_Bigint *' from 'long long int'
```

A parameter that one call gives a Bignum and another an Integer is typed a Bignum, and each boundary has to make a Bignum of the Integer. A method call and a local write do. A proc's body and a Method's proc cast the `sp_int` slot to a pointer, and the slot carries the Integer as itself; a `yield` spliced into its block assigns the Integer to the pointer.

The two bodies now read the parameter through `sp_proc_arg_bigint`, which looks at the box every call publishes beside the slot: a Bignum is taken as it is, an Integer becomes a rooted Bignum, nil and any other kind read the slot as before. The spliced `yield` converts as a local write does. `pr === 2**70`, where the runtime's own call fills the slot with the Bignum's low bits, handed the proc nil and is right by the same read.

The first commit only moves the other arm of `emit_proc_literal_here` that reads the box into a helper, so the function goes from 1,293 lines to 1,283 instead of growing. `make cident` for it is 0 differ, in the default mode and with `--int-overflow=promote`.

Cost, by callgrind: a proc with an Integer parameter emits the C it did, 92.6 instructions a call before and after. A proc with a Bignum parameter given a Bignum goes from 211 to 247 a call (the tag test and the root), a Method's proc from 250 to 263.

Not here, wrong on master and unchanged:

- `S = Struct.new(:a); S.new(2**70); S.new(7)` and `a, b = 2**70, 7; a, b = b, a` do not build: the same Integer into a Bignum, at two other boundaries.
- `yield nil` into a Bignum block parameter that is then used as a number (`n + 1`) is a segmentation fault where CRuby raises NoMethodError. A block that is also yielded an Integer did not build and now reaches that fault, as the same block yielded two Bignums and nil does on master.
- A call with more than 16 arguments reads a parameter past the sixteenth from beyond the slots the call fills. The new read stops at 16, so such a parameter reads as it did; a program the fault above stopped first (`def f(a, *r, z)` through `to_proc`, 17 arguments) now runs on to that value.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
