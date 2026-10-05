<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

`when Integer` and `in Integer` beside a boxed subject missed a Bignum, so it took the next arm or the else.

```ruby
v = [2**70, :a][0]
case v
when Integer then p :integer
else p :other
end
```

Spinel prints `:other`. CRuby prints `:integer`. `v.is_a?(Integer)`, `Integer === v` and `when Numeric` already took it.

The arm tested the tag of an Integer that fits and no other. A Bignum in a box has a tag of its own, and the arm now tests both, as `is_a?` does. It is one condition in `emit_poly_class_when`.

The arm's body is reached where it was not, and what the body does with a Bignum is as on master. `p v + 1` in the arm prints 1180591620717411303425, as CRuby does. `p v.to_i` in the arm raises RangeError (bignum too big to convert into 'long') where master printed the else; master raises the same today with `p v.to_i` in the else.

Checked:

- `test/case_when_integer_bignum.rb` fails on master and passes here, also under `SPINEL_GC_STRESS=1` and `2`.
- 1,512 generated programs, each against CRuby: 252 bodies in the arm, with 7, 2**70 and -(2**70), under `when Integer`, under `in Integer`, and with the same body repeated in the else. The 756 with a Bignum and an else that only prints a marker are all wrong on master, because the arm is missed. 682 of them are right here. The other 74 (23 raise, 51 print a wrong value) print byte for byte what master prints where the same body runs through the else. No program that is right on master changes.
- Generated C, `tools/cident.sh` against master: the tests with a `when Integer` or an `in Integer` beside a boxed subject differ, each only by the second tag in that test, and they pass under `SPINEL_GC_STRESS=0`, `1` and `2`. optcarrot and the benchmarks are byte-identical.

Left alone. What a Bignum does once it is inside the arm: `v.to_i` and `Integer(v)` raise RangeError, and `v.chr` and `Array.new(v)` answer what the boxed operators answer for a Bignum on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
