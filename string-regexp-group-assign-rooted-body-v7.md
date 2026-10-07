<!-- See CONTRIBUTING.md. A pull request needs no issue. If its gate fails here on a mechanical point, or it conflicts, we fix it and say so; a failure that needs a design decision goes back to its author. -->

## What this changes

```ruby
s = +"abc"; s << "defghijklmnop"
s[/(b)(cde)/, 2] = "XYZW"; p s   # CRuby "abXYZWfghijklmnop"; here, under SPINEL_GC_STRESS=2, "the mark reached a freed heap string"
```

`s[/re/, n] = v` as a statement built its answer in one nested call, `sp_str_concat(sp_str_concat(sp_str_byteslice(..), v), sp_str_byteslice(..))`: whichever piece C made first was in flight, unrooted, while the next allocated. In a plain run that loses a piece and raises nothing: 6 of 300,000 rounds of `s[/(a)(bc)/, 2] = "x" * 33` left `s` wrong built with gcc, 3 built with clang.

For a value that is a String by its type, a new arm cuts the head into a rooted temp and joins it with the value and the tail in one `sp_str_concat3`: 3,981 instructions a statement before, 3,841 after (callgrind). It reads the value ahead of the receiver, as CRuby reads its arguments, so `s[/(b)(cd)/, 2] = (s << "ZZ"; "x")` keeps the append built with gcc as with clang, and it tests the receiver for frozen last, as CRuby does (a negative group or one past the ninth, which CRuby takes and this statement still refuses, stays FrozenError on a frozen String). A value of another kind (nil, an Integer, a boxed value) raises where it is read, which CRuby does after the match, so it keeps the old arm, unchanged. `gc-stress-test` runs the new test.

Wrong on master in a plain run and unchanged here, now at level 2 as well where the fault used to stop them: a group that took no part in the match and a group past the pattern's own are stored without CRuby's IndexError, a nil String value without its TypeError. Two of those leave a different wrong String than master's, since the value is now read first: `s[/(x)?b/, 1] = (s << "Z"; "v")` keeps the append master lost built with gcc, and `s[/(b)c/, 2] = (t =~ /(w)(x)(y)/; "Q")` reads the spans the value's own match left. With a value that freezes the receiver, `s[/(x)?bc/, 1] = (s.freeze; "x")`, a missing group raises FrozenError here, where master stored and CRuby raises IndexError; the pull request that adds those raises, stacked on this one, rights it.

## `make gate` (on this branch merged with current master)

```
paste the Tests:, scale-test and gate: lines here
```

- [ ] New tests have `.expected` files that match CRuby 4.0 run with `--enable-frozen-string-literal`
- [ ] Values past 2^31 are marked `# spinel: int64`
- [ ] If optcarrot's generated C changed: callgrind numbers, checksum 59662
- [ ] Depends on: #
