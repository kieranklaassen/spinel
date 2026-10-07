<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A cost first. In a program where a class has a `freeze` or `frozen?` of its own, every such call on a boxed value now takes the dispatch on the value's class before it reaches the builtin: three to seven instructions a call, by the loop around it and the compiler (callgrind, master 759d120f, a builtin value read from a mixed Array in a loop of 3,000,000: over five kinds of value a `frozen?` call costs 3.0 more with gcc and with clang and a `freeze` call 4.2 more with gcc and 1.0 fewer with clang; over an Integer and a String alone, `frozen?` 4.0 and 7.0, `freeze` 3.0 and 7.0). It is what master charges `dup`, `to_s` and `nil?` in the same program today (5.0, 5.0 and 1.5 instructions a call with gcc, 4.0, 4.1 and 2.4 with clang, on master 1df866be): the two arms now ask the question those arms ask, whether a class of the program defines the name. A boxed value carries no record of the classes it can hold, so there is nothing narrower to ask; a later change that gave one answer for every name master dispatches this way would repay all of them at once.

A class's own `freeze` and `frozen?` had two faults:

```ruby
class Cart
  def initialize = @items = [1, 2]
  def freeze
    @items.freeze
    super
  end
  def frozen? = super && @items.frozen?
end
c = Cart.new
c.freeze              # NoMethodError: super: no superclass method 'freeze'
p c.frozen?           # Ruby prints true

class Doc
  def initialize = @sealed = false
  def freeze
    @sealed = true
    self
  end
  def sealed = @sealed
end
d = Doc.new
row = [d, 5]
row[0].freeze
p d.sealed            # false; Ruby prints true
```

They are fixed together because each hides the other. Through a boxed value the override was never called, so a `freeze` that ends in `super` ran there by accident; calling it reaches the `super`, which raised. And once `super` answers the object, a call on a box of the object or nil is typed for the object, where the boxed line still made a boxed value, and a program that ran stops building. Either fix alone breaks a program that was right.

**The `super`.** In a `freeze` or `frozen?` override that no ancestor defines, `super` had no method to reach and was typed unknown, so `def frozen? = super` did not compile; `emit_super` answers Object's method for `initialize`, the copy hooks, `respond_to?` and `is_a?`, and these two names were not on its list. They are now: for an object of the class, `freeze` sets the frozen bit of the object's header and answers the object, `frozen?` reads the bit, which is what the call does on a class with no `freeze` of its own. It is taken only where the super hands nothing on (a bare `super` in a method with no parameters, or `super()`) and carries no block. The class is marked as one whose instances are frozen, as a bare `freeze` in one of its methods marks it, so a write to an instance variable of the frozen object raises FrozenError however the override was reached (by name, an alias, `send`).

**Through a box.** The boxed `freeze` arm called the builtin whatever class the value had, and the boxed `frozen?` arm read the header's bit and never asked the class. Both now stand down in a program where a class defines the name, as the `nil?` arm above the `freeze` line and the `dup` and `clone` arm below the `frozen?` line do (`user_defines_or_reads`). The call goes on to the dispatch on the value's class: the class's method runs for its objects, and every other value comes back to the same builtin arm.

They stand down only where that dispatch keeps the builtin for every other value (`poly_dispatch_keeps_builtin`, the test the dispatch's default arm makes). A box the analysis types by the class, as a local that holds the object or nil (`x = cond ? d : none`), has a slot typed for the class's answer, and the default arm declines there and raises NoMethodError for nil. For a `freeze` that answers the object the arm now stays, where every class's `freeze` answers that one type: the builtin's value is taken back into the slot by the checked unbox, nil as its NULL. Everywhere else the builtin line answers as it did, and where the call is typed for the object its value is taken back the same way: `y = x.freeze` on such a box did not compile, with or without an override in the program.

Not covered, as before: the same `super` in a reopened builtin class (`String`, `Object`), whose self is the value; one that passes arguments or a block (Ruby raises ArgumentError for the arguments; this does not build); an object laid out by value. And through a box typed by the class, where the builtin still answers: a `freeze` that answers something other than the object, and two classes whose `freeze` answer different types (master's dispatch does not build there for any method). A typed object's own `frozen?` that answers something other than true or false prints true or false.

Not in this change: six faults master has with no such `super` in the program, which a program that did not build, or died at the `super`, now runs on to meet. A frozen object's instance variable write does not raise when the method that writes belongs to another class of its chain than the one the freeze was seen on (an inherited `poke` called on a subclass object). `+=` on a member of a frozen Struct does not raise (`self.n += 1` after the `super`). A slot typed by the class that holds nil at run time (a local that is the object or nil, a local a block writes, an instance variable) runs the class's method with no object, and that is a crash where the method touches an instance variable. A `freeze` that writes one before its `super` is a segmentation fault on master with gcc (clang's build reached the `super` and raised) and here. A `frozen?` that reads one after its `super` (`def frozen? = super || @sealed`) raised NoMethodError at the `super` on master, or did not build; it now gets false from the `super` and reads through the null object: a segmentation fault with gcc, false with clang, where Ruby answers true for nil. `def frozen? = super` alone prints false there, and a `freeze` that only counts its calls counts one Ruby never makes. And through a box typed by one class beside a second class with a `freeze` of another type, `y = x.freeze` now builds and the builtin answers, as it does on master when the value is dropped. And a typed object's own `frozen?` that answers a Symbol prints true, in a program that did not build for a boxed call beside it. And a String that interpolates `x.frozen?` ahead of `x.freeze` (`"#{x.frozen?} #{x.freeze.class}"`) prints true for the first where Ruby prints false. For the first two the line is what master prints when the override has another name and a bare `freeze` stands where the `super` was; for the third, what master does with the `super` taken out (`self` in its place in the `freeze`, `false` in the `frozen?`: the same segmentation fault, the same false); for the fourth, what master prints for `y = x`; for the fifth, what master prints with the boxed call's value written in its place; for the sixth, what master prints with no override in the program at all.

Two of the three tests do not build on master and the third prints three wrong lines. No corpus program's generated C changes; optcarrot's is unchanged. A class whose override runs pays, on its instance variable stores, the frozen check a class with a bare `freeze` already pays (2.5 instructions a store under gcc, 4.5 under clang; callgrind); such a program raised before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
