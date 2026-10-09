<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

The cost first: this refuses 212 generated programs that master builds and that answer as CRuby does, the ones in which nothing reads the String through the first name after the change. The smallest:

```ruby
s = +"ab "
t = s
r = t.strip!
r << "!"
p r        # CRuby "ab!", master "ab!", refused here
```

Reading the receiver's own name after the change (`p t` for `p r`) gives a program master already refuses, for each of the 185 of them that call a bang method; for the other 27, which call one of the four mutators without a bang, the pull request this sits on refuses it. Where the first name is a local, as it is in all 212, calling the method on that name instead (`r = s.strip!`) is refused the same way; where it is a reader or a Struct member (`t = st.a`), that program is not refused, and the read's twin is the one that holds. In all 283 of the 425 programs refused beyond that pull request (67 in 100) are right today; the count is under Measured.

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

On the head this depends on (master 8dc55225 with its one commit), over 10,636 generated programs (the kept result of the bang methods and of those four calls, on locals, second names, instance variables, globals, constants, parameters, block parameters and readers): the compiler decides 10,211 as that head does and refuses 425 more: 371 bang calls on a local that shares its String, in the route's own sentence, and 54 of the four calls on one.

- 142 of them print a wrong answer on master. 283 answer as CRuby does today. In 212, the kind at the top, nothing reads the String through the first name after the change: the route asks whether the receiver shares its handle, not whether the other name is read again. In 68 the method changes nothing at run time, in 2 the kept name is given another String before it is changed, in 1 the change is a `setbyte`, which lands in bytes the two names still share. Reading the receiver's own name after the change (`p t`) in each of the 425 gives a program already refused, by master (371) or by the pull request this depends on (54); so does calling the method on the first name, a local in 424 of them and an instance variable in one.
- With `--share-strings` no decision changes.
- On master 70ff7a36 with that pull request's commit: the same 425 are refused beyond it and no other decision changes, with the flag or without. Master's C is no longer 8dc55225's for 314 of them; run again on 70ff7a36, each answers as it did. On master 47225b48 with that commit the same held. On master 9c57b440 with that commit, which this commit sits on: the same 425 are refused beyond it, no other decision changes, and with the flag every decision and every sentence is master's. `tools/cident.sh` against that head: 6657 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 566 records, the 4 added lines are the new reject test's. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. On master 9c57b440 the reject test builds and prints "ab".

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the test of the pull request beneath with both compilers plain and at `SPINEL_GC_STRESS=2`, and `tools/cident.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test; the reject test prints "ab!" under CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: "Refuse a kept result of the String mutators that answer self without a bang" (its commit is the first of this branch, unchanged)
