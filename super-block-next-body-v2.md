<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

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

After: `[10, 0]`.

A `next` in the block given to `super` ended the Fiber.new, Thread.new or Enumerator.new block the `super` is written in, with `super()`, `super(n)` and a bare `super`. The program did not build before #7141; since then it builds and answers wrongly.

How: `subtree_owns_next` says whether a `next` is such a body's own. The walk stops at the block of a call and went through the block of a SuperNode and of a ForwardingSuperNode. It now treats a super's block as a call's, for that one `next`, where the splice of the block into the method the super lands on is right today: the method carries every yield whole (a statement, its last statement, the value written to a local, an element of an Array literal, the argument of `<<`), the block has no parameter or block-local named like a variable around it, the block does not answer a Float, and its last statement is not a `begin` or a loop: `while`, `until`, their modifier forms (`i += 1 until i > 2`) and `begin ... end while`. The walk's other form, which asks about any `next` and is read by the blocks that are run in place (a tap block, the block of a yielding method, Array.new's and delete's), answers as before: a program with no super in a Fiber, Thread or Enumerator body compiles to the C it had. `test/block_next_beside_super_block.rb` holds those blocks around a super with a block, and its C is the same before and after.

Left as before, with the same C, because master's splice is wrong there in a plain method too and the body would only take that answer over:

```ruby
def arm(n = 2) = n > 0 ? yield(n) : 5                  # the parent computes with the yield: an arm, a receiver, an operand, `return yield(n)`
a = super() { |x; v| v = x * 2; next if x == 2; v }    # v is a variable around the super too, and the splice writes it
a = super() { |x| next 1.5 if x == 2; 2.5 }            # a Float: [2.0, 1.0] in a plain method; CRuby [2.5, 1.5]
a = super() { |x| begin; next 0 if x == 2; x * 10; end }   # a `begin` or a loop last: [nil, 0] in a plain method, for an ordinary call's block too; CRuby [10, 0]
```

and a super into a method that takes its block as a parameter. Every block whose last statement is a loop is left out with these, one that is right in a plain method today too (a `while` that answers nil, `begin ... end while`, a trailing `until`). In a Fiber, Thread or Enumerator body these still end the body at the `next`: the answer is right where the `next` is the body's last act (`Fiber.new { super() { |x| next :n if x == 2; :s } }.resume` into `arm` prints `:n`), and it is 0, `[]`, StopIteration or FiberError, as today, where it is not.

A parent that ends in an explicit `return` (`return r`) raises LocalJumpError in such a body, as the same super without a `next` does on master.

One program of that kind goes from a raise to a build failure: a block `{ |x| next [] if x == 2; [x] }` given to a super in a Fiber or Enumerator body raised FiberError or StopIteration and now does not build, as an ordinary call with that block in a plain method does not build today.

Generated C against master fa08b100 (`make cident`): 6,112 programs identical, 1 differs (`test/fiber_block_next_in_super_block.rb`), no refusal changes. optcarrot's C is identical.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
