<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

`bytesplice`, `append_as_bytes`, and `concat` or `prepend` with other than one argument answer their receiver, as a bang method that changed it does. No alias walk follows them, and the bang-result route of `refuse_string_alias_copies` asked only names ending in `!`, so the name that keeps the result held a copy and a change through it was lost silently:

```ruby
s = +"ab"
r = s.concat("x", "y")
r << "!"
p s        # CRuby "abxy!", Spinel "abxy"
```

`sa_bang_receiver` now takes those four calls. The route refuses the kept result when it is mutated in place through a local, a global or an instance variable of the top level and the receiver is read, in a sentence of its own (the call is no bang method), and the returned-parameter route refuses a method that answers its parameter through one of them (`def patch(x) = x.bytesplice(0, 1, "Z")`, then `t = patch(s); t << "!"`).

Left as on master:

- a class's instance variable that keeps the result. Where that builds (`@r = @s.concat(a, b)` in a method of the class) it takes the handle itself, and a change through it reaches the receiver. One of the top level holds a copy, as a global does, and is refused (`@s = +"ab"; @r = @s.concat("x", "y"); @r << "!"; p @s` printed "abxy");
- `--share-strings` at the bang route's site. The rule names every such result a shared handle, a read-only one too, so asking it there would refuse `r = s.concat(a, b); puts r`. The kept result is still a silent copy under the flag;
- a mutator straight on the result of `bytesplice` or `append_as_bytes` (`s.bytesplice(0, 1, "Z") << x`), which does not reach the receiver either. The same shape on a bang method is right, so there is no refusal for it to sit beside, and it is not refused here.

## Measured

On master 5390d300, over 10,664 generated programs (the kept result of these four calls and of the bang methods, on locals, instance variables in a class and at the top level, globals, constants, parameters, block parameters and readers): the compiler decides 10,209 as master does and refuses 455 more.

- 417 of the 455 are wrong on master (409 print other content than CRuby, 7 answer `equal?` false, 1 raises NoMethodError) and 38 answer as CRuby does today: the change is a `setbyte`, which lands in bytes the two names still share; the call raises before the change; or the result is read before the receiver changes.
- Swapping the call for `strip!` in each of the 455 gives a program master already refuses (420 by the bang-result route, 35 by the returned-parameter route).
- 210 of the 455 keep the result at the top level, 70 each in an instance variable, a global and a local: all 210 are wrong on master.
- With `--share-strings` only the returned-parameter route changes: 35 more refused, 15 of them wrong on master, all 35 `strip!` twins refused.
- `tools/cident.sh`: 6357 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 540 records, the 12 added lines are the three new reject tests'. `make reject-test` and `make share-strings-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
