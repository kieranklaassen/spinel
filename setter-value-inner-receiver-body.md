<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`obj.x = v` answers `v`, whatever a hand-written `def x=` returns. Written inside the receiver of another such assignment, in a block of the receiver's call, it answered what the writer returns:

```ruby
class Job
  attr_reader :state, :owner
  def initialize = @state = :new
  def state=(s)
    @state = s
    @log = "state #{s}"
  end
  def owner=(o)
    @owner = o
    @log = "owner #{o}"
  end
end
def claim(job)
  tag = yield
  puts "claimed for #{tag}"
  job
end
a = Job.new
b = Job.new
claim(a) { b.owner = "kai" }.state = :taken
p a.state, b.owner
```

```
spinel diff: output-diff
  program: job.rb
  ruby:    exit 0
  spinel:  exit 0

--- stdout (ruby)
+++ stdout (spinel)
@@ -1,3 +1,3 @@
-claimed for kai
+claimed for owner kai
 :taken
 "kai"
```

The arm that makes the assignment answer its right-hand side emits the call itself with `g_setter_value_inner` raised, so that the call is not wrapped a second time. The counter switched the arm off for every writer assignment emitted meanwhile, and those are the ones written in a block or an argument of the receiver's call. The emission now also keeps the node it is for (`g_setter_value_node`); a writer assignment written inside that node is another assignment and keeps its arm. The counter stays, since the emission may go through a copy of the node.

1,332 programs (a writer that answers 42, nil, or a generated one; the receiver's call taking a block by `yield`, by `&blk`, a lambda's call or a `map` in its argument; nine bodies; three values; as a statement, a local, an argument and a method's last expression), against the commit below this one: 56 were wrong and are right, 56 did not build (the inner writer answers nil, a `void` in a slot) and are right, 1,033 have that commit's C, 184 are right on both. 3 through `attr_writer` are wrong on both: the attribute store's own order, named in the pull request below.

**Not in this change.** `K.cv = 3` through `def self.cv=` and `i[1] = 3` through `def []=` answer what the method returns, in any position: `p(K.cv = 3)` prints the method's last expression.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
