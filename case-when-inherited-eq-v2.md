<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `case` whose arm takes its `==` or `===` from a parent class did not build.

```ruby
class Base
  attr_reader :v
  def initialize(v) = @v = v
  def ===(o) = v == o.v
end
class P < Base; end
p(P.new(8) === P.new(9))
case P.new(1)
when P.new(1) then puts "same"
else puts "other"
end
```

Master (a2bd8900) stops in the C compiler: `passing argument 1 of 'sp_Base__set_set_set' from incompatible pointer type`. CRuby prints `false` and `same`.

`when P.new(1)` calls the parent's typed function with the arm as `self`, and the arm was passed as its own class. The two places that call the method directly, the statement's typed call in `emit_case` and the class's own method in `emit_case_obj_eq`, now cast the arm to the class that defines the method, as the call written out (`P.new(8) === P.new(9)`) and `emit_when_user_eq` already do.

Cost: none. An arm whose class defines the method itself compiles as before, and no program of the corpus changes its C.

This sits on the pull request "A `when` arm that makes its object is rooted across its own == or ===": both change the same two calls.

A subject or an arm that is nil when the case runs: the typed call has no nil test, and a program this makes build ends there in a segmentation fault, as the same call does on master where the arm's own class defines the method or the call is written out.

Not in this change, each the same on master for a method the arm's own class defines:

- An arm held boxed (read out of an Array) is compared and not asked.
- The subject is still passed as its own type: beside a subject of a sibling class or an Integer the program still does not build.
- An arm that is the parent or an overriding child when the case runs calls the parent's method.
- A module's `===` included in two classes, the arm of one and the subject of the other, is a miss.
- A class that takes `==` from a reopened Object or from Kernel, and a splat arm, are compared and not asked.

Test: `test/case_when_inherited_eq.rb`, 19 lines; it does not build on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
