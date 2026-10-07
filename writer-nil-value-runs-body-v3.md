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

Both forms of the boxed writer dispatch wrote `sp_box_nil()` for any value typed nil. A value that is no nil literal is now emitted for its effects first, `((void)(value), sp_box_nil())`, where this place is known to emit it (`boxed_writer_nil_value_runs`): every node of the value is a literal, a variable read, a write to a local or a global, a call with its arguments and its block, a sequence, `begin` with `ensure`, `if`, `unless`, `case`, `&&`, `||`, `while` or `until`. The list is of what emits. A rescue modifier over a call of nil type (`quiet rescue nil`), an instance-variable write at top level and a `yield` whose block holds a boxed writer do not build when emitted here, so those and every kind not listed keep the plain nil, as on master.

Where the value runs, the receiver is read first and held in a rooted temporary: a value that allocates would collect a receiver nothing else holds (`mk("a").parent = churn`, in the test; a segmentation fault at `SPINEL_GC_STRESS=2` without the root; the value form has the root already). What the value hoists, a block's loop or an argument of nil type, runs with it: after the receiver and, in a `&.` statement, only where the receiver is not nil.

1,492 programs that print what ran (46 values; 16 places for the assignment; an `attr_accessor` and a Struct member; and a method that yields, the caller's block in the value):

| on master | with this | programs |
|---|---|---|
| wrong | right | 814 |
| right | right, master's C byte for byte | 264 |
| right | right | 88 |
| wrong | wrong, master's C byte for byte | 256 |
| wrong | wrong | 64 |
| does not build | does not build, master's C | 6 |

Of the 88, 64 are `p(x&.v = value)` on a boxed nil, where the value is emitted and does not run, and 24 have `(nil)` in parentheses, emitted for its effects as any other value. The 256 keep master's C: a value outside the list is still dropped (228), so is one that holds `yield` (16), and `x&.v = nil` as a statement on a boxed nil raises (12). The 64 are that statement with a value that now waits for the receiver's tag; they raise as before. The 6 are a lambda whose body assigns a rescue modifier or an instance-variable write, which does not build on master.

**Not in this change.**

- A value outside the list is still dropped: a rescue modifier, `begin` with `rescue`, an instance-variable write, `||=`, a multiple assignment, a lambda, a block that holds `break` or `next`, an operator write to an attribute, an element or an instance variable (`(o.name += "x"; nil)`), and a value that holds `yield`. `w.v = x.v = (quiet rescue nil)` drops the inner assignment with it and leaves `x.v` as it was.
- `nd&.parent = v` as a statement on a boxed nil raises NoMethodError on master and here, where CRuby skips the call. The value does not run before the raise.
- A value of another type leaves the statement's temporary unrooted: `mk("a").parent = churn.last` faults at `SPINEL_GC_STRESS=2`, on master and here.
- A receiver whose classes have a generated writer and a hand-written `def v=`: `x2.v = x.v = bump` stored nil without running `bump` and now runs it and raises NoMethodError, as `y = (x.v = bump)` raises there on master.
- A hand-written `def v=` on a typed receiver given such a value does not build (a `void` local); that is another arm.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
