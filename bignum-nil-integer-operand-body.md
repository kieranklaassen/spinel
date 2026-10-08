<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def sm(k, on) = on ? k : nil
h = 2**70
n = sm(3, false)
p h.nobits?(n)
p h + n
```

- Master: `true`, then it dies with signal 11.
- CRuby and here: each line raises TypeError (`no implicit conversion of nil into Integer`, `nil can't be coerced into Integer`).

An Integer local, instance variable or method result that can be nil holds the nil as a sentinel, the Integer -2**63. Where a Bignum operation takes such an operand, `emit_bigint_operand` makes the nil the NULL a Bignum slot holds, and the operation read through it. `==`, `!=`, `<`, `<=`, `>`, `>=`, `+`, `-`, `*`, `/` and `%` with the nil on either side, `modulo`, `div`, `divmod`, `pow(a, n)`, `quo`, `allbits?` and `@big += n` died with signal 11; `anybits?` answered `false` and `nobits?` `true`.

Now the operand is kept as it is read and made a Bignum as the number it holds, so the operation runs, with its operands in the order they ran in, and the nil is answered after it by the tests the runtime has for two Integers (`SP_INT_NIL_CK`, `SP_INT_NIL_CMP_CK`): `==` false and `!=` true, an ordering compare ArgumentError, arithmetic TypeError, and NoMethodError where the nil is the receiver. Where neither operand can hold nil the C is master's.

This is a crash fix at the operand: three emit functions beside `emit_bigint_operand`, which ask what it asks (`call_returns_nullable_int`). It adds nothing to the codegen nil helpers and changes no runtime file.

Cost: none. Instructions under callgrind for 200,000 operations with an operand that can be nil and is not: `h + n` 211,530,703 on master and 211,530,717 here with gcc, 210,684,029 on both with clang; `n < h` 97,498,712 and 97,498,698, with clang 96,855,947 and 96,855,951; `h == n` 96,898,611 and 96,898,597, with clang 96,655,847 and 96,655,851. The test of the sentinel that was made before the operation is made after it. A site's C is 37 to 70 bytes longer.

Not here:

- A nil held in a Bignum slot: with `def g(on); return 2**70 if on; if false then 1 end; end` and `m = g(false)`, `h == m`, `h < m` and `h + m` die with signal 11, on master and here. Nothing is converted there, and nothing says when it is compiled that `m` can be nil.
- A boxed operand that is nil goes another way: for `hh = { a: 3 }`, `h < hh[:zz]` answers `false` and `h.div(hh[:zz])` raises ZeroDivisionError, on master and here.
- `h <=> n` answers `1`, `h.between?(n, 2**71)` `true`, `h.coerce(n)` `[nil, h]` and `n ** h` `1`, on master and here; CRuby answers `nil` for the first and raises for the others.
- `h + hi.fetch("zz", nil)`, for a Hash of Integers, answers h - 2**63, on master and here.
- `h ** n`, `h & n`, `h | n`, `h ^ n`, `h.pow(n)` and `h.ceildiv(n)` raise TypeError with another message than CRuby's, on master and here.
- `x += n` on a Bignum local, global or class variable answers x - 2**63: the change that depends on this one.
- A slot that holds -2**63 itself reads as nil, as it does between two Integers on master: for `m = sm(-9223372036854775807 - 1, true)`, `h + m` died with signal 11 on master and raises TypeError here, where CRuby adds.

Test: `test/bignum_integer_or_nil_operand.rb`, 58 lines, 52 of output; master prints 24 and dies with signal 11.

Generated C against master (`make cident REF=548d4196def8`): 6483 identical, 3 differ, 0 refusal changes; no compile met cident's time or memory bound. The 3 are the new test and two tests with a Bignum compare against an Integer that can be nil, `test/float_div_integer_quotient.rb` and `test/kernel_conv_protocol.rb`; both print their `.expected` with gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on master and here. optcarrot's generated C is byte-identical.

112 small programs, one an operation, a side and nil-or-not: `==`, `!=`, `<`, `<=`, `>`, `>=`, `+`, `-`, `*`, `/` and `%` with the Bignum on either side and 16 methods, the operand read eight ways (a call, a local, an `attr_reader`, an Array read, a Hash read, `String#index`, `Array#find`, an instance variable); 12 pairs for the order of the operands, 5 for the place the value is used, and `@big += n`. With gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 548d4196def8: master is right in all six for 64, this for 112. Of the 48, 45 died with signal 11 and 3 printed a wrong answer. None loses a cell.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
