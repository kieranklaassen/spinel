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

The temp is now the handle the store would have made, for the statements a list proves (`masgn_fresh_stmt`): as many values as targets; each target a local, or an element of a local that is an Array or a Hash by its text (every write of it a literal, `nil`, or a conditional of those) and not nil there, under a literal key or the key of a local no proc rebinds, of the kind the store takes as it is; each value a new String written as one (an interpolation whose every part is text, a literal or a local's read, adjacent literals too, which stay frozen; `+"lit"`; `"lit".dup`), a number, a Symbol, `nil`, `true`, `false` or a local, or a String literal bound for a local; and at least one new String bound for an element. Such a statement roots every temp it holds: nothing else holds a new handle until its own store, and a store before it can allocate. The test is marked `# spinel: gc-stress` for those roots. An Integer key past what an Array can hold is the store's own to refuse: it is killed as the single store is, where CRuby raises IndexError.

No listed value writes a local, and the one thing of the program's a listed value can run is a `to_s` its interpolation calls; the key's local and the holder are ones no proc rebinds, so nothing that `to_s` runs changes which key or holder the statement stores under. A multiple assignment here evaluates its values before it reads its keys and its holder, and CRuby reads those first: `r[k], r[2] = (k += 1), 7` stores under the changed key on master. A new String whose interpolation changed a key's local or rebound the holder (`r[k], r[2] = "a#{k += 1}", +"cd"`) would be stored where CRuby does not store it, so an interpolation that holds a call, a block, a write or anything else but a literal or a local's read keeps its statement off the list.

Any other multiple assignment is emitted as before.

Of 3,283 multiple assignments (twelve kinds of target, thirteen of value, nine ways the element is then changed, at top level, in a method and in a block), 558 go from the C error to right, at `SPINEL_GC_STRESS` 0, 1 and 2; 2,405 have the C they had and 320 are refused before and after. None prints a wrong line. With `--share-strings` 606 go from the C error to right, 2,469 have the C they had and 208 are refused before and after. Of 245 more beside a Struct, one goes from the C error to right in each mode and the rest have the C they had or are refused as before. `tools/cident.sh`: 6780 identical, 1 differ (the new test); with `--share-strings` 6779 identical, 1 differ (the new test), 1 refused before and after; no compile reached the script's time or memory bound. `tools/refusals.sh` pass (594 records); `make reject-test`, `make share-strings-test`, `make int-min-test` and `make gc-stress-test` pass.

At compile time the whole-program question is three lookups in what master's walk of the program noted; this change walks nothing of its own. `spinel -S` under callgrind, master and then this change: 1,000 methods that each hold a listed statement, 7,171,045,311 instructions and 7,230,295,098, and 2,000 of them 14,720,253,246 and 14,770,664,057; each method also changing a String by `gsub!` and reading an `upcase!` for its value, 1,000 18,793,153,872 and 18,820,684,462, 2,000 53,902,979,867 and 53,978,791,374; each method also reading an explicit setter for its value, 1,000 106,000,793,858 and 105,871,278,630.

Not in this change; each is emitted as it was and still stops at the same C error:

- a value in parentheses, a bang method's result or a lambda's call: each names a String that lives elsewhere, and a second handle around it would be a copy;
- an interpolation that holds anything but text, a literal or a local's read (`"a#{k += 1}"`, `"a#{n + 1}"`, `"a#{f(n)}"`, `"a#{@n}"`), and a key that is a local a proc rebinds: the values are evaluated before the keys are read;
- a new String bound for a local, or a String literal bound for an element, beside the new String;
- a nested or a rest target, and a key that is computed or is not of the kind the store takes as it is;
- an element of a local that is not an Array or a Hash by its text (`r = Array.new(2)`, a parameter, a call's answer, a block's parameter, a local a proc captures), or that can be nil at the statement: where the local is nil CRuby raises NoMethodError and the store does not; inside `if r` the local is on the list;
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

No `docs/limitations.md` entry is owed: no entry names this statement, and the change lifts a C error, not a refusal.
