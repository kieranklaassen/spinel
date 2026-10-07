<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

An attribute writer on a boxed receiver, as a statement, reads the receiver into a temporary, runs the value and then stores. The temporary is not rooted: a value that allocates collects a receiver nothing else holds, and the store writes through the freed object.

```ruby
class Node
  attr_accessor :name, :parent
  def initialize(n) = @name = n
end
def churn
  a = []
  40.times { |i| a << ("s" + i.to_s) * 3 }
  a
end
def mk(n) = [Node.new(n), 1][0]
keep = []
mk("a").parent = churn.last
keep << "k1" * 5
p keep
```

Right in a plain run; with `SPINEL_GC_STRESS=2`:

```
*** SPINEL_GC_VERIFY: fault on the GC mark path (signal 11)
  phase = remembered
```

The temporary is now rooted when the value may allocate (`subtree_may_allocate`), as the value form of the same writer roots it. A value that cannot allocate keeps its C.

44 programs (eleven kinds of value; as a statement, in a loop, through `&.`, and a Struct member): 30 crash at stress 2 on master and are right with this, the other 14 are right on both. `send(:parent=, v)` and a chained writer reach the same arm and are cured with it. The test is in `GC_STRESS_TESTS`.

`tools/cident.sh`: seven corpus tests gain the root, their writer's value being a call (`self.right.left = self.left`; `subtree_may_allocate` counts every call); no benchmark's C changes, nor optcarrot's.

This sits on the pull request that makes a nil-typed value run on a boxed receiver: the lines are the same, and the root it put in its own branch is this one now.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
