<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Of 3,364 generated programs, this refuses 1,952 that master builds. 342 of them answer as CRuby does today: 202 change the String with `setbyte`, 68 change it only in or before the assignment, in a method or a block, 43 rebind the variable before changing it, and 29 `upcase!` a String the call had emptied. For every one of the 1,952, the same program with `$` for `@` is one master already refuses.

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

`refuse_string_alias_copies` now asks of that assignment what it asks of `t = $g`: it refuses `@t = @s`, `@t = @s.to_s` and `@t = s.itself` when one name is mutated in place and the other is read, unless the assignment runs after the program's last mutation or its own call is that last mutation (`@t = @s.replace(x)` as the program's only mutation, or as the last one of the script body: the copy follows the change, and nothing changes either name after it). It shares nothing and adds no sharing rule: it is the global route's refusal, in a sentence of its own, for the assignment beside it that copies the same way.

Left as on master, with master's C byte for byte:

- a plain `@t = @s` between two names that already hold the one shared handle, which hands the handle over. (Through a call the write copies even then, and is refused. A `clear` through such an instance variable is lost on master whatever the assignment; that is not this route's.)
- `@t = s`, `t = @s` and `t = @s.to_s`, which have alias walks of their own;
- a source that is no String (`@t = @n.to_s` makes a new one);
- what the route cannot see, still a silent copy: a parameter mutated after `@t = s` in a method, a third name through an instance variable write (`@t = (@u = @s)`), and a read or a change through a reader (`k.t << x`).

Under `--share-strings` the plain `@t = @s` is the rule's and is left to it. Through a call the rule names the two one shared class and the write still copies (`@t = @s.to_s; @t << "!"; p @s` printed "a"), so those stay refused, as their global twins are. A kept `reverse!` or `encode!` result is left to the rule: its global twin builds there.

## Measured

On master a2bd8900, over 3,364 generated programs, each with its twin that has `$` for `@`. 2,620 write the assignment five ways and through six mutators that answer their receiver, between two instance variables, from a local, from a parameter and to a local; in the script body, a block, a top-level method, a method of a class and across two methods; with ten mutations through either name, a rebinding, an operator assignment and a mutation before the assignment. In 744 more both names are shared handles before the assignment.

- Master refuses 22 and builds 3,342. Of those the compiler now refuses 1,952 and builds 1,390, each with master's C.
- Of the 1,952, 1,574 print other content than CRuby on master and 36 do not build (the C does not compile). 342 answer as CRuby does:
  - 202 change the String with `setbyte`, which lands in bytes the two names still share (29 of them raise IndexError on an emptied String, as CRuby does);
  - in 68 every change runs in or before the assignment, in a method or a block. The script body's forms of these build: the order fact the global route has proves them. A method or a block can run again, and then the change follows the alias the run before made; nothing the route has says it runs once;
  - 43 rebind the variable before changing it. The route asks names, not Strings: a name bound to a new String and then changed reads to it as the old one changed;
  - 29 `upcase!` a String the call had emptied.
- Master refuses the twin of all 1,952.
- With `--share-strings` master builds all 3,364. The compiler refuses 1,605: 1,422 print other content than CRuby under the flag, 27 do not build, 156 answer as CRuby does. Master refuses the twin of all 1,605 under the flag; the 1,759 still built have master's C.
- `tools/cident.sh`: 6378 identical, 0 differ, 0 refusal changes. `tools/refusals.sh`: 538 records, the 8 added lines are the two new reject tests'. `make reject-test` and `make share-strings-test` pass; the plain reject test is listed in `test/share/reject.list`, where the flag builds it and prints "a!".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (not compared here: the gate compares it)
- [ ] Depends on: #
