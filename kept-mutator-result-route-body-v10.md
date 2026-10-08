<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 10,664 generated programs, this refuses 455 that master builds. 38 of them answer as CRuby does today: the change is a `setbyte`, the call raises before the change, or the result is read before the receiver changes. For every one of the 455, the same program with `strip!` for the call is one master already refuses.

`bytesplice`, `append_as_bytes`, and `concat` or `prepend` with other than one argument answer their receiver, as a bang method that changed it does. No alias walk follows them, and the bang-result route of `refuse_string_alias_copies` asked only names ending in `!`, so the name that keeps the result held a copy and a change through it was lost silently:

```ruby
s = +"ab"
r = s.concat("x", "y")
r << "!"
p s        # CRuby "abxy!", Spinel "abxy"
```

`sa_bang_receiver` now takes those four calls. The route refuses the kept result when it is mutated in place through a local, a global or an instance variable of the top level and the receiver is read, in a sentence of its own (the call is no bang method), and the returned-parameter route refuses a method that answers its parameter through one of them (`def patch(x) = x.bytesplice(0, 1, "Z")`, then `t = patch(s); t << "!"`).

Left as on master:

- a class's instance variable that keeps the result, where nothing is refused yet. Of 1,554 generated programs of that kind (five calls and `call || @s`; the receiver an instance variable, a local or a parameter; fourteen changes through either name), master f3da0151 builds 1,404, and a2bd8900 emits the same C for each: 409 answer as CRuby does, 853 do not, and for 142 the C does not compile. Of the 409, 282 have no change to see, 84 change with `setbyte` and 43 are others. An append through the kept name reaches an instance-variable receiver that a parameter set (`def initialize(s) = @s = s`, then `@r = @s.concat(a, b); @r << "!"`); where a literal set it, master refuses it or the C does not compile, but for eight programs that also ask `equal?`, four of them right. `upcase!`, `replace`, `clear` and `reverse!` through the kept name are lost in all 210 (`@r.upcase!; p @s` printed "abxy"), and so are nearly all changes through the receiver. One of the top level holds a copy, as a global does, and is refused (`@s = +"ab"; @r = @s.concat("x", "y"); @r << "!"; p @s` printed "abxy");
- `--share-strings`. Nothing is asked there: the four calls are the rule's. On master 47225b48 the rule shares a local or a global that keeps `concat` with arguments, refuses an instance variable that keeps it in a sentence of its own, and still copies a kept `bytesplice` silently;
- a mutator straight on the result of `bytesplice` or `append_as_bytes` (`s.bytesplice(0, 1, "Z") << x`), which does not reach the receiver either. The same shape on a bang method is right, so there is no refusal for it to sit beside, and it is not refused here.

## Measured

On master 8dc55225, over 10,664 generated programs (the kept result of these four calls and of the bang methods, on locals, instance variables in a class and at the top level, globals, constants, parameters, block parameters and readers): the compiler decides 10,209 as master does and refuses 455 more.

- 417 of the 455 are wrong on master (409 print other content than CRuby, 7 answer `equal?` false, 1 raises NoMethodError) and 38 answer as CRuby does today: the change is a `setbyte`, which lands in bytes the two names still share; the call raises before the change; or the result is read before the receiver changes.
- Swapping the call for `strip!` in each of the 455 gives a program master already refuses (420 by the bang-result route, 35 by the returned-parameter route).
- 210 of the 455 keep the result at the top level, 70 each in an instance variable, a global and a local: all 210 are wrong on master.
- With `--share-strings` no decision and no sentence changes.
- On master 70ff7a36: the same 455 are refused and no other decision changes; with the flag every decision and every sentence is master's (10,664 programs compared). Master's C is no longer 8dc55225's for 206 of them; run again on 70ff7a36, each answers as it did. The same holds for the 108 of the class instance-variable programs above whose C changed. On master 47225b48, which this commit sits on: the same 455 are refused, no other decision changes, and with the flag every decision and every sentence is master's. `tools/cident.sh`: 6550 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 554 records, the 12 added lines are the three new reject tests'. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. On that master each of the three reject tests builds and prints other content than CRuby.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the new test with both compilers plain and at `SPINEL_GC_STRESS=2`, and `tools/cident.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6 run with that flag)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: nothing
