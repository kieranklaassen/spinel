<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def kept(c)
  x = (c && yield)
  x
end
p kept(true) { true }
p kept(true) { 9 }    # did not build; CRuby prints true, 9
```

The same for `c || yield`, `yield && c`, `c && d && yield`, `!c && yield` and the keyword forms, as an assignment, an argument, an element or an instance variable's value.

Where blocks of different types make a yield's value boxed, an `&&` or `||` over it is boxed too, and each call site emits the chain for its own block. At a site whose block answers true or false both sides are booleans, so the chain took the flat C `&&` and handed its int on as it stood ("incompatible types when assigning to type 'sp_RbVal' from type 'int'"). That arm of `emit_and_or_begin_expr` now boxes its result where the chain is boxed for the sites together.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
