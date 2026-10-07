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
  def initialize(side) = super(side) { |n| yield n }
end
p Square.new(3) { |n| n * n }.area    # no block given (yield) (LocalJumpError); CRuby prints 9
```

The same where the parent wraps the block in one of its own (`pass(a) { |z| yield z }`), and through three classes whatever the parent does. With the value in an Array literal the C did not build; as a condition the program was refused.

A literal block of an inlined call is recorded as yielding to the block current at its call site (the yield-target entries), so its own `yield` is found from however deep it runs. The inliner of a `super` and the one of a constructor whose initialize yields recorded none. Once the parent handed the block on through another inlined call, that call found no entry, took the block as its own fallback, and the `yield` inside it had no block. Both now record the block they make current, as emit_inline_call_x does.

The first commit moves that push, its pop and the test for a forwarded block out of emit_inline_call_x into three small functions, so the two other inliners call them. It changes no emitted C (`tools/cident.sh`: 0 differ).

With the block found, the value the parent's forwarding call answers needs its type, or the store drops it and the program prints nil. So the test that lets yvt_forwarded_value ask the super route also takes a `super` that writes a block. That is why this stands above the fix named below.

Not here: the same `super` in an ordinary method is refused as before (a block written in a proc-form method does not capture the method's own block).

Cost: none for a program that built and ran before. The entries are kept while compiling, and every test in the corpus but this one's compiles to the same C.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A forwarded block's value reaches a method called only by `super`)
