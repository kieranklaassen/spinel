<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A call answered at compile time dropped its receiver. Where the call is the first thing its statement runs, the receiver is now emitted ahead of the answer. Anywhere else the call compiles as it did.

```ruby
class Shape; end
$n = 0
def bump = ($n += 1; 7)
p bump.size
p bump.respond_to?(:abs)
puts "no" unless bump.is_a?(Shape)
p $n
```

```
spinel diff: output-diff
  program: folded.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,4 +1,4 @@
 8
 true
 no
-3
+0
```

| answered from | calls | witness |
|---|---|---|
| a row of `builtin_ops.c` that names the receiver nowhere | `Integer#size`; a Float Range's `cover?`, `include?`, `member?`, `===`, `eql?` with a non-number | `bump.size`; `(7 / z).size` answered 8 with `z` zero |
| the receiver's type | `respond_to?` with a literal name | `bump.respond_to?(:abs)` |
| the live arm of an `if`, `unless` or ternary | on that `respond_to?`, or on `is_a?`, `kind_of?`, `instance_of?` of a class the type rules out | `puts "no" unless bump.is_a?(Shape)` |

The first thing a statement runs (`call_runs_first`) is the statement itself, the value it writes or returns, the test of its `if`, the head of a chain (`bump.size.to_s`), the left of an operator (`bump.size + 1`), the one argument of `p bump.size`. A receiver that is a variable or a literal emits the C it did.

Not here: the receiver stays dropped, in master's C.

- After another operand: `other + bump.size`, `x += bump.size`, `p bump.size, 1`, `"#{bump.size}"`, and an Array element. A receiver that was dropped has no place among the operands written before it: kept where it stands, `mk < (b.is_a?(Shape) ? 1 : 2)` runs `b` before `mk` under gcc.
- The right of `&&` and `||`, the test of an `elsif`, a `when` or a `while`, an arm of a ternary, the body of a `def ... rescue`.
- An `if` whose value is the receiver of a call, `(if bump.is_a?(Shape) then 1 else 2 end).+(mk)`: its test runs first there and is still left as it was.
- `1.5.eql?(1)`, `("a".."c").cover?(1)` and `"ab".casecmp(1)` drop the receiver through arms of their own.

Cost: the receiver's own run where it was dropped. optcarrot's C is byte for byte master's.

Test: `test/folded_call_runs_receiver.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: the pull request "A builtin that reads its receiver twice runs it once" (both add lines at the same place in `emit_op_template`; this one is written on top of it), and the pull request "An interpolated String operand is made in the order written and held" (`test/syscall_errno.rb` runs a `Pathname.new` this change no longer drops, and under GC stress the String that test makes beside an interpolated argument is held only there)
