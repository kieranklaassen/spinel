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

The temp is now the handle the store would have made, for the statements a list proves (`masgn_fresh_stmt`): as many values as targets; each target a local, or an element of a local typed an Array or a Hash and not nil there, its key a literal or a local; each value a new String written as one (an interpolation, `+"lit"`, `"lit".dup`), a number, a Symbol, `nil`, `true`, `false` or a local, or a String literal bound for a local; and at least one new String bound for an element. A String of adjacent literals (`"a" "b"`) is on the list as an interpolation is: the literal needed no root, and its handle is rooted while a later value can allocate, as any other temp is. The test is in `GC_STRESS_TESTS` for that line: without that root it stops at `SPINEL_GC_STRESS=2` with "the mark reached a freed slot".

Any other multiple assignment is emitted as before.

Of 3,283 multiple assignments (twelve kinds of target, thirteen of value, nine ways the element is then changed, at top level, in a method and in a block), 660 go from the C error to right, at `SPINEL_GC_STRESS` 0, 1 and 2; 2,303 have the C they had and 320 are refused before and after in the same words. None prints a wrong line. With `--share-strings` 726 go from the C error to right, 2,384 have the C they had and 173 are refused before and after. Of 245 more beside a Struct, one goes from the C error to right (the listed statement next to a Struct in an Array) and 244 have the C they had or are refused as before; with the flag all 245 are as before. `tools/cident.sh`: 6481 identical, 1 differ (the new test); with `--share-strings` 6411 identical, 1 differ, 70 refused by both; no compile reached the script's time or memory bound.

Not in this change; each still stops at the same C error:

- a value in parentheses, a bang method's result or a lambda's call: each names a String that lives elsewhere, and a second handle around it would be a copy;
- a new String bound for a local, or a String literal bound for an element, beside the new String;
- a nested or a rest target, and a computed key;
- an element of a local that is boxed or can be nil at the statement (a block's parameter, a `for` variable, a local a pattern binds, a parameter with a default, a local of two kinds, `r = c ? nil : [+"q"]`): a boxed local's store goes by another road, which stores nothing through a class's own `[]=`, and where the local is nil CRuby raises NoMethodError and the store does not; inside `if r` the local is on the list;
- any such statement in a program that defines `Array#[]=`, `Hash#[]=`, `String#+@` or `String#dup` itself: the store or the value is the program's own to make;
- the assignment used as a value: `x = (r[0], r[1] = +"ab", +"cd")`, or the last expression of a method, of a lambda or of a block whose value is used. As the last statement of an `each` block it is on the list.

Master's own, seen beside it and not changed here: an Array a constant holds, read into a local (`r = C`), is the local's own Array, so a store through the local, single or multiple, leaves the constant as it was.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
