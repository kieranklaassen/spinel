<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"ab"; s.insert(9, "x"); p s        # CRuby IndexError; here "abx"
s = +"ab"; s.insert(-4, "x"); p s       # CRuby IndexError; here "xb"
s = +"ab"; r = s.insert(-4, "x"); p r   # CRuby IndexError; here "axb"
```

The statement arm cut the String with two `sp_str_sub_range` calls and checked no bound; with the value taken, a negative index below the start was folded twice. Both arms now go through one `sp_str_insert` in the runtime, which raises for an index past either end, ahead of the frozen check as CRuby does. `lib/spinel_rt.h` only gains lines.

The statement arm also nested both fresh pieces in `sp_str_concat`, so a collection between them freed the piece in flight. Under `SPINEL_GC_STRESS=2`, `s = +"x"; s << "a"; s.insert(0, "b")` stopped with "the mark reached a freed heap string"; in a plain run, 35 of 20,000 rounds of `s = "x" * 2100; s.insert(0, "y" * n)` left `s` the text alone, built with gcc. The test joins `GC_STRESS_TESTS`.

An insert is not slower: 1,172 instructions a statement insert before, 1,096 after (callgrind).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
