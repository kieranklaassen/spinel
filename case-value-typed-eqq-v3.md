<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A case used as a value took the `else` arm for an object arm whose `===` takes the subject's own type.

```ruby
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
above = Above.new(3)
p(above === 1)
p(case 5 when above then :hit else :miss end)
```

Master (a2bd8900) prints `false` and `:miss`. CRuby prints `false` and `:hit`. Written as a statement (`case 5` / `when above then puts "hit"`) master prints `hit`.

The statement calls the arm's typed function in place. The case value called an arm's `===` only where its parameter is boxed (`emit_when_user_eq`); otherwise it compared an arm of another class with the subject as a pointer, which never matches. The case value now makes the statement's call for an arm of another class whose `===` or `==` has one parameter of the subject's type and answers a boolean. The call is made only for an arm that is not nil when the case runs: a slot typed as an object can hold nil (`def find(i) = i > 0 ? Above.new(i) : nil`), and a nil arm keeps the comparison the case value made before.

Two commits. The first moves the statement's call into `emit_when_obj_call`; the generated C is unchanged (`tools/cident.sh`: 0 differ). The second calls it from `emit_case_expr`.

Cost: the call the statement already makes, behind one test that the arm is not nil (two where the subject is an object: the arm and the subject), where the pointer compare stood. No program of the corpus changes its C.

This sits on the pull request "A `when` arm with an inherited == or === is passed as the class that defines it": the helper carries that cast.

Not in this change: an answer that is no boolean, an optional or rest parameter, a class kept by value, a Float subject beside an Integer parameter and a String subject keep the test they had. A nil subject where the subject is an object keeps it too: the `else` arm, where CRuby calls the method, which raises on nil or answers for it as it is written. The statement form calls a nil arm's method and crashes, on master and here.

Test: `test/case_when_value_typed_eqq.rb`, 19 lines; 10 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
