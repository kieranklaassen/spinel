<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
r = [+"q"]
r[0], r[1] = +"ab", +"cd"
r[0] << "z"
p r
```

prints `["abz", "cd"]` in CRuby and does not build here, with and without `--share-strings`:

```
error: initialization of 'sp_String *' from incompatible pointer type 'const char *'
```

With `r[0] = +"ab"; r[1] = +"cd"` in the multiple assignment's place it builds and is right.

A String stored where an element is changed in place is wrapped in a handle of its own, and a single store does that at the store. A multiple assignment holds each value in a temp first. The temp was declared by the value's stored type, the handle, and filled with what the value renders as, the String.

The temp is now the handle the store would have made, for the statements a list proves (`masgn_fresh_stmt`): as many values as targets; each target an element of a local, its key a literal or a local, or a local; each value a new String written as one (an interpolation, `+"lit"`, `"lit".dup`), a literal or a local; and at least one new String bound for an element. Every temp of such a statement is rooted: the handle is built after the values before it and is stored into a container that can grow. The test is in `GC_STRESS_TESTS` for that; without the rooting it faults at `SPINEL_GC_STRESS=2`.

Any other multiple assignment is emitted as before.

Of 3,283 multiple assignments (twelve kinds of target, thirteen of value, nine ways the element is then changed, at top level, in a method and in a block), 660 go from the C error to right, at `SPINEL_GC_STRESS` 0, 1 and 2; 2,303 have the C they had and 320 are refused before and after in the same words. None prints a wrong line. With `--share-strings` 714 go from the C error to right, 2,330 have the C they had and 239 are refused before and after. `tools/cident.sh`: 6413 identical, 1 differ (the new test); with `--share-strings` 6301 identical, 1 differ, 112 refused by both.

Not in this change; each still stops at the same C error:

- a value in parentheses, a bang method's result or a lambda's call: each names a String that lives elsewhere, and a second handle around it would be a copy;
- a nested or a rest target, and a computed key;
- the assignment used as a value (`x = (r[0], r[1] = +"ab", +"cd")`, or as the last expression of a block or a lambda).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
