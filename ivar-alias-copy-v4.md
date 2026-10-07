<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 3,364 generated programs, this refuses 1,952 that master builds. 342 of them answer as CRuby does today: 202 change the String with `setbyte`, 68 change it only in or before the assignment, in a method or a block, 43 rebind the variable before changing it, and 29 `upcase!` a String the call had emptied. With `--share-strings`, where master builds all 3,364, it refuses 1,605 of them, and 156 of those answer as CRuby does under the flag. A fifth kind of right program is refused too, counted on a family of its own below: the other name is read only before the change, in a method, a block or a conditional, or in the script body through more than a print (1,924 of the 4,536 refused there). For every program refused, the same program with `$` for `@` is one master already refuses.

An instance variable assigned from another instance variable, or from a local through a call that answers its receiver, is a second name for the one String. No alias walk follows that assignment, so the instance variable held a copy, and a change in place through one name was lost to the other silently:

```ruby
class Box
  def initialize = @s = +"a"
  def go
    @t = @s
    @t << "!"
    p @s       # CRuby "a!", Spinel "a"
  end
end
Box.new.go
```

`refuse_string_alias_copies` now asks of that assignment what it asks of `t = $g`: it refuses `@t = @s`, `@t = @s.to_s` and `@t = s.itself` when one name is mutated in place and the other is read, unless the assignment runs after the program's last mutation or its own call is that last mutation (`@t = @s.replace(x)` as the program's only mutation, or as the last one of the script body: the copy follows the change, and nothing changes either name after it). It stands aside too where the script body only prints the other name, ahead of the assignment (`p @s; @t = @s.to_s; @t << "!"; p @t`): the print keeps no second name for the String, nothing reads the change through `@s`, and `@s` was not written from another variable that would. It shares nothing and adds no sharing rule: it is the global route's refusal, in a sentence of its own, for the assignment beside it that copies the same way.

Left as on master, with master's C byte for byte:

- a plain `@t = @s` between two names that already hold the one shared handle, which hands the handle over. (Through a call the write copies even then, and is refused. A `clear` through such an instance variable is lost on master whatever the assignment; that is not this route's.)
- `@t = s`, `t = @s` and `t = @s.to_s`, which have alias walks of their own;
- a source that is no String (`@t = @n.to_s` makes a new one);
- what the route cannot see, still a silent copy: a parameter mutated after `@t = s` in a method, a third name through an instance variable write (`@t = (@u = @s)`), and a read or a change through a reader (`k.t << x`).

Under `--share-strings` the plain `@t = @s` is the rule's and is left to it. Through a call the rule names the two one shared class and the write still copies (`@t = @s.to_s; @t << "!"; p @s` printed "a"), so those stay refused, as their global twins are. A kept `reverse!` or `encode!` result is left to the rule: its global twin builds there.

## Measured

On master 759d120f, over 3,364 generated programs, each with its twin that has `$` for `@`. 2,620 write the assignment five ways and through six mutators that answer their receiver, between two instance variables, from a local, from a parameter and to a local; in the script body, a block, a top-level method, a method of a class and across two methods; with ten mutations through either name, a rebinding, an operator assignment and a mutation before the assignment. In 744 more both names are shared handles before the assignment.

- Master refuses 22 and builds 3,342. Of those the compiler now refuses 1,952 and builds 1,390, each with master's C.
- Of the 1,952, 1,574 print other content than CRuby on master and 36 do not build (the C does not compile). 342 answer as CRuby does:
  - 202 change the String with `setbyte`, which lands in bytes the two names still share (29 of them raise IndexError on an emptied String, as CRuby does);
  - in 68 every change runs in or before the assignment, in a method or a block. The script body's forms of these build: the order fact the global route has proves them. A method or a block can run again, and then the change follows the alias the run before made; nothing the route has says it runs once;
  - 43 rebind the variable before changing it. The route asks names, not Strings: a name bound to a new String and then changed reads to it as the old one changed;
  - 29 `upcase!` a String the call had emptied.
- Master refuses the twin of all 1,952.
- With `--share-strings` master builds all 3,364. The compiler refuses 1,605: 1,422 print other content than CRuby under the flag, 27 do not build, 156 answer as CRuby does. Master refuses the twin of all 1,605 under the flag; the 1,759 still built have master's C.
- The other name read only before the change, 4,998 more programs with their twins: seven positions; `@t = @s`, `.to_s`, `.itself` and `.to_str` from an instance variable or a local; six changes through the new name; no read of the old name, or one of sixteen ahead of the assignment (printed, its size, an interpolation, in a conditional or a block, kept in another variable or an Array, changed first). Master builds all 4,998. The compiler builds 462 with master's C: the 252 that never read the old name, and 210 in which the script body prints it ahead of the assignment (`p`, `puts`, `print`); all 210 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`. It refuses 4,536: 1,548 print other content than CRuby on master, 96 do not build, and 2,892 answer as CRuby does:
  - 756 change the String with `setbyte`;
  - in 1,679 the read and the change run once, in a method, a block or a conditional. Nothing the route has says they run once: of the 1,548 wrong, 860 run the same lines twice, and the second run reads the first's change;
  - in 245 the script body reads the old name through more than a print statement (its size, an interpolation, a `dup`, a modifier `if`, a block) or changes it before printing it. The stand-aside takes a `p`, `puts` or `print` statement alone, whose argument is kept nowhere;
  - 212 run the lines twice: 180 set the String anew each run, and in 32 the second run's read does not show the change.
  Master refuses the `$` twin of all 4,536. With `--share-strings` the compiler builds 912 of the 4,998 with master's C (the 714 plain `@t = @s`, which are the rule's, 108 that never read the old name, and 90 of the 210) and refuses 4,086, each `$` twin refused by master under the flag: 1,578 of them print other content than CRuby under the flag, 96 do not build, 2,412 answer as CRuby does.
- `tools/cident.sh`: 6432 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 538 records, the 8 added lines are the two new reject tests'. `make reject-test` and `make share-strings-test` pass; the plain reject test is listed in `test/share/reject.list`, where the flag builds it and prints "a!".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
