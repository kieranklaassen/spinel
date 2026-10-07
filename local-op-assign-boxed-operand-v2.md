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

Master (ae2c38c7) prints `5`. CRuby prints `5.5`.

Spelled `total = total + i.price` it prints `5.5`: `infer_write_types` gives the local the type of that sum, a box. The op-assign arm kept the Integer slot and the operand was converted into it. Where the operator is `+`, `-`, `*`, `/`, `%` or `**` and the operand is boxed, an Integer or a Bignum local is now boxed, so the two spellings type the local alike.

Cost: such a local is boxed also where the operand only ever holds an Integer that fits. A loop adding a million elements of a two-kind Array into `total` runs 61.7 million instructions under callgrind where it ran 29.7 million; spelled `total = total + x` it runs 63.7 million on master.

This sits on the pull request for a boxed `/` or `%` beside a value that is no number: without it `y /= nil` on a local this change boxes would raise ZeroDivisionError where the Integer slot raised TypeError.

Test: `test/local_op_assign_boxed_operand.rb`, 31 lines; 17 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
