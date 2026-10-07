<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `case` never asked an object arm its `===` when a call such as `big === 1` had typed the method's parameter and the subject was of another kind.

Cost: the method of a program this cures takes its argument boxed, as it does on master when the same value reaches it by a call. A million `big === i` calls beside such a case run 75.8 million instructions under callgrind where they ran 7.8 and the case was wrong; with the case spelled `big === x` master runs 75.8 too. Only a parameter another call has typed is widened, and a subject of the parameter's own type changes nothing: no program of the corpus changes its C.

```ruby
class Above
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

Master (a2bd8900) prints `false`, `other`, `other`, `other`. CRuby prints `false`, `other`, `big`, `other`. Without the `p(big === 1)` line master is right.

`case v when obj` is `obj === v`, but the parameter pass did not count the case as a call. `big === 1` typed the parameter an Integer, the subject is boxed, and codegen compared the subject with the arm as a value. A Float subject beside a parameter an Integer call typed took the `else` too. `infer_param_types` now binds the case subject to the parameter of the arm's own `===` (its `==` where it has none, which `Object#===` calls) through `bind_args_params`, as it does for the call written out and as `infer_block_params` does for a Proc arm. A parameter no call types, or that only a nil reaches, keeps the boxed default it has. A String subject binds nothing: the String arm of `when` answers before an object arm is asked, so the subject is never passed.

Depends on the pull request "A boxed Integer, Symbol, nil or true answers the object_id it has unboxed". A parameter boxed here answers `o.object_id` through the boxed receiver, and without that pull request an Integer there has another id than it had typed.

Not in this change:

- The call that types the parameter has a literal or a method's value as its argument. With a local there (`t = 1; big === t`) the case is still not asked: the parameter is not yet typed when the pass meets the case.
- An arm of a small read-only class kept by value, and a String subject, are turned away before the arm is asked.

Test: `test/case_when_subject_types_param.rb`, 18 lines; 9 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
