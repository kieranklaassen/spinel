<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Before:

```ruby
def twice
  yield 1
  yield 2
end

r = (twice { |x| raise "stop" if x == 2 }) rescue :rescued
```

does not build: `incompatible types when assigning to type 'sp_sym' from type 'sp_RbVal'`.

After: `r` is `:rescued`, and nil where nothing is raised.

When the modifier's expression is always nil, the modifier's type was the fallback's, as it is for an expression that can only raise, and the value arm stored the expression into a slot of that type. A bare call is emitted for its effect there (#3021). The same call in parentheses was not, nor two statements, an `if` with no else, a begin block, or a conditional with nil in both arms. `([1, 2].each { ... }; nil) rescue :rescued` built and answered `:x`, the first Symbol of the program.

Such an expression is a value, so the modifier's type is now the boxed join of nil and the fallback (`infer_type`, src/analyze_infer.c). An Integer or a Float fallback keeps its slot, whose sentinel is the nil already. A bare `yield` and a bare `super` are values too. No emitter changes.

Left alone: a bare call keeps the fallback's type and the C it has, and so what it answers today; a fallback of nil, of an empty [] or {}, or of a raise still does not build (`_tN declared void`); and with a Float fallback the nil is still NaN once it is boxed (`r = (m) rescue 1.5; [r, 1]` prints `[NaN, 1]`), as on master.

A program that builds now may go on to a fault master has without any rescue: a nil stored into an Array of objects and then printed with the class's own inspect prints the object's line, as `acc << (c ? Box.new : nil)` does on master.

It stands above the pull request that keeps a local written before the raise: a program that builds now may write one, and without that change the write is lost at -O1 and above (the test's last case).

<!-- AT OPENING: measure the lines below on the master of that day and replace the numbers. -->
- Generated C (`make cident`): no program's C changes but the new test's.
- scale-test: the same four ratios as master.
- 639 programs of one expression, one fallback and one place the value goes, at -O0 and -O2: 463 did not build and are right, 4 were wrong and are right, 142 are right on both, 30 are the same on both (a bare call, or a fallback of nil).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
