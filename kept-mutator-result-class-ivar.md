<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 4,048 generated programs, this refuses 1,445 that master builds. 234 of them answer as CRuby does today: the change shows nothing (the same `upcase!` through both names, a `setbyte` into bytes the two names still share, a `squeeze!` with nothing to squeeze), the kept name is given another String before it is changed, or the result is read before the change. For every one of the 1,445, the same program with `strip!` for the call is one master already refuses.

`bytesplice`, `append_as_bytes`, and `concat` or `prepend` with other than one argument answer their receiver. "Refuse a kept result of the String mutators that answer self without a bang", which this sits on (its commit is the first of this branch, unchanged), refuses the kept result of those calls in a local, a global and an instance variable of the top level, and leaves a class's instance variable as on master. There the copy goes through silently too:

```ruby
class Box
  def initialize = @s = +"ab"

  def shout
    @r = @s.concat("x", "y")
    @r.upcase!
    @s
  end
end
p Box.new.shout        # CRuby "ABXY", Spinel "abxy"
```

The route now asks a class's instance variable what it asks the others: the kept result mutated in place while the receiver is read is refused, in that pull request's sentence, as `@r = @s.strip!` is in the same class. One write stands aside, the one that hands over the receiver's handle (`sa_ivar_keeps_handle`): `concat` with arguments on an instance variable, where both slots hold a String handle (`def initialize(s) = @s = s`, then `@r = @s.concat(a, b); @r << "!"`). The two names are one String there, and a change through either reaches the other.

Left as on master:

- a change through the receiver that is read through the kept name (`@r = @s.concat("x", "y"); @s << "!"; p @r`). The route asks whether the kept name is changed, for a bang method as for these calls, and master builds the `strip!` form of each such program too;
- a receiver typed poly, as an instance variable is that a subclass reads from its parent or that an `attr_writer` sets: `concat` may be an Array's there, and the call is not taken for a String's;
- `--share-strings`: nothing changes. The calls are left to the rule, as in the pull request beneath.

## Measured

On the head this depends on (master 8dc55225 with its one commit), over 4,048 generated programs: a class's instance variable keeping the result in eight forms (six calls, `call || @s`, and the call in parentheses), the receiver an instance variable, a local or a parameter, in a method, a block, two methods, a module's method and a subclass, with 44 changes through either name or none. The compiler decides 2,603 as that head does and refuses 1,445 more.

- 903 of the 1,445 print other content than CRuby on master, and for 308 the C does not compile. 234 answer as CRuby does today: in 73 both names are upcased alike, 69 change with `setbyte`, in 65 the kept name is given another String before it is changed, in 14 the result is read before the change, 11 `squeeze!` a String with nothing to squeeze, and 2 write the same bytes with `[]=`.
- Swapping the call for `strip!` in each of the 1,445 gives a program master already refuses. Writing `$` for `@` in each gives one the pull request beneath refuses.
- The write that stands aside: 44 of the 4,048 (`concat` with arguments, the receiver set from a parameter, the kept name appended to, inserted into or replaced). All 44 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`.
- Still built, as on master: 1,672 programs whose change goes through the receiver (master builds the `strip!` form of all 1,672), and 88 in a subclass whose receiver is typed poly, 72 of them wrong.
- On the 1,554 programs the pull request beneath counts for a class's instance variable (master builds 1,404 of them: 409 right, 853 wrong, 142 whose C does not compile), this refuses 644: 332 of the wrong ones, the 142, and 170 right ones. The 760 it still builds are 239 right and 521 wrong, and every one of the 521 changes the String through the receiver or asks `equal?`.
- 1,792 more programs written against the write that stands aside (eight ways the receiver comes to hold its String, seven forms of the keep, sixteen changes through the kept name, each with and without an `equal?` question): the head beneath refuses 224 and builds 1,568; this refuses 336 more, and for all 336 master's C does not compile. Of the 1,232 it still builds, with that head's C, 763 answer as CRuby does and 469 do not, none of them by the kept write: in 210 another instance variable took the receiver's String first and was changed (`@u = @s; @u << "0"`), in 210 an `attr_writer` set the receiver, which is typed poly, and 49 change the kept name with `clear`, which master loses on a shared String instance variable that has one name too (`def initialize(s) = @s = s`, then `@s << "1"; @s.clear; p @s` prints "aabcd1").
- Over 10,424 programs of the other routes' families the compiler decides as the head beneath does but for 7, which it refuses: for 6 of them master's C does not compile, 1 answers as CRuby does.
- With `--share-strings` no decision changes in any of these families.
- `tools/cident.sh` against that head: 6447 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 544 records, the 4 added lines are the new reject test's. `make reject-test` and `make share-strings-test` pass.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test; the reject test prints "ABXY" under CRuby)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: # ("Refuse a kept result of the String mutators that answer self without a bang")
