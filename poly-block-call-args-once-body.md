<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def tick; $c += 10000; 1; end
class K
  def blk(a); $c += 1; yield(a); end
end
class L
  def blk(a); $c += 4; yield(a + 1); end
end
$c = 0
x = [K.new, L.new][0]
x.blk([tick, 2][0]) { |q| $c += q }
p $c
```

printed 20002 where CRuby prints 10002: `tick` ran twice, once a class. `emit_poly_recv_block_dispatch` splices one arm a class into its switch, and the statements an arm's arguments hoist went to the statement's prelude, ahead of the switch. Every arm's ran, whatever class the receiver had; with three classes `tick` ran three times, and on the nil of `x&.blk([tick, 2][0]) { |q| $c += q }` it ran where CRuby runs nothing.

Each arm now collects the statements its arguments hoist and writes them into its own case, ahead of its body.

Depends on "A block call on a receiver of several classes runs the receiver once". Both change the arm loop of `emit_poly_recv_block_dispatch`, and that change's comment says its declining return takes back what the receiver and the arms hoisted; after this one only the receiver's statements are in the prelude, and the sentence says so. The test here passes without it.

Not here: under `--int-overflow=promote`, or with a String for the argument, a `&.` call of a yielding method on a nil of several classes raises NoMethodError, with this change and without. "A &. call of a method that yields runs nothing on a nil receiver" answers nil there.

Measured on 4,750 generated programs (5 sets of two or three classes whose methods yield, call their block or forward it; the receiver a local, an instance variable, an Array element, a Hash value; `.` and `&.`, the `&.` also on nil; 10 arguments; at the top level, in a method, in a loop, under a condition, in a block): the C of 2,550 changes, the ones whose argument hoists a statement (an Array or Hash literal, a call with a block). All 2,550 printed something else and are right, with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2. Of the 2,200 whose C is unchanged, 2,139 are right and 61 raise as they did: the point above. None that was right is lost. `make cident`: the corpus C is unchanged but for the new test.

No cost: the hoisted statements move into the one arm that runs. A million calls of `x.blk([i, 2][0]) { |q| s += q }` on two classes take 373,311,163 instructions where they took 681,262,370; `x.blk(i) { |q| s += q }` takes 36,672,007, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/poly_block_dispatch_argument_once.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: "A block call on a receiver of several classes runs the receiver once"
