<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

A `then` or `yield_self` the program defines is never called when it is given no block:

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

and `p t.then.n` does not build. With no block the two names made an Enumerator of the receiver whatever the receiver was, on a typed object and through a boxed value alike, while the call was typed by the method the class defines: dropped, the value hid the miss; used, it did not fit its slot.

The arm now stands down for an object whose class defines or reads the name, and for a boxed value beside such a class, as the dup and clone arm of the same function does. The call goes on to the class's method (a def, an alias, a `define_method`, a module's or a parent's method, an `attr_reader`, a Struct member, a singleton method), and every other value in the box still answers the Enumerator. A program with no `then` or `yield_self` of its own emits the C it did.

Not covered, as on master: called with a block, an object's own `then` still runs the block (`job.then { }`); `x.then(&blk)` raises NoMethodError on a value with no `then` of its own; a `then` only a subclass defines, called on the parent, does not build.

A program that calls its own `then` with no block and has one of those lines beside it did not build; it now builds, and that line prints what master prints for it once the blockless calls are taken out.

The test does not build on master. No corpus program's generated C changes; optcarrot's is unchanged. Beside a class with a `then` of its own, a blockless `then` on another value in a box costs four (clang) to six (gcc) instructions more a call, of about four hundred: the class switch in front of the Enumerator it still makes (callgrind).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
