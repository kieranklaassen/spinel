<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`:a.equal?(3)` raised NoMethodError where CRuby answers false.

```ruby
s = :a
p s.equal?(3)
x = [3, :a][1]
p s.eql?(x)
```

Master (9274c732) stops at the first line: `undefined method 'equal?' for an instance of Symbol (NoMethodError)`. CRuby prints `false`, `true`.

The Symbol rows of the builtin table (`src/builtin_ops.c`) had none for `equal?` or `eql?`. The one arm was the compare of two Symbols by type, their ids; any other argument (an Integer, a String, nil, an object, and a boxed value even where it holds the same Symbol) found no row and the call was compiled as the raise. An Integer, a Float and a boolean receiver each answer the rest. Two rows now ask the boxed pair, `sp_poly_equal` or `sp_poly_eql`, with the receiver read before the argument: a Symbol is itself alone. A Symbol slot that holds nil is boxed as nil there and equals nil. Two Symbols by type keep the compare they had, so no call that built and ran changes its C.

No program of the corpus changes its C (`tools/cident.sh`: 1 differ, the new test). `make bop-arity-check-test traits-check-test` pass with the rows in (914 rows).

Test: `test/symbol_equal_other_kind.rb`, 39 lines; master raises on the first.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
