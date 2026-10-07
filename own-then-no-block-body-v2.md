<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

One program that was right pays: beside a class with a `then` of its own, a blockless `then` on another value in a box still makes the Enumerator, behind the class switch. Callgrind, an Integer in the box, the value dropped: `v.then` in a `while` loop, 5.0 instructions a call more with gcc and 4.0 with clang, of 387; with the value read from an Array each turn, 6.0 and 4.0, of 400.

A `then` or `yield_self` the program defines, called with no block, is answered by the builtin:

```ruby
class Tally
  def initialize = @n = 0
  def then
    @n += 1
    self
  end
  def n = @n
end
t = Tally.new
t.then
p t.n                 # 0; Ruby prints 1
```

and `p t.then.n` does not build. With no block the arm for the two names made an Enumerator of the receiver, on a typed object and through a boxed value alike, without asking whether the receiver's class defines the name, while the call was typed by that method: dropped, the value hid the miss; used, it did not fit its slot.

The arm now stands down where the receiver is the class's object and cannot be nil as written: `X.new`, a local every write of which is `X.new`, a local read behind a truthiness guard of it (`if t`, `t && t.then`), and the `&.` form. It stands down too for a boxed value beside a class that defines or reads the name, where the class switch sends nil and every other value to the Enumerator as before. The call goes on to the class's method (a def, an alias, a `define_method`, a module's or a parent's method, an `attr_reader`, a Struct member, a singleton method), as a user-defined dup or clone already does. A program with no `then` or `yield_self` of its own emits the C it did.

nil answers Kernel's `then`, so a receiver typed as the class that may hold nil keeps the code it had. The nil analysis is asked, but not alone: it takes a builtin iteration's block parameter as not nil without proof, and a hole in a typed Array reaches one.

Not covered, as on master:

- a receiver typed as the class and not proved an object as above: the builtin answers. Dropped, the method does not run; used, the program does not build, or where C lets the Enumerator through it is printed as the object (`p s.then.then`). With `Tally` as above, each of these prints 0 where Ruby prints 1, here and on master:

  ```ruby
  def run(t)                       # a parameter
    t.then
    nil
  end
  t = Tally.new
  run(t)
  p t.n

  class Desk                       # an ivar
    def initialize = @t = Tally.new
    def run
      @t.then
      @t.n
    end
  end
  p Desk.new.run

  $t = Tally.new                   # a method's value
  def make = $t
  make.then
  p $t.n

  ts = [Tally.new, Tally.new]      # a block parameter
  ts.map { |t| t.then; 1 }
  p ts[0].n
  ```

  So do a constant, a global, `self` and a local copied from another local;
- called with a block, an object's own `then` runs the block (`job.then { }`);
- `x.then(&blk)` raises NoMethodError on a value with no `then` of its own;
- a `then` only a subclass defines, called with the value used on a receiver typed as the parent, does not build.

Master builds few programs that use the value of a blockless call to their own `then` (one whose method answers nil builds). Where such a program builds for the first time, three kinds of line beside that call run for the first time too, and print what master prints for them once the blockless calls are taken out, which is not Ruby's line: a block given to an object with its own `then` (the block's value; Ruby calls the method); `x.then(&blk)` (NoMethodError; Ruby answers the block's value); a block given where only the child defines `then` (the block's value again). Where such a line does not build by itself, the program still does not build.

The test does not build on master. No corpus program's generated C changes; optcarrot's is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
