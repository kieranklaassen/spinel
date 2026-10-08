<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`total += v` into an Integer local truncated a boxed Float and dropped a Bignum.

```ruby
Item = Struct.new(:name, :price)
items = [Item.new("a", 3), Item.new("b", 2.5)]
total = 0
items.each { |i| total += i.price }
p total
```

Master (42557a3c) prints `5`. CRuby prints `5.5`.

Spelled `total = total + i.price` it prints `5.5`: `infer_write_types` gives the local the type of that sum, a box. The op-assign arm kept the Integer slot and the operand was converted into it. Where the operator is `+`, `-`, `*`, `/`, `%` or `**` and the operand is boxed, an Integer or a Bignum local is now boxed, so the two spellings type the local alike.

Cost: `total += x` now costs what `total = total + x` already costs on master. A loop adding a million elements of a two-kind Array into `total` runs 61.7 million instructions under callgrind; the spelled form runs 63.7 million on master, and `+=` ran 29.7 million while it kept the Integer slot. Such a local is boxed also where the operand only ever holds an Integer that fits, and the C of 84 corpus programs changes.

Two small groups end otherwise than right: a Bignum local with a Rational operand (`big += Rational(1, 2)`) answered the Bignum unchanged and now raises RangeError, as `big = big + r` does on master; `total **= v` in a `while`, which master refuses to compile, now builds and answers as `total = total ** v` does.

This sits on the pull request for a boxed `/` or `%` beside a value that is no number: without it `y /= nil` on a local this change boxes would raise ZeroDivisionError where the Integer slot raised TypeError, and it asks that change's `comp_nonnumber_arith_reopened`.

Not in this change: a program that gives a builtin class that is no number arithmetic or a `coerce` of its own keeps the Integer slot (`class TrueClass; def coerce(n) = [n, 1]; end` with `total += true` adds 1 on CRuby and, by the slot's conversion, here); a boxed `+` does not ask such a method on master, and reaching it is a change of its own.

Tests: `test/local_op_assign_boxed_operand.rb`, 31 lines; 17 of them fail on master. `test/local_op_assign_reopened_builtin.rb`, 3 lines of a program that reopens TrueClass and String: right on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A boxed `/` or `%` beside a value that is no number raises": this one asks its `comp_nonnumber_arith_reopened`)
