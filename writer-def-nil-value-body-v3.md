<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`obj.x = v` through a hand-written `def x=` did not build when `v` is a call or a sequence of nil type: a method that answers nil, `(bump; nil)`, `(bump if c)`, `(nil)`. A bare `nil` and a variable built.

```ruby
class Node
  def initialize(n) = @name = n
  def parent=(x)
    @parent = x
  end
end
def detach(nd)
  puts "detach"
  nil
end
a = Node.new("a")
a.parent = detach(a)     # error: variable or field 'lv___sv2' declared void
```

The value of the assignment is its right-hand side, not what the writer returns, so the call binds a value that is no literal or variable to a temporary and reads it back after the writer. A value of nil type made that temporary a `void` local. Such a value has nothing a temporary could hold: it now runs for its effect ahead of the call, where every other value runs into its temporary, and the call is handed a nil literal.

The receiver comes first, as in CRuby. One that is not `self` is read into a temporary of its own ahead of the value, rooted while a value that may allocate runs, and the call reads it there. So a value that gives the variable another object still writes to the first one, however it does it (`a.v = (a = b; nil)`, an interpolation whose `to_s` assigns `a`, a writer in a multiple assignment), and a receiver nothing else holds (`fresh.v = churn`) is not collected under its value. Against `f; a.v = nil` written by hand the held receiver costs 11 instructions a store (callgrind, 200,000 stores in a loop).

The value is emitted outside the arm's own call, so a writer assignment in it answers its own right-hand side, also where a method that yields has the caller's block written into the value:

```ruby
def outer(a)
  a.v = show(yield)
  nil
end
outer(a) { b.v = 6 }     # show is handed 6, not what `def v=` returns
```

No program that builds on master changes its C: every changed program has the `void` local in master's C.

600 programs (five ways to write the writer, twelve places for the assignment, ten values): 440 did not build and are right; 45 with `&.` do not build on master or here; 115 are right with master's C (a nil literal, a String).

576 with a block, a lambda or `map` in the value or in the receiver's call: 432 did not build and are right, 144 are right with master's C.

704 with the assignment in a method that yields, the caller's block ending in a writer assignment or holding one (through `yield`, `blk.call`, an inner block, `each`, `while`, two methods deep, a class method, `initialize`, the block in the receiver's call) and with receivers the value rebinds: 501 did not build and are right, 18 with `&.` do not build on master or here, 177 are right with master's C, 8 through `attr_writer` are wrong or crash on both with master's C (not this arm). 432 more of the same kind from a second generator: 288 did not build and are right, 144 are right with master's C.

234 where the value gives the receiver's variable another object (a local, an instance variable, a global, a class variable, a call's answer and a fresh object as the receiver; by an assignment, a block, a lambda, a method, and by the methods Ruby calls itself: `to_s` in an interpolation and in `puts`, `===` in a `when`, a writer in a multiple assignment and in `o[0] += 1`; as a statement, an argument and a value): 216 did not build and write to the object CRuby writes to; 18 whose value holds `o.n ||= 1` do not build on master or here (below).

**Not in this change.**

- The same assignment with a value of another type: `a.v = (a = b; 3)` writes to `b` on master and here, where CRuby writes to the first object. Of the 234 typed twins of the last set 183 are wrong on both with master's C. That arm reads its receiver after the value; this one no longer does.
- `x&.v = f`. Since "A &. call's block emitters wait for its nil guard" a `&.` call that answers nil and hoists a statement declares a `void` temporary of its own (`_snr`), with this change or without: `x&.say("hi")` to a method that ends in `puts` fails the same way.
- A receiver of a class held by value is left as it is, since a temporary would be a copy; no program here reaches it.
- `a.v &&= f`, and `a.v ||= f` where the slot holds a value of another type, do not build ("void value not ignored as it ought to be").
- `p(a.v = f)` where another call types the writer's parameter as an object still does not build, as `p(a.v = nil)` does not on master.
- Two faults of master's are reached by programs that did not build. `[1, 2].map { |i| next 7 if i == 1; a.v = f }` gives `[7, 0]` for `[7, nil]`, as `a.v = nil` in that block does on master. Where another call types the writer's parameter as an object (`a.v = Pt.new("pt")`) and the writer calls a method on it (`puts x.name`), `a.v = f` ends in a segmentation fault for the NoMethodError, as `r = f; a.v = r` and an ordinary method (`a.set(f)`) do on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
