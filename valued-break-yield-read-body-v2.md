<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class T
  def pair(a) = [1, yield(a)]
end
p T.new.pair(2) { |x| break 9 }    # 9
```

did not build, with gcc (`void value not ignored as it ought to be`) or with clang. So did `t += yield(a)` under such a block, and `yield(a) + 1`, `v = yield(a)` and `@v = yield(a)` where another site's block answers first. A block parameter called for its value, `def pair(a, &b) = [1, b.call(a)]`, did not build under such a block either, and now does.

The block is spliced where the yield stood. Its last statement leaves by a jump, so the statement expression had no value for the Array to read. `{ return v }` and `{ raise }` leave the same hole, and `emit_block_invoke` fills it with a value of the type the consumer wants that is never reached. A block whose last statement is `break` now takes that filler too.

Not in this change:

- `"<#{yield(a)}>"` under such a block still does not build: the interpolation reads the untyped yield as a boxed value, and the filler is an Integer.
- A `break` inside the last statement is still refused (`unsupported expression: BreakNode`), on master and here: `if c then break 9 else break 8 end`, `(break 9)`, `begin; break 9; end`, `x > 5 ? 1 : (break 9)`.
- `yield(a) || 5` under such a block still does not build where the breaking site is the only one or the first.
- A yield that is the receiver of a reader of the program's own class, `def use(a) = yield(a).x`, still does not build when a site whose block answers comes before the breaking one. With `v = yield(a); v.x` it is right.
- A method called first with a block that ends in `break` and then with one that answers has its yield typed from the first block, and the second call's value is lost: `def plus(a) = yield(a) + 1`, then `p plus(2) { |x| break 9 }` and `p plus(3) { |x| x * 2 }`, prints `9` and `nil` on master and here. With the two calls in the other order master did not build; here it prints `7` and `9`.

`tools/cident.sh` against c994071d2ded: 6399 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
