<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 3,364 generated programs, this refuses 1,952 that master builds. 342 of them answer as CRuby does on master 8dc55225, and again on 70ff7a36 and ed986127: 202 change the String with `setbyte`, 68 change it only in or before the assignment, in a method or a block, 43 rebind the variable before changing it, and 29 `upcase!` a String the call had emptied. With `--share-strings` nothing changes. A fifth kind of right program is refused too, counted on a family of its own below: the other name is read only before the change, in a method, a block or a conditional, or in the script body through more than a print (1,924 of the 4,536 refused there, on the same three masters). And a sixth, on a third family run on master ed986127: a short append to a String that is already a buffer (built by interpolation, or changed in place before the assignment) lands in bytes the two names still share, and the program answers as CRuby does; a longer one, or any other change but `setbyte`, is lost. For every program refused, the same program with `$` for `@` is one master already refuses.

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

`refuse_string_alias_copies` now asks of that assignment what it asks of `t = $g`: it refuses `@t = @s`, `@t = @s.to_s` and `@t = s.itself` when one name is mutated in place and the other is read, unless the assignment runs after the program's last mutation or its own call is that last mutation (`@t = @s.replace(x)` as the program's only mutation, or as the last one of the script body: the copy follows the change, and nothing changes either name after it). It stands aside too where the script body only prints the other name, ahead of the assignment (`p @s; @t = @s.to_s; @t << "!"; p @t`): the print keeps no second name for the String, nothing reads the change through `@s`, and no write of `@s` takes its value from a variable by name. It covers that printed-before read only: where `@s` was itself assigned a copy (`@s = [x][0]`), the older name `x` misses the change as it does on master, with or without the print. It shares nothing and adds no sharing rule: it is the global route's refusal, in a sentence of its own, for the assignment beside it that copies the same way.

Left as on master, with master's C byte for byte:

- a plain `@t = @s` between two names that already hold the one shared handle, which hands the handle over. (Through a call the write copies even then, and is refused. A `clear` through such an instance variable is lost on master whatever the assignment; that is not this route's.)
- `@t = s`, `t = @s` and `t = @s.to_s`, which have alias walks of their own;
- a source that is no String (`@t = @n.to_s` makes a new one);
- what the route cannot see, still a silent copy: a parameter mutated after `@t = s` in a method, a third name through an instance variable write (`@t = (@u = @s)`), a read or a change through a reader (`k.t << x`), and an assignment that runs again with no other read of the old name (`@t = @s; @t << "1"; p @t` in a method called twice).

Under `--share-strings` nothing is asked: the write is the rule's in every form. On master ed986127 the rule shares the write or refuses it in a sentence of its own.

## Measured

On master 8dc55225, over 3,364 generated programs, each with its twin that has `$` for `@`. 2,620 write the assignment five ways and through six mutators that answer their receiver, between two instance variables, from a local, from a parameter and to a local; in the script body, a block, a top-level method, a method of a class and across two methods; with ten mutations through either name, a rebinding, an operator assignment and a mutation before the assignment. In 744 more both names are shared handles before the assignment.

- Master refuses 22 and builds 3,342. Of those the compiler now refuses 1,952 and builds 1,390, each with master's C.
- Of the 1,952, 1,574 print other content than CRuby on master and 36 do not build (the C does not compile). 342 answer as CRuby does:
  - 202 change the String with `setbyte`, which lands in bytes the two names still share (29 of them raise IndexError on an emptied String, as CRuby does);
  - in 68 every change runs in or before the assignment, in a method or a block. The script body's forms of these build: the order fact the global route has proves them. A method or a block can run again, and then the change follows the alias the run before made; nothing the route has says it runs once;
  - 43 rebind the variable before changing it. The route asks names, not Strings: a name bound to a new String and then changed reads to it as the old one changed;
  - 29 `upcase!` a String the call had emptied.
- Master refuses the twin of all 1,952.
- With `--share-strings` no decision and no sentence changes: on master ed986127 the flag builds 2,613 of the 3,364 and refuses 751, and the compiler does the same, with master's C.
- The other name read only before the change, 4,998 more programs with their twins: seven positions; `@t = @s`, `.to_s`, `.itself` and `.to_str` from an instance variable or a local; six changes through the new name; no read of the old name, or one of sixteen ahead of the assignment (printed, its size, an interpolation, in a conditional or a block, kept in another variable or an Array, changed first). Master builds all 4,998. The compiler builds 462 with master's C: the 252 that never read the old name, and 210 in which the script body prints it ahead of the assignment (`p`, `puts`, `print`); all 210 answer as CRuby does, plain and at `SPINEL_GC_STRESS=2`. It refuses 4,536: 1,548 print other content than CRuby on master, 96 do not build, and 2,892 answer as CRuby does:
  - 756 change the String with `setbyte`;
  - in 1,679 the read and the change run once, in a method, a block or a conditional. Nothing the route has says they run once: of the 1,548 wrong, 860 run the same lines twice, and the second run reads the first's change;
  - in 245 the script body reads the old name through more than a print statement (its size, an interpolation, a `dup`, a modifier `if`, a block) or changes it before printing it. The stand-aside takes a `p`, `puts` or `print` statement alone, whose argument is kept nowhere;
  - 212 run the lines twice: 180 set the String anew each run, and in 32 the second run's read does not show the change.
  Master refuses the `$` twin of all 4,536. With `--share-strings` nothing changes here either: on master ed986127 the flag builds 4,704 of the 4,998 and refuses 294, and so does the compiler.
- On master 70ff7a36: the same 1,952 and 4,536 are refused and no other decision changes. Master's C is no longer 8dc55225's for 670 and 1,201 of them; run again on 70ff7a36, each answers as it did. The 462 still built in the second family were run there, plain and at `SPINEL_GC_STRESS=2`: the 210 answer as CRuby does; of the 252 that never read the old name, 216 do, 30 run the assignment twice and print the first run's content again, and 6 do not build (the C does not compile). On master 47225b48 the same held.
- A String that is already a buffer, 216 more programs on master ed986127: the source built by interpolation (`@s = "a#{1}"`), changed in place before the assignment, or a plain `+"ab"`; `@t = @s`, `.to_s` and `.itself`; the change through either name; twelve changes. Master builds all 216 and the compiler refuses all 216. With a buffer for the source (144), master answers as CRuby does in 36: one or two appends of one character, and `setbyte`. The other 108 print other content than CRuby: an append of 125 characters, `upcase!`, `replace`, `clear`, `concat` with two arguments, `insert`, `prepend`, `gsub!` and `reverse!`. In `@s = "a#{1}"; @t = @s.to_s` an append is right up to 20 characters and lost from 30: the two names share bytes, not the String. With the plain source 6 of the 72 are right, the `setbyte` ones.
- On master 9c57b440, which this commit sits on: the same 1,952 and 4,536 are refused, no other decision changes, the 216 above are refused as on ed986127, and with the flag every decision and every sentence is master's (of the 3,364 the flag builds 2,602 there and refuses 762). The 1,952 and the 4,536 were last run again on master ed986127, plain and at `SPINEL_GC_STRESS=2`, where each answered as it did. `tools/cident.sh`: 6660 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 560 records, the 8 added lines are the two new reject tests'. `make reject-test`, `make share-strings-test`, `make int-min-test` and `make infer-test` pass; the plain reject test carries `# spinel: reject-share`, so `make share-strings-test` builds it with the flag, where it prints "a!". On master 9c57b440 each of the two reject tests builds and prints other content than CRuby.

## `make gate` (on this branch merged with current master)

```
gate: run on the Mac at opening
```

Run on this commit in a Linux container, with gcc 13.3 and clang 18.1: the build, `ruby tools/gate.rb check` with the change staged, `tools/refusals.sh`, `make reject-test`, `make share-strings-test`, `make int-min-test`, `make infer-test`, the four new tests with both compilers plain and at `SPINEL_GC_STRESS=2` and by the gate's rule for one program in both corpus lanes, and `tools/cident.sh`. Two of the four new tests, `string_ivar_alias_last_mutation` and `string_ivar_alias_only_mutation`, are named in `test/share/known-failures.txt`: the default lane passes them, and `--share-strings` refuses them by design, in a sentence of its own, at `@t = @s.replace(x)`; the other two pass both lanes.

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (compared with CRuby 3.3.6 run with that flag)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (its C is byte-equal to master's)
- [x] Depends on: nothing
