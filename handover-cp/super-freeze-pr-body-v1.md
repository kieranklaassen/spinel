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

A program that did not build, or died at the `super`, now runs on, and may then meet one of two faults master has with no override in the program at all: a frozen object's instance variable write does not raise when the method that writes belongs to another class of its chain than the one the freeze was seen on (an inherited `poke` called on a subclass object), and through a boxed value the class's own `freeze` is not called. Such a line prints what master prints for the same program once the `super` is taken out.

The test does not build on master. No corpus program's generated C changes; optcarrot's is unchanged. No program that runs on master changes its path. A class whose override runs pays, on its instance variable stores, the frozen check a class with a bare `freeze` already pays (2.5 instructions a store under gcc, 4.5 under clang; callgrind); such a program raised before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
