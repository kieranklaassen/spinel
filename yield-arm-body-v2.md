<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
def guarded
  yield rescue :rescued
end
p guarded { :s }    # :s
p guarded { 9 }     # :""; CRuby prints 9
```

The same with the yield in one arm of an `if` or a ternary, beside `||`, and in a `case`. With a String among the blocks the program did not build.

Where a yielding method's blocks answer different types at different call sites, a yield whose value goes into a local, an Array literal, an argument, a receiver or a rescue frame is typed poly, so that each spliced site boxes its own block's value (upstream pull request 6185). One arm of the method's own last statement was not in that list: the other arm and the first site's block settled the method's return, and a later site's value was converted to it.

The method's last statement is now one of those places, unless `method_call_ret` types the call from each site's block already (a bare `yield` tail, a call of the block parameter, the block arm of an `if block_given?`). The walk through value arms also learns the rescue modifier and `case`, so `v = (yield rescue :none)` keeps its site's type too.

Left as before: a yield in an arm of an explicit `return` (`return (c ? yield : :none)`), and `(yield)` in parentheses as the last statement.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [ ] Depends on: #
