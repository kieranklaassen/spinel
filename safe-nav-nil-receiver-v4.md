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

After: a nil receiver runs no argument, where the call is a statement, an assigned or returned value, a condition, or stands beside operands that are plain reads (the rest is under "Not here"). A receiver that is not nil runs each argument once, in order, as before.

How: a `&.` call whose receiver is a typed pointer or a number is a nil test around the call re-entered on the guarded temp. What the re-entry hoisted went into the statement's prelude, ahead of the test. The value arm of `emit_call_safe_nav_arms` now keeps it in a statement expression under the test, as the boxed receiver's arm already does with an `if`. A builtin's operands were ordered by `emit_operands_in_order` before the guard was reached at all; it now leaves a `&.` call alone until its guard has re-entered it (`sn_guard_ahead`), so they are ordered under the test.

Where: ahead of the statement nothing of the statement's own is live; under the test, whatever the statement has already taken is, and an argument that allocates can collect a value no root holds (`pool.pop.w = o&.keep([K.new])` lost the popped object). So the arguments move only where the statement can hold nothing: from the statement that owns the prelude (`g_prelude_stmt`, set by `emit_with_prelude`) down to the call, every other operand of every call and interpolation on the way is a read (`sn_nothing_held`): a literal, self, a variable the call cannot give another value (`read_rebound_by`), a constant that names no object, arithmetic over those. A variable whose value is a String, a boxed value or an object kept by value is not one (`sn_type_assigned_in_place`): `s << "x"` assigns the C variable, so in `two(s, o&.name((s << "x"; 1)))` the read of `s` and the assignment would stand in one C expression, in the order the C compiler picks. Parentheses, a conditional, `&&`, `||`, `return` and a variable's assignment hold nothing and are passed through. Anywhere else the call's C is master's, byte for byte.

`test/safe_nav_nil_receiver_runs_no_argument.rb` prints 68 lines. On master 24 of them are wrong, with gcc and with clang; with this change it prints its `.expected` with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`.

Three more tests pin where the arguments must stay ahead of the statement: `test/safe_nav_in_value_of_unnamed_receiver_writer.rb` (a writer on `pool.pop`, on `pool.shift`, a `&.` writer, a writer in a block) and `test/safe_nav_in_value_of_writer_used_as_value.rb`, 20,000 rounds each, and `test/safe_nav_arguments_change_string_beside.rb` (a String before the call, after it, as the receiver of the call around, changed by `<<`, `concat`, `upcase!`, `replace`, `[]=`, `clear`, by a method, by a lambda, through a second name). They pass on master and their C is master's.

Generated C against master (`make cident REF=23e9734df`): 6099 identical, 8 differ, 0 refusal changes. The eight are the new test and seven with a `&.` call whose value arm hoists (`dispatch_block_param_arms`, `proc_safe_nav_call`, `safe_nav_poly_dispatch`, `safe_nav_specialized_miss`, `safe_nav_typed_receiver`, `setter_nullable_result`, `super_anon_block_bare_variants`). In each, what stood ahead of the nil test now stands under it, and each still prints its `.expected`, also under `SPINEL_GC_STRESS=2`. No benchmark changes, and optcarrot's generated C is byte-identical.

2,254 small programs written around `&.` calls, on the same master: 1,919 have master's C byte for byte, 6 differ only in the numbers of their string literals, 36 are refused by both, 2 are chains of 200 `&.` calls that master's compiler does not finish in a minute, and in 291 the arguments stand under the test. Those 299, with gcc and clang, plain and under `SPINEL_GC_STRESS=1` and `2`: none loses a cell; right in all six, 142 on master and 247 here.

Not here, wrong on master and not made right:

- A `&.` call beside an operand that is a call, makes an object, reads an element or a field, is a String or boxed variable, or is a variable its own arguments can reassign still runs its arguments on a nil receiver: `p o&.m(lg(1)), $log`, `[lg(0), o&.m(lg(1))]`, `a.pop.w = o&.m(lg(1))`, `s + (o&.m(lg("z")) || "!")`. So does one in an Array or Hash literal, a keyword argument, the subject of a `case`, a loop's condition, or the value of a block.
- A String receiver that one of its own arguments changes is read before the argument runs, as on master: `s&.center(app(s), "*")` centres the String as it was. Where `s` is nil master ran `app(nil)` and stopped with a FrozenError; now that call answers nil and the program goes on.
- A block given to a yielding method of a nil receiver, `o&.each_n(2) { }`, still runs the method.
- `i&.clamp(a, b)` on a nil Integer or Float still raises NoMethodError.
- A local of an unboxed kind first assigned inside a skipped argument reads its zero, not nil: after `o&.m((fresh = 5))`, `p fresh` prints nil in Ruby, 5 on master and 0 here (0.0 for a Float, false for true, 0..0 for a Range).

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only since the tests changed)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
