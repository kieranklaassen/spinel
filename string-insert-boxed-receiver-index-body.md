<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
box = [+"ab", 1][0]
box.insert(-4, "x"); p box    # CRuby IndexError, index -3 out of string; here "axb"
box.insert(-9, "x")           # CRuby IndexError, index -8 out of string; here IndexError, index -6 out of string
```

`sp_poly_insert` counted a negative index from the end once and `sp_str_splice_at` counted it, still negative, again, so an index one below the start came back inside the String. Its String arm now raises with CRuby's message before the splice, and so ahead of a frozen receiver's FrozenError as CRuby has it: one added line in `lib/spinel_rt.h`. A String variable's insert checks its own index and is not touched.

An insert at an index that is not negative runs the same instructions as before (callgrind, gcc and clang). No generated C changes.

Left as it is: `box.insert(1, 5)` answers "a5b" where CRuby raises TypeError, another cause.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
