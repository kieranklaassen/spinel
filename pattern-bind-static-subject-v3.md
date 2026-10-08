<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
LINE = +"zz"
case LINE
in String => s
  s << "!"
end
p LINE     # "zz!" in CRuby, "zz" on master with --share-strings
```

Under `--share-strings` a local that a pattern binds to its whole subject (`in String => s`, `in s`) takes the subject's own handle when the subject is a variable that holds one. `emit_pattern_bind_handle` asked that of a local, an instance variable and a global. A constant, a constant under a module (`Cfg::NAME`) and a class variable hold the shared handle in their slot as well, and for those the local took a fresh handle over the subject's text: a copy, so a change through one name did not show through the other.

The subject is now asked with `repr_static_read_kind` as well. The slot is read where the arm binds, after the arms before it were tried, so the handle is taken only where none of those runs code in its pattern or its guard (`subtree_has_side_effect`):

```ruby
case @@c
in String => t if (@@c = +"other"; false)
in String => s
  s << "!"
end
p @@c, s   # "other", "zz!" in CRuby and on master
```

The guard assigns the class variable after the `case` read its subject, and the next arm binds the String the `case` read. That is right on master, by the copy, and stays master's C. Without the flag no such slot is a handle, `emit_handle_var_ref` answers no, and the generated C is the same.

Part of it is a regression of the commit "Array.new(a) is not followed, and a whole-String pattern binding takes the subject's handle": 8 of the 120 programs below were right under the flag on master 5c78f07e, before it.

Not in this change, wrong on master and the same here:

- a constant or a class variable bound under an earlier arm whose guard calls a method (`in String => t if big(1)`): the copy stays, since the call may assign the subject;
- a global bound under an earlier arm whose guard assigns it: master takes the slot's handle there and the local follows the assignment (`"other!"`, `"other!"` for the program above with `$g`);
- a class variable's reader (`def self.cur = @@c`) or a method that returns a reader's String as the subject: a call that returns a held String is not told from one that returns a new one;
- an earlier arm that names a constant whose class defines `self.===` (`in M`): a pattern does not call a user-defined `===` today, so that arm runs no code and is not counted as one that does. Once it is called, the arm has to count;
- without the flag a constant's or a class variable's String is a copy at each read, in a pattern as in an assignment.

Tests: `test/share/share_strings_pattern_static_subject.rb`, which `make share-strings-test` runs: a constant bound with a class and by `if LINE in String => u`, a constant under a module bound bare, a class variable inside a class method, a local that already held another String's handle, and a class variable under an earlier arm that fails on its class, one whose guard only compares, and one whose guard assigns the class variable, in its text and through a method. On master 11 of its 18 lines are wrong.

Generated C against master (`make cident REF=bce327d0`): `6482 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (536 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master bce327d0 with CRuby 3.3.6 as the reference. 120 whole-subject bindings, 30 for each of a constant, a constant under a module, a class variable and, as the control, a global (a local that holds a reader's handle, one appended to before, one first bound by the pattern; an append through the local, one through the subject, one after the `case`, `equal?`, nothing; `in String => s` and `in s`):

| with `--share-strings` | constant | under a module | class variable | global |
|---|---|---|---|---|
| wrong on master, right here | 24 | 24 | 24 | 0 |
| right on both, the handle in place of the copy | 6 | 6 | 6 | 0 |
| right on both, master's C | 0 | 0 | 0 | 30 |

60 more bind in the second arm, under an earlier arm of five kinds (a class that fails, a guard that compares, one that assigns the subject, one that calls a method that assigns it, one that calls a method that does not), for the same four subjects and three uses:

| with `--share-strings` | |
|---|---|
| wrong on master, right here (the earlier arm runs no code) | 12 |
| right on both | 32 |
| wrong on both, the same output (the first two bullets above) | 14 |
| no build on both | 2 |

None that is right on master is wrong here. Without the flag all 180 have master's C byte for byte.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
