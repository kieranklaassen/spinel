<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
class A
  def go
    r = []
    r << (yield 1)
    r << (yield 2)
    r
  end
end
class B < A
  def go
    f = Fiber.new do
      a = super() { |x| next 0 if x == 2; x * 10 }
      a
    end
    f.resume
  end
end
p B.new.go          # 0; CRuby prints [10, 0]
```

A `next` in the block given to `super` ended the Fiber.new, Thread.new or Enumerator.new block the `super` is written in. `subtree_owns_next` stops at the block of a call, but it walked through the block of a SuperNode or a ForwardingSuperNode and took the `next` for the body's own.

It now treats a super's block as a call's where the splice of that block into the parent's method is right today. Not changed, by choice, because the splice is wrong there in a plain method too and the body would only take that answer over: a parent that computes with the yield (an arm, a receiver, an operand), a parent that takes its block as a parameter, a block-local named like a variable around the super, a block that answers a Float, and a block whose last statement is a `begin` or a loop. Those keep the C they had.

One program goes from a raise to a build failure: `{ |x| next [] if x == 2; [x] }` given to a super in a Fiber or Enumerator body raised FiberError or StopIteration, and now does not build, as an ordinary call with that block does not build today.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A block's Float value beside a `next` keeps its fraction at the yield)
