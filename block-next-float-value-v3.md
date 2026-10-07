<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def twice
  r = []
  r << (yield 1)
  r << (yield 2)
  r
end
p twice { |x| next 1.5 if x == 2; 2.5 }   # [2.0, 1.0]; CRuby prints [2.5, 1.5]
```

A block that holds a `next` and answers a Float lost the fraction of its value at the yield. `emit_block_invoke` declares a slot for such a block's value, and the declaration had no arm for a Float, which fell to the `sp_int` arm.

The slot is an `sp_float` now where the block cannot leave with nil (its last expression and each `next` value are number literals, arithmetic on numbers, `to_f` of an Integer, or a conditional with an `else` of these), or where the method keeps the yield's value boxed.

Not changed, by choice: a block that can leave with nil (a bare `next`, `next nil`) where the yield's value is read as an unboxed Float keeps the C it had. A Float slot would hold that nil as the Float sentinel, which `to_f` and arithmetic on an unboxed Float do not look for: `v = yield 2; v.to_f + 1` under `{ |x| next nil if x == 2; 2.5 }` prints 1.0 today, as CRuby does, and would print nil.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
