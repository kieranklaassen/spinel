<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

The receiver is boxed there because a block's parameter is; a `for` variable, a local read from a mixed Array, a boxed global, `x[0].v =` and `x&.v =` on a receiver that is not nil lost the value the same way, and so did `(bump; nil)`, `begin; bump; nil; end`, `(bump if c)`, a `case` with a nil arm and `(raise "boom" if c; nil)`, which never raised.

Both forms of the boxed writer dispatch wrote `sp_box_nil()` for any value typed nil. A value that is no nil literal is now emitted for its effects first, as the typed receiver's store already does. The receiver is still read before the value, and the statement form holds it in a rooted temporary while the value runs: a value that allocates would collect a receiver nothing else holds (`mk("a").parent = churn`, in the test; a segmentation fault at `SPINEL_GC_STRESS=2` without the root). The value form has the root already.

608 programs, one writer, receiver and value each: the 348 that were wrong on master are right; of the 242 right ones 218 have master's C and 24, whose value is `(nil)` in parentheses, emit it for its effects as any other value. The other 18 do not build on either: a hand-written `def v=` given such a value on a typed receiver (a `void` local), another site, not in this change.

**Not in this change.** `nd&.parent = (bump; nil)` on a boxed nil raises NoMethodError on master and here, where CRuby skips the call; `bump` now runs before the raise.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
