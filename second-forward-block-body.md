<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
class Reader
  def each_row(n) = yield(n)
end
class Logged < Reader
  def each_row(...) = [super(...), note(...)]
  def note(n) = block_given? ? yield(n) : -1
end
class Loud < Reader
  def each_row(...) = [super(...), tell(...)]
  def tell(n) = yield(n)
end
p Logged.new.each_row(2) { |x| x * 3 }    # [6, 6]
p Loud.new.each_row(2) { |x| x * 3 }      # [6, 6]
```

The first answered `[6, -1]`, with no error; the second raised `no block given (yield)`.

A method whose `super(...)` reaches a parent that yields keeps its `...` and is inlined at the call, so that the site's block is spliced at the parent's `yield`. `emit_inline_call_x` chooses the block an inlined callee's yields run from the call's own block node, and takes the block the site runs under only for `inner(&)` and `inner(&b)`. `note(...)` has no block node, so it was inlined as a call with no block, beside a `super(...)` that was given it.

The forward now takes that block as `inner(&)` does: the site's literal block, or the proc the inline runs under.

Where the forward is left as it was, so that nothing that builds and runs right today stops:

- A block that can `break`.
- Where the callee reads the value of a yield, a block whose last statement has no C value when it is spliced as one. Such a splice does not build today, with the dots or without (`def h(a) = [1, yield(a)]` called `h(2) { |x| x += 1 while x < 9 }`), and a program whose block leaves by `throw`, `raise` or `return` before the forward is reached runs right today. The test names the endings that do have a value (a literal, a variable read or written, `&&`, `||`, `if`, `unless`, `case`, `begin`, a `yield`, an iterator whose value the splice carries, a plain call); any other ending is left.
- A callee with a default the forward would fill: the kept `...` binds by position.
- The method's own proc form, which a site reaches by dispatch or with `&pr`, unless every literal block the program hands a method of that name is taken. It serves every site, and forwarding in it alone would build a program that did not build into a site's `LocalJumpError`.

Two things to know:

- For a plain call the test is measured, not proven. A call has a value unless its statement form is void, and six such are named (`srand`, `rand`, `concat`, `insert`, `replace`, `[]=`): the calls with no block of their own that do not build among 141 call endings tried. A void call that is not named, ending a block that always leaves before the forward, would stop building. The tests go when such a splice builds.
- A forward that raised now runs on, and shows two faults the raise hid. A call whose block breaks, beside one whose block does not, loses the super's own value at the other: `Loud` above, called with `{ |x| break 9 }` and then `{ |x| x * 3 }`, printed `9` and raised; here it prints `9` and `[nil, 6]`. The nil is master's: `Logged`, whose forward does not raise, prints `9` and `[nil, -1]` there. And a block that ends in `x => y` answers `x` where CRuby answers nil, as it does on master under any `yield` (`def h(a) = yield(a)` called `h(2) { |x| x => y }`).

`tools/cident.sh` against 5c78f07e5906: 6414 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
