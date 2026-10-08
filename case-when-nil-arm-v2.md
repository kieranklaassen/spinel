<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A case statement ended in a segmentation fault where a `when` arm typed as an object is nil when the case runs. Cost: one test of the arm, 3 to 5 instructions a `when`, only where the nil analysis says the arm may be nil; an arm it shows is never nil costs nothing.

```ruby
class Above
  attr_accessor :n
  def initialize(n) = @n = n
  def ===(o) = o > @n
end
def above(i) = i > 0 ? Above.new(i) : nil
p(Above.new(1) === 2)
case 5
when above(0) then puts "hit"
else puts "miss"
end
```

Master (42557a3c) prints `true` and ends in SIGSEGV. CRuby prints `true` and `miss`: `nil === 5` is false.

Three places called the arm's `===` with no test: the statement's typed call (`emit_when_obj_call`) and, in the statement and the case value, the arm beside an Array or Hash subject (`emit_case_container_eq`) and the arm beside a subject of its own class (`emit_case_obj_eq`). Each now reads the nil analysis's fact for the arm (`nil_fact_node`): where the arm may be nil it is held in a temporary and the method is called only when it is there; a nil arm matches a nil subject alone. An arm the analysis shows is never nil (`when Above.new(3)`, a local set on every path) compiles to the C it had. This reads the nil fact and adds to none of the code generator's nil helpers.

Two commits. The first moves the statement's typed call out of `emit_case` into `emit_when_obj_call` and changes no C (`tools/cident.sh`: 0 differ). The second is the fix.

This sits on the pull request "A `when` arm that a call makes is rooted across its compare": the call that moves carries that pull request's root.

Not in this change: a nil subject beside an arm that is there is still handed to the method, as CRuby hands it. An arm with an inherited `===` beside an Array or Hash subject does not build, on master and here.

A program that crashed at a nil arm now runs on, and a statement after it prints what master prints for that statement on its own. Of 7,400 lines tried, 82 are wrong so: 81 are wrong on master in the same way with the statement run alone (a Float arm compared with `==`, an inherited `===` that is not found), and one, `[find(0), find(1), find(8)].map { |k| case 5 when k then :hit else :miss end }`, is printed by the loop that meets the nil arm and is master's line with the nil turn taken out of the loop.

Test: `test/case_when_nil_arm.rb`, 24 lines; master prints the first and crashes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request "A `when` arm that a call makes is rooted across its compare": the call the first commit moves carries its root)
