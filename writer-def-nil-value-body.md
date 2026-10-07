<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`obj.x = v` through a hand-written `def x=` did not build when `v` is an expression of nil type: a method that answers nil, `(bump; nil)`, `(bump if c)`. A nil literal and a variable built.

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

The value of the assignment is its right-hand side, not what the writer returns, so the call binds a value that is no literal or variable to a temporary and reads it back after the writer. A value of nil type made that temporary a `void` local. Such a value has nothing to read back: it is now handed to the writer as it is, run once, and the assignment answers nil as it does for a nil literal.

Not where the receiver or the value holds a writer assignment of its own (`a.v = yb { b.v = 6 }`, `a.v = b.v = f`). The call is emitted there with this arm switched off for what is inside it, so a block that ends in `b.v = 6` would answer what `def v=` returns, not 6. Those keep master's C and still do not build.

600 programs, one writer (its own, one that returns another value, one that stores nothing, a superclass's, a module's), receiver (a local, `self`, an instance variable, a parameter, `K.new`, `x&.v =`, in value position) and value each: 440 did not build and are right, 115 with a nil literal or a String have master's C, 45 through `x&.v =` do not build on master or here (below). 576 more with a block, a lambda or `map` in the value or in the receiver's call: the 108 with no writer assignment inside did not build and are right, the 324 with one keep master's C and do not build, 144 are right with master's C.

**Not in this change.**

- `x&.v = f`. Since "A &. call's block emitters wait for its nil guard" a `&.` call that answers nil and hoists a statement declares a `void` temporary of its own (`_snr`), with this change or without: `x&.say("hi")` to a method that ends in `puts` fails the same way.
- `a.v &&= f` does not build ("void value not ignored as it ought to be").
- Two faults of master's are reached by programs that did not build. `[1, 2].map { |i| next 7 if i == 1; a.v = f }` gives `[7, 0]` for `[7, nil]`, as `a.v = nil` in that block does on master. Where another call types the writer's parameter as an object (`a.v = Pt.new("pt")`) and the writer calls a method on it (`puts x.name`), `a.v = f` ends in a segmentation fault for the NoMethodError, as `r = f; a.v = r` and an ordinary method (`a.set(f)`) do on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
