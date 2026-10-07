<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def id(s) = s
def pick(c, x) = c ? 5 : [x, 2]
x = id("bc")
begin
  pick(ARGV.size > 5, x).zork(1)
rescue NoMethodError => e
  p e.receiver                   # aborts with SPINEL_GC_STRESS=2
end
```

A NoMethodError lost the receiver or an argument of its call to a collection when that value was a temporary. `sp_nomethod_msg_args` and `sp_stage_args_msg` build `NoMethodError#args`: they allocated the list first, and the receiver was staged after it, so nothing held a value like `pick(c, x)` or `"a" + x` during that allocation. Both now root the argument slots before they allocate, and `sp_nomethod_msg_args` stages the receiver first.

```
*** SPINEL_GC_STRESS: the mark reached a freed slot ***
  obj = 0x7f172b424030   phase = globals:break-values   ctx = 0x7f1b2f7ffed8
```

With `SPINEL_GC_STRESS=1` nothing aborts and the answer is wrong: in the new test `e.receiver` of `pick(c, x).next_float` reads `[]` for `["bc", 2]`, and `e.args` of `r.zork("v=#{x}", [x, 1])` reads `["5", ["bc", 1]]` for `["v=bc", ["bc", 1]]`.

The two helpers are `SP_COLD` and run only on the way to a raise: no generated C changes, and a call that is answered costs what it did (callgrind, 200,000 dispatched calls with gcc: 108,472,558 instructions before and after). A call that raises pays 8 to 28 instructions more, of 2,500 to 5,600. Test: `test/nomethod_holds_receiver_and_args.rb`, one of `GC_STRESS_TESTS`.

A second commit holds tests only, written by another builder of this fork for the same fault: `test/nomethod_args_fresh_held.rb` reaches the statically typed gate arm with a Range and with a String just built, a Range boxed for the call, and a receiver a method has just returned; and `test/boxed_slice_receiver_checked.rb`, which stopped at `SPINEL_GC_STRESS=2` for the same cause, joins `GC_STRESS_TESTS`.

Not here: a receiver and an argument that are both temporaries, or two such arguments (`r.zork("a" + x, "b" + x)`), lose the first while the second is made, before these helpers run. That is "A call no method answers runs its receiver before its arguments". And `NoMethodError#receiver` of a String that is a temporary (`("q" + x).zork(1)`) is nil where CRuby answers the String, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
