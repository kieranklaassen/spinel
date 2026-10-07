<!-- See CONTRIBUTING.md. A pull request whose gate fails here goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s << "defghijklmnop"
s[/(b)(cde)/, 2] = "XYZW"; p s   # CRuby "abXYZWfghijklmnop"; here, under SPINEL_GC_STRESS=2, "the mark reached a freed heap string"
```

`s[/re/, n] = v` as a statement built its answer in one nested call, `sp_str_concat(sp_str_concat(sp_str_byteslice(..), v), sp_str_byteslice(..))`: whichever piece C made first was in flight, unrooted, while the next allocated. In a plain run that loses a piece and raises nothing: 6 of 300,000 rounds of `s[/(a)(bc)/, 2] = "x" * 33` left `s` wrong built with gcc, 3 built with clang.

For a value that is a String by its type, a new arm cuts the head into a rooted temp and joins it with the value and the tail in one `sp_str_concat3`: 3,981 instructions a statement before, 3,844 after (callgrind). It reads the value ahead of the receiver, as CRuby reads its arguments, so `s[/(b)(cd)/, 2] = (s << "ZZ"; "x")` keeps the append built with gcc as with clang. A value of another kind (nil, an Integer, a boxed value) raises where it is read, which CRuby does after the match, so it keeps the old arm, unchanged. `gc-stress-test` runs the new test.

Wrong on master in a plain run and unchanged here, now at level 2 as well where the fault used to stop them: a group that took no part in the match and a group past the pattern's own are stored without CRuby's IndexError, a nil String value without its TypeError.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
