## What this changes

An attribute writer or a Struct member on a boxed receiver never ran a value that answers nil. It stored nil and dropped the call:

```ruby
class Node
  attr_accessor :name, :parent
  def initialize(n) = @name = n
end
def detach(nd)
  puts "detach #{nd.name}"
  nil
end
items = [Node.new("a"), Node.new("b")]
items.each { |nd| nd.parent = detach(nd) }   # CRuby: detach a, detach b. spinel: nothing
```

The receiver is boxed there because a block's parameter is; a `for` variable, a local read from a mixed Array, a boxed global, `x[0].v =` and `x&.v =` lost the value the same way, and so did `(bump; nil)`, `begin; bump; nil; end`, `(bump if c)`, a `case` with a nil arm and `(raise "boom" if c; nil)`, which never raised.

Both forms of the boxed writer dispatch wrote `sp_box_nil()` for any value typed nil. A value that is no nil literal is now emitted for its effects first, as the typed receiver's store already does. The receiver is still read before the value.

608 programs, one writer, receiver and value each: the 348 that were wrong on master are right, the 242 right ones are unchanged. The other 18 do not build on either: a hand-written `def v=` given such a value on a typed receiver (`void` local), another site, not in this change. `tools/cident.sh`: 6,334 corpus programs identical; the one that differs is the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
