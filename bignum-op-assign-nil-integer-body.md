<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def sm(k, on) = on ? k : nil
x = 2**70
n = sm(3, false)
x += n
p x
```

- Master: `1171368248680556527616`, which is 2**70 - 2**63.
- CRuby and here: TypeError (`nil can't be coerced into Integer`).

Cost: a slot that holds -2**63 itself reads as nil, here as in `h + m` and in `+=` on an Integer. For `m = sm(-9223372036854775807 - 1, true)`, `x += m` was right on master and raises TypeError here. It costs no instruction: 200,000 turns of `x += n` with an `n` that can be nil and is not are 200,538,270 instructions under callgrind on master and 200,538,284 here with gcc, 199,890,541 on both with clang.

`x += n` on a Bignum local, global or class variable made a Bignum of its Integer operand raw. An Integer slot that can be nil holds the nil as the Integer -2**63, so `x += n` answered x - 2**63 for an `n` that was nil, `x *= n` a negative product, `x /= n` `-128` and `x |= n` `-9223372036854775808`.

Now the operand goes the way the binary operator's does in the change this depends on: it is kept as it is read, and a nil raises TypeError (`SP_INT_NIL_CK`). `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=` and `^=` take it. Where the operand cannot hold nil the C is master's. It adds nothing to the codegen nil helpers and changes no runtime file.

Not here: `x **= n`, `x <<= n` and `x >>= n` on a Bignum do not build, on master and here.

Test: `test/bignum_op_assign_integer_or_nil.rb`, 36 lines, 25 of output; 12 of the 25 are wrong on master.

Generated C against the change this depends on (`make cident`, both on 548d4196def8): 6486 identical, 1 differ, 0 refusal changes; no compile met cident's time or memory bound. The 1 is the new test. optcarrot's generated C is byte-identical.

18 small programs: `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=` and `^=` on a Bignum local, and `+=`, `-=` and `*=` on a local, a global, a class variable and an instance variable in one program, each with an operand that is nil and one that is not. With gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`, on 548d4196def8: the change this depends on is right in all six for 9, this for 18. The 9 printed a wrong number. None loses a cell.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A Bignum operation whose Integer operand is nil answers as CRuby does": this commit stands on its one)
