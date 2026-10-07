<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class Record
  def initialize(n) = @n = n
  def instance_variable_get(name) = "get #{name} of #{@n}"
end
p Record.new(3).instance_variable_get(:@n)   # "get @n of 3" in CRuby
```

prints 3 on master: on a typed object the call is lowered to a read of the field, and the class's method never runs. An own `instance_variable_set` writes the field, an own `instance_variable_defined?` is answered from the layout, an own `instance_variables` lists the slots, an own `remove_instance_variable` answers the field, and on a Struct the set is refused.

The lowerings now stand down where the receiver's class has a method of the name in its chain: in the inference (`infer_object_call` for get, set and remove, `infer_call_inner` for the other two) and in the emitter (`emit_object_ivar_call`, `emit_call_display_ivar_arms`, `emit_object_call`'s list and its remove arm). Each is one `comp_method_in_chain(...) < 0` on the arm's condition, so a class with none of the five names takes the lowering it always took.

Not in this change: a boxed receiver takes the builtin.

`test/own_ivar_reflection_methods.rb` prints 26 lines; 18 differ on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
