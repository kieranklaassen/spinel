<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A boxed `div`, `divmod`, `remainder` or `fdiv` computed with an operand that is no number, where CRuby raises.

```ruby
row = [7, true]
p row[0].divmod(row[1])
```

Master (2f204adb) prints `[7, 0]`. CRuby raises TypeError (`true can't be coerced into Integer`). With `row = [7, nil]`, `row[0].div(row[1])` raises ZeroDivisionError where CRuby raises TypeError, and `2.5.fdiv("s")` raises ArgumentError.

Each of the four turns away a receiver without the method and then converts its operand: nil to 0, true to 1, a Symbol to its index in the symbol table, a String by `strtoll` or `Float()`. Below its receiver guard each now sends an operand outside the numeric tower to `sp_poly_binop_bad`, which raises as `+` does. An object with `coerce` has answered above that line. Nothing is removed; `sp_poly_divmod`'s Float arm still calls `sp_flo_divmod`.

Cost: one test of the operand on each call. A million boxed Integer `div` calls run 78.7 million instructions under callgrind where they ran 68.7; `divmod` 247.0 where 239.0; `remainder` with a Float operand 86.7 where 76.7; Float `fdiv` 48.7 where 38.7. Three forms that test the operand's tag first were measured and are no cheaper across the four.

Not in this change: `**` converts the same way in `sp_poly_pow`.

Test: `test/poly_named_division_operand.rb`, 60 lines; 44 of them fail on master (8 answer a value, 15 raise another class, 21 word the TypeError differently).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
