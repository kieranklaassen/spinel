<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A number `==` an object of the program answered false without asking the object's own `==`.

Cost: a program with no class that answers `==` is not touched, the test is not compiled into its unit. In a program with such a class the boxed `==` must read the right operand's tag and its class's byte in a table before it knows the pair is not a number against such an object, and for two boxed values nothing at compile time says so. That is 3 to 12 instructions a comparison where the right operand is an object or an Array; two Integers pay nothing; a Float pair and an Integer against nil or a String pay nothing built with gcc and 2 built with clang (the table below).

```ruby
class Money
  attr_reader :cents
  def initialize(cents) = @cents = cents
  def ==(other) = other.is_a?(Money) ? cents == other.cents : cents == other
end

row = [Money.new(0), "paid", 3]
balance = row[0]
p balance == 0
p 0 == balance
puts "settled" if 0 == balance
p row.count { |v| 0 == v }
p [0, "x"].include?(balance)
```

Master (d02a49fb7) prints `true`, `false`, nothing, `0`, `false`, built with gcc and with clang. CRuby prints `true`, `true`, `settled`, `1`, `true`.

Integer#== and Float#==, and a Bignum's and a Rational's, hand an operand that is no number back to it: `0 == balance` is `balance == 0`. The boxed `==`, `sp_poly_eq_slow`, asked a program object's `==` only with the object on the left. It now asks it with a number on the left too, beside the arms that do so for `0 == $?` and for an Array against an object with `to_ary`, and by the call they make.

Which object is asked is settled at compile time. Codegen writes `sp_user_eq_tab`, one byte a class: 1 where the class has an `==` of its own, an ancestor's or a module's, or Comparable's through its `<=>`. An object of any other class is not asked, so a class with a `<=>` and no Comparable stays unequal to a number, as in CRuby. A program with no such class does not define `SP_TU_USER_EQ` ahead of the header (the way `SP_TU_NO_POLY_RENDER` is defined), and the test is not compiled: the units of 15 such programs disassemble the same before and after.

Only `==` hands the pair over; `eql?` and `<=>` answer for the number alone. `sp_poly_eql` and the key lookup of `Hash#<=` end in `sp_poly_eq_alone`, which is `sp_poly_eq` without the hand-back, and the `Object#<=>` fallback of `<=>` answers nil for the pair. So `0.eql?(balance)` stays false and `0 <=> balance` nil, and `uniq`, `|`, a Set and a Hash key keep the two apart as on master. In `lib/spinel_rt.h` 40 lines are added and two calls of `sp_poly_eq` become `sp_poly_eq_alone`; `make cident` against the pull request below it: 6179 identical, 227 differ: the new test and 226 programs of the corpus with such a class, each by three added lines (the define, the table and the line that installs it) and no other; 224 of the 226 print their `.expected` before and after, one has none, and `test/promote_array_slot_rederive.rb`, a test of a flag, fails without it before and after.

Depends on the pull request that makes `uniq` with a block compare its keys by `eql?`: its loop called the boxed `==`, and with this arm alone `[0, 6].uniq { |x| x == 0 ? 0 : balance }` would lose the element it keeps on master.

Not in this change, each wrong on master and the same here: a Bignum the compiler has typed (`g = 2**70; g == b`) is compared as a Bignum and never reaches the boxed `==`; `Complex(5, 0) == b` raises TypeError; `eql?` with the object on the left falls to its `==` (`balance.eql?(0)` is true, so `[balance, 0].uniq` is one element); an object with a `<=>` and no Comparable is `==` a number it compares equal to when the object is on the left; a boxed object's own `!=` is not called; with both sides typed, a Rational against an object, and a number against an object whose `==` is Comparable's, are false. An `==` that asks its operand back (`def ==(o) = o == self`) printed false for `5 == b` and for `b == 5`; both now raise SystemStackError, where CRuby raises NameError.

2,188 programs, each against CRuby, on master and with this change above the pull request it depends on. 1,080 put eight classes (an `==` of its own, inherited, from a module, Comparable's, one that answers a Symbol or nil, a class with none, a Struct) against nine numbers on the left (an Integer literal and variable, Floats, a Bignum, a Rational, a Complex, an Array element, a boxed Integer); 972 are the classes the table must tell apart (a `<=>` with no Comparable, Comparable inherited or from a module, another class of the program that answers `==`, an `==` that answers false, raises or prints, a `!=` alone); 136 were written against the change. 1,010 are right before and after; 740 were wrong and are right; 73 were wrong and raise what CRuby raises; 188 are wrong before and after, by the lines above (88 of them the typed Bignum); 104 raise TypeError before and after (the Complex line); 14 raise as CRuby does before and after; 59 do not build before and after. None that was right is otherwise.

Cost under callgrind, 200,000 comparisons of two boxed values, instructions a comparison more than before.

No class of the program answers `==`: nothing, with gcc 13.3 and with clang 18.1 (a number `==` an object, two Integers, an Integer against a String or an Array, two objects, `eql?`, `3 <=> "paid"`, `Hash#<=`, `uniq` of 12 boxed values).

A class in use answers `==`, on pairs of other values:

| the pair | gcc | clang |
|---|---|---|
| two Integers | 0 | 0 |
| two Floats | -1 | +2 |
| an Integer and nil; an Integer and a String | 0 | +2 |
| an Integer and an Array | +3 (+2.0%) | +5 (+4.4%) |
| two Arrays | +6 (+1.2%) | +5 (+1.0%) |
| two objects of a class with no `==` | +11 (+3.3%) | +12 (+5.0%) |
| a number and an object with no `==` | +6 (+4.0%) | +12 (+10.5%) |
| an object `==` a number | +3 (+1.6%) | +4 (+2.7%) |
| `eql?` of two Integers | +1 | +1 |
| a Hash read by a boxed key | 0 | 0 |
| `3 <=> "paid"` | +9 (+3.0%) | +2 (+0.8%) |
| `Hash#<=` of two and three pairs | 0 | +20 a call (+2.1%) |
| `uniq` of 12 boxed values | +50 a call (+1.2%) | +74 a call (+1.8%) |

A number and an object with `==`, the cured pair: 148 instructions a comparison before and 238 after with gcc, 113 and 192 with clang, the call.

Test: `test/number_eq_program_object.rb`, 36 lines; master is wrong in 10.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (uniq with a block compares its keys by eql?)
