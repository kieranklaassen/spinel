<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
def str(v) = v ? +"ab" : nil
s = str(true)
p s&.concat("x")
p s
```

- Master: `"abx"`, then `"ab"`.
- CRuby and here: `"abx"`, then `"abx"`.

A String mutator is lowered to a reassignment of its receiver (`s = sp_str_concat(s, ...)`). Under a `&.` guard the receiver is bound to the guard's temp, so the new String was written to the temp and the variable kept the old one. With `&.`, a mutator used for its value or followed by another call (`s&.<<("y").size`) lost the change for `concat`, `<<`, `replace`, `insert`, `prepend`, `clear`, `slice!`, `[]=` and the `!` methods; on a boxed receiver the bare statement lost it too (`b&.upcase!`).

The typed arm and the boxed arm of the guard now store the temp back after the call (`sn_store_back`), where the receiver is a variable read as its plain slot (a local, a global, a captured variable's cell) and the text of the guarded call assigns the temp. A `&.` call that assigns nothing to its temp keeps master's C.

Not here, as on master:

- `@s&.[]=(0, "Z")` and `@s&.insert(1, "Q")` on an instance variable still lose the change (they go through the shared buffer's shim, which has its own way back), and `$s&.[]=(0, "Z")` on a global raises NoMethodError, as `$s.[]=(0, "Z")` does.
- With `--share-strings`, `insert`, `slice!`, `[]=` and `setbyte` on a String that is shared: the same shim. The other forms are cured with the flag too.

Test: `test/safe_nav_string_mutator_keeps_change.rb`, 33 lines; 17 of them are wrong on master.

Generated C against master (`make cident REF=759d120fd207`): 6428 identical, 1 differ, 0 refusal changes. The one is the new test. optcarrot's generated C is byte-identical.

780 small programs written for this change: 26 mutators, on a local that may be nil, a local that is never nil, a boxed local, a global and an instance variable, used for its value, followed by `size`, and as a statement, with `&.` and with `.`. With gcc and with clang, plain and under `SPINEL_GC_STRESS=1` and `2`: 523 are right in all six on master, 752 here. The 229 more printed a wrong line with no error, and no program loses a cell. The 28 left print the same on both: the six forms of the first point below "Not here", and 22 with a `.` (a call on the nil a `!` method answers; `s.setbyte(0, 65).size`, which loses the write with a `.` too; a global's `[]=`). With `--share-strings` (gcc, plain): 552 right on master, 748 here, none lost.

48 of the programs right on master take the new C: `lstrip!`, `strip!` and `squeeze!` on a String with nothing to strip, and `setbyte`, which wrote in place. Each loses the change on master for a String it has to replace (`"  ab"`; for `setbyte` a String `Symbol#to_s` answers). The cost there is the store.

## `make gate` (on this branch merged with current master)

```
GATE_LINES
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal` (run under 3.3.6 only)
- [ ] Values past 2^31 are marked `# spinel: int64` (none)
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662 (it did not change: byte-identical)
- [ ] Depends on: # (nothing)
