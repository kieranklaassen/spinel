<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

The bang-result route of `refuse_string_alias_copies` refuses a kept bang result that is mutated in place when the receiver's own name is read again. A receiver that is a second name for the String is not read again itself, so the copy went through silently:

```ruby
s = +"ab "
t = s
r = t.strip!
r << "!"
p s        # CRuby "ab!", Spinel "ab"
```

The route now also takes a local receiver that shares its handle (`sa_handle`): the String is read through the other name. `sa_mutated` already asks the same of the name that keeps the result. With `--share-strings` the route asks the rule as before, and the program compiles and answers as CRuby does.

## Measured

On master 06064727, over 10,424 generated programs (the kept result of the bang methods, on locals, second names, instance variables, globals, constants, parameters, block parameters and readers): the compiler decides 10,238 as master does and refuses 186 more, all in the route's own sentence.

- 116 of them print a wrong answer on master. 70 answer as CRuby does today: in 68 the method changes nothing at run time, in 2 the kept name is given another String before it is changed. Calling the method on the other name instead (`r = s.strip!`) in each of the 70 gives a program master already refuses.
- With `--share-strings` no decision changes.
- `tools/cident.sh`: 6333 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 532 records, the 4 added lines are the new reject test's. `make reject-test` and `make share-strings-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test; the reject test prints "ab!" under CRuby)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
