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

The temp is now the handle the store would have made, for the statements a list proves (`masgn_fresh_stmt`): as many values as targets; each target a local, or an element of a local that is an Array or a Hash by its text (every write of it a literal, `nil`, or a conditional of those) and not nil there, under a literal or a local key of the kind the store takes as it is; each value a new String written as one (an interpolation, `+"lit"`, `"lit".dup`), a number, a Symbol, `nil`, `true`, `false` or a local, or a String literal bound for a local; and at least one new String bound for an element. Such a statement roots every temp it holds: nothing else holds a new handle until its own store, and a store before it can allocate. The test is marked `# spinel: gc-stress` for those roots.

Any other multiple assignment is emitted as before.

Of 3,283 multiple assignments (twelve kinds of target, thirteen of value, nine ways the element is then changed, at top level, in a method and in a block), 558 go from the C error to right, at `SPINEL_GC_STRESS` 0, 1 and 2; 2,405 have the C they had and 320 are refused before and after. None prints a wrong line. With `--share-strings` 606 go from the C error to right, 2,469 have the C they had and 208 are refused before and after. Of 245 more beside a Struct, one goes from the C error to right in each mode and the rest have the C they had or are refused as before. `tools/cident.sh`: 6707 identical, 1 differ (the new test), with and without `--share-strings`; no compile reached the script's time or memory bound. `tools/refusals.sh` pass (580 records); `make reject-test`, `make share-strings-test`, `make int-min-test` and `make gc-stress-test` pass.

At compile time the whole-program question is three lookups in what master's walk of the program noted; this change walks nothing of its own. `spinel -S` under callgrind, master and then this change: 1,000 methods that each hold a listed statement, 7,149,267,686 instructions and 7,209,240,375, and 2,000 of them 14,676,426,903 and 14,726,649,754; each method also changing a String by `gsub!` and reading an `upcase!` for its value, 1,000 18,761,863,784 and 18,790,585,318, 2,000 53,841,239,113 and 53,917,018,842; each method also reading an explicit setter for its value, 1,000 105,930,238,425 and 105,843,890,410, 2,000 421,784,241,883 and 420,989,487,912.

Not in this change; each is emitted as it was and still stops at the same C error:

- a value in parentheses, a bang method's result or a lambda's call: each names a String that lives elsewhere, and a second handle around it would be a copy;
- a new String bound for a local, or a String literal bound for an element, beside the new String;
- a nested or a rest target, and a key that is computed or is not of the kind the store takes as it is;
- an element of a local that is not an Array or a Hash by its text (`r = Array.new(2)`, a parameter, a call's answer, a block's parameter), or that can be nil at the statement: where the local is nil CRuby raises NoMethodError and the store does not; inside `if r` the local is on the list;
- any such statement in a program that could have a `[]=`, a `+@` or a `dup` of its own (`masgn_program_may_own`, which asks master's `an_prog_never_gives`: no def and no Symbol of such a name, and no site that names, makes or loads a method by something the text does not spell, so no computed name, no text evaluated, no file left unread and no module mixed in, as by `include Comparable`): the store or the value may be the program's own to make;
- the assignment read for its value: `x = (r[0], r[1] = +"ab", +"cd")`, or the last expression of a method.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [x] Depends on: # (nothing)
