<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A case took the `else` arm for an object arm whose `===` would have matched, where a call written out had typed the method's parameter and the subject is held boxed.

```ruby
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o.is_a?(Integer) && o > @n
end
big = Above.new(3)
p(big === 1)
[1, 5, "x"].each do |x|
  case x
  when big then puts "big"
  else puts "other"
  end
end
```

Master (a2bd8900) prints `false`, `other`, `other`, `other`. CRuby prints `false`, `other`, `big`, `other`. Without the `p(big === 1)` line master is right: the parameter is boxed then, and the case calls the method.

`emit_when_user_eq` made the call only for a boxed parameter. For a parameter the written call typed, the case fell to `sp_poly_eq(subject, arm)`, which compares the two as values and never runs the method. It now tests the subject's tag in place and calls the typed method where the subject holds the parameter's type (an Integer, a Float, a String, a Symbol or an object of the parameter's class); any other subject, and a nil arm, keep the `sp_poly_eq` they had. The tag test and the unboxed argument are the ones the operator tables use (`user_dispatch_arg`, no longer `static`).

Cost: one tag test where the subject is of another kind, 3 instructions a `when` (133.7 to 136.7 a test in a loop of misses); a subject the method takes is called directly (134.2 to 56.4 in a loop of hits and misses).

Not in this change: a class with `==` and no `===`, an answer that is neither a boolean nor boxed, a String parameter that is its caller's slot or the shared handle (a `===` that appends to its argument) and a class kept by value keep the comparison they had.

Test: `test/case_when_boxed_subject_typed_eqq.rb`, 22 lines; 7 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
