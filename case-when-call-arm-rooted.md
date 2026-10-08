<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `when` arm that a call makes was freed while it was being compared, where the compare runs a `==` of the program.

Cost: an object arm that a call makes, of a class with its own `==`, pays 10 to 12 instructions a test for its root (tests of 106 and 202) in a program that ran right because that `==` never collected. The compiler holds no fact that a method cannot collect, so the root is not left out for one that does not.

```ruby
class Level
  attr_reader :n
  def initialize(n) = @n = n
  def ==(o)
    i = 0
    while i < 20000
      [Level.new(i + 100)]
      i += 1
    end
    o > @n
  end
end
def levels(i) = [Level.new(i)]
p(case [5] when levels(1) then :hit else :miss end)
```

Master (42557a3c) prints `:miss`. CRuby prints `:hit`.

`when levels(1)` beside an Array subject compares the two through `sp_poly_eq`, which calls the element's own `==`. The arm was the call's value, in no root. The method collected, the Array and its element were freed, and the next object of that size took the element's place.

The arm is now held in a rooted temporary at the three places that left it out: an Array or Hash arm beside an Array or Hash subject, and an object arm beside one (`emit_case_container_eq`); an object arm that falls to the boxed compare (`emit_case_obj_eq`). The two that pass the object itself take `emit_when_arm_root`; the one that passes it boxed roots the boxed value.

Left as it was, with the C unchanged:

- an arm that allocates nothing, and a literal Array or Hash (its own temporary holds it);
- an Array or Hash of Integers, Floats or Strings: the compare calls nothing of the program;
- an element read of an Array or Hash that a variable holds (`rows[i]`);
- an object arm of a class with no `==` or `<=>` that is no Struct: it compares by identity.

The cost, callgrind, instructions a test, master then this branch: an object arm beside an Integer subject 202 and 214; beside an Array subject 106 and 116; an Array arm of objects 784 and 786; a Hash arm 1,362 and 1,362; each arm of the list above the same on both.

Not here:

- An arm that arrives boxed (`when level_or_nil(i)`): `emit_when_boxed_test` holds it in a temporary of its own with no root.
- A boxed subject beside an object arm (`x = [5, "a"][0]`, then `case x when level(1)`) is compared as `x == arm`, not `arm === x`, on master. It still is.

The corpus's C changes in the new test and in two tests whose arm makes an object of a class with its own `==` or `<=>` (`test/binop_recv_root.rb`, `test/case_when_object_value_eq.rb`): each takes the root and prints what it printed.

Test: `test/case_when_call_arm_rooted.rb`, 20 lines; 6 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: # (the pull request whose last commit is "A `when` arm with an inherited == or === is passed as the class that defines it": this one calls its `emit_when_arm_root`)
