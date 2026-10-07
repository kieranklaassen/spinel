<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A case statement called `==` on the same object, where the case value and CRuby match it without a call.

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

Master (5390d300) prints `false`, `none` and `:na`. CRuby prints `false`, `na` and `:na`.

`when na` asks `na === subject`, which for a class that defines only `==` is Object#===: the same object matches before `==` runs. The case value tests that in `emit_case_obj_eq`; the statement called the method directly when its parameter has the class's own type. An arm of the subject's own class with `==` and no `===` now goes to `emit_case_obj_eq` in the statement too, so both forms emit the same test. Every other arm keeps the call it had.

Also changes: the C of `test/binop_recv_root.rb`, whose case statement now takes `emit_case_obj_eq`. That function holds the arm in a rooted temporary, and the test is right under `SPINEL_GC_STRESS=2`, where master prints `:diff` for `:third`.

Not in this change: a boxed subject (`case list[0]` with `when na`), which both forms compare with `sp_poly_eq`, and an object kept by value, which has no identity to compare. The program above without its `p(na == Never.new(2))` line is that case: `Never` is then kept by value, and both forms print `none` on master and here.

Test: `test/case_when_same_object_statement.rb`, 9 lines; 3 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
