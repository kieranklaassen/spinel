<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
a = [1, "x", nil].freeze
h = { "a" => a, "n" => 1 }
h["a"].clear
p a
```

prints `[]` (`spinel diff`: exception-diff, no exception where CRuby has one). CRuby raises FrozenError (can't modify frozen Array: [1, "x", nil]). A frozen Hash is emptied the same way: `c = { "a" => 1 }.freeze; h = { "c" => c, "n" => 1 }; h["c"].clear; p c` prints `{}`.

An Array or a Hash read back from a Hash or an Array, or passed to a parameter that takes both, is cleared by `sp_poly_clear`, which set the length of every kind with no look at the frozen flag. The typed `clear` raises. Now `sp_poly_clear` raises before it removes anything, for an empty receiver too: a Hash by the flag in its header, an Array by the flag in its struct. Twenty-eight Array methods that change their receiver were tried through a boxed receiver: `clear` and `delete` were the two that did not raise, and `delete` is its own pull request.

Cost: `m["x"].clear` on an Array that is not frozen takes 5 instructions more a call, on a Hash 3 more (callgrind on 5a752fceb48c, gcc, 100,000 calls: 127 to 132 and 292 to 295 a round of the loop). The change is in lib/sp_poly_cold.c, so no generated C changes.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is unchanged)
- [ ] Depends on: #
