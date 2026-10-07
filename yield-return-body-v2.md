<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def fetched(c)
  return yield if c
  :none
end
p fetched(true) { :s }    # :s
p fetched(true) { 9 }     # :""; CRuby prints 9
```

The same for `return (c ? yield : :none)`, `return yield || :none` and `return (yield rescue :none)`. With a String among the blocks the program did not build, or built and crashed.

The value of a `return` is one more place where a yield settles a type from the first call site alone: the return joins it into the method's type, and the per-site coercion reaches only a bare `yield` tail. It is now on the list `yield_uses` keeps, so the yield there is typed poly when the blocks diverge, and each spliced site boxes its own block's value.

Left as before: a return whose value holds a parenthesized sequence (`return (note; yield) || 5`), like such a last statement in the fix this stands above.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A yield in an arm of a method's value keeps each site's block type)
