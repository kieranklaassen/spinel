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

The subject is now asked with `repr_static_read_kind`, which answers for the global too. Without the flag no such slot is a handle, `emit_handle_var_ref` answers no, and the generated C is the same.

Part of it is a regression of the commit "Array.new(a) is not followed, and a whole-String pattern binding takes the subject's handle": 8 of the programs below were right under the flag on master 5c78f07e, before it.

Not in this change, wrong on master and the same here:

- a class variable's reader (`def self.cur = @@c`) or a method that returns a reader's String as the subject: a call that returns a held String is not told from one that returns a new one;
- without the flag a constant's or a class variable's String is a copy at each read, in a pattern as in an assignment.

Tests: `test/share/share_strings_pattern_static_subject.rb`, which `make share-strings-test` runs: a constant bound with a class and by `if LINE in String => u`, a constant under a module bound bare, a class variable inside a class method, and a local that already held another String's handle. On master nine of its twelve lines are wrong.

Generated C against master (`make cident REF=759d120f`): `6429 identical, 0 differ, 0 refusal changes`. `tools/refusals.sh` passes (534 records); `make reject-test` and `make share-strings-test` pass. optcarrot's generated C is byte-identical. Programs of ours, on master 759d120f with CRuby 3.3.6 as the reference: 120 whole-subject bindings, 30 for each of a constant, a constant under a module, a class variable and, as the control, a global (a local that holds a reader's handle, one appended to before, one first bound by the pattern; an append through the local, one through the subject, one after the `case`, `equal?`, nothing; `in String => s` and `in s`).

| with `--share-strings` | constant | under a module | class variable | global |
|---|---|---|---|---|
| wrong on master, right here | 24 | 24 | 24 | 0 |
| right on both, the handle in place of the copy | 6 | 6 | 6 | 0 |
| right on both, master's C | 0 | 0 | 0 | 30 |

Of the 72: on master 5c78f07e 8 were right, 12 wrong and 52 did not build. Without the flag all 120 have master's C byte for byte (40 right, 64 wrong, 16 that do not build).

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (written with CRuby 3.3.6 and that flag; the test prints Strings and true)
- [x] Values past 2^31 are marked `# spinel: int64` (none)
- [x] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change)
- [ ] Depends on: #
