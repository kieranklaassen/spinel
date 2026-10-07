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

The forward now takes that block where all of these hold. Any other forward keeps its C, and its raise:

- The callee reaches its block by a `yield` of its own and by nothing else: no block parameter, no `&` or `...` argument, no `super`.
- The block holds no `break`.
- Where the callee reads what a `yield` answers, the block's last statement is one that has a C value by construction: a literal (Integer, Float, String, Symbol, `true`, `false`, `nil`), a local or instance variable, an Array literal of these, or `+`, `-`, `*`, `<`, `>`, `<=`, `>=`, `==` between two of these that are Integer, Float or boxed, in a program with no operator of that name of its own. Where the callee only runs the block, the block is spliced as a statement and any last statement is taken.
- The callee has no default in a slot the forward would fill: the kept `...` binds by position.
- In the method's proc form, which serves every call that finds the method at run time: every literal block the program hands a method of that name passes the tests above.

The test has a section for each of the five, a program that leaves before its forward is reached and prints the same as before.

Not in this change:

- `def asked(n) = block_given?` and `def call_it(n, &b) = b.call(n)` beside the `super(...)` still see no block.
- A block that ends in a call (`x.to_s`), under a callee that reads it, still raises `no block given (yield)`.

To know: a forward that raised now runs on, and where master has another fault on that road the program prints that fault's answer where it raised. Each is master's own and shows there without this change:

- The super's own value is nil in `[super(...), tell(...)]` when another call of the method has a block that breaks, when the method is named `each`, and when the call is a subclass's `super(n) { ... }`: `[nil, 6]` for `[6, 6]`. Master prints the same with `def tell(n) = block_given? ? yield(n) : 6`.
- The callee's count is not judged through `...`: `def tell(n, k)` runs where CRuby raises `wrong number of arguments`, as it does on master with a `block_given?` arm.
- Under a callee that only runs the block, the parent's `yield` answers `x` for a block that ends in `x => y`, and nil for one that ends in `begin; next 3 if x > 5; x; end` or in `Array.new`. `def m(a) = yield(a)` called with those blocks answers the same on master.
- `yield(n) * 2.5` answers nil where the block answers `true`, `false`, `nil` or a Symbol and CRuby raises NoMethodError. `def h(a) = yield(a) * 2.5` called `h(2) { |x| x == 2 }` prints nil on master.

Cost: a program that is right today, whose callee is `yield(n) if block_given?`, now runs the block there as CRuby does. 200,000 calls of it with `{ |x| x * 3 }`: 7,068,084 Ir to 19,870,539 under callgrind, 64 Ir a call, the block's second run on a boxed parameter.

`tools/cident.sh` against 8dc5522541bb: 6447 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
