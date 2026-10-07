<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

A boxed `/` or `%` computed with a value that is no number, where CRuby raises.

```ruby
row = [nil, 2]
p row[0] / row[1]
```

Master (06064727) prints `0`. CRuby raises NoMethodError (`undefined method '/' for nil`). With `row = [7, nil]` master raises ZeroDivisionError where CRuby raises TypeError (`nil can't be coerced into Integer`), and `7 % true` answers `0`.

`sp_poly_div` and `sp_poly_mod` convert both sides to an Integer on their last line, and their Float branch tests either side's tag: nil was read as 0, a String as the number it starts with, a Symbol as its index in the symbol table. `+`, `-` and `*` end in `sp_poly_binop_bad` for such a pair; `/` and `%` now ask for it after the tower-mismatch check, before the first branch that converts, and raise as those three do.

Cost: two Integers and two Floats answer on the first lines, as before; a million boxed Integer divisions run the same 118.7 million instructions under callgrind. A mixed pair passes the new check: Integer / Float runs 153.7 million where it ran 156.7, Float % Integer 252.7 million where it ran 231.7.

Not in this change: `div`, `divmod`, `fdiv`, `remainder` and `**` convert the same way in functions of their own.

Test: `test/poly_div_mod_operand.rb`, 42 lines; 32 of them fail on master (10 answer a value, 13 raise another class, 9 word the TypeError differently).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
