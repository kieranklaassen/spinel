<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed `div`, `divmod`, `remainder` or `fdiv` computed with an operand that is no number, where CRuby raises.

Cost: one test of the operand on each call, 2 to 16 instructions by the loop it sits in. A million boxed calls under callgrind, in million instructions, master (e527d205) then here: Integer `div` 67.7, 75.7; `div` with a Float operand 90.7, 106.7; Float `div` 87.7, 101.7; `divmod` 239.0, 246.0; `remainder` with a Float operand 78.7, 88.7; Float `fdiv` 38.7, 46.7; Integer `fdiv` 44.7, 53.7; `ceildiv` 33.7, 35.7. Another loop around the same call gives another figure. Three forms that test the operand's tag first were measured and are no cheaper across the four.

```ruby
row = [7, true]
p row[0].divmod(row[1])
```

Master (e527d205) prints `[7, 0]`. CRuby raises TypeError (`true can't be coerced into Integer`). With `row = [7, nil]`, `row[0].div(row[1])` raises ZeroDivisionError where CRuby raises TypeError, and `2.5.fdiv("s")` raises ArgumentError.

Each of the four turns away a receiver without the method and then converts its operand: nil to 0, true to 1, a Symbol to its index in the symbol table, a String by `strtoll` or `Float()`. Below its receiver guard each now sends an operand outside the numeric tower to `sp_poly_binop_bad`, which raises as `+` does. An object with `coerce` has answered above that line. Nothing is removed; `sp_poly_divmod`'s Float arm still calls `sp_flo_divmod`.

This sits on the pull request for a boxed `/` or `%` beside a value that is no number: it reads that change's `sp_poly_divmod_converts`.

Not in this change: a program that gives a builtin class that is no number, or one object of such a class, arithmetic or a `coerce` of its own keeps master's answers (`class TrueClass; def coerce(n) = [n, 1]; end` with `7.divmod(true)` prints `[7, 0]` on CRuby and, by the conversion, here); the boxed helpers do not ask such a method on master, and reaching it is a change of its own. `**` converts the same way in `sp_poly_pow`. `ceildiv` negates its operand before it divides, so only a String operand reaches the new check (`[7, :a][0].ceildiv("x")` now raises the TypeError where it raised ZeroDivisionError); nil and an Array still raise ZeroDivisionError there and a Symbol still answers a number, as on master.

Tests: `test/poly_named_division_operand.rb`, 60 lines; 44 of them fail on master (8 answer a value, 15 raise another class, 21 word the TypeError differently). `test/poly_named_division_reopened_builtin.rb`, 7 lines of a program that reopens TrueClass, String and NilClass: right on master and here.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
