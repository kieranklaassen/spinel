<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`test/binop_recv_root.rb` prints `:diff` for `:third` under `SPINEL_GC_STRESS=2`, and a case statement called `==` on the same object where the case value and CRuby match it without a call.

```ruby
case Pt.make(3)
when Pt.make(4) then p :same
when Pt.make(3) then p :third
else p :diff
end
```

That is the test's own case statement. Master (a2bd8900) hands the arm straight to the call, `sp_Pt__set_set(sp_Pt_s_make(3LL), subject)`: the arm is in no root, `Pt#==` builds an Array, the collection frees the arm it was called on, and it compares what took the arm's place. The test is not in `GC_STRESS_TESTS`, so the gate does not see it.

```ruby
class Never
  attr_reader :n
  def initialize(n) = @n = n
  def ==(o) = o.n > 1_000_000
end
na = Never.new(1)
p(na == Never.new(2))
case na
when na then puts "na"
else puts "none"
end
p(case na when na then :na else :none end)
```

Master prints `false`, `none` and `:na`. CRuby prints `false`, `na` and `:na`.

Both come from one call. `when na` asks `na === subject`, which for a class that defines only `==` is Object#===: the same object matches before `==` runs. The case value tests that in `emit_case_obj_eq`, with the arm in a rooted temporary; the statement called the method directly when its parameter has the class's own type. An arm of the subject's own class with `==` and no `===` now goes to `emit_case_obj_eq` in the statement too, so both forms emit the same test. Every other arm keeps the call it had. `test/binop_recv_root.rb` joins `GC_STRESS_TESTS`.

Not in this change: an arm of a class with its own `===`, or of another class than the subject's, is still called in no root (the pull request "A `when` arm that makes its object is rooted across its own == or ===" above this one); a boxed subject (`case list[0]` with `when na`), which both forms compare with `sp_poly_eq`; and an object kept by value, which has no identity to compare. The second program without its `p(na == Never.new(2))` line is that case: `Never` is then kept by value, and both forms print `none` on master and here.

Test: `test/case_when_same_object_statement.rb`, 9 lines; 3 of them fail on master. `test/binop_recv_root.rb` under `SPINEL_GC_STRESS=2`: 1 of its lines fails on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
