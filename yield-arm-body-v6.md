<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def guarded
  yield rescue :rescued
end
p guarded { :s }    # :s
p guarded { 9 }     # :""; CRuby prints 9
```

The same with the yield in one arm of an `if` or a ternary, beside `||` or `&&`, and in a `case`. With a String among the blocks the program did not build, or built and crashed; with the value passed on as an argument (`dbl(m(true) { 1 })` beside a site whose block answers a Symbol) it was refused.

Where a yielding method's blocks answer different types at different call sites, a yield whose value goes into a local, an Array literal, an argument, a receiver or a rescue frame is typed poly, so that each spliced site boxes its own block's value (upstream pull request 6185). One arm of the method's own last statement was not in that list: the other arm and the first site's block settled the method's return, and a later site's value was converted to it.

The method's last statement is now one of those places, unless `method_call_ret` types the call from each site's block already (a bare `yield` tail, a call of the block parameter, the block arm of an `if block_given?`). The walk through value arms also learns the rescue modifier and `case`, so `v = (yield rescue :none)` keeps its site's type too.

Left as before: a yield in an arm of an explicit `return` (`return (c ? yield : :none)`); `(yield)` alone in parentheses as the last statement; and a last statement one of whose arms is a parenthesized sequence (`(note; yield) || 5`), whose C is unchanged. The last value of such a sequence is not boxed for a block that answers nil, and with blocks that fit one slot the program is right today. In the 43,215 programs this was measured on, 462 are of that kind and give the C they gave: 87 right, 224 wrong and 151 that do not build, as before.

This stands above the two small fixes named below. Without the first, `yield && c` as a method's last statement, right today with a true-or-false block among the sites, does not build. Without the second, `(yield) || 5` there, right today with a true block and a nil one, does not build either.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (unchanged)
- [x] Depends on: # (A yield under && or || hands a true-or-false block's value on boxed) and # (A parenthesized yield hands a nil block's value on boxed)
