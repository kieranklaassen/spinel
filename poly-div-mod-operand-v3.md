<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed `/` or `%` computed with a value that is no number, where CRuby raises.

```ruby
row = [nil, 2]
p row[0] / row[1]
```

Master (5390d300) prints `0`. CRuby raises NoMethodError (`undefined method '/' for nil`). With `row = [7, nil]` master raises ZeroDivisionError where CRuby raises TypeError (`nil can't be coerced into Integer`), and `7 % true` answers `0`.

`sp_poly_div` and `sp_poly_mod` convert both sides to an Integer on their last line, and their Float branch tests either side's tag: nil was read as 0, true as 1, a String as the number it starts with, a Symbol as its index in the symbol table. `+`, `-` and `*` end in `sp_poly_binop_bad` for such a pair; `/` and `%` now ask for it after the tower-mismatch check, before the first branch that converts, and raise as those three do.

Cost: no pair of plain numbers reaches the new check. An Integer beside a Float now answers on the first lines of both functions, as it does in `sp_poly_add`, `sub` and `mul`, with the value the Float branch computed (144 mixed pairs print the same on master, here and on CRuby). A million boxed operations under callgrind, in million instructions:

| | master | here |
|---|---|---|
| Integer / Integer | 68.8 | 68.8 |
| Float / Float | 57.8 | 54.8 |
| Integer / Float | 125.8 | 55.8 |
| Float / Integer | 125.8 | 57.8 |
| Integer % Integer | 64.8 | 64.8 |
| Float % Float | 74.8 | 73.8 |
| Integer % Float | 129.8 | 83.8 |
| Float % Integer | 132.8 | 84.8 |

`lib/spinel_rt.h` stays additive.

Not in this change: a program that gives NilClass, String, Symbol or another builtin class that is no number arithmetic or a `coerce` of its own keeps master's answers (`class NilClass; def /(o) = 0; end` with `[nil, 2]` prints 0 on CRuby and, by the conversion, here). A boxed operator does not reach such a method on master, for `+` either; reaching it is a change of its own. `comp_nonnumber_arith_reopened` asks the class table once, and the unit of such a program sets `sp_poly_divmod_converts`, a static the two checks read only after an operand has failed them (the counts above are the same with and without it). `div`, `divmod`, `fdiv`, `remainder` and `**` convert in functions of their own.

Tests: `test/poly_div_mod_operand.rb`, 78 lines; 32 of them fail on master (10 answer a value, 13 raise another class, 9 word the TypeError differently). `test/poly_div_reopened_builtin.rb`, 12 lines of a program that reopens NilClass, String, Symbol and TrueClass: right on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
