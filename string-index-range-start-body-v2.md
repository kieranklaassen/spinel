<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s[-5..1] = "x"; p s      # CRuby RangeError, -5..1 out of range; here "ax"
s = +"abc"; s[4..5] = "x"            # CRuby RangeError, 4..5 out of range; here RangeError, 4 out of range
b = [+"abc", 1][0]; b[4..5] = "x"    # CRuby the same RangeError; here IndexError, index 4 out of string
f = "abc"; f[-5..1] = "x"            # CRuby RangeError; here FrozenError
```

The Range arm counted a negative start from the end once and `sp_str_splice_at` counted it again, so a start below the String wrote into it; a boxed receiver's `sp_poly_splice_range` did the same. Both now check the start against the String before the splice and raise with the Range's own text, ahead of the frozen check as CRuby has it. `lib/spinel_rt.h` only gains two lines.

The statement reads its value into a temp ahead of the check, so `s[1..2] = (s << "ef"; "x")` answers the same built with gcc and with clang.

An assignment inside the String pays the two compares: 1,296 instructions a `s[2..4] = "xyz"` before, 1,305 after (callgrind). Five existing tests change their generated C and print what they printed.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
