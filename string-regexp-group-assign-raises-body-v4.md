<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s << "defghijklmnop"
s[/(x)?bc/, 1] = "XYZW"   # CRuby IndexError, regexp group 1 not matched; here s becomes "XYZWp"
s[/(b)c/, 3] = "XYZW"     # CRuby IndexError, index 3 out of regexp; here s becomes "XYZWabcdefghijklmnop"
s[/(b)(cd)/, 2] = v       # v nil: CRuby TypeError; here the group is deleted
```

A group that took no part in the match has -1 for its span, and the String was cut there. The index was tested against 9, not against the pattern: past the pattern's groups `sp_re_caps` holds whatever an earlier match left. A nil String value joined as "".

The statement now tests the index against `sp_re_last_ncap`, the group count `sp_re_match` records, then the group's start, then a nil value, then frozen, in CRuby's order and with its messages; `emit_str_splice_value` leaves the frozen check to this arm for that. So a frozen String whose pattern does not match, or whose group is missing, raises the IndexError as well. Four instructions a statement more with a literal value built with gcc (3,576 to 3,580, callgrind), five with clang; six and seven with a variable, six and thirteen with a value from a call.

The rooting of the arm's pieces and the value read before the String came with "A String's []= value runs before the String is cut"; this is what that arm still stored. The tests wait for the value to have run: a value of another type that runs code (`s[/(x)?bc/, 1] = Integer("q")`) is read at the splice, and what it raises must be heard first, as in CRuby, so for it the arm emits the C it did.

Left as they are: a negative group still raises IndexError where CRuby counts from the last group, and a group past the ninth of a longer pattern raises where CRuby stores (both FrozenError on a frozen String where the group took part in the match, as before). A boxed value that is no String raises FrozenError on a frozen String ahead of its TypeError, as before.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
