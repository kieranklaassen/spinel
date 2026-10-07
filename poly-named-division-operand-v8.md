<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed `div`, `divmod`, `remainder` or `fdiv` computed with an operand that is no number, where CRuby raises.

Cost: one test of the operand on each call. A million boxed calls under callgrind, in instructions a call: master (42557a3c), then the difference here.

| operand | `div` | `divmod` | `remainder` | `fdiv` |
|---|---|---|---|---|
| Integer | 91, +3 | 265, +5 | 73, +5 | 44, -1 |
| Float | 122, -3 | 340, +5 | 94, +5 | 38, -1 |
| Bignum | 1,084, +5 | 2,078, +7 | 1,153, +7 | 90, +5 |
| Rational | 6,832, +24 | 11,412, +16 | 10,118, +23 | 44, +18 |

The receiver is an Integer, but a Float in the Float row's `divmod` and `fdiv` and the Bignum row's `fdiv`. A Float receiver beside an Integer: `div` 120, +1; `remainder` 92, +5. `ceildiv` 34, +2.

In `div`, `divmod` and `remainder` an Integer, a Float or a Bignum operand passes on its tag and a Rational on its kind; the rest of the test is out of line (`sp_poly_operand_bad`). `fdiv` reads those four kinds of operand itself and asks the check only for what is left, so an Integer or a Float operand costs it nothing. Its Rational operand pays 18 on a call of 44, the one row left: of seven arrangements of the tests measured, those that take it to 10 to 14 cost every Integer or Float operand 2 to 10 more than this one.

```ruby
row = [7, true]
p row[0].divmod(row[1])
```

Master (42557a3c) prints `[7, 0]`. CRuby raises TypeError (`true can't be coerced into Integer`). With `row = [7, nil]`, `row[0].div(row[1])` raises ZeroDivisionError where CRuby raises TypeError, and `2.5.fdiv("s")` raises ArgumentError.

Each of the four turns away a receiver without the method and then converts its operand: nil to 0, true to 1, a Symbol to its index in the symbol table, a String by `strtoll` or `Float()`. Below its receiver guard each now sends an operand outside the numeric tower to `sp_poly_binop_bad`, which raises as `+` does. An object with `coerce` has answered above that line. Nothing is removed; `sp_poly_divmod`'s Float arm still calls `sp_flo_divmod`.

This sits on the pull request for a boxed `/` or `%` beside a value that is no number: it reads that change's `sp_poly_divmod_converts`.

Not in this change: a program that gives a builtin class that is no number, or one object of such a class, arithmetic or a `coerce` of its own keeps master's answers (`class TrueClass; def coerce(n) = [n, 1]; end` with `7.divmod(true)` prints `[7, 0]` on CRuby and, by the conversion, here); the boxed helpers do not ask such a method on master, and reaching it is a change of its own. `**` converts the same way in `sp_poly_pow`. `ceildiv` negates its operand before it divides, so only a String operand reaches the new check (`[7, :a][0].ceildiv("x")` now raises the TypeError where it raised ZeroDivisionError); nil and an Array still raise ZeroDivisionError there and a Symbol still answers a number, as on master. A Complex operand is in the tower and reaches the arms: `[7, "a"][0].div(Complex(1, 1))` raises ZeroDivisionError where CRuby raises NoMethodError, on master and here. A class of the program whose `coerce` raises, or answers no Array, is a TypeError on both.

Tests: `test/poly_named_division_operand.rb`, 60 lines; 44 of them fail on master (8 answer a value, 15 raise another class, 21 word the TypeError differently). `test/poly_named_division_reopened_builtin.rb`, 7 lines of a program that reopens TrueClass, String and NilClass: right on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
