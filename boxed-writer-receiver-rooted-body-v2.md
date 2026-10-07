<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A fix with a cost: a method whose only root is this one gains its root frame, 3 to 13 instructions a call in the cases measured below.

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

The temporary is now rooted, as the value form of the same writer roots it, unless nothing can allocate between the read and the store: the value is a literal, a variable or `self`, no String buffer, and of a type the store boxes without allocating. The list is of what cannot allocate, not of what can. An operator write allocates with no call written in it:

```ruby
sl = +"s"
mk("g").parent = (sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl += sl; sl)
```

173 programs, each at stress 0 and 2 (33 values, among them operator writes on a local, an element, an attribute and an instance variable, a Range stored into a boxed local, a call, an interpolation, an Array, the literals and variables; as a statement, in a loop, through `&.`, through `send(:parent=, v)`, in a method): 24 crash at stress 2 on the commit below and are right with this, 133 are right on both, 4 crash on both (next paragraph), and 12 are wrong on both: a sequence of operator writes on an attribute, an element or an instance variable that answers nil, a value the commit below still drops. `send` and a chained writer reach the same arm and are cured with it. The test is in `GC_STRESS_TESTS`.

**Not in this change.** A value that is a by-value struct (a Range, a Time, a Rational, a Complex, a value object) keeps master's C. The store boxes such a value behind a heap copy after it has taken the write barrier on the receiver, so a receiver that lives on would hold a copy the collector has not seen: `mk("a").name = (1..n)` is right on master at stress 2 and stops there ("the mark reached a freed slot") if the receiver is held. So `mk("a").parent = (churn; r)` with `r` a Range, which crashes at stress 2 on master, still does: the 4 above.

The cost, callgrind, 200,000 calls of `def set(nd, i); nd.parent = V; nil; end`, which has no other root: `i + 1` 6 instructions a call, `i > 3`, `i.to_f` and `(i if i > 3)` 3, two such statements 13. Where the method has a root frame already (`nd.parent = o.name`) the count does not rise. A value in the list above keeps its C.

`tools/cident.sh` against master: ten corpus tests gain the root (the receiver's temporary becomes a frame slot; their writer's value is a call, an operator write or a Regexp literal); no benchmark's C changes, nor optcarrot's.

This sits on the pull request that makes a nil-typed value run on a boxed receiver: the lines are the same, and its branch keeps the root it put there.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
