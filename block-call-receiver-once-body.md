<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def tick; $c += 10000; 1; end
class K
  def blk(a); $c += 1; yield(a); end
end
class K2 < K
  def blk(a); $c += 2; yield(a + 1); end
end
$c = 0
h = { 1 => K2.new, 2 => K.new }
h[[tick, 1][1]].blk(1) { |q| $c += 10 }
p $c
```

printed 20012 where CRuby prints 10012: `tick` ran twice. `emit_poly_recv_block_dispatch` writes the receiver into its switch, and the statements the receiver hoists go ahead of the statement. An arm whose method a subclass overrides is not spliced, so the switch is dropped and the ordinary dispatch emits the call; the hoisted statements stayed behind, and the receiver ran again. `[mk(0), mk(1)][1].blk(1) { |q| $c += q }` ran both `mk` calls twice.

The declining return takes them back, as `emit_or_take_back` does for an emitter of a value.

Not here:

- With `&.` the same call runs `tick` three times, and twice with this change. The run that is left is `emit_iteration_stmt_sn`'s, which declines the same way; "A &. statement evaluates its receiver once" takes it back.
- Where no arm declines and the switch is emitted, an argument that hoists is built once an arm, ahead of the switch: `x.blk([tick, 2][0]) { |q| $c += q }` with two classes runs `tick` twice, with this change and without.

Measured on 2,790 generated programs (10 receiver forms; 5 sets of classes; `.` and `&.`; 3 arguments; at the top level, in a method, in a loop, under a condition): the C of 792 changes, all where a subclass overrides the method. The 336 with `.` printed something else and are right, with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2. The 456 with `&.` are the first point above: they print before and after, one run of the receiver fewer, and all 456 are right with that change beside this one. None that was right is lost. Of the 1,998 whose C is unchanged, 1,470 are right and 528 print what they printed: the second point above. `make cident`: the corpus C is unchanged but for the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/poly_block_dispatch_receiver_once.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
