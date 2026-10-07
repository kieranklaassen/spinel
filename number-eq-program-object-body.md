<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A number `==` an object of the program answered false without asking the object's own `==`. The cost of asking is in the boxed `==`: two Integers pay nothing; a Float, String or nil pair pays one instruction; a number against an object whose class has no `==` pays 22 (+17.3%), and `Hash#<=` 22 a key (+2.2%).

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

Master (3cb8982d8) prints `true`, `false`, nothing, `0`, `false`, built with gcc and with clang. CRuby prints `true`, `true`, `settled`, `1`, `true`.

Integer#== and Float#==, and a Bignum's and a Rational's, hand an operand that is no number back to it: `0 == balance` is `balance == 0`. The boxed `==`, `sp_poly_eq_slow`, asked a program object's `==` only with the object on the left. It now asks it with a number on the left too, as the arm beside it does for `0 == $?`. A class with no `==` of its own is not asked. Runtime only: `lib/spinel_rt.h`, 16 lines added, none changed; `make cident` against the pull request below it: 6394 identical, 0 differ.

Only `==` hands the pair over; `eql?` and `<=>` answer for the number alone. Three places reach the boxed `==` for one of those, and each now returns before it for this pair: `sp_poly_eql`, the `Object#<=>` fallback of `<=>`, and the key lookup of `Hash#<=`. So `0.eql?(balance)` stays false and `0 <=> balance` nil, and `uniq`, `|`, a Set and a Hash key keep the two apart as on master.

Depends on the pull request that makes `uniq` with a block compare its keys by `eql?`: its loop called the boxed `==`, and with this arm alone `[0, 6].uniq { |x| x == 0 ? 0 : balance }` would lose the element it keeps on master.

Not in this change, each wrong on master and the same here: a Bignum the compiler has typed (`g = 2**70; g == b`) is compared as a Bignum and never reaches the boxed `==`; `Complex(5, 0) == b` raises TypeError; `eql?` with the object on the left falls to its `==` (`balance.eql?(0)` is true, so `[balance, 0].uniq` is one element); a boxed object's own `!=` is not called; with both sides typed, a Rational against an object, and a number against an object whose `==` is Comparable's, are false. An `==` that asks its operand back (`def ==(o) = o == self`) printed false and now raises SystemStackError; CRuby raises NameError.

1,080 programs, each against CRuby: 8 classes (its own `==` with an equal and with an unequal number, an inherited one, a module's, Comparable's, one that answers a Symbol or nil, none, a Struct) by 9 numbers on the left by `==`, `!=`, a condition, a block, a parameter, a Hash value. 412 are right before and after, 456 wrong before and right now, 77 wrong before and after (57 with a typed Bignum on the left, 10 with a Complex, 10 with both sides typed), 104 raise before and after (a Complex on the left) and 31 fail to build before and after. 136 more attack what stands on `==`: `eql?`, `equal?`, `<=>`, `sort`, `uniq`, `|`, `&`, a Set, a Hash key, `include?`, `index`, `case`, and an `==` that raises, logs its operand or answers no boolean. 66 are right before and after, 48 wrong before and right now, 21 wrong before and after, 1 fails to build. None that was right is otherwise.

Cost under callgrind, built by gcc 13.3 at `-O2`, 200,000 comparisons of two boxed values, instructions a comparison: two Integers, no change; a Float, String or nil pair, +1 (under 1%); an Integer and an Array, +6 (+4.7%); two Arrays, +5 (+1.0%); two objects of a class with no `==`, +6 (+3.2%); a number and an object with no `==`, +22 (25,471,481 instructions to 29,871,481, +17.3%); a number and an object with `==`, the call (29,672,240 to 45,272,341); an object `==` a number, no change. `eql?` of two boxed values +3 (+5.7%), so `uniq` of 12 boxed values +3.1%; a Hash read by a boxed key, no change; `5 <=> "s"` +7 (+2.6%); `Hash#<=` +22 a key (99,173,610 to 101,373,610, +2.2%).

Test: `test/number_eq_program_object.rb`, 33 lines; master is wrong in 9.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
