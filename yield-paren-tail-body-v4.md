<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def handed
  (yield)
end
p handed { :s }    # :s
p handed { 9 }     # :""; CRuby prints 9
```

With a String among the blocks the program did not build.

Where a method's last statement is a `yield`, `method_call_ret` types each call from its own block, and `scope_joined_tail` leaves the method to it. `scope_joined_tail` looked through parentheses to decide that and `method_call_ret` does not, so `(yield)` got neither. In parentheses the yield is now the method's joined tail like any other arm, typed poly when the blocks diverge.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A yield in an arm of a method's value keeps each site's block type) and # (A parenthesized yield hands a nil block's value on boxed)
