<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A class that freezes its parts and then itself raises at the `super`:

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
```

and `def frozen? = super` does not compile. `super` in a `freeze` or `frozen?` override that no ancestor defines had no method to reach and was typed unknown; `emit_super` answers Object's method for `initialize`, the copy hooks, `respond_to?` and `is_a?`, and these two names were not on its list.

They are now: for an object of the class, `freeze` sets the frozen bit of the object's header and answers the object, `frozen?` reads the bit, which is what the call does on a class with no `freeze` of its own. It is taken only where the super hands nothing on (a bare `super` in a method with no parameters, or `super()`) and carries no block. The class is marked as one whose instances are frozen, as a bare `freeze` in one of its methods marks it, so a write to an instance variable of the frozen object raises FrozenError however the override was reached (by name, an alias, `send`). A program that defines such an override and never names it emits the C it did.

Not covered, as before: the same `super` in a reopened builtin class (`String`, `Object`), whose self is the value; one that passes arguments or a block (Ruby raises ArgumentError for the arguments; this does not build); an object laid out by value.

A program that did not build, or died at the `super`, now runs on, and may then meet one of six faults master has with no such override in the program. A frozen object's instance variable write does not raise when the method that writes belongs to another class of its chain than the one the freeze was seen on (an inherited `poke` called on a subclass object). `+=` on a member of a frozen Struct does not raise (`self.n += 1` after the `super`). A String that interpolates `x.frozen?` ahead of `x.freeze` (`"#{x.frozen?} #{x.freeze.class}"`) prints true for the first where Ruby prints false. Through a boxed value the class's own `freeze` is not called (`[c].each(&:freeze)`). A `case x.frozen?` whose first arm is `when nil` takes that arm for false. And a slot typed by the class that holds nil at run time (a local that is the object or nil, a parameter, an instance variable) runs the class's method with no object, which is a crash where the method touches an instance variable: a `freeze` that writes one before its `super` is a segmentation fault on master with gcc (clang's build reached the `super` and raised) and here; a `frozen?` that reads one after its `super` (`def frozen? = super || @sealed`) now gets false from the `super` and reads through the null object, a segmentation fault with gcc and false with clang, where Ruby answers true for nil; `def frozen? = super` alone prints false there, and a `freeze` that only counts its calls counts one Ruby never makes. For the first three the line is what master prints when the override has another name and a bare `freeze` stands where the `super` was (`def seal; freeze; self.n += 1; end`); for the other three, what master does for the same program once the `super` is taken out (`self` in its place in the `freeze`, `false` in the `frozen?`: the same segmentation fault, the same false).

The test does not build on master. No corpus program's generated C changes; optcarrot's is unchanged. No program that runs on master changes its path. A class whose override runs pays, on its instance variable stores, the frozen check a class with a bare `freeze` already pays (2.5 instructions a store under gcc, 4.5 under clang; callgrind); such a program raised before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
