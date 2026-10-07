<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

Stacked on #NNNN (String#[]= with a Regexp group keeps its pieces rooted): its commit is the first here, and the one above it is this pull request's.

```ruby
s = +"abc"; s << "defghijklmnop"
s[/(x)?bc/, 1] = "XYZW"   # CRuby IndexError, regexp group 1 not matched; here s becomes "XYZWp"
s[/(b)c/, 3] = "XYZW"     # CRuby IndexError, index 3 out of regexp; here s becomes "XYZWabcdefghijklmnop"
s[/(b)(cd)/, 2] = v       # v nil: CRuby TypeError; here the group is deleted
```

A group that took no part in the match has -1 for its span, and the String was cut there. The index was tested against 9, not against the pattern: past the pattern's groups `sp_re_caps` holds whatever an earlier match left. A nil String value joined as "".

The statement now tests the index against `sp_re_last_ncap`, the group count `sp_re_match` records, then the group's start, then the value, then frozen, in CRuby's order and with its messages. Four instructions a statement more with a literal value (3,841 to 3,845, callgrind), six or seven with any other. A value that is not a String by its type gets the two group tests only when it has nothing to run (a literal, a plain variable read): one that raises must be heard first, as in CRuby.

Left as they are: a negative group still raises IndexError where CRuby counts from the last group, and a group past the ninth of a longer pattern raises where CRuby stores (both FrozenError on a frozen String, as before). For a value that is not a String by its type a frozen receiver raises FrozenError first, and a boxed value that comes from a call is still stored into a missing group.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [x] Depends on: #NNNN
