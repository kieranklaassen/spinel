<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A block handed down through 34 methods answers nil, with nothing said:

```ruby
def f1(x)
  f2(x) { |v| yield v }
end
# ... 34 methods, each one's block yielding on
def f34(x) = yield(x + 1)
p f1(1) { |v| v * 2 }     # 4 in CRuby, nil on master
```

The type a `yield` answers is read from the blocks at the method's call sites, and where such a block's value is itself a `yield` the question goes on to the method that block is written in. The methods being asked are kept on a stack (`g_yvt_mi`), and the stack was an array of 32: asked 33 deep the answer was "unknown", the call had no type, and its value was boxed as nil. The stack grows; the four functions that push on it share one helper (`yvt_enter`), and a method already on the stack still ends the walk.

What was chosen: past the 32 master asks, only a method that yields and that something calls is asked, and only while fewer than 64 such methods are being answered. Its call is written out in place and needs the type of the block handed down to it; one more would be written out 65 deep inside the others, which the inliner refuses (`SP_INLINE_DEPTH_MAX`). Every other method stops at 32, as on master: one nothing calls has no block to answer for its yield, and one with a function of its own, such as one that calls its block as `b.call`, has its value boxed there, which is right. The walk keeps no memory of what it has asked, so each method of a chain asks the whole chain above it, and without the bound those two kinds of chain compile many times slower (400 `b.call` methods took 55 s for master's 10). With it, in CPU seconds of `spinel -c`:

| methods in one chain | 100 | 200 | 400 | 800 |
|---|---|---|---|---|
| each block `{ \|v\| b.call(v) }`: master | 0.50 s | 2.34 s | 10.08 s | 49.46 s |
| the same: this | 0.57 s | 1.82 s | 10.52 s | 49.55 s |

| methods in one chain | 800 | 1,600 | 3,200 |
|---|---|---|---|
| nothing calls it: master | 0.21 s | 0.46 s | 1.29 s |
| nothing calls it: this | 0.25 s | 0.57 s | 1.38 s |
| called, each asking `block_given?`, refused: master | 1.11 s | 4.96 s | |
| the same: this | 1.30 s | 5.01 s | |

The `b.call` chain's C is master's byte for byte.

Right now from 34 methods: the block yielded on from a literal block and handed on as `&b`, the callee defined first, instance methods, a String, the value kept in a local on the way up, a block that may answer nil, two call sites answering different types, and `block_given?` at the far end. They are right for as long a chain as the inliner's rename table has room for (64 methods of one parameter, 43 with a local beside it). Past it each of the 19 shapes measured is refused by name, as on master. That is what the pull request this depends on is for: with the types known, such a chain would go from master's refusal to C that does not link.

Tests: `test/yield_chain_long.rb` has four chains of 40 methods, six of whose seven lines are nil on master, and a chain of 65 methods that call their block as `b.call`, which is right on master and stays so.

Generated C against master, with the pull request this depends on beneath (`make cident REF=8578e3fb`): `6354 identical, 1 differ, 0 refusal changes` (the new test). `tools/refusals.sh` passes (536 records). optcarrot's generated C is byte-identical. Programs, on master 8578e3fb with CRuby 3.3.6 as the reference and the pull request this depends on as the base: 1,222 chains of 3 to 300 methods. 278 that print nil or raise NoMethodError are right. The other 944 are the same: 533 right, 410 refused by name, 1 that does not build.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Integers, Strings and nil)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A call to a yielding method the inliner declines is refused when its value is typed too"
