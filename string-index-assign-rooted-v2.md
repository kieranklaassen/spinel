<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

Stacked on #NNNN (String#insert raises IndexError for an index past either end): its commit is the first here, and the two above it are this pull request's. Only neighbouring lines tie them, in `lib/sp_cold.c` and in the stress list of the `Makefile`; no code of that one is used here.

`s[1] = x` as a statement built its answer in one nested call, `sp_str_concat(sp_str_concat(sp_str_sub_range(..), x), sp_str_sub_range(..))`: whichever piece C made first was in flight, unrooted, while the next allocated. `sp_str_splice_at`'s comment describes the window; this arm still had it. In a plain run a collection in that window loses the String and raises nothing: of 20,000 rounds of `s = "x" * 2100; s[0] = "y" * n` with n from 1 to 40, 34 leave `s` the value alone, built with gcc (the count moves with what else allocates). Under `SPINEL_GC_STRESS=2` the assignment stopped with "the mark reached a freed heap string", with a literal value as with one that allocates. The arm now calls `sp_str_splice_at` with a length of one, as the (start, length) arm below it does; the bounds and the IndexError text are the helper's and were the same. `gc-stress-test` runs the new test at level 2: on master it fails there built with gcc and with clang; plain, it fails by one line built with gcc and passes built with clang.

The statement reads its index, then its value, then the receiver, so a value that changes the receiver, `s[1] = (s << "ef"; "x")`, is seen whichever order the C compiler reads a call's arguments in. The nested calls it replaces lost the append built with gcc and kept it built with clang. `s[a, n] = v` and `s[range] = v` pass the receiver and the value to one call as they did, and are not changed here.

So that the call is not slower than the nested form, the first commit has `sp_str_splice_at` join its three pieces in one `sp_str_concat3` instead of two joins: three allocations for four.

Instructions a statement on an eight-character String (callgrind, 200,000 statements):

| | before | after |
|---|---|---|
| `s[3] = "x"` | 1,155 | 1,087 |
| `s[2, 3] = "xy"` | 1,327 | 1,145 |
| `s[2..4] = "xy"` | 1,362 | 1,180 |

No benchmark and not optcarrot assigns into a String; their generated C is unchanged.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [x] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: #NNNN
