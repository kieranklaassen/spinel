<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def f1(x) = f2(x)
def f2(x) = f3(x)
# ... 200 methods, each answers the next one's
def f200(x) = x + 1
p f1(1)                   # 2 in CRuby, nil here
```

with the warning that type inference did not converge in 128 rounds. A type crosses one call in a round, so the chain takes a round a method, and stopped at 128 the methods at the far end had no type. Of 18 chain shapes at 200 methods, 3 were right on master, 12 printed a wrong answer and 3 did not compile.

The cap is there for an oscillation. The two are told apart by where a round ends: an oscillation comes back to a state of types it has been in, a chain ends each round in a new one. From round 64 on each round's state (a digest of every node's, return's, local's, instance variable's, global's and constant's type) is kept, and the last round the cap allows earns one more when its state is new and the round added no node. A program that has stopped growing has finitely many states, so this ends; a rewrite undone and redone each round grows the program and is cut at 128 as before. No loop is given more than four rounds for each slot a type waits a round to cross (a return, a local, an instance variable, a global, a constant), so the bound is the program's size. The re-narrowing loop after the fixpoint has a cap of 128 of its own and no warning (160 methods called with an Integer and a String printed nil twice with the first loop fixed alone); it takes the same rule.

17 of the 18 shapes are right at 200 and at 300 methods. The eighteenth, a block handed down the chain, is refused at 100 methods too, which is another limit. A chain runs along instance variables the same way: 200 of them in one method, each assigned from the next, ran to the cap on master and settle on round 203. No String rule is touched.

**Cost.** The numbers below are with master b2a283d4 merged in.

No program in the tree pays. Nothing is computed before round 64, and of the 5,880 programs under `test/` and `benchmark/` none goes past round 32 but `test/ptr_array_set_poly_value.rb`, which oscillates to the cap on master and still does, on the same round, to the same C. Every other round count is master's.

The cost is on the chains, and it has no bound in time. The bound is in rounds, 128 and four for each slot, and a chain never meets it: n methods run n + 3 rounds where master stopped at 128. A round is a pass over the whole program and costs what it costs on master (37 ms for master's 40 ms at 2,000 methods); there are more of them, and a pass grows faster than the program does. Measured, the time grows as the chain to the power 2.4 to 2.5. CPU seconds to C, least of three, on a quiet machine:

| methods in the chain | master | here |
|---|---|---|
| 200 | 0.21 (wrong answer) | 0.30 |
| 500 | 0.68 (wrong answer) | 2.38 |
| 1,000 | 1.85 (wrong answer) | 12.91 |
| 2,000 | 5.18 (wrong answer) | 74.13 |
| 200, a chain along locals, right on master at the cap with the warning | 0.28 | 0.42, no warning |
| 1,000, the same | 2.56 | 18.11 |
| 1,000 methods with no chain | 0.18 | 0.17 |

So a chain of 2,000 methods compiles for over a minute, and a longer one for longer; nothing stops it but its own end.

Of the chains master had right at the cap, with the warning, seven get typed C here where master's was boxed (`sp_int sp_f200(sp_int)` for `sp_RbVal sp_f200(sp_RbVal)`). One shape pays and gets nothing but the warning gone: a parameter given two types down a chain whose callee is defined first. The parameter is boxed whether the rounds end or are cut, so the C is byte for byte master's, and 1,000 such methods take 1,002 rounds for master's 128, 14.13 s for 1.87 s. At 127 and 128 methods a chain runs two or three rounds more than on master; under 127 nothing changes.

**Generated C.** `make cident REF=upstream/master`, with master b2a283d4 merged in: `6033 identical, 5 differ, 1 refusal changes`. Four of the five are the programs that print the compiler's revision; the fifth is the new test that compiles on master. The refusal that changes is `test/method_chain_long.rb`, which master refuses for an append it does not make. optcarrot's generated C is byte-identical. `an_phase_infer_fixpoint` is 462 lines (446 on master).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; they print Integers and Strings)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
