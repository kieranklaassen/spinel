<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Shape
  attr_reader :area
  def initialize(side, &blk)
    @area = measure(side, &blk)
  end
  def measure(side) = yield(side)
end
class Square < Shape
  def initialize(side, &blk) = super(side, &blk)
end
p Square.new(3) { |n| n * n }.area    # nil; CRuby prints 9
```

The same through `super(...)`, a bare `super`, `super(a, &)`, a grandchild, and a method of an included module the class reaches by `super`. With the value in an Array literal (`@pair = [read(a, &), 1]`) the C did not build; as a condition the program was refused.

`yvt_forwarded_value` types what a block handed on to another method answers, from the call sites of the method that hands it on. A method the program reaches only through a child's `super` has no call site, so the value had no type and the store dropped it. It now asks `yield_value_type_via_super`, as the two sites in analyze_infer.c do. A method with a call site of its own never gets there.

It asks only where every `super` that lands on the method hands on the block its own method was given. Left as before: a child whose `super` carries a literal block that yields again (`def initialize(a) = super(a) { |q| yield q }`). That child raises LocalJumpError today whatever the parent does with the value, and a type there would turn a build failure into that raise.

This stands above the fix named below. A child `def initialize(a) = super` hands on the block `new` was given, and nothing holds that block while the object is allocated. Programs of that kind which this makes right would otherwise lose the block to a collection.

Cost: analysis only. At run time the one new thing is the store itself: where the value had no type the store was dropped, and it is now made with the value's own type.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A block handed to new is held for the call)
