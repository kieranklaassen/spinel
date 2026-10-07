<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A cost comes with it: on a receiver that is not nil, a `&.` call of a method that yields now pays the nil guard every other `&.` call pays, 17 instructions a call as a statement and 16 as a value (callgrind, a million calls of `o&.blk(i) { |q| s += q }`: 17,664,582 before and 34,664,584 after; of `s += o&.blk(i) { |q| q + 1 }`: 15,664,582 and 31,664,587; master's `o&.add(i)` against `o.add(i)`, for a method that does not yield: 31,664,532 against 10,664,506). The guard is the one `emit_iteration_stmt_sn` and `emit_call_safe_nav_arms` emit already.

```ruby
class K
  def blk(a); $c += 1; yield(a); end
end
def mk(v) = v ? K.new : nil
$c = 0
o = mk(false)
r = o&.blk([1, 2]) { |q| q.size }
p r, $c
h = { 1 => K.new }
h[2]&.blk(5) { |q| $c += 10 }
```

printed 2 and 1 where CRuby prints nil and 0, and the last line raised `undefined method 'blk' for nil (NoMethodError)`. A method that yields has no function of its own: its body is spliced in place of the call. The splices were asked ahead of the `&.` guard and never look at the operator, so the method ran on nil, and its block with it: `emit_inline_expr` for a value, `emit_inline_call` for a statement. As a statement on a receiver of several classes, `emit_poly_recv_block_dispatch` splices one arm a class, and its default arm raised for the nil.

`emit_inline_expr` declines while the call's guard is pending (`sn_guard_pending`), so `emit_call_safe_nav_arms` tests the receiver and re-enters on the guarded temp. For the statement, `emit_iteration_stmt_sn` takes the emission it goes around as a parameter, and `emit_inline_call_sn` puts the two splices inside it, only for a call that targets a yielding method or has a dispatch candidate. Every other call is emitted as it was.

Depends on "A &. statement evaluates its receiver once". This adds a caller of `emit_iteration_stmt_sn`, and where the guarded splice declines, that change takes back the statements the receiver hoisted. The test here passes without it; what it covers is a decline. With `class K2 < K` overriding `blk` and `h = { 1 => K2.new, 2 => K.new }`, `h[[tick, 1][1]]&.blk(1) { }` runs `tick` three times on master, four times with this change alone, and twice with that one, with this change or without (CRuby once; the second run is the last point below).

Not here:

- As a statement, an Array or Hash literal among the arguments is still built ahead of the guard: `o&.blk([tick, 2]) { }` on nil still runs `tick`, and no longer the method and the block. The value form builds it inside the guard.
- An `emit_poly_recv_block_dispatch` that declines leaves the statements its receiver hoisted, with `&.` or without: `h[[tick, 1][1]].blk(1) { }` above runs `tick` twice.

Measured on 2,400 generated programs against master with that change (12 receiver forms, nil or not at run time; 10 methods that yield; 5 block bodies; as a statement, an assigned value, an argument, a condition, an interpolation, an `||` operand): the C of 2,088 changes. 1,036 that were wrong are right: 1,020 that ran the method on nil, and 16 that raised. 1,052 were right and are. None that was right is lost, and none of the 2,088 is wrong after; they agree with CRuby with gcc and clang at `SPINEL_GC_STRESS` unset, 1 and 2. The 312 whose C is unchanged were right. `make cident`: the corpus C is unchanged but for the new test and `test/yield_inherited_self_class.rb`, whose `m&.kinds { |s| puts s }` gains the guard and passes as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (`test/safe_nav_yield_method_nil.rb` is written from CRuby 3.3.6; its 4.0 run is owed)
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: "A &. statement evaluates its receiver once"
