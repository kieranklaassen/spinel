<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Cost: compile time, in a program this makes right. 250 subclasses whose `initialize` reaches one parent by `super` compile in 10.4 billion instructions where the build that printed nil took 3.2 (each `super` that lands on the parent is asked for its sites). A program whose C does not change compiles as before: 1.00 and 1.00 times on two programs of 250 classes.

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

The same through `super(...)`, a bare `super`, `super(a, &)`, a grandchild, and a method of an included module that the class's own method reaches by `super`. With the value in an Array literal (`@pair = [read(a, &), 1]`) the C did not build; as a condition the program was refused.

`yvt_forwarded_value` types what a block handed on to another method answers, from the call sites of the method that hands it on. A method the program reaches only through a child's `super` has no call site, so the value had no type and the store dropped it. It now asks `yield_value_type_via_super`, as the two sites in analyze_infer.c do, and for every site of the children as it does for a method's own: where their blocks answer different types (`Square.new(2) { true }` beside `Square.new(3) { "t" }`) the value is poly and each site keeps its own.

It asks only for a method that is spliced into the methods that reach it and nothing else: an `initialize`, or the copy a module left beneath the class's own method. A method that another class of its chain defines too (`def run(a, &b) = super(a, &b)` over a parent's `run`) is given a proc form, its forwarded value is poly through that, and it is right today: its C is unchanged. So is that of a method with a call site of its own.

It asks only where every `super` that lands on the method hands on the block its own method was given. Left as before: a child whose `super` carries a literal block that yields again (`def initialize(a) = super(a) { |q| yield q }`). That child raises LocalJumpError today whatever the parent does with the value, and a type there would turn a build failure into that raise.

This stands above the fix named below. A child `def initialize(a) = super` hands on the block `new` was given, and nothing holds that block while the object is allocated: without that fix the test here aborts under `SPINEL_GC_STRESS=2`.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A block handed to new is held for the call)
