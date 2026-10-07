<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stacked on #NNNN (String#insert raises IndexError for an index past either end): its commit is the first here, and the two above it are this pull request's.

```ruby
s = +"hello"
s[1] = "X"
p s        # CRuby "hXllo"; here, under SPINEL_GC_STRESS=2, "the mark reached a freed heap string"
```

In a plain run the same statement gives a wrong String and raises nothing. Of 1,000,000 rounds of `s = "hello" + i.to_s; s[k] = "V" + i.to_s`, 76 come out wrong (`"heV63162heV63162"` for `"heV63162lo63162"`) built with gcc, 70 with clang; so do 3 of 4,000 rounds on a String of 1,400 to 3,200 characters (1 with clang).

`s[1] = x` as a statement built its answer in one nested call, `sp_str_concat(sp_str_concat(sp_str_sub_range(..), x), sp_str_sub_range(..))`: the piece C makes first is held by nothing while the next one allocates, and a collection there frees it.

The arm now calls `sp_str_splice_at` with a length of one, as the (start, length) arm below it does. So that the call is not slower, the first commit has `sp_str_splice_at` join its three pieces in one `sp_str_concat3`: 1,155 instructions a `s[3] = "x"` before, 1,090 after (callgrind). `gc-stress-test` runs the new test.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: #NNNN
