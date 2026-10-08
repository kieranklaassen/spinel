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

Compile time: what the calls of a name say is read once for each forwarded name, not once for each forward at each site. Instructions to compile to C under callgrind, for S calls of one name with a block and F classes that forward: +3.0% at 600 and 20 (7,179,670,480 to 7,393,364,247), +1.1% at 600 and 200, +2.0% at 2,000 and 200. At 600 and 20 the conditions themselves are under 20 million of the 214 million more; the rest is the block emitted at each forward.

A method whose `super(...)` reaches a parent that yields keeps its `...` and is inlined at the call, so that the site's block is spliced at the parent's `yield`. `emit_inline_call_x` chooses the block an inlined callee's yields run from the call's own block node, and takes the block the site runs under only for `inner(&)` and `inner(&b)`. `note(...)` has no block node, so it was inlined as a call with no block, beside a `super(...)` that was given it.

The forward now takes that block where each of these conditions holds. Any other forward keeps its C:

- The callee runs its block by a `yield` in its own body and hands it on nowhere: no block parameter, no `&` or `...` argument, no `super`, no parameter default that reaches the block (`def tell(n, k = yield(n))`), and no `yield` under a block or lambda of its own (`Hash.new { |h, k| yield(k) }`, `[n].each { |v| yield(v) }`), which can be a C function of its own where the site's block is not in reach.
- The block holds no `break`, a loop's inside it included.
- Where the callee reads what a `yield` answers, the block's last statement is one of a short list: a literal (Integer, Float, String, Symbol, `true`, `false`, `nil`), a local or instance variable, an Array literal of these, or `+`, `-`, `*`, `<`, `>`, `<=`, `>=`, `==` between two of these that are Integer, Float or boxed; with a boxed operand, only in a program with no operator of that name of its own. Where the callee only runs the block, the block is spliced as a statement and its last statement is not asked about.
- The callee is handed exactly what the `...` carries. The forward binds the forwarder's slots to the callee by position and judges no count, so a callee CRuby would refuse runs on, and with the block it would run the block too. So the callee takes as many required parameters as the forwarder has slots and no other parameter; the forwarder names no parameter of its own and no call hands it a key; every call of its name, and every `super` in a method of that name, writes out that many arguments; the program names the method by no Symbol (`send`, `alias_method`); and the forwarder is not `initialize`, which `new` calls.
- In the method's proc form, which serves every call that finds the method at run time: every literal block the program hands a method of that name meets the two conditions on the block.

Each forward left as it was is master's C byte for byte. What is cured is narrow: a callee of exactly the forwarded parameters that yields in its own body, under a block that ends in a literal, a local, an instance variable, an Array of those or one of the eight operators over them, or under any block where the callee does not read the yield. Measured on 9,487 generated programs of these shapes: 1,960 that raised, printed a wrong line or did not build print CRuby's lines, the 4,691 that were right stay right, and 15 that raised or did not build print one of the answers under "To know". What is given up is every other ending under a callee that reads the yield (a call such as `x.to_s`, an `if`, a `case`, `&&`, a ternary, a Hash, a Range, an interpolated String, a constant) and every callee the first and fourth conditions turn away.

The test file has a section for each condition: programs that leave before their forward is reached, or whose block CRuby runs once, and that print the same as before.

Not in this change:

- `def asked(n) = block_given?` and `def call_it(n, &b) = b.call(n)` beside the `super(...)` still see no block.
- A block that ends in a call (`x.to_s`), under a callee that reads it, still raises `no block given (yield)`.
- A callee that yields under a block of its own (`def tell(n) = [n].each { |v| yield(v) }`) or in a parameter default still raises `no block given (yield)`.
- A count that is off is not judged, as on master: behind a forward of one argument, `def tell(n, k) = yield(n)` raises `no block given (yield)` where CRuby raises `wrong number of arguments`. A callee with a default or a `*rest` beyond the forwarded slots, which CRuby accepts, still raises `no block given (yield)` too, and so does a forwarder the program also calls by `send`.
- A subclass that overrides the forward's callee (`class Sub < Loud; def tell(n) = yield(n) + 1; end`) does not build, as on master.

To know: a forward that raised now runs on, and where master has another fault on that road the program prints that fault's answer where it raised (in one case below, where it did not build). Each is master's own and shows there without this change:

- The super's own value is nil in `[super(...), tell(...)]` when another call of the method has a block that breaks, and when the call is a subclass's `super(n) { ... }`: `[nil, 6]` for `[6, 6]`. Master prints the same with `def tell(n) = block_given? ? yield(n) : 6`.
- Under a callee that only runs the block, the parent's `yield` answers `x` for a block that ends in `x => y`, and nil for one that ends in `begin; next 3 if x > 5; x; end` or in `Array.new`. `def m(a) = yield(a)` called with those blocks answers the same on master.
- `yield(n) * 2.5` answers nil where the block answers `true`, `false`, `nil` or a Symbol and CRuby raises NoMethodError. `def h(a) = yield(a) * 2.5` called `h(2) { |x| x == 2 }` prints nil on master. With a block that answers `nil` the forward did not build (`invalid operands to binary *` in the C) and now prints nil, as `h(2) { |x| nil }` does on master.
- An operator the program gives Integer is not called for the block's parameter at the parent's `yield`, where the parameter is boxed: with `class Integer; def *(o) = 99; end`, a callee that only runs the block prints `[6, 2]` for `[99, 2]`. `def each_row(...) = super(...)` alone prints 6 for 99 on master.

Cost at run time: a program that is right today, whose callee is `yield(n) if block_given?`, now runs the block there as CRuby does. 200,000 calls of it with `{ |x| x * 3 }`: 7,068,084 Ir to 19,870,539 under callgrind, 64 Ir a call, the block's second run on a boxed parameter.

`tools/cident.sh` against 3d629868df96: 6498 identical, 1 differ (the new test), 0 refusal changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
