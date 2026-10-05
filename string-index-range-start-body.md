<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s[-5..1] = "x"; p s      # CRuby RangeError, -5..1 out of range; here "ax"
s = +"abc"; s[4..5] = "x"            # CRuby RangeError, 4..5 out of range; here RangeError, 4 out of range
b = [+"abc", 1][0]; b[4..5] = "x"    # CRuby the same RangeError; here IndexError, index 4 out of string
f = "abc"; f[-5..1] = "x"            # CRuby RangeError; here FrozenError
```

The Range arm counted a negative start from the end once, and `sp_str_splice_at` counted the start, still negative, from the end again, so a start below the String wrote into it. The assignment with its value taken and a String two names hold run the same arm, and a boxed receiver's `sp_poly_splice_range` answered the same.

The arm now checks its start against the String before the splice and raises with the Range's own text, ahead of the frozen check as CRuby has it. `sp_poly_splice_range`'s String arm has the same check; `lib/spinel_rt.h` only gains its two lines.

The statement reads its value into a C temp after the Range and ahead of the check, as CRuby reads its arguments before it looks at the String: `s[4..5] = lg("x")` has run `lg` when the RangeError is raised. Read there, a value that changes the receiver is seen whichever order the C compiler reads a call's arguments in: `s[1..2] = (s << "ef"; "x")` on "abcd" answered "axdef" built with gcc and "axd" built with clang, and answers "axdef" with both.

An assignment inside the String pays the two compares: 1,296 instructions a `s[2..4] = "xyz"` before, 1,305 after (callgrind, 200,000 statements).

The generated C changes in the new test and in five existing tests that assign through a Range; each of the five prints what it printed. No benchmark and not optcarrot.

Left as they are:

- `s[0..] = "x"` answers "xabc": the arm tests an endless end against SP_INT_NIL where the Range carries INTPTR_MAX, another cause.
- A Float end is printed as its Integer part: `s[20..20.5] = "x"` says "20..20 out of range" where CRuby says "20..20.5 out of range"; it said "20 out of range".

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
