<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
$log = []
def lg(x) = ($log << x; x)
def none = (lg(:r); nil)
p none&.foo(lg(1)), $log          # nil and [:r] in Ruby, nil and [] here
```

Before: a `&.` call whose receiver is typed nil answered the nil of its type and emitted nothing else, so a receiver with an effect never ran: a method that always answers nil (`none&.foo`, `none2(lg(1))&.foo`, `K.new.nothing&.foo`) or a sequence ending in nil (`(lg(:a); nil)&.foo`). The same as a statement, a condition, an operand of `||`, an element of an Array literal, in an interpolation, in a loop, and for each link of `none&.foo&.bar&.baz`.

After: the receiver runs, once, and the call answers nil. Its arguments and its block still do not run.

How: the arm of `emit_call_safe_nav_arms` for a receiver typed nil writes `(receiver, nil)` when the receiver has an effect (`subtree_has_side_effect`) and the bare nil otherwise, so `nil&.foo` and a local holding nil build the C they built.

`test/safe_nav_nil_typed_receiver_runs.rb` prints 31 lines. On master 14 of them are wrong, with gcc and with clang; here it prints its `.expected` with both, and under `SPINEL_GC_STRESS=1` and `2`.

Generated C against master (`make cident REF=origin/master`): the new test differs and nothing else in the corpus; optcarrot's generated C is byte-identical.

Left alone: a plain `.` call on a receiver typed nil is not touched.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
