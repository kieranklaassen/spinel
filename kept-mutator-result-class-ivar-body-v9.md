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

The route now asks a class's instance variable what it asks the others: the kept result mutated in place while the receiver is read is refused, in that pull request's sentence, as `@r = @s.strip!` is in the same class. One write stands aside, the one that hands over the receiver's handle (`sa_ivar_keeps_handle`): `concat` with arguments on an instance variable or a local, where both slots hold a String handle and the call carries the mark the emitter reads to hand a call's handle on (`def initialize(s) = @s = s`, then `@r = @s.concat(a, b); @r << "!"`). The write stores that handle: the two names are one String, and a change through either reaches the other. Without the mark master's write wraps the call's bytes in a handle of its own, whatever the two slots hold, and that copy is refused with the rest:

```ruby
class Box
  def initialize(s) = @s = s

  def add(a, b)
    @r = @s.concat(a, b)
    @r.upcase!
    [@s, @r]
  end
end
p Box.new(+" ab ").add("x", "y")        # CRuby [" AB XY", " AB XY"], Spinel [" ab xy", " AB XY"]
```

With `@r << "!"` for the `upcase!` there, master's write hands the String over and the program is built; with `@r << x`, `x` a third parameter, it copies, and the program is refused. A change that shows nothing on a copy is refused with those that do, as its `strip!` form is on master: `@r.squeeze!` with nothing to squeeze, where the receiver is read after it.

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

Neither commit refuses it alone. As in that pull request, the route asks whether the receiver shares its String, not whether the other name is read again: with `p @r` for `p s` master answers as CRuby does, and the program is refused. Where the receiver is a second name of a parameter (`def go(s)`, then `t = s; @r = t.concat("x", "y")`), master's write hands the String itself over and the change shows through every name: the call is marked there, and the write stands aside as it does on an instance variable. Where `s` is a local of the method the same lines copy the String and lose the change, with both slots holding a String handle just as there; the call is not marked, and the program is refused. Of 148 generated programs that only the two together refuse, 79 answer as CRuby does on master: 72 print only the kept name and 7 change with `setbyte`; 65 print other content, and for 4 the C does not compile.

In `docs/limitations.md` this rewrites the line the first pull request adds to the list of refused routes, and no line master has: "a local, a global or an instance variable of the top level" becomes "a variable", and the sentence that left a class's instance variable alone gives way to the one write that stands aside.

Left as on master:

- a change through the receiver that is read through the kept name (`@r = @s.concat("x", "y"); @s << "!"; p @r`). The route asks whether the kept name is changed, for a bang method as for these calls, and master builds the `strip!` form of each such program too;
- a receiver typed poly, as an instance variable is that a subclass reads from its parent or that an `attr_writer` sets: `concat` may be an Array's there, and the call is not taken for a String's;
- the kept name changed through its reader from outside the class (`b.r << "!"`), and an instance variable of the class body (`class K; @s = +"ab"; @r = @s.concat("x", "y"); @r.upcase!; p @s; end`): the copy still goes through silently there, and master builds the `strip!` form of each too;
- `clear` through an instance variable that holds a shared String, which master loses with one name as with two (`def initialize(s) = @s = s`, then `@s << "1"; @s.clear; p @s` prints "aabcd1"): a separate fault, left as master has it;
- the value of a method that ends in the write that stands aside is master's too: nil where the write is last, a copy where the instance variable is read after it;
- `--share-strings`: nothing changes. The calls are left to the rule, as in the first pull request beneath.

## Measured

On the first pull request's head (master 8dc55225 with its one commit), over 4,048 generated programs: a class's instance variable keeping the result in eight forms (six calls, `call || @s`, and the call in parentheses), the receiver an instance variable, a local or a parameter, in a method, a block, two methods, a module's method and a subclass, with 44 changes through either name or none. The compiler decides 2,603 as that head does and refuses 1,445 more.

- 868 of the 1,445 print other content than CRuby on master, and for 308 the C does not compile. 269 answer as CRuby does today: in 84 both names are upcased alike, 80 change with `setbyte`, in 76 the kept name is given another String before it is changed, in 16 the result is read before the change, 11 `squeeze!` a String with nothing to squeeze, and 2 write the same bytes with `[]=`.
- Swapping the call for `strip!` in each of the 1,445 gives a program master already refuses. Writing `$` for `@` in each gives one the first pull request beneath refuses.
- The write that stands aside: 44 of the 4,048 (`concat` with arguments, the receiver set from a parameter, the kept name appended to, inserted into or replaced). All 44 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`.
- Still built, as on master: 1,672 programs whose change goes through the receiver (master builds the `strip!` form of all 1,672), and 88 in a subclass whose receiver is typed poly, 72 of them wrong.
- On the 1,554 programs the first pull request beneath counts for a class's instance variable (master builds 1,404 of them: 409 right, 853 wrong, 142 whose C does not compile), this refuses 644: 332 of the wrong ones, the 142, and 170 right ones. The 760 it still builds are 239 right and 521 wrong, and every one of the 521 changes the String through the receiver or asks `equal?`.
- 1,792 more programs written against the write that stands aside (eight ways the receiver comes to hold its String, seven forms of the keep, sixteen changes through the kept name, each with and without an `equal?` question): the first pull request's head refuses 224 and builds 1,568; this refuses 336 more, and for all 336 master's C does not compile. Of the 1,232 it still builds, with that head's C, 763 answer as CRuby does and 469 do not, none of them by the kept write: in 210 another instance variable took the receiver's String first and was changed (`@u = @s; @u << "0"`), in 210 an `attr_writer` set the receiver, which is typed poly, and 49 change the kept name with `clear`, which master loses on a shared String instance variable that has one name too (`def initialize(s) = @s = s`, then `@s << "1"; @s.clear; p @s` prints "aabcd1").
- 1,092 more programs written against the mark, on master ed986127: `@s` set from a parameter, from a literal or from a `dup`; `@r = @s.concat(` two literals, three, two parameters, or a parameter and a literal `)`; ten changes through `@r`, two through `@s` or none; seven reads. Master refuses 280, and the two commits beneath no more; this refuses 384 more: 207 print other content than CRuby on master, for 60 the C does not compile, and 117 answer as CRuby does, 90 of them a `squeeze!` with nothing to squeeze and 27 a `setbyte`. For every one of the 384 the `strip!` form is one master refuses. Of the 428 still built, with master's C, 355 answer as CRuby does, for 20 the C does not compile, and 53 do not, none of them by a change through the kept name: 44 change the String through the receiver and 9 make no change and ask `equal?` of the two names.
- Over 10,424 programs of the other routes' families the compiler decides as the second pull request's head does but for 6, which it refuses: for all 6 master's C does not compile.
- Where the two pull requests beneath meet, 486 more programs on master ed986127: in a class's method, in a block there, and with a parameter for `s`; `t = s`, then `@r = t.` one of six forms of the four calls or `strip!`, `upcase!` or `sub!`; five changes through `@r` or none; `s`, `t` or `@r` printed. Master refuses 90, and so does the first pull request; the second refuses 168; this commit on the first alone would refuse 164; on both it refuses 390. 148 of the 390 neither refuses alone (they print `s` or `@r`), and nothing either refuses is built. Of the 148, 65 print other content than CRuby on master, for 4 the C does not compile, and 79 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`: 72 print only the kept name and 7 change with `setbyte`. For every one of the 148 the `strip!` form is one the second pull request refuses. The other 74 it refuses beyond the second pull request print `t`, and it refuses them on the first alone too: 65 wrong, 2 whose C does not compile, 7 right (a `setbyte`). The 96 still built are the 81 that make no change through the kept name and the 15 where `concat` with arguments on a parameter's second name hands the String over; all 96 answer as CRuby does. With the flag every decision and every sentence is master's.
- With `--share-strings` no decision changes in any of these families.
- Every family above but the 1,092 and the 486 was first counted on master 8dc55225 with the first pull request's commit and decided again on masters 70ff7a36 and 47225b48, by this commit before it asked for the mark and took a local receiver: the same programs were refused each time, with the flag or without, the twins' included. Master's C is no longer 8dc55225's for 859 of the programs refused and 1,390 of those still built; run again on 70ff7a36, each answers as it did (21 of the still built had not been run before: 12 answer as CRuby does, 9 do not). On master 9c57b440 with the two commits beneath, which this commit sits on, each of them and the 1,092 and the 486 were decided again by this commit as it is: the same programs are refused, but for one of the 10,424 that is built again (a parameter's `concat` kept and appended to, which answers as CRuby does), no other decision changes, and with the flag every decision and every sentence is master's; the programs refused were last run again on master ed986127, where they answered as they did. `tools/cident.sh` against the second commit: 6657 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 570 records, the 8 added lines are the two reject tests'. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass. On master 9c57b440 the two reject tests build and print "abxy" and `[" ab xy", " AB XY"]`.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the test of the first pull request beneath, which this one adds lines to, with both compilers plain and at `SPINEL_GC_STRESS=2`, and `tools/cident.sh`. By the gate's rule for one program the default lane passes that test; in the shared-String lane it stays the known failure the first pull request lists, refused by the flag where a class's instance variable keeps `concat`'s result.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (no new run test: the lines added to the first pull request's test match CRuby 3.3.6 run with that flag and with `append_as_bytes` defined for the run; the two reject tests print "ABXY" and `[" AB XY", " AB XY"]` under it)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: "Refuse a kept result of the String mutators that answer self without a bang" and "The bang-result route asks a receiver read through its other name" (their commits are the first and the second of this branch, unchanged)
