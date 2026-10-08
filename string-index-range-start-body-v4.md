<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s[-5..1] = "x"; p s      # CRuby RangeError, -5..1 out of range; here "ax"
s = +"abc"; s[4..5] = "x"            # CRuby RangeError, 4..5 out of range; here RangeError, 4 out of range
b = [+"abc", 1][0]; b[4..5] = "x"    # CRuby the same RangeError; here IndexError, index 4 out of string
f = "abc"; f[-5..1] = "x"            # CRuby RangeError; here FrozenError
```

The Range arm counted a negative start from the end once and `sp_str_splice_at` counted it again, so a start below the String wrote into it; a boxed receiver's `sp_poly_splice_range` did the same. Both now check the start against the String before the splice and raise with the Range's own text, ahead of the frozen check as CRuby has it; for that `emit_str_splice_value` leaves the frozen check to an arm that passes no receiver. `lib/spinel_rt.h` only gains lines: the check, and a cold function for the raise that takes the Range's ends as words.

An assignment inside the String pays the two compares: 1,296 instructions a `s[2..4] = "xyz"` before, 1,298 after (callgrind). Six existing tests change their generated C and print what they printed.

Left as they are: `s[0..] = "x"` answers "xabc" (the arm tests an endless end against `SP_INT_NIL` where the Range carries `INTPTR_MAX`, another cause); a Float end is named by its Integer part ("20..20 out of range" for `s[20..20.5] = "x"`); a value that is no String raises its TypeError ahead of the RangeError; a frozen String that a second name holds raises FrozenError ahead of the RangeError, as before (`t = s; t.freeze`, and an instance variable set from a parameter or read through an `attr_reader`): its frozen test stands at the top of the statement.

"String#[]= with a Regexp group raises for a missing group or nil" makes the same change to `emit_str_splice_value`, in the same words. That one goes first; the two merge clean in either order and were built together.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
