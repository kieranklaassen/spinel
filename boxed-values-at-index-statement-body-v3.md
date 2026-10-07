<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`values_at` on a boxed receiver did not build when one of its indexes needed a statement of its own:

```ruby
a = [[1, 2, 3], nil][ARGV.size]
p a.values_at(0, [1].size)   # error: expected expression before 'sp_IntArray'; CRuby: [1, 2]
```

`values_at` on a boxed receiver collects its indexes into an Array, one statement each. It wrote the head of that statement, `sp_PolyArray_push(_tN, `, and only then emitted the index, so whatever the index hoisted (here the literal Array) landed inside the call. A splatted list did the same with its `sp_poly_to_poly_array(`. Each is now emitted first and its statement written whole after it.

Where an index hoists nothing the C is master's, byte for byte. Of 810 programs, 486 compile to the same C; the other 324 are the ones with such an index, none of which built. All 324 now build, and each prints what the same program prints with the index held in a local first, which for these is CRuby's answer.

This stands on "fetch and values_at on a boxed Array refuse an index that is no Integer": alone, 18 of the 324 (`values_at(:a)` or `values_at("a")` on a boxed Array) would answer a wrong element where CRuby raises TypeError, as master answers them with the index in a local.

In the corpus only the new test's C differs, in both overflow modes and under `--share-strings`.

Not in this change: two shapes that did not build now build and answer as master answers them with a plain index. A splatted Range, `a.values_at(*(0..[1].size))`, prints `[]`, as `a.values_at(*(0..1))` does on master (CRuby: `[1, 2]`). And a receiver that changes a variable an index reads, `(i += 1; a).values_at(i, [1].size)`, has its index read first and prints `[1, 2]`, as `(i += 1; a).values_at(i, 1)` does on master (CRuby: `[2, 2]`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (fetch and values_at on a boxed Array refuse an index that is no Integer)
