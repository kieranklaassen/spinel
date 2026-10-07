<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm that makes its object was freed while its own `==` or `===` ran.

```ruby
class Pt
  attr_accessor :v
  def initialize(v); @v = v; end
  def ===(o)
    $pad = "x" * 4_000_000
    junk = []
    64.times { |i| junk << Pt.new(i + 100) }
    v == o.v
  end
end
p(Pt.new(1) === Pt.new(2))
p(case Pt.new(3) when Pt.new(3) then :same else :other end)
```

Master (26d456ec) prints `false` and `:other`. CRuby prints `false` and `:same`. No environment variable is set: the 4 MB String starts a collection, and the next `Pt` takes the freed arm's place.

`when Pt.new(3)` calls the class's method with the arm as `self`. The case statement, and the case value for a class with `===`, passed the fresh object straight to the call, in no root. An arm that allocates is now held in a rooted temporary while the call runs, at the two places that pass it directly: the statement's typed call in `emit_case` and the class's own method in `emit_case_obj_eq`. An arm that allocates nothing (a local, a constant, an instance variable) compiles as before.

Cost: one root for each arm that allocates. A million `when Pt.new(i)` tests run 114.4 million instructions under callgrind where they ran 104.4. No program of the corpus has such an arm: its emitted C is unchanged.

This sits on the pull request "A case statement finds the same object before calling its ==": both change the same lines of `emit_case`.

Not in this change: a small read-only class kept by value, whose temporary is not a pointer to root; and an arm that is an element of an Array or a Hash of the class (`when [P.new(2), P.new(1)][1]`), which is not compared by the class's `===`: `:other` where CRuby says `:same`, on master and here. Three of the 288 programs measured put such an arm after one this change roots: they take the `else` on master in a plain run and still do here, and under `SPINEL_GC_STRESS=2`, where master stops inside the first arm, they now run on to that same `else`.

Test: `test/case_when_arm_rooted.rb`, 12 lines; 3 of them fail on master in a plain run, 7 under `SPINEL_GC_STRESS=1` or `2`. On the pull request beneath this one they are 3 and 6: one of the seven is that one's cure.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
