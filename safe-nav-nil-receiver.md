<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A `&.` call on a nil receiver answers nil, but its arguments have already run:

```ruby
class K; def m(a) = a; end
def mk(v) = v ? K.new : nil
o = mk(false)
n = 0
o&.m(n += 1)
p n                               # 0 in Ruby, 1 here

$log = []
def lg(x) = ($log << x; x)
s = [nil, "ab"].first
s&.rjust(lg(5), lg("b"))
p $log                            # [] in Ruby, [5, "b"] here
```

For a method of the program one argument is enough. For a builtin it takes two arguments with effects (`rjust`, `center`, `sub`, `tr`), and `a&.fetch(lg(0), lg(9))` runs one of its two. Since #7358 a conditional argument is ordered ahead as a call is, so `s&.rjust(n > 0 ? 1 : (n = 5), n.to_s)` assigns `n` on a nil receiver too.

After: a nil receiver runs no argument. A receiver that is not nil runs each argument once, in order, as before.

How: a `&.` call whose receiver is a typed pointer or a number is a nil test around the call re-entered on the guarded temp. What the re-entry hoisted went into the statement's prelude, ahead of the test. The value arm of `emit_call_safe_nav_arms` now keeps it in a statement expression under the test, as the boxed receiver's arm already does with an `if`. A builtin's operands were ordered by `emit_operands_in_order` before the guard was reached at all; it now leaves a `&.` call alone until its guard has re-entered it (`sn_guard_ahead`), so they are ordered under the test.

`test/safe_nav_nil_receiver_runs_no_argument.rb` prints 70 lines. On master 25 of them are wrong, with gcc and with clang; with this change it prints its `.expected` at `-O0` to `-O3`, with clang, and under `SPINEL_GC_STRESS=1` and `2`. A chain of 200 `&.` calls, which master's compiler was still working on after 25 minutes, compiles in 3 seconds and answers as Ruby does.

Generated C against master (`make cident`): ten tests differ, the new one and nine with a `&.` call whose value arm hoists (`dispatch_block_param_arms`, `exception_circular_cause`, `proc_safe_nav_call`, `safe_nav_builtin_pointer`, `safe_nav_poly_dispatch`, `safe_nav_specialized_miss`, `safe_nav_typed_receiver`, `setter_nullable_result`, `super_anon_block_bare_variants`). In each, what stood ahead of the nil test now stands under it, and each still prints its `.expected`, also under `SPINEL_GC_STRESS=2`. No benchmark changes, and optcarrot's generated C is byte-identical.

Not here, wrong on master and not made right:

- A block given to a yielding method of a nil receiver, `o&.each_n(2) { }`, still runs the method.
- `i&.clamp(a, b)` on a nil Integer or Float still raises NoMethodError.
- A local of an unboxed kind first assigned inside a skipped argument reads its zero, not nil: after `o&.m((fresh = 5))`, `p fresh` prints nil in Ruby, 5 on master and 0 here (0.0 for a Float, false for true, 0..0 for a Range).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
