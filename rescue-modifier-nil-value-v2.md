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

When the modifier's expression is always nil, the modifier took the fallback's type, and the value arm stored the expression into a slot of that type. A bare call is emitted for its effect there. The same call in parentheses was not, nor two statements, an `if` with no else, a begin block, or a conditional with nil in both arms. Such an expression is a value, so the modifier's type is now the boxed join of nil and the fallback (`infer_type`, src/analyze_infer.c). An Integer or a Float fallback keeps its slot, whose sentinel is the nil already.

Left alone: a bare call keeps the fallback's type and its C; a fallback of nil, `[]`, `{}` or a raise still does not build.

Measured on master dafa0d047: no corpus program's C changes but the new test's (`make cident`: 6,280 identical), scale-test keeps master's four ratios, and of 639 generated programs (one expression, one fallback, one place the value goes; -O0 and -O2) 463 that did not build now print CRuby's answer, 4 wrong ones are right, and the other 172 print what they printed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (4.0.7)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
