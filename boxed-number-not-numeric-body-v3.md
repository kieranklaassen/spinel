<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
[1, 1.5].each { |v| p v.instance_of?(Numeric) }   # true, true; CRuby prints false, false
```

`instance_of?` asks for the object's own class, and no number's class is Numeric. A receiver typed as a number was right, but for a Rational past the machine range (`(2**70).to_r`), which is boxed. `emit_poly_isa_test`'s Numeric arm listed every numeric tag whatever `exact` said, so on a boxed receiver the test answered as `is_a?` does, for an Integer, a Float, a Bignum, a Rational and a Complex. The arm now answers false for the exact form; `is_a?`, `kind_of?` and `Numeric === v` are untouched.

Test: `test/instance_of_numeric_boxed.rb`; 9 of its 19 lines differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
