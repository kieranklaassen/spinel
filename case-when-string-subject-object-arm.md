<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `case` on a String never asked an object arm its `===`.

```ruby
class Prefix
  attr_accessor :s
  def initialize(s) = @s = s
  def ===(o) = o.start_with?(@s)
end
case "abc"
when Prefix.new("ab") then puts "hit"
else puts "miss"
end
```

Master (a3941433) prints `miss`. CRuby prints `hit`. With `case ["abc"]` and `o[0].start_with?(@s)` master prints `hit`.

The String arm of `when` answers false for every arm that is not a String, and it stood before the object arm's own `===` was asked. An Array or a Hash subject already asks such an arm (`emit_case_container_eq`); a String subject now does too, in `emit_when_str_obj_eq`, called from `emit_when_typed_test` so the statement and the case value share it. It calls the method where its one parameter is boxed or a String and it answers a boolean, roots the arm across the call, and lets a nil arm match only a nil subject. A class with `==` and no `===` is asked its `==`, which is what `Object#===` calls.

Cost: one call where a constant false stood. No program of the corpus changes its C.

Not in this change: an arm of a small read-only class kept by value, a method whose parameter a call written out typed as something other than a String, an optional or rest parameter and an answer that is no boolean keep the answer they had.

Test: `test/case_when_string_subject_object_arm.rb`, 15 lines; 7 of them fail on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
