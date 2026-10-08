<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 4,048 generated programs, this refuses 1,445 that master builds. 269 of them answer as CRuby does today: the change shows nothing (the same `upcase!` through both names, a `setbyte` into bytes the two names still share, a `squeeze!` with nothing to squeeze), the kept name is given another String before it is changed, or the result is read before the change. For every one of the 1,445, the same program with `strip!` for the call is one master already refuses.

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

This sits on "The bang-result route asks a receiver read through its other name" too (the second commit of this branch, unchanged), and the two meet in the one route. That pull request takes a local receiver that shares its String as read through its other name, so a class's instance variable that keeps one of these calls on such a local is refused though the local is not read again:

```ruby
class K
  def go
    s = +"abcd"
    t = s
    @r = t.concat("x", "y")
    @r << "!"
    p s        # CRuby "abcdxy!", Spinel "abcdxy"
  end
end
K.new.go
```

Neither commit refuses it alone. As in that pull request, the route asks whether the receiver shares its String, not whether the other name is read again: with `p @r` for `p s` master answers as CRuby does, and the program is refused. And where the receiver is a second name of a parameter (`def go(s)`, then `t = s; @r = t.concat("x", "y")`), master's write hands the String itself over and the change shows through every name; that is refused too. Where `s` is a local of the method the same lines copy the String and lose the change, in a block with both slots holding a String handle just as there, and the route does not tell the two apart. Of 158 generated programs that only the two together refuse, 89 answer as CRuby does on master: 77 print only the kept name, 8 change with `setbyte`, and 4 are that parameter's; 65 print other content, and for 4 the C does not compile.

In `docs/limitations.md` this rewrites the line the first pull request adds to the list of refused routes, and no line master has: "a local, a global or an instance variable of the top level" becomes "a variable", and the sentence that left a class's instance variable alone gives way to the one write that stands aside.

Left as on master:

- a change through the receiver that is read through the kept name (`@r = @s.concat("x", "y"); @s << "!"; p @r`). The route asks whether the kept name is changed, for a bang method as for these calls, and master builds the `strip!` form of each such program too;
- a receiver typed poly, as an instance variable is that a subclass reads from its parent or that an `attr_writer` sets: `concat` may be an Array's there, and the call is not taken for a String's;
- the kept name changed through its reader from outside the class (`b.r << "!"`), and an instance variable of the class body (`class K; @s = +"ab"; @r = @s.concat("x", "y"); @r.upcase!; p @s; end`): the copy still goes through silently there, and master builds the `strip!` form of each too;
- `--share-strings`: nothing changes. The calls are left to the rule, as in the first pull request beneath.

## Measured

On the first pull request's head (master 8dc55225 with its one commit), over 4,048 generated programs: a class's instance variable keeping the result in eight forms (six calls, `call || @s`, and the call in parentheses), the receiver an instance variable, a local or a parameter, in a method, a block, two methods, a module's method and a subclass, with 44 changes through either name or none. The compiler decides 2,603 as that head does and refuses 1,445 more.

- 868 of the 1,445 print other content than CRuby on master, and for 308 the C does not compile. 269 answer as CRuby does today: in 84 both names are upcased alike, 80 change with `setbyte`, in 76 the kept name is given another String before it is changed, in 16 the result is read before the change, 11 `squeeze!` a String with nothing to squeeze, and 2 write the same bytes with `[]=`.
- Swapping the call for `strip!` in each of the 1,445 gives a program master already refuses. Writing `$` for `@` in each gives one the first pull request beneath refuses.
- The write that stands aside: 44 of the 4,048 (`concat` with arguments, the receiver set from a parameter, the kept name appended to, inserted into or replaced). All 44 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`.
- Still built, as on master: 1,672 programs whose change goes through the receiver (master builds the `strip!` form of all 1,672), and 88 in a subclass whose receiver is typed poly, 72 of them wrong.
- On the 1,554 programs the first pull request beneath counts for a class's instance variable (master builds 1,404 of them: 409 right, 853 wrong, 142 whose C does not compile), this refuses 644: 332 of the wrong ones, the 142, and 170 right ones. The 760 it still builds are 239 right and 521 wrong, and every one of the 521 changes the String through the receiver or asks `equal?`.
- 1,792 more programs written against the write that stands aside (eight ways the receiver comes to hold its String, seven forms of the keep, sixteen changes through the kept name, each with and without an `equal?` question): the first pull request's head refuses 224 and builds 1,568; this refuses 336 more, and for all 336 master's C does not compile. Of the 1,232 it still builds, with that head's C, 763 answer as CRuby does and 469 do not, none of them by the kept write: in 210 another instance variable took the receiver's String first and was changed (`@u = @s; @u << "0"`), in 210 an `attr_writer` set the receiver, which is typed poly, and 49 change the kept name with `clear`, which master loses on a shared String instance variable that has one name too (`def initialize(s) = @s = s`, then `@s << "1"; @s.clear; p @s` prints "aabcd1").
- Over 10,424 programs of the other routes' families the compiler decides as the first pull request's head does but for 7, which it refuses: for 6 of them master's C does not compile, 1 answers as CRuby does.
- Where the two pull requests beneath meet, 486 more programs on master ed986127: in a class's method, in a block there, and with a parameter for `s`; `t = s`, then `@r = t.` one of six forms of the four calls or `strip!`, `upcase!` or `sub!`; five changes through `@r` or none; `s`, `t` or `@r` printed. Master refuses 90, and so does the first pull request; the second refuses 168; this commit on the first alone would refuse 169; on both it refuses 405. 158 of the 405 neither refuses alone (they print `s` or `@r`), and nothing either refuses is built. Of the 158, 65 print other content than CRuby on master, for 4 the C does not compile, and 89 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`: 77 print only the kept name, 8 change with `setbyte`, and in 4 `concat` with arguments on a parameter's second name hands the String over and the change shows. For every one of the 158 the `strip!` form is one the second pull request refuses. The other 79 it refuses beyond the second pull request print `t`, and it refuses them on the first alone too: 65 wrong, 2 whose C does not compile, 12 right (8 a `setbyte`, 4 that parameter's). The 81 still built make no change through the kept name, and all answer as CRuby does. With the flag every decision and every sentence is master's.
- With `--share-strings` no decision changes in any of these families.
- On master 70ff7a36 with the first pull request's commit: in every family above the same programs are refused beyond it and no other decision changes, with the flag or without, the twins' included. Master's C is no longer 8dc55225's for 859 of the programs refused and 1,390 of those still built; run again on 70ff7a36, each answers as it did (21 of the still built had not been run before: 12 answer as CRuby does, 9 do not). On master 47225b48 with that commit the same held, and on master ed986127 with it. On master ed986127 with the two commits beneath, which this commit sits on: in every family but the 486 the same programs are refused beyond them as beyond the first alone, no other decision changes, and with the flag every decision and every sentence is master's. `tools/cident.sh` against the second commit: 6605 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 570 records, the 4 added lines are the new reject test's. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. On master ed986127 the reject test builds and prints "abxy".

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the test of the first pull request beneath, which this one adds lines to, with both compilers plain and at `SPINEL_GC_STRESS=2`, and `tools/cident.sh`.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test; the reject test prints "ABXY" under CRuby 3.3.6)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: "Refuse a kept result of the String mutators that answer self without a bang" and "The bang-result route asks a receiver read through its other name" (their commits are the first and the second of this branch, unchanged)
