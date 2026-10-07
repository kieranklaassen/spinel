<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm of a small read-only class was never asked its `===`.

```ruby
class Above
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
case 5
when Above.new(3) then puts "big"
else puts "other"
end
```

Master (5390d300) prints `other`. CRuby prints `big`. With `attr_accessor :n` in the class master prints `big`.

A class with no writer and a few scalar fields is kept by value. `emit_when_user_eq`, which calls an arm's own `===` (or `==`) with the boxed subject, turned a by-value arm away on its first line; the arm was then boxed and compared with the subject as a value. It now calls the method on the arm as it stands, with the subject boxed and rooted as for a pointer arm. There is no pointer to test for nil or to compare as the same object.

Cost: the call, where the boxed compare stood. One program of the corpus changes its C (`test/case_when_user_equality.rb`: the same call of a by-value class's `==`, its boxed subject now held in a root).

This sits on the pull request "What a `when obj` object's === answers is read for its Ruby truth": both change `emit_when_user_eq`, and a by-value arm's answer is read the same way.

Not in this change: an arm that makes an object holding a String (`when Len.new(a + b)`), which has nowhere to be rooted while the method runs, and an arm whose `===` a call written out has given a typed parameter.

Test: `test/case_when_value_class_arm.rb`, 14 lines; 6 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
