<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

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

This sits on "Refuse a kept result of the String mutators that answer self without a bang" (its commit is the first of this branch, unchanged), which adds `bytesplice`, `append_as_bytes`, and `concat` or `prepend` with other than one argument to the same route. Together they also refuse those four calls on a second name (`t = s; r = t.concat(a, b); r << "!"; p s`), in that pull request's sentence.

## Measured

On the head this depends on (master 2f204adb with its one commit), over 10,636 generated programs (the kept result of the bang methods and of those four calls, on locals, second names, instance variables, globals, constants, parameters, block parameters and readers): the compiler decides 10,211 as that head does and refuses 425 more: 371 bang calls on a local that shares its String, in the route's own sentence, and 54 of the four calls on one.

- 142 of them print a wrong answer on master. 283 answer as CRuby does today. The largest kind, 212, is the program in which nothing reads the String through the first name after the change (`t = s; r = t.strip!; r << "!"; p r`): the route asks whether the receiver shares its handle, not whether the other name is read again. In 68 the method changes nothing at run time, in 2 the kept name is given another String before it is changed, in 1 the change is a `setbyte`, which lands in bytes the two names still share. Calling the method on the other name instead (`r = s.strip!`, `r = s.concat(a, b)`) in each of the 283 gives a program already refused, by master or by the pull request this depends on.
- With `--share-strings` no decision changes.
- `tools/cident.sh`: 6340 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 536 records, the 4 added lines are the new reject test's. `make reject-test` and `make share-strings-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test; the reject test prints "ab!" under CRuby)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: # ("Refuse a kept result of the String mutators that answer self without a bang")
