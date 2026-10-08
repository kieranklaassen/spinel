<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`values_at` on a boxed receiver did not build when one of its indexes is built where it stands and needs a statement of its own:

```ruby
a = [[1, 2, 3], nil][ARGV.size]
p a.values_at(0..[1].size)   # error: expected expression before 'sp_IntArray'; CRuby: [1, 2]
p a.values_at(*[*[0], 1])    # the same error; CRuby: [1, 2]
```

`values_at` on a boxed receiver collects its indexes into an Array, one statement each. It wrote the head of that statement, `sp_PolyArray_push(_tN, `, and only then emitted the index, so whatever the index hoisted (here the literal Array in the Range's bound) landed inside the call. A splatted list did the same with its `sp_poly_to_poly_array(`. An index with an effect of its own, a call, runs ahead of the whole call and is read from its temp; a Range, a literal Array or Hash and a list that holds a splat are built where they stand. Each is now emitted first and its statement written whole after it.

Where an index hoists nothing the C is master's, byte for byte. Of 480 programs (240 with an index of 15 kinds, in four places of the list, on four receivers, and for each the same program with the index held in a local first), 288 compile to the same C; the other 192 are the ones whose index is built in place, none of which built. All 192 now build and print CRuby's answer.

This stands on "fetch and values_at on a boxed Array refuse an index that is no Integer": alone, 48 of the 192 (a literal Array or Hash, or a splatted list that holds an Array, as an index of a boxed Array) would answer a wrong element where CRuby raises TypeError, as master answers them with the index in a local.

In the corpus only the new test's C differs.

Not in this change: a receiver that changes a variable a Range index reads, `(i += 1; a).values_at(i..[1].size)`, did not build; it now builds, has its index read first and prints `[1, 2]`, as `(i += 1; a).values_at(i..1)` does on master (CRuby: `[2]`).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: # (fetch and values_at on a boxed Array refuse an index that is no Integer)
