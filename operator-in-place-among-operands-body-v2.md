<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Among a call's operands, an operator that asks an object's own `==`, or that divides by zero, ran out of its place beside an operand that prints.

```ruby
class Seen
  def ==(o)
    puts "eq"
    true
  end
end
def lg(n)
  puts "lg#{n}"
  n
end
def pair(a, b) = [a, b]
v = Seen.new
p pair(lg(1), 3 == v)
```

```
spinel diff: output-diff
  program: eq.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-lg1
 eq
+lg1
 [1, true]
```

```ruby
def lg(n)
  puts "lg#{n}"
  n
end
def pair(a, b) = [a, b]
z = ARGV.size
p pair(lg(2), 10 / z)
```

```
spinel diff: output-diff
  program: div.rb
  ruby:    exit 1
  spinel:  exit 1

--- stdout (ruby)
+++ stdout (spinel)
@@ -1 +0,0 @@
-lg2
```

Both with gcc, which runs a C call's arguments from the right; `10 % z` and `10 % zf` (a Float zero) lose their line the same way.

A builtin operator over scalars computes a value and touches nothing, so the operands of a call are not put in order around it. `call_is_scalar_op` asked that of the receiver and of the result only. `3 == v` has both scalar and runs `v`'s `==`; a division has both scalar and raises on a zero divisor.

`call_is_scalar_op` now also asks that the argument is of a kind that runs no code of the program's (`ty_runs_no_code`). Every caller of it asks "can this run code", and for an object's `==` the answer was wrong for each.

The raise is asked only where order is, in `subtree_has_side_effect`: `/` unless one side is a Float, `%` always, unless the divisor folds to a number other than zero (`n % 16`, `n / SIZE`). The callers that ask whether code runs keep a division as it was: a loop that caches a String's bytes around `h = (h * 31 + s.getbyte(i)) % m` still does.

Measured with gcc and clang at `SPINEL_GC_STRESS` 0 to 2 over 665 programs: 19 operators (an object compared with `==` and `!=`, by an Integer and a Float; `/` and `%` by a zero Integer and a zero Float, alone and inside a sum; and twins that cannot run code or raise: a literal or constant divisor, a Float division, scalars compared) in 18 places (a method's arguments, keywords, a Struct, `yield`, `p`, an Array or Hash literal, an interpolation, a ternary, a nested call, `+=`), the printing operand first or second. 176 change their C. With gcc 140 that were wrong on master are right and 36 are right on both; with clang 20 and 156. The other 489 compile to master's C, every twin among them. None right on master is wrong, refused or unbuildable.

Cost: a division whose divisor cannot be shown non-zero (`10 / n`) beside an operand with an effect is now put in order, one temporary an operand. `tools/cident.sh` against master: two programs of `test/` change beside the new test (`array_push_recv_root`, `array_unshift_recv_root`: `@a.push(@n == @k)`, `@k` an object with its own `==`), both passing with gcc and clang at stress 0 to 2 as on master. optcarrot's C is the same and it compiles in fewer instructions than on master, 8,346,448,584 for 8,349,046,980: the order question folds every constant divisor among a call's operands, and `fold_int_const_name`, which read the whole node table for the constant's one write each time it was asked, now keeps that write per name.

Not here, the same on master:

- a typed Array's index assignment runs its value before its index (`ary[lg(1)] = lg(2)` prints `lg2` first with gcc), whatever the value is;
- an Integer operator that overflows raises RangeError where CRuby answers a Bignum, and does so before the line of an operand to its left.

Test: `test/scalar_operator_operand_order.rb`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: nothing
