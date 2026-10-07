<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when obj` whose `===` answers something other than true or false was not asked it.

```ruby
class OneOf
  def initialize(*xs) = @xs = xs
  def ===(o) = @xs.index(o)
end
small = OneOf.new(1, 2, 3)
p(case 1 when small then :hit else :miss end)
```

Master (5390d300) prints `:miss`. CRuby prints `:hit`: `index` answers 0, and 0 is true.

`emit_when_user_eq` calls an object arm's own `===` (or `==`) only when the method answers a boolean or a boxed value. One that answers an Integer, a Float, a Symbol, a String, an Array, a Hash or an object was left to the older paths: compared with `==` in a case value and beside a boxed subject, and read as a C word in a case statement, where a 0 was a miss and the nil of an Integer a hit. A `===` that answers nil on every path is a void function, and the statement did not build. The function now takes every kind of answer and reads it for its Ruby truth.

Not in this change:

- A statement arm whose `===` answers the one Integer or the one Float that Spinel keeps for nil is now a miss, as it already is in a case value. With `def ===(o) = -9223372036854775807 - 1`, `case 1; when k then puts "hit"; else puts "miss"; end` printed `hit` on master and prints `miss` here; so does a `===` that answers the NaN `[0x7FF8000000000001].pack("Q").unpack1("D")`. Master reads both values as nil wherever it asks their truth: `def floor = -9223372036854775807 - 1`, then `if floor` takes the else on master, and `if f` with `f` that NaN does too. An answer that may also be a String holds either value boxed, and is a hit on master and here.
- An arm of a small read-only class kept by value is compared as a value; its `===` is not called.
- A String subject does not call an object arm's `===`.
- A `===` whose parameter has one type (the program also calls it itself, with Integers alone) goes by other paths.

Tests: `test/case_when_object_answer_truth.rb` (7 lines, 5 fail on master), `test/case_when_object_answer_boxed_subject.rb` (22 lines, 12 fail on master), `test/case_when_object_answers_nil.rb` (13 lines, does not build on master).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
