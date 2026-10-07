<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `&.` call on a nil receiver answers nil, but its arguments have already run:

```ruby
class K; def m(a) = a; end
def mk(v) = v ? K.new : nil
o = mk(false)
n = 0
o&.m(n += 1)
p n                               # 0 in Ruby, 1 on master

$log = []
def lg(x) = ($log << x; x)
s = [nil, "ab"].first
s&.rjust(lg(5), lg("b"))
p $log                            # [] in Ruby, [5, "b"] on master
```

Now a nil receiver runs no argument. The call that is re-entered under the nil test hoisted its arguments into the statement's prelude, ahead of the test; `emit_call_safe_nav_arms` keeps them under the test, and `emit_operands_in_order` leaves a `&.` call alone until its guard has re-entered it.

What was chosen: under the test, whatever the statement has already taken is live, and an argument that allocates can collect it (`pool.pop.w = o&.keep([K.new])` lost the popped object). So the arguments move only where the statement holds nothing: every other operand between the statement and the call is a plain read (`sn_nothing_held`). Anywhere else the call's C is master's, byte for byte, and its arguments still run on nil: `p o&.m(lg(1)), $log`, `[lg(0), o&.m(lg(1))]`. The guard's test of which typed receivers can be nil moved into a helper, `sn_typed_nil_recv`, unchanged: it reads the receiver from `repr_of` (`rrr.kind != RK_VOBJ`) as the guard does on master.

A limit: a local of an unboxed kind first assigned inside a skipped argument reads its zero, not nil. After `o&.m((fresh = 5))`, `p fresh` prints nil in Ruby, 5 on master and 0 here.

Test: `test/safe_nav_nil_receiver_runs_no_argument.rb`, 68 lines, 24 of them wrong on master. Three more tests pin where the arguments must stay ahead of the statement; they pass on master and their C is master's.

Generated C against master (`make cident REF=dafa0d047`): 6276 identical, 8 differ, 0 refusal changes. The eight are the new test and seven tests with a `&.` call whose value arm hoists; each still prints its `.expected`, also under `SPINEL_GC_STRESS=2`. optcarrot's generated C is byte-identical.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only since the tests changed)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
