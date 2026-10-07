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

The value of the assignment is its right-hand side, not what the writer returns, so the call binds a value that is no literal or variable to a temporary and reads it back after the writer. A value of nil type made that temporary a `void` local. Such a value has nothing a temporary could hold: it now runs for its effect ahead of the call, where every other value runs into its temporary, and the call is handed a nil literal.

The receiver is read after the value. So the branch is taken only where that cannot change which object is written: the receiver is `self` or a variable the value cannot rebind, and the call is no `&.`. Every other receiver keeps master's C and still does not build: a call (`f(a).v = g`, `K.new.v = g`), and an instance variable or a global where the value calls a method, which may assign it. A boxed receiver takes another arm and has a pull request of its own.

The value is emitted outside the arm's own call, so a writer assignment in it answers its own right-hand side, also where a method that yields has the caller's block written into the value:

```ruby
def outer(a)
  a.v = show(yield)
  nil
end
outer(a) { b.v = 6 }     # show is handed 6, not what `def v=` returns
```

600 programs (five ways to write the writer, twelve places for the assignment, ten values): 360 did not build and are right; 125 do not build on master or here (the receiver is an instance variable or `K.new`, or the call is `&.`); 115 are right with master's C (a nil literal, a String).

576 with a block, a lambda or `map` in the value or in the receiver's call: 384 did not build and are right, 48 with the block in the receiver's call do not build on master or here, 144 are right with master's C.

1,136 with the assignment in a method that yields, the caller's block ending in a writer assignment or holding one (through `yield`, `blk.call`, an inner block, `each`, `while`, two methods deep, a class method, `initialize`, the block in the receiver's call) and with receivers the value rebinds: 609 did not build and are right, 198 do not build on master or here (a receiver outside the list above), 321 are right with master's C, 8 through `attr_writer` are wrong or crash on both with master's C (the receiver is read after a value that rebinds it; not this arm).

**Not in this change.**

- `x&.v = f`. Since "A &. call's block emitters wait for its nil guard" a `&.` call that answers nil and hoists a statement declares a `void` temporary of its own (`_snr`), with this change or without: `x&.say("hi")` to a method that ends in `puts` fails the same way.
- `a.v &&= f`, and `a.v ||= f` where the slot holds a value of another type, do not build ("void value not ignored as it ought to be").
- Two faults of master's are reached by programs that did not build. `[1, 2].map { |i| next 7 if i == 1; a.v = f }` gives `[7, 0]` for `[7, nil]`, as `a.v = nil` in that block does on master. Where another call types the writer's parameter as an object (`a.v = Pt.new("pt")`) and the writer calls a method on it (`puts x.name`), `a.v = f` ends in a segmentation fault for the NoMethodError, as `r = f; a.v = r` and an ordinary method (`a.set(f)`) do on master.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
