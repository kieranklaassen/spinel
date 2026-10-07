<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Stacked on #NNNN (String#insert raises IndexError for an index past either end): its commit is the first here, and the two above it are this pull request's.

```ruby
s = +"abc"; s << "d"
s[1] = "x"; p s      # CRuby "axcd"; here, under SPINEL_GC_STRESS=2, "the mark reached a freed heap string"
```

`s[1] = x` as a statement built its answer in one nested call, `sp_str_concat(sp_str_concat(sp_str_sub_range(..), x), sp_str_sub_range(..))`: whichever piece C made first was in flight, unrooted, while the next allocated. In a plain run that loses the String and raises nothing: 34 of 20,000 rounds of `s = "x" * 2100; s[0] = "y" * n` left `s` the value alone, built with gcc.

The arm now calls `sp_str_splice_at` with a length of one, as the (start, length) arm below it does. So that the call is not slower, the first commit has `sp_str_splice_at` join its three pieces in one `sp_str_concat3`: 1,155 instructions a `s[3] = "x"` before, 1,093 after (callgrind). `gc-stress-test` runs the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: #NNNN
